--!strict

--[=[
    @class PluginAPI
    
    Main Plugin API for luau-lint
    
    This module provides the primary API for the luau-lint plugin system, implementing
    the listener pattern architecture. It offers a clean, intuitive developer experience
    for creating custom linting rules with comprehensive validation, execution, and
    error handling.
    
    ## Key Features
    
    - **Intuitive API**: Clean, developer-friendly interface for rule creation
    - **Listener Pattern**: Efficient rule registration using node type listeners
    - **Type Safety**: Full type definitions for all interfaces
    - **Performance**: Optimized for handling 200+ rules through batching
    - **Auto-fixing**: Built-in support for automatic code fixes
    - **Error Handling**: Graceful error handling without stopping execution
    
    ## Example Usage
    
    ```luau
    local PluginAPI = require("src/plugin/plugin-api")
    
    -- Create a rule
	local myRule = PluginAPI.createRule({
		id = "noUnusedVariables",
		title = "Disallow unused variables",
		description = "Variables that are declared but never used should be removed",
		category = "Best Practices",
		fixable = false,
		
		create = function(context)
			return {
				LocalDeclaration = function(node)
					-- Handle local variable declarations
				end,
			}
		end
	})
	
	-- Create registry and engine
	local registry = PluginAPI.createRuleRegistry()
	local engine = PluginAPI.createRuleEngine(registry)
	
	-- Register rules and lint
	registry.registerRule(myRule)
	local result = engine.lintFile(ast, sourceText, "file.luau")
	```
	
	@since v0.1.0
]=]

local Engine = require("./engine")
local Registry = require("./registry")
local Rule = require("./rule")
local RuleContext = require("./context")

-- Re-export core types for convenience
export type Rule = Rule.Rule
export type RuleMetadata = Rule.RuleMetadata
export type RuleContext = Rule.RuleContext
export type RuleIssue = Rule.RuleIssue
export type RuleFix = Rule.RuleFix
export type ListenerMap = Rule.ListenerMap
export type NodeListener = Rule.NodeListener
export type NodeListenerWithExit = Rule.NodeListenerWithExit
export type SourceRange = Rule.SourceRange
export type SourcePosition = Rule.SourcePosition

export type RuleRegistry = Registry.RuleRegistry
export type RegisteredRule = Registry.RegisteredRule

export type RuleEngine = Engine.RuleEngine
export type LintResult = Engine.LintResult
export type LintIssue = Engine.LintIssue
export type LintStats = Engine.LintStats

--[=[
	Creates a new rule with validation.
	
	This is the primary function for creating custom linting rules. It validates
	the rule definition and returns a properly structured Rule object that can
	be registered with a rule registry.
	
	@param rule Rule -- The rule definition
	@return Rule -- A validated rule object
	
	@error "RuleError" -- If the rule definition is invalid
	
	@since v0.1.0
]=]
local function createRule(rule: Rule): Rule
	-- Validate the rule
	local isValid, errorMessage = Rule.validateRule(rule)
	if not isValid then
		error(`Invalid rule definition: {errorMessage}`)
	end

	return rule
end

--[=[
	Creates a new rule registry.
	
	The registry manages rule definitions and provides efficient access patterns
	for the rule execution engine. Rules are automatically batched by their
	node type interests for optimal performance.
	
	@return RuleRegistry -- A new registry instance
	
	@since v0.1.0
]=]
local function createRuleRegistry(): RuleRegistry
	return Registry.createRuleRegistry()
end

--[=[
	Creates a new rule execution engine.
	
	The engine orchestrates the linting process by performing single-pass AST
	traversal and calling relevant rule listeners. It handles errors gracefully
	and collects all issues found by the rules.
	
	@param registry RuleRegistry -- The rule registry containing rules to execute
	@return RuleEngine -- A new engine instance
	
	@since v0.1.0
]=]
local function createRuleEngine(registry: RuleRegistry): RuleEngine
	return Engine.createRuleEngine(registry)
end

--[=[
	Convenience function to create a complete linting setup.
	
	Creates a registry, registers the provided rules, and returns both the
	registry and engine ready for use.
	
	@param rules { Rule } -- Array of rules to register
	@return RuleRegistry, RuleEngine -- The configured registry and engine
	
	@since v0.1.0
]=]
local function createLinter(rules: { Rule }): (RuleRegistry, RuleEngine)
	local registry = createRuleRegistry()
	local engine = createRuleEngine(registry)

	registry.registerRules(rules)

	return registry, engine
end

--[=[
	Validates a rule definition without creating it.
	
	Useful for testing rule definitions or providing validation feedback
	in development tools.
	
	@param definition any -- The rule definition to validate
	@return boolean, string? -- True if valid, false with error message if invalid
	
	@since v0.1.0
]=]
local function validateRuleDefinition(definition: any): (boolean, string?)
	return Rule.validateRule(definition)
end

--[=[
	Validates a listener map returned by a rule's create function.
	
	Useful for testing rule implementations to ensure they return valid
	listener structures.
	
	@param listeners any -- The listener map to validate
	@return boolean, string? -- True if valid, false with error message if invalid
	
	@since v0.1.0
]=]
local function validateListeners(listeners: any): (boolean, string?)
	return Rule.validateListenerMap(listeners)
end

-- Main API exports
return {
	-- Core creation functions
	createRule = createRule,
	createRuleRegistry = createRuleRegistry,
	createRuleEngine = createRuleEngine,
	createLinter = createLinter,

	-- Validation utilities
	validateRuleDefinition = validateRuleDefinition,
	validateListeners = validateListeners,

	-- Direct access to modules for advanced usage
	Rule = Rule,
	RuleContext = RuleContext,
	Registry = Registry,
	Engine = Engine,
}
