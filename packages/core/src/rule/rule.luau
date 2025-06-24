--!strict
--[=[
	@class Rule

	Rule Implementation for luau-lint Plugin API

	This module provides validation functions for rule definitions and listener maps.
	It works with the types defined in the core types/api module.

	@since v0.1.0
]=]

local ApiTypes = require("../api-types/api")

-- Import types from the API module
export type NodeType = ApiTypes.NodeType
export type NodeTag = ApiTypes.NodeTag
export type RuleCategory = ApiTypes.RuleCategory
export type FixCategory = ApiTypes.FixCategory
export type RuleMetadata = ApiTypes.RuleMetadata
export type RuleContext = ApiTypes.RuleContext
export type SourcePosition = ApiTypes.SourcePosition
export type SourceRange = ApiTypes.SourceRange
export type Source = ApiTypes.Source
export type RuleFix = ApiTypes.RuleFix
export type AstNode = ApiTypes.AstNode
export type AnyNode = ApiTypes.AnyNode
export type LintNode = ApiTypes.LintNode
export type RuleIssue = ApiTypes.RuleIssue
export type NodeListener = ApiTypes.NodeListener
export type NodeListenerWithExit = ApiTypes.NodeListenerWithExit
export type ListenerMap = ApiTypes.ListenerMap
export type RuleCreateFunction = ApiTypes.RuleCreateFunction
export type Rule = ApiTypes.Rule

-- Import constants
local NODE_TYPES = ApiTypes.NODE_TYPES
local TAG_TO_NODE = ApiTypes.TAG_TO_NODE

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
