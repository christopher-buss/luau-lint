--!strict

--[=[
	@class RuleEngine
	
	Rule Execution Engine for luau-lint Plugin API
	
	This module implements the rule execution engine that orchestrates the
	linting process. It performs single-pass AST traversal, calls relevant rule
	listeners for each node type, handles errors gracefully, and collects all
	issues found by the rules.
	
	## Key Features
	
	- **Single-Pass Traversal**: Efficiently visits each AST node only once
	- **Rule Batching**: Only calls rules that are interested in each node type
	- **Error Handling**: Graceful handling of rule errors without stopping
	  execution
	- **Issue Collection**: Aggregates all issues found by rules
	- **Context Management**: Creates and manages rule contexts for each file
	
	## Example Usage
	
	```luau
	local engine = RuleEngine.createRuleEngine(registry)
	
	-- Lint a file
	local result = engine.lintFile(ast, sourceText, "file.luau")
	
	-- Process results
	for _, issue in result.issues do
		print(`{issue.ruleId}: {issue.message}`)
	end
	```
	
	@since v0.1.0
]=]

local Context = require("./context")
local ErrorHandling = require("../core/error-handling")
local Registry = require("./registry")
local Rule = require("./rule")

local result = require("@Batteries/result")

type AstNode = Rule.AstNode
type LintError = ErrorHandling.LintError
type NodeListener = Rule.NodeListener
type NodeListenerWithExit = Rule.NodeListenerWithExit
type NodeTag = Rule.NodeTag
type RegisteredRule = Registry.RegisteredRule
type RuleIssue = Rule.RuleIssue
type RuleRegistry = Registry.RuleRegistry
type RuleType = Rule.Rule

local createLintError = ErrorHandling.createLintError

--[=[
	@interface LintResult
	@within RuleEngine
	.issues { LintIssue } -- Array of all issues found during linting
	.errors { LintError } -- Array of any errors that occurred during execution
	.stats LintStats -- Statistics about the linting process
	
	Result of linting a file, containing all issues and metadata.
]=]
export type LintResult = {
	issues: { LintIssue },
	errors: { LintError },
	lintStats: LintStats,
}

--[=[
	@interface LintIssue
	@within RuleEngine
	.ruleId string -- ID of the rule that found this issue
	.message string -- Human-readable description of the issue
	.node any? -- Optional AST node where the issue occurs
	.loc Rule.SourceRange? -- Optional source location of the issue
	.fix Rule.RuleFix? -- Optional automatic fix for the issue
	
	An issue found by a rule during linting.
]=]
export type LintIssue = RuleIssue & {
	ruleId: string,
}

--[=[
	@interface LintStats
	@within RuleEngine
	.rulesExecuted number -- Number of rules that were executed
	.nodesVisited number -- Number of AST nodes visited
	.issuesFound number -- Number of issues found
	.executionTimeMs number -- Time taken to lint in milliseconds
	
	Statistics about the linting process.
]=]
export type LintStats = {
	rulesExecuted: number,
	nodesVisited: number,
	issuesFound: number,
	executionTimeMs: number,
}

--[=[
	@interface RuleEngine
	@within RuleEngine
	.lintFile (ast: any, sourceText: string, filename: string?) -> LintResult -- Lint a file
	.lintNode (node: any, sourceText: string, filename: string?) -> LintResult -- Lint a node
	
	Engine interface for executing rules against AST nodes.
]=]
export type RuleEngine = {
	lintFile: (ast: AstNode, sourceText: string, filename: string) -> LintResult,
	lintNode: (node: AstNode, sourceText: string, filename: string) -> LintResult,
}

--[=[
	Creates a new rule execution engine.
	
	The engine uses the provided registry to determine which rules to execute
	and efficiently batches rule execution by node type.
	
	@param registry RuleRegistry -- The rule registry containing all rules
	@return RuleEngine -- A new engine instance
	
	@since v0.1.0
]=]
local function createRuleEngine(registry: RuleRegistry): RuleEngine
	--[=[
		Recursively traverses an AST node and its children.
		
		@param node any -- The AST node to traverse
		@param visitors { [NodeType]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } } } -- Map of node types to listeners
		@param context { [string]: any } -- Map of rule IDs to contexts
		@param stats LintStats -- Statistics object to update
		
		@since v0.1.0
	]=]
	local function traverseNode(
		node: AstNode,
		visitors: {
			[NodeTag]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } },
		},
		contexts: { [string]: any },
		stats: LintStats
	): ()
		if type(node) ~= "table" then
			return
		end

		stats.nodesVisited += 1

		-- Call enter listeners for this node type
		local nodeVisitors = (visitors :: {
			[string]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } },
		})[node.tag]
		if nodeVisitors then
			for _, visitor in nodeVisitors do
				local status = result.pcall(function(): nil
					local listener = visitor.listener
					if type(listener) == "function" then
						-- Simple function listener
						listener(node)
					elseif type(listener) == "table" and listener.enter then
						-- Object with enter function
						listener.enter(node)
					end

					return nil
				end)

				if status.success == true then
					continue
				end

				-- Record the error but continue execution
				local _ruleError = createLintError(
					"RuleError",
					`Error in rule {visitor.rule.rule.id}`,
					{ filePath = contexts[visitor.rule.rule.id].filename :: string? }
				)

				-- TODO:: Collect these errors
			end
		end

		-- Recursively traverse child nodes
		local nodeTable = node :: { [string]: any }
		for key, value in nodeTable do
			if key ~= "parent" and key ~= "type" and key ~= "kind" then
				if type(value) == "table" then
					-- Check if it's an array by looking for numeric indices
					local valueTable = value :: { [any]: any }
					local isArray = false
					if valueTable[1] ~= nil then
						isArray = true
					end

					if isArray then
						-- Array of nodes
						for _, childNode in valueTable do
							traverseNode(childNode :: AstNode, visitors, contexts, stats)
						end
					else
						-- Single child node
						traverseNode(valueTable :: AstNode, visitors, contexts, stats)
					end
				end
			end
		end

		-- Call exit listeners for this node type
		if nodeVisitors then
			for _, visitor in nodeVisitors do
				local status = result.pcall(function(): nil
					local listener = visitor.listener
					if type(listener) == "table" and listener.exit then
						-- Object with exit function
						listener.exit(node :: any)
					end

					return nil
				end)

				if status.success == true then
					continue
				end

				-- Record the error but continue execution
				local _ruleError = createLintError(
					"RuleError",
					`Error in rule {visitor.rule.rule.id} exit`,
					{ filePath = contexts[visitor.rule.rule.id].filename :: string? }
				)
				-- Note: In a real implementation, we'd collect these errors
			end
		end
	end

	--[=[
		Lints a complete AST representing a file.
		
		@param ast any -- The root AST node to lint
		@param sourceText string -- The complete source text
		@param filename string? -- Optional filename for context
		@return LintResult -- The linting results
		
		@since v0.1.0
	]=]
	local function lintFile(ast: AstNode, sourceText: string, filename: string): LintResult
		local startTime = os.clock()

		-- Initialize result collections
		local allIssues: { LintIssue } = {}
		local allErrors: { LintError } = {}
		local lintStats: LintStats = {
			rulesExecuted = 0,
			nodesVisited = 0,
			issuesFound = 0,
			executionTimeMs = 0,
		}

		-- Get all registered rules
		local rules = registry.getAllRules()
		if #rules == 0 then
			lintStats.executionTimeMs = (os.clock() - startTime) * 1000
			return {
				issues = allIssues,
				errors = allErrors,
				lintStats = lintStats,
			}
		end

		-- Create contexts for each rule
		local contexts: { [string]: any } = {}
		local visitors: { [NodeTag]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } } } =
			{}

		local baseContext = Context.new({
			-- cwd = process.cwd,
			filename = filename,
			sourceText = sourceText,
		})

		for _, registeredRule in rules do
			if not registeredRule.enabled then
				continue
			end

			lintStats.rulesExecuted += 1

			local context = baseContext:extend({
				ruleId = registeredRule.rule.id,
				options = registeredRule.options,
				report = function(self, issue: RuleIssue): ()
					local lintIssue: LintIssue = {
						ruleId = registeredRule.rule.id,
						message = issue.message,
						node = issue.node,
						loc = issue.loc,
						fix = issue.fix,
					}
					table.insert(allIssues, lintIssue)
					lintStats.issuesFound += 1
				end,
			})

			contexts[registeredRule.rule.id] = context

			-- Get listeners from the rule
			local status = result.pcall(function(): Rule.ListenerMap
				return registeredRule.rule.create(context :: any)
			end)
			if status.success == false then
				local ruleError = createLintError(
					"RuleError",
					`Failed to create listeners for rule {registeredRule.rule.id}: {status.err}`,
					{ filePath = filename }
				)
				table.insert(allErrors, ruleError)
				continue
			end

			local listeners = status.value
			-- Validate listeners
			local isValid, errorMessage = Rule.validateListenerMap(listeners)
			if not isValid then
				local ruleError = createLintError(
					"RuleError",
					`Invalid listeners for rule {registeredRule.rule.id}: {errorMessage}`,
					{ filePath = filename }
				)
				table.insert(allErrors, ruleError)
				continue
			end

			-- Register listeners by node type
			for nodeType, listener in listeners :: { [string]: NodeListener | NodeListenerWithExit } do
				if not visitors[nodeType :: NodeTag] then
					visitors[nodeType :: NodeTag] = {}
				end
				table.insert(visitors[nodeType :: NodeTag], {
					rule = registeredRule,
					listener = listener,
				})
			end
		end

		-- Traverse the AST
		traverseNode(ast, visitors, contexts, lintStats)

		-- Calculate execution time
		lintStats.executionTimeMs = (os.clock() - startTime) * 1000

		return {
			issues = allIssues,
			errors = allErrors,
			lintStats = lintStats,
		}
	end

	--[=[
		Lints a single AST node (useful for testing or partial linting).
		
		@param node any -- The AST node to lint
		@param sourceText string -- The complete source text
		@param filename string? -- Optional filename for context
		@return LintResult -- The linting results
		
		@since v0.1.0
	]=]
	local function lintNode(node: AstNode, sourceText: string, filename: string): LintResult
		-- For single node linting, we treat the node as the root
		return lintFile(node, sourceText, filename)
	end

	-- Return the engine interface
	return {
		lintFile = lintFile,
		lintNode = lintNode,
	}
end

return {
	createRuleEngine = createRuleEngine,
}
