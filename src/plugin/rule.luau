--!strict
--[=[
	@class Rule
	
	Rule Interface and Types for luau-lint Plugin API
	
	This module defines the core types and interfaces for creating custom linting rules
	using the listener pattern architecture. Rules can register listeners for specific
	AST node types and receive callbacks during AST traversal.
	
	## Key Features
	
	- **Listener Pattern**: Rules define `create` functions that return listener objects
	- **Type Safety**: Full type definitions for all interfaces
	- **Metadata Support**: Rich rule metadata including documentation URLs
	- **Auto-fix Support**: Built-in support for automatic code fixes
	- **Node Interest Registration**: Efficient handling of rules through batching
	
	## Example Usage
	
	```luau
	local rule = createRule({
		id = "noUnusedVariables",
		title = "Disallow unused variables",
		description = "Variables that are declared but never used should be removed",
		category = "logical",
		fixable = "none",
		docsUrl = "https://example.com/rules/no-unused-vars",
		
		create = function(context)
			local declaredVars = {}
			local usedVars = {}
			
			return {
				LocalDeclaration = function(node)
					-- Register variable declarations
				end,
				
				Program = {
					exit = function(node)
						-- Report unused variables at end
					end
				}
			}
		end
	})
	```
	
	@since v0.1.0
]=]

local Luau = require("@lute/Luau")
local types = require("../types")

type NodeMap<K, V> = types.Map<K, V>

local function flip<K, V>(dictionary: { [K]: V }): { [V]: K }
	local result = {}

	for key, value in dictionary do
		result[value] = key
	end

	return result
end

-- cspell:disable
local NODE_TYPES: NodeMap<NodeType, NodeTag> = {
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

--[=[
	@type NodeTag string
	@within Rule

	The [NodeTag] represents a lowercase string literal corresponding to an AST node type.
	This is the actual tag value used internally by the AST parser, while [NodeType] 
	represents the PascalCase version used in the API.
]=]
--cspell:disable
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
--cspell:enable

local TAG_TO_NODE = flip(NODE_TYPES :: { [NodeType]: NodeTag })

--[=[
	@type NodeType string
	@within Rule

    The [NodeType] represents a string literal representing an AST node type that rules can listen to.
]=]
type NodeType =
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
	@within Rule
	
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
    @within Rule
    
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
	@interface RuleMetadata
	@within Rule
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
	@interface RuleContext
	@within Rule
	.id string -- Rule ID for context
	.options any? -- Rule-specific configuration options
	.report (issue: RuleIssue) -> () -- Report a linting issue
	.createFix (range: SourceRange, text: string) -> RuleFix -- Create an auto-fix
	.getSourceText (range: SourceRange?) -> string -- Get source text for a range
	.getScope (node: any?) -> any -- Get scope information for a node
	
	Context object passed to rule create functions containing utilities for
	reporting issues, creating fixes, and accessing source information.

	@note This is here as we cannot directly import `context` without creating
		cyclic dependencies.
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
	@interface SourcePosition
	@within Rule
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
	@within Rule
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
	@within Rule
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
	@within Rule
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
	@interface NodeListener
	@within Rule
	.(node: any) -> () -- Function that handles an AST node
	
	A function that receives an AST node when it's encountered during traversal.
]=]
export type NodeListener = (node: AstNode) -> ()

--[=[
	@interface NodeListenerWithExit
	@within Rule
	.enter NodeListener? -- Optional function called when entering the node
	.exit NodeListener? -- Optional function called when exiting the node
	
	Advanced listener that can handle both entering and exiting a node.
	Useful for tracking scope, maintaining state, or performing cleanup.
	Use this when you need to perform actions both when entering and leaving an AST node.
	
	## Example
	```luau
	return {
		Block = {
			enter = function(node)
				-- Track entering new scope
				scopeStack:push(createScope())
			end,
			exit = function(node)
				-- Clean up when leaving scope
				local scope = scopeStack:pop()
				reportUnusedVariables(scope)
			end
		}
	}
	```
]=]
export type NodeListenerWithExit = {
	enter: NodeListener?,
	exit: NodeListener?,
}

--[=[
    @type ListenerMap { [NodeTag]: NodeListener | NodeListenerWithExit }
    @within Rule
    
    Map of node types to their corresponding listener functions.
    Each rule's `create` function returns this type. Use this to define
    which AST nodes your rule wants to listen to and how to handle them.
    
    ## Example
    ```luau
    -- Simple listeners
    local listeners: ListenerMap = {
        Call = function(node)
            -- Handle function calls
        end,
        Local = function(node)
            -- Handle local variable declarations
        end
    }
    
    -- Mixed simple and enter/exit listeners
    local complexListeners: ListenerMap = {
        Call = function(node)
            -- Simple handler
        end,
        Block = {
            enter = function(node) 
                -- Entering scope
            end,
            exit = function(node)
                -- Leaving scope
            end
        }
    }
    ```
]=]
-- export type ListenerMap = { [NodeTag]: NodeListener | NodeListenerWithExit }
-- TODO: Fix this type.
export type ListenerMap = { [any]: any }

--[=[ 
    @interface RuleCreateFunction
    @within Rule
    .(context: RuleContext) -> ListenerMap -- Function that creates rule listeners
    
    The main function that defines a rule's behavior. Called once per file
    and returns a map of node type listeners. Use this to implement your rule's
    logic by registering callbacks for specific AST node types.
    
    ## Example
    ```luau
    create = function(context)
        local declaredVars = {}
        
        return {
            LocalDeclaration = function(node)
                -- Track variable declarations
                table.insert(declaredVars, node.name)
            end,
            
            Program = {
                exit = function(node)
                    -- Report unused variables at end of file
                    for _, varName in declaredVars do
                        if not isUsed(varName) then
                            context:report({
                                message = `Unused variable: {varName}`,
                                node = node
                            })
                        end
                    end
                end
            }
        }
    end
    ```
]=]
export type RuleCreateFunction = (context: RuleContext) -> ListenerMap

--[=[
	@interface Rule
	@within Rule
	.id string -- Unique rule identifier
	.title string -- Human-readable rule title
	.description string -- Detailed rule description
	.category RuleCategory -- Rule category
	.fixable boolean -- Whether rule supports auto-fixing
	.docsUrl string? -- Optional documentation URL
	.create RuleCreateFunction -- Function that creates rule listeners
	
	Complete rule definition with metadata and implementation.
]=]
export type Rule = RuleMetadata & {
	create: RuleCreateFunction,
}

--- Valid rule categories for validation
local VALID_CATEGORIES: { RuleCategory } = {
	"formatting",
	"logical",
	"stylistic",
}

--[=[
	Validates that a category string is one of the allowed RuleCategory values.
    Use this to ensure rule metadata has valid categories before registration.
	
	@param category string -- The category string to validate
	@return boolean -- True if the category is valid, false otherwise
	
	@since v0.1.0
]=]
local function isValidCategory(category: string): boolean
	return table.find(VALID_CATEGORIES, category) ~= nil
end

-- Valid fix categories for rules
local VALID_FIX_CATEGORIES: { FixCategory } = {
	"none",
	"auto",
	"suggestion",
}

--[=[
    Validates that a fix category string is one of the allowed FixCategory values.
    Use this to ensure rule metadata has valid fix capabilities before registration.
    
    @param category string -- The category string to validate
    @return boolean -- True if the category is valid, false otherwise
    
    @since v0.1.0
]=]
local function isValidFixCategory(category: string): boolean
	return table.find(VALID_FIX_CATEGORIES, category) ~= nil
end

--[=[
	Validates a rule definition to ensure it has all required fields and proper types.
    Use this before registering a rule to catch configuration errors early and get
    helpful error messages about what's missing or incorrect.
    
    ## Example
    ```luau
    local isValid, errorMsg = validateRule(myRule)
    if not isValid then
        print("Rule validation failed:", errorMsg)
        return
    end
    -- Continue with valid rule...
    ```
    
    @param rule any -- The rule object to validate
    @return boolean -- True if valid, false if invalid
    @return string? -- Error message if validation fails, nil if valid
    
    @since v0.1.0
]=]
local function validateRule(rule: any): (boolean, string?)
	if type(rule) ~= "table" then
		return false, "Rule must be a table"
	end

	local ruleTable = rule :: { [string]: any }

	-- Check required string fields
	local requiredStringFields = { "id", "title", "description" }
	for _, field in requiredStringFields do
		if type(ruleTable[field]) ~= "string" or ruleTable[field] == "" then
			return false, `Rule.{field} must be a non-empty string`
		end
	end

	-- Check category
	if type(ruleTable.category) ~= "string" or not isValidCategory(ruleTable.category) then
		return false, `Rule.category must be one of: {table.concat(VALID_CATEGORIES, ", ")}`
	end

	-- Check fixable
	if type(ruleTable.fixable) ~= "string" or not isValidFixCategory(ruleTable.fixable) then
		return false, `Rule.fixable must be one of: {table.concat(VALID_FIX_CATEGORIES, ", ")}`
	end

	-- Check docsUrl
	if type(ruleTable.docsUrl) ~= "string" then
		return false, "Rule.docsUrl must exist"
	end

	-- Check create function
	if type(ruleTable.create) ~= "function" then
		return false, "Rule.create must be a function"
	end

	return true, nil
end

--[=[
	Validates that a listener map has the correct structure and valid node types.
    Use this to ensure your rule's listener map is properly formatted before
    returning it from the create function.
    
    ## Example
    ```luau
    local listeners = {
        Call = function(node) end,
        Block = { enter = function(node) end }
    }
    
    local isValid, errorMsg = validateListenerMap(listeners)
    if not isValid then
        error("Invalid listener map: " .. errorMsg)
    end
    ```
    
    @param listeners any -- The listener map to validate
    @return boolean -- True if valid, false if invalid
    @return string? -- Error message if validation fails, nil if valid
    
    @since v0.1.0
]=]
local function validateListenerMap(listeners: ListenerMap): (boolean, string?)
	if type(listeners) ~= "table" then
		return false, "Listener map must be a table"
	end

	for nodeTag, listener in listeners :: { [string]: any } do
		if not TAG_TO_NODE[nodeTag :: NodeTag] then
			return false, `Listener for {nodeTag} must be a valid node type`
		end

		if type(listener) == "function" then
			-- Simple function listener - valid
			continue
		elseif type(listener) == "table" then
			-- Object with enter/exit functions
			local listenerObj = listener :: { [string]: any }
			if listenerObj.enter ~= nil and type(listenerObj.enter) ~= "function" then
				return false, `Listener for {nodeTag}.enter must be a function`
			end
			if listenerObj.exit ~= nil and type(listenerObj.exit) ~= "function" then
				return false, `Listener for {nodeTag}.exit must be a function`
			end
			if listenerObj.enter == nil and listenerObj.exit == nil then
				return false, `Listener for {nodeTag} must have at least enter or exit function`
			end
		else
			return false,
				`Listener for {nodeTag} must be a function or object with enter/exit functions`
		end
	end

	return true, nil
end

return {
	-- Validation functions
	validateRule = validateRule,
	validateListenerMap = validateListenerMap,
	isValidCategory = isValidCategory,

	-- Constants
	NODE_TYPES = NODE_TYPES,
	TAG_TO_NODE = TAG_TO_NODE,
	VALID_CATEGORIES = VALID_CATEGORIES,
	VALID_FIX_CATEGORIES = VALID_FIX_CATEGORIES,
}
