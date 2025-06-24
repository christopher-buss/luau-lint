--!strict

--[=[
	@class LuauLintCore

	Core linting engine for luau-lint

	This module provides the main entry point for the luau-lint core package.
	It exports the essential components needed for linting Luau code.

	@since v0.1.0
]=]

local ApiTypes = require("@self/api-types/api")
local Engine = require("@self/engine/engine")
local ErrorHandling = require("@self/reporting/error-handling")
local Registry = require("@self/registry/registry")
local Rule = require("@self/rule/rule")
local VisitorKeys = require("@self/traversal/visitor-keys")

-- Re-export types
export type LintResult = Engine.LintResult
export type LintIssue = Engine.LintIssue
export type LintStats = Engine.LintStats
export type RuleRegistry = Registry.RuleRegistry
export type RegisteredRule = Registry.RegisteredRule

-- Factory functions
local function createLinter(registry: Registry.RuleRegistry)
	return Engine.new({ registry = registry })
end

local function createRegistry(): RuleRegistry
	return Registry.createRuleRegistry()
end

return {
	-- Core components
	Rule = Rule,
	Engine = Engine,
	Registry = Registry,
	ErrorHandling = ErrorHandling,
	VisitorKeys = VisitorKeys,
	ApiTypes = ApiTypes,

	-- Factory functions
	createLinter = createLinter,
	createRegistry = createRegistry,
}
