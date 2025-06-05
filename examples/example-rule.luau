--[[
    Example Rule: Generalized Iteration
    
    This example demonstrates a single rule implementation following the proposed
    Rule API for the Luau Linter. This showcases how rules are structured and
    how they interact with the AST visitor system.
    
    The rule detects usage of pairs() and ipairs() in for-in loops and suggests
    using Luau's direct table iteration instead for better performance.
]]

-- Rule metadata types following our design specifications
export type RuleCategory =
	-- Rules that don't change the AST
	| "formatting"
	-- Rules that change the AST but don't change code logic
	| "stylistic"
	-- Rules that change code logic
	| "logical"

type FixCategory =
	-- No automatic fix available
	| "none"
	-- Can be automatically applied safely
	| "auto"
	-- Requires user review before applying
	| "suggestion"

type RuleDependency = {
	ruleId: string,
	required: boolean?,
	conflict: boolean?,
}

export type Rule = {
	id: string,
	title: string,
	description: string,
	category: RuleCategory,
	fixable: FixCategory,
	docsUrl: string,
	dependsOn: { RuleDependency }?,
	conflictsWith: { RuleDependency }?,
	create: (context: RuleContext) -> RuleListener,
}

-- Mock AST node types (these would come from Lute's visitor system)
export type ASTNode = {
	type: string,
	range: { number },
	parent: ASTNode?,
}

-- Mock source code utilities (these would come from Lute's system)
export type SourceCode = {
	getText: (self: SourceCode, node: ASTNode?) -> string,
}

export type Scope = {
	-- Scope information would be defined by Lute
}

export type Fix = {
	range: { number }, -- [start, end] positions
	text: string, -- replacement text
}

export type RuleFixer = {
	replaceText: (node: ASTNode, text: string) -> Fix,
	replaceTextRange: (range: { number }, text: string) -> Fix,
	insertTextBefore: (node: ASTNode, text: string) -> Fix,
	insertTextAfter: (node: ASTNode, text: string) -> Fix,
	removeText: (node: ASTNode) -> Fix,
}

export type RuleContext = {
	-- Current file being analyzed
	filename: string,
	sourceCode: string,

	-- Configuration for this rule
	settings: { [string]: any },

	-- Reporting functions
	report: (self: RuleContext, diagnostic: Diagnostic) -> (),

	-- Source code utilities
	getSourceCode: (self: RuleContext) -> SourceCode,
	getScope: (self: RuleContext) -> Scope?,
	getAncestors: (self: RuleContext) -> { ASTNode },

	-- Fix utilities
	fix: (self: RuleContext, fixerFn: (fixer: RuleFixer) -> Fix) -> Fix?,
}

export type RuleListener = {
	-- Visitor methods that handle specific AST node types
	[string]: (node: ASTNode) -> (),
}

export type Diagnostic = {
	node: ASTNode,
	message: string,
	fix: Fix?,
}

export type CallExpression = ASTNode & {
	type: "CallExpression",
	base: ASTNode,
	args: { ASTNode },
}

export type ForInStatement = ASTNode & {
	type: "ForInStatement",
	vars: { ASTNode },
	values: { ASTNode },
	body: ASTNode,
}

export type Identifier = ASTNode & {
	type: "Identifier",
	name: string,
}

-- Example rule implementation
local function createRule(rule: Rule): Rule
	return rule
end

local generalizedIterationRule = createRule({
	id = "generalizedIteration",
	title = "Use direct table iteration instead of pairs() and ipairs()",
	description = "Luau's generalized iteration allows direct table iteration using `for k, v in "
		.. "table do` syntax without `pairs()` or `ipairs()`. This provides unified iteration "
		.. "semantics that automatically handles both arrays and dictionaries with consistent "
		.. "behavior. Using the older functions adds unnecessary verbosity when direct iteration "
		.. "accomplishes the same result more elegantly.",
	category = "logical",
	fixable = "auto",
	docsUrl = "https://example.com/docs/generalized-iteration",

	create = function(context: RuleContext): RuleListener
		local function checkForInStatement(node: ASTNode): ()
			-- Type guard to ensure this is a ForInStatement
			local forInNode = node :: ForInStatement

			-- Check if this is a for-in loop with pairs/ipairs
			if #forInNode.values ~= 1 then
				return
			end

			local valueExpr = forInNode.values[1]
			if valueExpr.type ~= "CallExpression" then
				return
			end

			local callExpr = valueExpr :: CallExpression
			if callExpr.base.type ~= "Identifier" then
				return
			end

			local funcName = (callExpr.base :: Identifier).name

			if funcName == "pairs" or funcName == "ipairs" then
				local iteratedTable = callExpr.args[1]
				local replacement: string
				local messageType: string

				if funcName == "pairs" then
					-- For pairs, suggest direct iteration
					replacement = context:getSourceCode():getText(iteratedTable)
					messageType = "pairs()"
				else
					-- For ipairs, suggest either generalized iteration or numeric loop
					local tableText = context:getSourceCode():getText(iteratedTable)
					replacement = tableText
					messageType = "ipairs()"
				end

				context:report({
					node = callExpr,
					message = string.format(
						"Avoid %s for better performance. Use generalized iteration instead.",
						messageType
					),
					fix = context:fix(function(fixer: RuleFixer): Fix
						-- Replace pairs(table) or ipairs(table) with just table
						return fixer.replaceText(valueExpr, replacement)
					end),
				})
			end
		end

		-- Return listener object following the ESLint approach
		return {
			ForInStatement = checkForInStatement,
		}
	end,
})

-- Example usage patterns (for documentation purposes):
--[[
Valid patterns that this rule encourages:
    for key, value in myTable do end
    for i = 1, #myArray do local value = myArray[i] end
    for i, value in myArray do end

Invalid patterns that this rule flags:
    for key, value in pairs(myTable) do end
    for i, value in ipairs(myArray) do end

The rule will automatically suggest fixes to remove the unnecessary function calls.
]]

return generalizedIterationRule
