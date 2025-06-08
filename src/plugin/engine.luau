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

local Luau = require("@lute/Luau")
local Result = require("@batteries/result")

local Context = require("./context")
local ErrorHandling = require("../core/error-handling")
local Registry = require("./registry")
local Rule = require("./rule")

type AstNode = Rule.AstNode
type AstStatBlock = Luau.AstStatBlock
type LintError = ErrorHandling.LintError
type LintNode = Rule.LintNode
type NodeListener = Rule.NodeListener
type NodeListenerWithExit = Rule.NodeListenerWithExit
type NodeTag = Rule.NodeTag
type RegisteredRule = Registry.RegisteredRule
type RuleIssue = Rule.RuleIssue
type RuleRegistry = Registry.RuleRegistry
type RuleType = Rule.Rule

local createLintError = ErrorHandling.createLintError

local function merge<T, U>(source0: T, source1: U): T & U
	local result = table.clone(source0)

	assert(type(source1) == "table", "Luau")

	for key, value in source1 :: any do
		(result :: any)[key] = value
	end

	return result
end

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
	executionTimeMs: number,
	fixableIssues: number,
	issuesFound: number,
	nodesVisited: number,
	rulesExecuted: number,
}

--[=[
	@interface RuleEngine
	@within RuleEngine
	.lintFile (ast: any, sourceText: string, filename: string?) -> LintResult -- Lint a file
	.lintNode (node: any, sourceText: string, filename: string?) -> LintResult -- Lint a node
	
	Engine interface for executing rules against AST nodes.
]=]
export type RuleEngine = {
	lintFile: (ast: AstStatBlock, sourceText: string, filename: string) -> LintResult, -- Changed AstNode to AstStatBlock
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
		Calculates the starting character offset for each line in the source text.
		Line numbers are 1-indexed. Character offsets are 0-indexed.
		
		@param sourceText string -- The source code of the file
		@return {number} -- An array where the index is the line number (1-based)
			and the value is the character offset (0-based) of the start of that line.
	]=]
	local function calculateLineStartOffsets(sourceText: string): { number }
		local offsets = { 0 } -- Line 1 (1-indexed) starts at character offset 0
		local currentCharacterOffset = 0
		for i = 1, #sourceText do
			-- currentCharacterOffset is the 0-indexed offset of the character sourceText:sub(i,i)
			if sourceText:sub(i, i) == "\n" then
				if i < #sourceText then -- Ensure there's a next line
					-- The character after \n is at currentCharacterOffset + 1
					table.insert(offsets, currentCharacterOffset + 1)
				end
			end
			currentCharacterOffset += 1
		end
		return offsets
	end

	--[=[
		Recursively traverses an AST node and its children.
		
		@param node any -- The AST node to traverse
		@param visitors { [NodeType]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } } } -- Map of node types to listeners
		@param context { [string]: any } -- Map of rule IDs to contexts
		@param stats LintStats -- Statistics object to update
		@param lineStartOffsets {number} -- Array of character offsets for the start of each line
		
		@since v0.1.0
	]=]
	local function traverseNode(
		node: LintNode,
		visitors: {
			[NodeTag]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } },
		},
		contexts: { [string]: any },
		stats: LintStats,
		lineStartOffsets: { number }
	): ()
		if type(node) ~= "table" then
			return
		end

		stats.nodesVisited += 1

		-- Calculate and attach character offsets if location is available
		local loc = node.location
		-- Luau.Position line is 1-based, column is 0-based
		local startCharOffset = lineStartOffsets[loc.begin.line] + loc.begin.column
		-- Assuming loc["end"] is an exclusive end position (points to the char *after* the node)
		local endCharOffset = lineStartOffsets[loc["end"].line] + loc["end"].column;

		(node :: any).charOffsetRange = {
			start = startCharOffset, -- Inclusive start character offset
			finish = endCharOffset, -- Exclusive end character offset
		}

		-- Call enter listeners for this node type
		local nodeVisitors = (visitors :: {
			[string]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } },
		})[node.tag]
		if nodeVisitors then
			for _, visitor in nodeVisitors do
				local status = Result.pcall(function(): nil
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
			if key ~= "parent" and key ~= "type" and key ~= "kind" and key ~= "charOffsetRange" then -- Avoid re-traversing our new property
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
							traverseNode(
								childNode :: AstNode,
								visitors,
								contexts,
								stats,
								lineStartOffsets
							)
						end
					else
						-- Single child node
						traverseNode(
							valueTable :: AstNode,
							visitors,
							contexts,
							stats,
							lineStartOffsets
						)
					end
				end
			end
		end

		-- Call exit listeners for this node type
		if nodeVisitors then
			for _, visitor in nodeVisitors do
				local status = Result.pcall(function(): nil
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

	local function getLoc(node: (Rule.AstNode & { location: Luau.Location? })?): Rule.SourceRange?
		if node == nil or node.location == nil then
			return nil
		end

		return {
			start = {
				line = node.location.begin.line,
				column = node.location.begin.column,
			},
			finish = {
				line = node.location["end"].line,
				column = node.location["end"].column,
			},
		}
	end

	local lintNodes: { [AstNode]: LintNode } = {}

	local function createLintNode(node: AstNode): LintNode
		local existingNode = lintNodes[node]
		if existingNode then
			return existingNode
		end

		local lintNode: LintNode = merge(node, {
			location = {
				start = {
					line = 1,
					column = 2,
					offset = 5,
				},
				finish = {
					line = 3,
					column = 4,
					offset = 6,
				},
			},
		})

		lintNodes[node] = lintNode
		return lintNode
	end

	--[=[
		Lints a complete AST representing a file.
		
		@param ast any -- The root AST node to lint
		@param sourceText string -- The complete source text
		@param filename string? -- Optional filename for context
		@return LintResult -- The linting results
		
		@since v0.1.0
	]=]
	local function lintFile(ast: AstStatBlock, sourceText: string, filename: string): LintResult
		local startTime = os.clock()

		-- Initialize result collections
		local allIssues: { LintIssue } = {}
		local allErrors: { LintError } = {}
		local lintStats: LintStats = {
			executionTimeMs = 0,
			fixableIssues = 0,
			issuesFound = 0,
			nodesVisited = 0,
			rulesExecuted = 0,
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

		-- Calculate line start offsets once per file
		local lineStartOffsets = calculateLineStartOffsets(sourceText)

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
						loc = issue.loc or getLoc(issue.node :: any),
						fix = issue.fix,
					}
					table.insert(allIssues, lintIssue)
					lintStats.issuesFound += 1
					lintStats.fixableIssues += if issue.fix ~= nil then 1 else 0
				end,
			})

			contexts[registeredRule.rule.id] = context

			-- Get listeners from the rule
			local status = Result.pcall(function(): Rule.ListenerMap
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

		for _, statement in ast.statements do
			-- Traverse the AST
			traverseNode(createLintNode(statement), visitors, contexts, lintStats, lineStartOffsets)
		end

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
		-- This will implicitly use the new lineStartOffsets logic via lintFile
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
