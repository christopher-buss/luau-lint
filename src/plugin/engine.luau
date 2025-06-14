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
local VisitorKeys = require("./visitor-keys")
local pp = require("../pretty-print")
local types = require("../types")

type Omit<K, V> = types.Omit<K, V>
type Pick<K, V> = types.Pick<K, V>
type Required<T> = types.Required<T>
type OmitPrivate<T> = types.OmitPrivates<T>

type AstNode = Rule.AstNode
type AnyNode = Rule.AnyNode
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
local TraversalKeys = VisitorKeys.VisitorKeys

--[=[
	Merges properties from a source object into a target object.
	
	This is a shallow merge operation that copies all enumerable properties
	from the source object to the target object. The target object is modified
	in place and also returned.
	
	@param target T -- The target object to merge properties into
	@param source U -- The source object to copy properties from
	@return T & U -- The target object with merged properties
	
	@since v0.1.0
]=]
local function assign<T, U>(target: T, source: U): T & U
	for k, v in source :: any do
		(target :: any)[k] = v
	end

	return target
end

--[=[
	Merges properties from a source object into a target object, creating a new object.
	
	This function creates a shallow copy of the target object and then copies all
	enumerable properties from the source object into the copy. Unlike `assign`,
	this function does not modify the original target object.
	
	@param target T -- The target object to use as the base
	@param source U -- The source object to copy properties from
	@return T & U -- A new object with properties from both target and source
	
	@since v0.1.0
]=]
local function merge<T, U>(target: T, source: U): T & U
	local result = table.clone(target)

	for key, value in source :: any do
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
export type LintIssue = Omit<RuleIssue, "loc"> & Required<Pick<RuleIssue, "loc">> & {
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
	Calculates the starting character offset for each line in the source text.
	Line numbers are 1-indexed. Character offsets are 0-indexed.
	
	@param sourceText string -- The source code of the file
	@return {number} -- An array where the index is the line number (1-based)
		and the value is the character offset (0-based) of the start of that line.
]=]
local function calculateLineStartOffsets(sourceText: string): { number }
	local offsets = { 0 }
	local currentCharacterOffset = 0
	for i = 1, #sourceText do
		if sourceText:sub(i, i) == "\n" and i < #sourceText then
			table.insert(offsets, currentCharacterOffset + 1)
		end

		currentCharacterOffset += 1
	end

	return offsets
end

--[=[
	Normalizes the location information of an AST node.
	
	Some AST nodes have a `location` field with begin/end positions, while
	others (like tokens) only have a `position` and `text`. This function
	normalizes both cases into a consistent Location format.
	
	For nodes with only position/text, it calculates the end position by
	adding the text length to the start position (assuming single-line text).
	
	@param node AnyNode -- The AST node to normalize location for
	@return Luau.Location? -- The normalized location, or nil if insufficient data
	
	@since v0.1.0
]=]
local function normalizeLocation(node: AnyNode): Luau.Location?
	if node.location ~= nil then
		return node.location
	end

	if node.argLocation ~= nil then
		return node.argLocation
	end

	if node.position == nil then
		print("could not normalize")
		return nil
	end

	local positionType = if node.position then "position" else "argLocation"

	local startLine = node[positionType].line :: number
	local startColumn = node[positionType].column :: number

	assert(node.text, "Expected node.text to be defined")
	local nodeTextLength = #node.text

	return {
		begin = {
			line = startLine,
			column = startColumn,
		},
		["end"] = {
			line = startLine,
			column = startColumn + nodeTextLength,
		},
	}
end

type RuleEngineOptions = {
	registry: RuleRegistry,
}

type RuleEngineData = RuleEngineOptions

local RuleEngine = {}
RuleEngine.__index = RuleEngine

type RuleEngine = setmetatable<RuleEngineData, typeof(RuleEngine)>

--[=[
	@interface RuleEngine
	@within RuleEngine
	
	Engine interface for executing rules against AST nodes.
]=]
export type RuleEnginePublic = setmetatable<OmitPrivate<RuleEngineData>, typeof(RuleEngine)>

--[=[
	Creates a new rule execution engine.
	
	The engine uses the provided registry to determine which rules to execute
	and efficiently batches rule execution by node type.
	
	@param registry RuleRegistry -- The rule registry containing all rules
	@return RuleEngine -- A new engine instance
	
	@since v0.1.0
]=]
function RuleEngine.new(options: RuleEngineOptions): RuleEnginePublic
	return setmetatable(
		merge(options, {
			_lintNodes = setmetatable({}, { __mode = "k" }),
		}),
		RuleEngine
	)
end

--[=[
	Converts an AST node to a LintNode with normalized location information.
	
	This function transforms raw AST nodes into a standardized format that includes
	consistent location data. It caches converted nodes to avoid duplicate processing
	and ensures that location information is properly normalized.
	
	The function performs the following transformations:
	- Normalizes location data from various AST node formats
	- Adds placeholder character offsets (calculated later during traversal)
	- Caches converted nodes to prevent reprocessing
	- Returns nil for nodes without sufficient location information
	
	@param node AnyNode -- The raw AST node to convert
	@return LintNode? -- The converted node with normalized location, or nil if conversion fails
	
	@since v0.1.0
]=]
function RuleEngine.createLintNode(self: RuleEngine, node: AnyNode): LintNode?
	if type(node) ~= "table" then
		return nil
	end

	local existingNode = node
		and (node :: any).location ~= nil
		and (node :: any).location.start ~= nil
		and (node :: any).location.start.offset ~= nil
	if existingNode then
		return node :: any
	end

	local location = normalizeLocation(node :: any)
	if not location then
		return nil
	end

	local lintNode = assign(node, {
		location = {
			start = {
				line = location.begin.line,
				column = location.begin.column,
				offset = -1,
			},
			finish = {
				line = location["end"].line,
				column = location["end"].column,
				offset = -1,
			},
		},
	})

	return lintNode
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
function RuleEngine.traverseNode(
	self: RuleEngine,
	node: LintNode,
	visitors: {
		[NodeTag]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } },
	},
	contexts: { [string]: any },
	stats: LintStats,
	lineStartOffsets: { number }
): ()
	if type(node) ~= "table" or not node.tag then
		return
	end

	stats.nodesVisited += 1

	local loc = node.location
	node.location.start.offset = lineStartOffsets[loc.start.line + 1] + loc.start.column
	node.location.finish.offset = lineStartOffsets[loc.finish.line + 1] + loc.finish.column

	local nodeType = VisitorKeys.getNodeType(node)

	-- Call enter listeners for this node type
	local nodeVisitors = (visitors :: {
		[string]: { { rule: RegisteredRule, listener: NodeListener | NodeListenerWithExit } },
	})[nodeType]
	if nodeVisitors then
		for _, visitor in nodeVisitors do
			local status = Result.pcall(function(): nil
				local listener = visitor.listener
				if type(listener) == "function" then
					listener(node)
				elseif type(listener) == "table" and listener.enter then
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
				contexts[visitor.rule.rule.id].filename
			)

			pp(status.err)

			-- TODO:: Collect these errors
		end
	end

	local keys = TraversalKeys[nodeType]
	if keys and #keys > 0 then
		-- Recursively traverse child nodes
		for _, value in keys :: { keyof<typeof(node)> } do
			local childNode = node[value] :: AnyNode
			if type(childNode) == "table" and childNode[1] ~= nil then
				for _, child in childNode do
					local lintNode = self:createLintNode(child.node :: any)
					if not lintNode then
						continue
					end

					self:traverseNode(lintNode, visitors, contexts, stats, lineStartOffsets)
				end
			else
				local lintNode = self:createLintNode(childNode :: any)
				if not lintNode then
					continue
				end

				self:traverseNode(lintNode, visitors, contexts, stats, lineStartOffsets)
			end
		end
	end

	-- Call exit listeners for this node type
	if nodeVisitors then
		for _, visitor in nodeVisitors do
			local status = Result.pcall(function(): nil
				local listener = visitor.listener
				if type(listener) == "table" and listener.exit then
					listener.exit(node)
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

			pp(status.err)
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
function RuleEngine.lintFile(
	self: RuleEngine,
	ast: AstStatBlock,
	sourceText: string,
	filename: string
): LintResult
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
	local rules = self.registry.getAllRules()
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
			report = function(_, issue: RuleIssue): ()
				local location = issue.loc or (issue.node and issue.node.location)
				if location == nil then
					local ruleError = createLintError(
						"RuleError",
						`Error in rule {registeredRule.rule.id} report. Missing location.`,
						{ filePath = filename }
					)
					table.insert(allErrors, ruleError)
					return
				end

				local lintIssue: LintIssue = {
					ruleId = registeredRule.rule.id,
					message = issue.message,
					node = issue.node,
					loc = location,
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
		local lintNode = self:createLintNode(statement :: any)
		if lintNode then
			self:traverseNode(lintNode, visitors, contexts, lintStats, lineStartOffsets)
		end
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
function RuleEngine.lintNode(
	self: RuleEngine,
	node: AstNode,
	sourceText: string,
	filename: string
): LintResult
	local syntheticBlock: AstStatBlock = {
		tag = "block",
		statements = { node :: any },
	}

	return self:lintFile(syntheticBlock, sourceText, filename)
end

-- Return the engine interface
return RuleEngine :: Pick<RuleEngine, "new">
