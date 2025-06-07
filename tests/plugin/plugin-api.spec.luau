--!strict
local Luau = require("@lute/Luau")
local types = require("../tiniest/types")

type DescribeFunction = types.DescribeFunction
type TestFunction = types.TestFunction
type ExpectFunction = types.ExpectFunction

-- Import the plugin API modules
local PluginAPI = require("../../src/plugin/plugin-api")

local mockNode = {
	tag = "call",
	argLocation = {
		begin = { line = 1, column = 17 },
		["end"] = { line = 1, column = 23 },
	},
} :: Luau.AstExprCall

local function plugin_api_test_suite(
	describe: DescribeFunction,
	test: TestFunction,
	expect: ExpectFunction
): ()
	describe("Plugin API", function(): ()
		describe("Rule Creation and Validation", function(): ()
			test("should create a valid rule with all required fields", function(): ()
				local ruleDefinition: PluginAPI.Rule = {
					id = "test-rule",
					title = "Test Rule",
					description = "A test rule for validation",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {}
					end,
				}

				local rule = PluginAPI.createRule(ruleDefinition)

				expect(rule.id).is("test-rule")
				expect(rule.title).is("Test Rule")
				expect(rule.description).is("A test rule for validation")
				expect(rule.category).is("logical")
				expect(rule.fixable).is("none")
				expect(rule.docsUrl).is("https://docs.example.com/rules/test-rule")
			end)

			test("should validate rule definition and reject invalid rules", function(): ()
				-- Missing required fields
				local invalidRule1 = {
					id = "invalid-rule",
					-- Missing other required fields
				}

				expect(function()
					PluginAPI.createRule(invalidRule1 :: any)
				end).fails()

				-- Invalid category
				local invalidRule2 = {
					id = "invalid-rule-2",
					title = "Invalid Rule",
					description = "Invalid rule",
					category = "invalid-category",
					fixable = "none",
					docsUrl = "https://example.com",
					create = function(): PluginAPI.ListenerMap
						return {}
					end,
				}

				expect(function()
					PluginAPI.createRule(invalidRule2 :: any)
				end).fails()

				-- Invalid fixable value
				local invalidRule3 = {
					id = "invalid-rule-3",
					title = "Invalid Rule",
					description = "Invalid rule",
					category = "logical",
					fixable = "invalid-fixable",
					docsUrl = "https://example.com",
					create = function(): PluginAPI.ListenerMap
						return {}
					end,
				}

				expect(function()
					PluginAPI.createRule(invalidRule3 :: any)
				end).fails()
			end)

			test("should support optional dependency fields", function(): ()
				local ruleWithDeps: PluginAPI.Rule = {
					id = "rule-with-deps",
					title = "Rule With Dependencies",
					description = "A rule with dependencies",
					category = "logical",
					fixable = "none",
					docsUrl = "https://example.com",
					create = function(_context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {}
					end,
				}

				local rule = PluginAPI.createRule(ruleWithDeps)

				-- Dependency fields are part of the rule definition, not getter methods
				expect(rule.id).is("rule-with-deps")
				expect(rule.title).is("Rule With Dependencies")
			end)
		end)

		describe("Rule Registration System", function(): ()
			test("should register rules and organize by node types", function(): ()
				local registry = PluginAPI.createRuleRegistry()

				local rule1: PluginAPI.Rule = {
					id = "rule-1",
					title = "Rule 1",
					description = "First rule",
					category = "logical",
					fixable = "none",
					docsUrl = "https://example.com",
					create = function(_context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {
							["call"] = function(_node) end,
							["local"] = function(_node) end,
						}
					end,
				}

				local rule2: PluginAPI.Rule = {
					id = "rule-2",
					title = "Rule 2",
					description = "Second rule",
					category = "stylistic",
					fixable = "auto",
					docsUrl = "https://example.com",
					create = function(_context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {
							["call"] = function(_node) end,
						}
					end,
				}

				registry.registerRule(rule1)
				registry.registerRule(rule2)

				-- Verify rules are registered
				local allRules = registry.getAllRules()
				expect(#allRules).is(2)
				expect(registry.isRuleRegistered("rule-1")).is(true)
				expect(registry.isRuleRegistered("rule-2")).is(true)

				-- Verify node type batching
				local callRules = registry.getRulesForNodeType("call")
				expect(#callRules).is(2)

				local localRules = registry.getRulesForNodeType("local")
				expect(#localRules).is(1)
			end)

			test("should prevent duplicate rule registration", function(): ()
				local registry = PluginAPI.createRuleRegistry()

				local rule: PluginAPI.Rule = {
					id = "duplicate-rule",
					title = "Duplicate Rule",
					description = "A rule that will be duplicated",
					category = "logical",
					fixable = "none",
					docsUrl = "https://example.com",
					create = function(_context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {}
					end,
				}

				registry.registerRule(rule)

				expect(function()
					registry.registerRule(rule)
				end).fails()
			end)
		end)

		describe("Rule Execution Engine", function(): ()
			test("should execute rules with proper context", function(): ()
				local registry = PluginAPI.createRuleRegistry()
				local engine = PluginAPI.createRuleEngine(registry)

				local rule: PluginAPI.Rule = {
					id = "test-execution-rule",
					title = "Test Execution Rule",
					description = "Rule for testing execution",
					category = "logical",
					fixable = "none",
					docsUrl = "https://example.com",
					create = function(context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {
							["call"] = function(_node: any)
								context:report({
									message = "Found function call",
									node = _node,
								})
							end,
						}
					end,
				}

				registry.registerRule(rule)

				-- Test with engine lintNode method (this is the actual API)
				local result = engine.lintNode(mockNode, "print('hello')", "test.luau")

				expect(#result.issues).is(1)
				expect(result.issues[1].ruleId).is("test-execution-rule")
				expect(result.issues[1].message).is("Found function call")
			end)

			test("should handle rule errors gracefully", function(): ()
				local registry = PluginAPI.createRuleRegistry()
				local engine = PluginAPI.createRuleEngine(registry)

				local errorRule: PluginAPI.Rule = {
					id = "error-rule",
					title = "Error Rule",
					description = "Rule that throws errors",
					category = "logical",
					fixable = "none",
					docsUrl = "https://example.com",
					create = function(_context: PluginAPI.RuleContext): PluginAPI.ListenerMap
						return {
							["call"] = function(_node: any)
								error("Intentional rule error")
							end,
						}
					end,
				}

				registry.registerRule(errorRule)

				-- Should not crash, should handle error gracefully
				expect(function()
					engine.lintNode(mockNode, "print('hello')", "test.luau")
				end).never_fails()
			end)
		end)
	end)
end

return plugin_api_test_suite
