--!strict

local ApiTypes = require("../api-types/api")
local types = require("../types")

type Pick<K, V> = types.Pick<K, V>

--[=[
	@class RuleContext

	RuleContext Implementation for luau-lint Plugin API

	This module implements the RuleContext interface that provides utilities for rules
	to report issues, create fixes, access source text, and interact with the AST.
	The context is passed to each rule's `create` function and provides the primary
	API for rule implementations.

	## Key Features

	- **Issue Reporting**: Clean API for reporting linting issues with optional fixes
	- **Source Text Access**: Utilities for reading source code at specific ranges
	- **Auto-fix Creation**: Helper functions for creating automatic fixes
	- **Comment Access**: Methods for retrieving comments associated with nodes
	- **Scope Information**: Access to variable scope and binding information

	## Example Usage

	```luau
	-- Inside a rule's create function
	local function create(context)
		return {
			[NODE_TYPES.Local] = function(node)
				if node.name == "badName" then
					context:report({
						message = "Avoid using 'badName' as identifier",
						node = node,
						fix = context.createFix(
							node.range,
							"goodName"
						)
					})
				end
			end
		}
	end
	```

	@since v0.1.0
]=]

--[=[
	@interface ContextOptions
	@within RuleContext
	.cwd string? -- The current working directory of the project
	.ruleId string -- The ID of the rule this context belongs to
	.sourceText string -- The complete source text of the file being linted
	.filename string? -- Optional filename for the source being linted
	.options any? -- Rule-specific configuration options
	.report (issue: ApiTypes.RuleIssue) -> () -- Callback to report issues to the engine

	Configuration options for creating a RuleContext instance.
]=]
export type BaseContextOptions = {
	cwd: string?,
	filename: string,
	sourceText: string,
}

--[=[
	@interface ExtendContextOptions
	@within RuleContext
	.options Table? -- Optional table containing additional configuration options
	.report (self: Context, issue: ApiTypes.RuleIssue) -> () -- Function to report rule violations/issues
	.ruleId string -- Unique identifier for the rule being applied

	Options for extending a context with additional configuration.
]=]
export type ExtendContextOptions = {
	options: { [any]: any }?,
	report: (self: Context, issue: ApiTypes.RuleIssue) -> (),
	ruleId: string,
}

local Context = {}
Context.__index = Context

export type SourceContext = setmetatable<BaseContextOptions, typeof(Context)>
export type ContextStatic = Pick<typeof(Context), "new">

export type Context = SourceContext & ExtendContextOptions

--[=[
	Creates a new RuleContext instance with the specified options.

	The context provides utilities for rules to interact with the source code,
	report issues, create fixes, and access AST metadata like comments and scope.

	@param options ContextOptions -- Configuration for the context
	@return ApiTypes.RuleContext -- A fully configured context instance

	@since v0.1.0
]=]
function Context.new(options: BaseContextOptions): SourceContext
	local self: SourceContext = setmetatable(options, Context)
	return self
end

--[=[
	Creates an automatic fix for replacing text in a source range.

	@param range ApiTypes.SourceRange -- The range of source code to replace
	@param text string -- The replacement text
	@return ApiTypes.RuleFix -- A fix object that can be applied to the source

	@since v0.1.0
]=]
function Context.createFix(self: SourceContext, range: ApiTypes.SourceRange, text: string): ApiTypes.RuleFix
	-- Validate the range
	if type(range) ~= "table" or not range.start or not range.finish then
		error("Fix range must have start and end positions")
	end

	if type(text) ~= "string" then
		error("Fix text must be a string")
	end

	-- TODO: We'll move fixer into it's own module so we can supply more
	-- functionality, for now this will do.
	return {
		range = range,
		text = text,
	}
end

--[=[
	Retrieves the source text for a specific node or range with optional padding.

	This method extracts source code text from the current file, either for the entire
	source (when no node is provided) or for a specific AST node's location. Optional
	before and after padding allows retrieving additional context around the node.

	@param node ApiTypes.LintNode? -- The AST node to get source text for (optional)
	@param beforeCount number? -- Number of characters to include before the node (optional)
	@param afterCount number? -- Number of characters to include after the node (optional)
	@return string -- The extracted source text

	@since v0.1.0
]=]
function Context.getSourceText(
	self: SourceContext,
	node: ApiTypes.LintNode?,
	beforeCount: number?,
	afterCount: number?
): string
	if node == nil then
		return self.sourceText
	end

	-- Extract text using character offsets
	local startOffset = (node.location.start.offset or 0) - (beforeCount or 0)
	local endOffset = (node.location.finish.offset or 0) + (afterCount or 0)

	if startOffset < 0 or endOffset > #self.sourceText or startOffset > endOffset then
		error("Invalid source range")
	end

	return string.sub(self.sourceText, startOffset, endOffset)
end

--[=[
	Creates a new context with the current context as the base, and the specified
	properties as its own properties.

	@param options ExtendContextOptions -- The options for the new context
	@return Context -- The extended context

	@since v0.1.0
]=]
function Context.extend(self: SourceContext, options: ExtendContextOptions): Context
	local function create(inherited: SourceContext): SourceContext
		local obj = {}
		setmetatable(obj, { __index = inherited })
		return obj :: SourceContext
	end

	local function assign<T, U>(target: T, source: U): T & U
		for k, v in source :: any do
			(target :: any)[k] = v
		end

		return target
	end

	return table.freeze(assign(create(self), options) :: { [any]: any }) :: Context
end

return Context :: ContextStatic
