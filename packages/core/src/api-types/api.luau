--!strict

--[=[
	@class CoreTypes

	Public API Types for luau-lint Core

	This module contains all public type definitions used throughout the luau-lint
	core package. These types define the interfaces for rules, contexts, issues,
	and other core concepts.

	@since v0.1.0
]=]

local Luau = require("@lute/luau")

-- cspell:disable
local NODE_TYPES: { [NodeType]: NodeTag } = {
	AnonymousFunction = "anonymousfunction",
	Assign = "assign",
	Binary = "binary",
	Block = "block",
	Boolean = "boolean",
	Call = "call",
	CompoundAssign = "compoundassign",
	Expression = "expression",
	For = "for",
	ForIn = "forin",
	Function = "function",
	Global = "global",
	Group = "group",
	If = "if",
	IfExpression = "ifexpression",
	IndexExpr = "indexexpr",
	IndexName = "indexname",
	InterpolatedString = "interpolatedstring",
	Local = "local",
	LocalDeclaration = "localdeclaration",
	LocalFunction = "localfunction",
	LocalReference = "localreference",
	Nil = "nil",
	Number = "number",
	Repeat = "repeat",
	Return = "return",
	StatTypeFunction = "stattypefunction",
	String = "string",
	Table = "table",
	TableItem = "tableitem",
	Token = "token",
	TypeAlias = "typealias",
	TypeArray = "typearray",
	TypeAssertion = "typeassertion",
	TypeBoolean = "typeboolean",
	TypeFunction = "typefunction",
	TypeGroup = "typegroup",
	TypeIntersection = "typeintersection",
	TypePackExplicit = "typepackexplicit",
	TypePackGeneric = "typepackgeneric",
	TypePackVariadic = "typepackvariadic",
	TypeReference = "typereference",
	TypeString = "typestring",
	TypeTable = "typetable",
	TypeTypeof = "typetypeof",
	TypeUnion = "typeunion",
	Unary = "unary",
	Varargs = "varargs",
	While = "while",
}
-- cspell:enable

local function flip<K, V>(dictionary: { [K]: V }): { [V]: K }
	local result = {}
	for key, value in dictionary do
		result[value] = key
	end
	return result
end

local TAG_TO_NODE = flip(NODE_TYPES :: { [NodeType]: NodeTag })

--[=[
	@type NodeTag string
	@within CoreTypes

	The [NodeTag] represents an AST node tag used internally by the Luau parser.
]=]
export type NodeTag =
	| "anonymousfunction"
	| "assign"
	| "binary"
	| "block"
	| "boolean"
	| "call"
	| "compoundassign"
	| "expression"
	| "for"
	| "forin"
	| "function"
	| "global"
	| "group"
	| "if"
	| "ifexpression"
	| "indexexpr"
	| "indexname"
	| "interpolatedstring"
	| "local"
	| "localdeclaration"
	| "localfunction"
	| "localreference"
	| "nil"
	| "number"
	| "repeat"
	| "return"
	| "stattypefunction"
	| "string"
	| "table"
	| "tableitem"
	| "token"
	| "typealias"
	| "typearray"
	| "typeassertion"
	| "typeboolean"
	| "typefunction"
	| "typegroup"
	| "typeintersection"
	| "typepackexplicit"
	| "typepackgeneric"
	| "typepackvariadic"
	| "typereference"
	| "typestring"
	| "typetable"
	| "typetypeof"
	| "typeunion"
	| "unary"
	| "varargs"
	| "while"

--[=[
	@type NodeType string
	@within CoreTypes

	The [NodeType] represents a string literal representing an AST node type that rules can listen to.
]=]
export type NodeType =
	| "AnonymousFunction"
	| "Assign"
	| "Binary"
	| "Block"
	| "Boolean"
	| "Call"
	| "CompoundAssign"
	| "Expression"
	| "For"
	| "ForIn"
	| "Function"
	| "Global"
	| "Group"
	| "If"
	| "IfExpression"
	| "IndexExpr"
	| "IndexName"
	| "InterpolatedString"
	| "Local"
	| "LocalDeclaration"
	| "LocalFunction"
	| "LocalReference"
	| "Nil"
	| "Number"
	| "Repeat"
	| "Return"
	| "StatTypeFunction"
	| "String"
	| "Table"
	| "TableItem"
	| "Token"
	| "TypeAlias"
	| "TypeArray"
	| "TypeAssertion"
	| "TypeBoolean"
	| "TypeFunction"
	| "TypeGroup"
	| "TypeIntersection"
	| "TypePackExplicit"
	| "TypePackGeneric"
	| "TypePackVariadic"
	| "TypeReference"
	| "TypeString"
	| "TypeTable"
	| "TypeTypeof"
	| "TypeUnion"
	| "Unary"
	| "Varargs"
	| "While"

--[=[
	@type RuleCategory "formatting" | "stylistic" | "logical"
	@within CoreTypes

	Categories for organizing rules in documentation and configuration.
]=]
export type RuleCategory =
	-- Rules that don't change the AST
	| "formatting"
	-- Rules that change code logic
	| "logical"
	-- Rules that change the AST but don't change code logic
	| "stylistic"

--[=[
	@type FixCategory "none" | "auto" | "suggestion"
	@within CoreTypes

	Categories for automatic fix capabilities of rules.
]=]
export type FixCategory =
	-- Can be automatically applied safely
	| "auto"
	-- No automatic fix available
	| "none"
	-- Requires user review before applying
	| "suggestion"

--[=[
	@interface SourcePosition
	@within CoreTypes
	.line number -- Line number (1-based)
	.column number -- Column number (1-based)
	.offset number -- Character offset from start of file (0-based)

	Represents a position in source code.
]=]
export type SourcePosition = {
	line: number,
	column: number,
	offset: number,
}

--[=[
	@interface SourceRange
	@within CoreTypes
	.start SourcePosition -- Starting position
	.finish SourcePosition -- Ending position

	Represents a range in source code.
]=]
export type SourceRange = {
	start: SourcePosition,
	finish: SourcePosition,
}

export type Source = { location: SourceRange }

--[=[
	@interface RuleFix
	@within CoreTypes
	.range SourceRange -- Source range to replace
	.text string -- Replacement text

	Represents an automatic fix for a linting issue.
]=]
export type RuleFix = {
	range: SourceRange,
	text: string,
}

--[[
	Represents any type of AST (Abstract Syntax Tree) node in Luau.

	This type union encompasses all possible node types that can be encountered
	when traversing or analyzing Luau source code:
	- AstType: Type annotations and type expressions
	- AstExpr: Expressions (literals, variables, function calls, etc.)
	- AstStat: Statements (assignments, control flow, function definitions, etc.)

	Used as a general parameter type for functions that need to work with
	any kind of AST node regardless of its specific category.
]]
export type AstNode = Luau.AstType | Luau.AstExpr | Luau.AstStat

export type AnyNode = AstNode & {
	argLocation: Luau.Location?,
	location: Luau.Location?,
	position: Luau.Position?,
	text: string?,
}

export type LintNode = AstNode & Source

--[=[
	@interface RuleIssue
	@within CoreTypes
	.message string -- Human-readable issue description
	.node AstNode? -- Optional AST node where the issue occurs
	.loc SourceRange? -- Optional source location of the issue
	.fix RuleFix? -- Optional automatic fix for the issue

	Represents a linting issue found by a rule.
]=]
export type RuleIssue = {
	message: string,
	node: LintNode?,
	loc: SourceRange?,
	fix: RuleFix?,
}

--[=[
	@interface RuleContext
	@within CoreTypes
	.cwd string? -- Current working directory
	.filename string -- Name of the file being linted
	.sourceText string -- Full source text of the file
	.options any? -- Rule-specific configuration options
	.report (issue: RuleIssue) -> () -- Report a linting issue
	.ruleId string -- ID of the rule using this context
	.createFix (range: SourceRange, text: string) -> RuleFix -- Create an auto-fix
	.getSourceText (node: LintNode?, beforeCount: number?, afterCount: number?) -> string -- Get source text for a range
	.extend (newContext: RuleContext) -> RuleContext -- Create extended context

	Context object passed to rule create functions containing utilities for
	reporting issues, creating fixes, and accessing source information.
]=]
export type RuleContext = {
	cwd: string?,
	filename: string,
	sourceText: string,
	options: { [any]: any }?,
	report: (self: RuleContext, issue: RuleIssue) -> (),
	ruleId: string,
	createFix: (self: RuleContext, range: SourceRange, text: string) -> RuleFix,
	getSourceText: (
		self: RuleContext,
		node: LintNode?,
		beforeCount: number?,
		afterCount: number?
	) -> string,
	extend: (self: RuleContext, newContext: RuleContext) -> RuleContext,
}

--[=[
	@interface RuleMetadata
	@within CoreTypes
	.id string -- Unique identifier for the rule (e.g., "noUnusedVariables")
	.title string -- Human-readable rule title
	.description string -- Detailed description of what the rule checks
	.category RuleCategory -- Category for organizing rules
	.fixable FixCategory -- Whether the rule can automatically fix issues
	.docsUrl string -- URL to rule documentation

	Metadata that describes a rule and its capabilities.
]=]
export type RuleMetadata = {
	id: string,
	title: string,
	description: string,
	category: RuleCategory,
	fixable: FixCategory,
	docsUrl: string,
}

--[=[
	@interface NodeListener
	@within CoreTypes
	.(node: any) -> () -- Function that handles an AST node

	A function that receives an AST node when it's encountered during traversal.
]=]
export type NodeListener = (node: AstNode) -> ()

--[=[
	@interface NodeListenerWithExit
	@within CoreTypes
	.enter NodeListener? -- Optional function called when entering the node
	.exit NodeListener? -- Optional function called when exiting the node

	Advanced listener that can handle both entering and exiting a node.
]=]
export type NodeListenerWithExit = {
	enter: NodeListener?,
	exit: NodeListener?,
}

--[=[
	@type ListenerMap { [NodeTag]: NodeListener | NodeListenerWithExit }
	@within CoreTypes

	Map of node types to their corresponding listener functions.
]=]
-- TODO: Fix this type when Luau supports it better
export type ListenerMap = { [any]: any }

--[=[
	@interface RuleCreateFunction
	@within CoreTypes
	.(context: RuleContext) -> ListenerMap -- Function that creates rule listeners

	The main function that defines a rule's behavior.
]=]
export type RuleCreateFunction = (context: RuleContext) -> ListenerMap

--[=[
	@interface Rule
	@within CoreTypes
	.id string -- Unique rule identifier
	.title string -- Human-readable rule title
	.description string -- Detailed rule description
	.category RuleCategory -- Rule category
	.fixable FixCategory -- Whether rule supports auto-fixing
	.docsUrl string -- Optional documentation URL
	.create RuleCreateFunction -- Function that creates rule listeners

	Complete rule definition with metadata and implementation.
]=]
export type Rule = RuleMetadata & {
	create: RuleCreateFunction,
}

--[=[
	@interface RegisteredRule
	@within CoreTypes
	.rule Rule -- The rule definition
	.nodeTypes { NodeType } -- Node types this rule is interested in

	Internal representation of a registered rule with its node type interests.
]=]
export type RegisteredRule = {
	rule: Rule,
	nodeTypes: { NodeType },
}

--[=[
	@interface LintIssue
	@within CoreTypes
	.ruleId string -- ID of the rule that found this issue
	.severity "error" | "warning" | "info" -- Issue severity
	.message string -- Human-readable issue description
	.line number -- Line number where issue occurs (1-based)
	.column number -- Column number where issue occurs (1-based)
	.endLine number? -- End line of the issue range
	.endColumn number? -- End column of the issue range
	.fix RuleFix? -- Optional automatic fix

	Represents a single linting issue found in a file.
]=]
export type LintIssue = {
	ruleId: string,
	severity: "error" | "warning" | "info",
	message: string,
	line: number,
	column: number,
	endLine: number?,
	endColumn: number?,
	fix: RuleFix?,
}

--[=[
	@interface LintStats
	@within CoreTypes
	.errors number -- Total number of errors found
	.warnings number -- Total number of warnings found
	.infos number -- Total number of info messages found
	.fixableErrors number -- Number of errors that can be auto-fixed
	.fixableWarnings number -- Number of warnings that can be auto-fixed
	.fixableInfos number -- Number of info messages that can be auto-fixed

	Statistics about linting results.
]=]
export type LintStats = {
	errors: number,
	warnings: number,
	infos: number,
	fixableErrors: number,
	fixableWarnings: number,
	fixableInfos: number,
}

--[=[
	@interface LintResult
	@within CoreTypes
	.filePath string -- Path of the file that was linted
	.issues { LintIssue } -- Array of issues found
	.stats LintStats -- Statistics about the issues
	.errorCount number -- Total number of errors (deprecated, use stats.errors)
	.warningCount number -- Total number of warnings (deprecated, use stats.warnings)

	Complete result of linting a single file.
]=]
export type LintResult = {
	filePath: string,
	issues: { LintIssue },
	stats: LintStats,
	errorCount: number,
	warningCount: number,
}

--[=[
	@interface RuleRegistry
	@within CoreTypes

	Registry for managing rule definitions and providing efficient access.
]=]
export type RuleRegistry = {
	registerRule: (self: RuleRegistry, rule: Rule) -> (),
	registerRules: (self: RuleRegistry, rules: { Rule }) -> (),
	getRule: (self: RuleRegistry, ruleId: string) -> Rule?,
	getAllRules: (self: RuleRegistry) -> { Rule },
	getRulesForNodeType: (self: RuleRegistry, nodeType: NodeType) -> { RegisteredRule },
	getRulesByNodeType: (self: RuleRegistry) -> { [NodeType]: { RegisteredRule } },
	isRuleRegistered: (self: RuleRegistry, ruleId: string) -> boolean,
}

--[=[
	@interface RuleEngine
	@within CoreTypes

	Engine for executing rules against AST nodes.
]=]
export type RuleEngine = {
	lintFile: (
		self: RuleEngine,
		ast: Luau.AstStatBlock,
		sourceText: string,
		filename: string?
	) -> LintResult,
	lintText: (self: RuleEngine, sourceText: string, filename: string?) -> LintResult,
}

-- Export constants
return {
	NODE_TYPES = NODE_TYPES,
	TAG_TO_NODE = TAG_TO_NODE,
}
