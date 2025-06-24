--!strict

local Luau = require("@lute/luau")
local result = require("@batteries/result")
local types = require("../../helpers/tiniest-types")

type DescribeFunction = types.DescribeFunction
type TestFunction = types.TestFunction
type ExpectFunction = types.ExpectFunction

-- Import the Registry module
local Registry = require("../../../packages/core/src/registry/registry")
local Rule = require("../../../packages/core/src/rule/rule")

local NODE_TYPES = Rule.NODE_TYPES

local function pluginRegistryTestSuite(
	describe: DescribeFunction,
	test: TestFunction,
	expect: ExpectFunction
): ()
	describe("Registry Module", function(): ()
		describe("createRuleRegistry", function(): ()
			test("should create a registry instance with all required methods", function(): ()
				local registry = Registry.createRuleRegistry()

				expect(type(registry)).is("table")
				expect(type(registry.registerRule)).is("function")
				expect(type(registry.registerRules)).is("function")
				expect(type(registry.unregisterRule)).is("function")
				expect(type(registry.getAllRules)).is("function")
				expect(type(registry.getRuleById)).is("function")
				expect(type(registry.getRulesForNodeType)).is("function")
				expect(type(registry.getAllNodeTypes)).is("function")
				expect(type(registry.isRuleRegistered)).is("function")
				expect(type(registry.setRuleEnabled)).is("function")
				expect(type(registry.setRuleOptions)).is("function")
				expect(type(registry.clear)).is("function")
			end)

			test("should start with empty registry", function(): ()
				local registry = Registry.createRuleRegistry()

				expect(#registry.getAllRules()).is(0)
				expect(#registry.getAllNodeTypes()).is(0)
				expect(registry.isRuleRegistered("any-rule")).is(false)
			end)
		end)

		describe("registerRule", function(): ()
			test("should register a valid rule", function(): ()
				local registry = Registry.createRuleRegistry()

				local validRule: Rule.Rule = {
					id = "test-rule",
					title = "Test Rule",
					description = "A test rule for validation",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal)
								-- Simple test handler
							end,
						}
					end,
				}

				-- Should not throw
				registry.registerRule(validRule)

				expect(registry.isRuleRegistered("test-rule")).is(true)
				expect(#registry.getAllRules()).is(1)
			end)

			test("should register rule with options", function(): ()
				local registry = Registry.createRuleRegistry()
				local validRule: Rule.Rule = {
					id = "test-rule-with-options",
					title = "Test Rule With Options",
					description = "A test rule with custom options",
					category = "stylistic",
					fixable = "auto",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Function] = function(_: Luau.AstFunctionBody)
								-- Simple test handler
							end,
						}
					end,
				}
				local options = { severity = "error", maxLength = 80 }

				registry.registerRule(validRule, options)

				local registeredRule = registry.getRuleById("test-rule-with-options")
				expect(registeredRule ~= nil).is(true)
				if registeredRule then
					expect(registeredRule.options).is(options)
					expect(registeredRule.enabled).is(true)
				end
			end)

			test("should throw on invalid rule", function(): ()
				local registry = Registry.createRuleRegistry()
				local invalidRule = {
					-- Missing required fields
					id = "invalid-rule",
				}

				local status = result.pcall(function(): nil
					registry.registerRule(invalidRule :: any)
					return nil
				end)

				expect(status.success).is(false)
			end)

			test("should throw on duplicate rule ID", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule1: Rule.Rule = {
					id = "duplicate-id",
					title = "First Rule",
					description = "First rule with this ID",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/duplicate-id",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal) end,
						}
					end,
				}

				local rule2: Rule.Rule = {
					id = "duplicate-id",
					title = "Second Rule",
					description = "Second rule with same ID",
					category = "formatting",
					fixable = "auto",
					docsUrl = "https://docs.example.com/rules/duplicate-id-2",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Function] = function(_: Luau.AstFunctionBody) end,
						}
					end,
				}

				registry.registerRule(rule1)

				local status = result.pcall(function(): nil
					registry.registerRule(rule2)
					return nil
				end)

				expect(status.success).is(false)
			end)
		end)

		describe("registerRules", function(): ()
			test("should register multiple rules at once", function(): ()
				local registry = Registry.createRuleRegistry()
				local rules: { Rule.Rule } = {
					{
						id = "rule-1",
						title = "Rule 1",
						description = "First rule",
						category = "logical",
						fixable = "none",
						docsUrl = "https://docs.example.com/rules/rule-1",
						create = function(_: Rule.RuleContext): Rule.ListenerMap
							return {
								[NODE_TYPES.Local] = function(_node: Luau.AstLocal) end,
							}
						end,
					},
					{
						id = "rule-2",
						title = "Rule 2",
						description = "Second rule",
						category = "formatting",
						fixable = "auto",
						docsUrl = "https://docs.example.com/rules/rule-2",
						create = function(_: Rule.RuleContext): Rule.ListenerMap
							return {
								[NODE_TYPES.Function] = function(_node: Luau.AstFunctionBody) end,
							}
						end,
					},
					{
						id = "rule-3",
						title = "Rule 3",
						description = "Third rule",
						category = "stylistic",
						fixable = "suggestion",
						docsUrl = "https://docs.example.com/rules/rule-3",
						create = function(_: Rule.RuleContext): Rule.ListenerMap
							return {
								[NODE_TYPES.Call] = function(_node: Luau.AstExprCall) end,
							}
						end,
					},
				}

				registry.registerRules(rules)

				expect(#registry.getAllRules()).is(3)
				expect(registry.isRuleRegistered("rule-1")).is(true)
				expect(registry.isRuleRegistered("rule-2")).is(true)
				expect(registry.isRuleRegistered("rule-3")).is(true)
			end)

			test("should stop on first invalid rule", function(): ()
				local registry = Registry.createRuleRegistry()
				local rules: { Rule.Rule } = {
					{
						id = "valid-rule",
						title = "Valid Rule",
						description = "A valid rule",
						category = "logical",
						fixable = "none",
						docsUrl = "https://docs.example.com/rules/valid-rule",
						create = function(_: Rule.RuleContext): Rule.ListenerMap
							return { [NODE_TYPES.Local] = function(_node: Luau.AstLocal) end }
						end,
					},
					{
						-- Invalid rule - missing required fields
						id = "invalid-rule",
					} :: Rule.Rule,
					{
						id = "another-rule",
						title = "Another Rule",
						description = "This shouldn't be registered",
						category = "formatting",
						fixable = "auto",
						docsUrl = "https://docs.example.com/rules/another-rule",
						create = function(_: Rule.RuleContext): Rule.ListenerMap
							return {
								[NODE_TYPES.Function] = function(_node: Luau.AstFunctionBody) end,
							}
						end,
					},
				}

				local status = result.pcall(function(): nil
					registry.registerRules(rules)
					return nil
				end)

				expect(status.success).is(false)
				expect(registry.isRuleRegistered("valid-rule")).is(true)
				expect(registry.isRuleRegistered("invalid-rule")).is(false)
				expect(registry.isRuleRegistered("another-rule")).is(false)
			end)
		end)

		describe("unregisterRule", function(): ()
			test("should unregister existing rule", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "removable-rule",
					title = "Removable Rule",
					description = "A rule that can be removed",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/removable-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal) end,
						}
					end,
				}

				registry.registerRule(rule)
				expect(registry.isRuleRegistered("removable-rule")).is(true)

				local unregister = registry.unregisterRule("removable-rule")
				expect(unregister).is(true)
				expect(registry.isRuleRegistered("removable-rule")).is(false)
				expect(#registry.getAllRules()).is(0)
			end)

			test("should return false for non-existent rule", function(): ()
				local registry = Registry.createRuleRegistry()

				local unregister = registry.unregisterRule("non-existent-rule")
				expect(unregister).is(false)
			end)
		end)

		describe("getAllRules", function(): ()
			test("should return all registered rules", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule1: Rule.Rule = {
					id = "rule-1",
					title = "Rule 1",
					description = "First rule",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/rule-1",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal) end,
						}
					end,
				}
				local rule2: Rule.Rule = {
					id = "rule-2",
					title = "Rule 2",
					description = "Second rule",
					category = "formatting",
					fixable = "auto",
					docsUrl = "https://docs.example.com/rules/rule-2",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Function] = function(_: Luau.AstFunctionBody) end,
						}
					end,
				}

				registry.registerRule(rule1)
				registry.registerRule(rule2)

				local allRules = registry.getAllRules()
				expect(#allRules).is(2)

				-- Check that rules have proper structure
				for _, registeredRule in allRules do
					expect(type(registeredRule.rule)).is("table")
					expect(type(registeredRule.nodeTypes)).is("table")
					expect(type(registeredRule.enabled)).is("boolean")
				end
			end)
		end)

		describe("getRuleById", function(): ()
			test("should return rule when it exists", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "findable-rule",
					title = "Findable Rule",
					description = "A rule that can be found",
					category = "stylistic",
					fixable = "suggestion",
					docsUrl = "https://docs.example.com/rules/findable-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Function] = function(_: Luau.AstFunctionBody) end,
						}
					end,
				}

				registry.registerRule(rule)

				local found = registry.getRuleById("findable-rule")
				expect(found ~= nil).is(true)
				if found then
					expect(found.rule.id).is("findable-rule")
					expect(found.rule.title).is("Findable Rule")
				end
			end)

			test("should return nil when rule doesn't exist", function(): ()
				local registry = Registry.createRuleRegistry()

				local found = registry.getRuleById("non-existent-rule")
				expect(found).is(nil)
			end)
		end)

		describe("getRulesForNodeType", function(): ()
			test("should return rules interested in specific node type", function(): ()
				local registry = Registry.createRuleRegistry()
				local localRule: Rule.Rule = {
					id = "local-rule",
					title = "Local Rule",
					description = "A rule for local declarations",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/local-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal) end,
						}
					end,
				}
				local functionRule: Rule.Rule = {
					id = "function-rule",
					title = "Function Rule",
					description = "A rule for functions",
					category = "formatting",
					fixable = "auto",
					docsUrl = "https://docs.example.com/rules/function-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Function] = function(_: Luau.AstFunctionBody) end,
						}
					end,
				}
				local multiRule: Rule.Rule = {
					id = "multi-rule",
					title = "Multi Rule",
					description = "A rule for multiple node types",
					category = "stylistic",
					fixable = "suggestion",
					docsUrl = "https://docs.example.com/rules/multi-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal) end,
							[NODE_TYPES.Function] = function(_: Luau.AstFunctionBody) end,
						}
					end,
				}

				registry.registerRule(localRule)
				registry.registerRule(functionRule)
				registry.registerRule(multiRule)

				local localRules = registry.getRulesForNodeType("local")
				expect(#localRules).is(2) -- localRule and multiRule

				local functionRules = registry.getRulesForNodeType("function")
				expect(#functionRules).is(2) -- functionRule and multiRule

				local callRules = registry.getRulesForNodeType("call")
				expect(#callRules).is(0) -- No rules for Call
			end)

			test("should only return enabled rules", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "rule-to-disable",
					title = "Rule to Disable",
					description = "A rule that can be disabled",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/rule-to-disable",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_: Luau.AstLocal) end,
						}
					end,
				}

				registry.registerRule(rule)

				local enabledRules = registry.getRulesForNodeType("local")
				expect(#enabledRules).is(1)

				registry.setRuleEnabled("rule-to-disable", false)

				local disabledRules = registry.getRulesForNodeType("local")
				expect(#disabledRules).is(0)
			end)
		end)

		describe("getAllNodeTypes", function(): ()
			test("should return all node types with listeners", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "multi-listener-rule",
					title = "Multi Listener Rule",
					description = "A rule with multiple listeners",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/multi-listener-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_node: Luau.AstLocal) end,
							[NODE_TYPES.Function] = function(_node: Luau.AstFunctionBody) end,
							[NODE_TYPES.Call] = function(_node: Luau.AstExprCall) end,
						}
					end,
				}

				registry.registerRule(rule)

				local nodeTypes = registry.getAllNodeTypes()
				expect(#nodeTypes).is(3)

				-- Check that all expected node types are present
				local hasLocal = false
				local hasFunction = false
				local hasCall = false
				for _, nodeType in nodeTypes do
					if nodeType == "local" then
						hasLocal = true
					end
					if nodeType == "function" then
						hasFunction = true
					end
					if nodeType == "call" then
						hasCall = true
					end
				end
				expect(hasLocal).is(true)
				expect(hasFunction).is(true)
				expect(hasCall).is(true)
			end)

			test("should return empty array when no rules registered", function(): ()
				local registry = Registry.createRuleRegistry()

				local nodeTypes = registry.getAllNodeTypes()
				expect(#nodeTypes).is(0)
			end)
		end)

		describe("isRuleRegistered", function(): ()
			test("should return true for registered rules", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "registered-rule",
					title = "Registered Rule",
					description = "A registered rule",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/registered-rule",
					create = function(_context: Rule.RuleContext): Rule.ListenerMap
						return { [NODE_TYPES.Local] = function(_node: Luau.AstLocal) end }
					end,
				}

				registry.registerRule(rule)

				expect(registry.isRuleRegistered("registered-rule")).is(true)
			end)

			test("should return false for unregistered rules", function(): ()
				local registry = Registry.createRuleRegistry()

				expect(registry.isRuleRegistered("unregistered-rule")).is(false)
			end)
		end)

		describe("setRuleEnabled", function(): ()
			test("should enable/disable existing rule", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "toggleable-rule",
					title = "Toggleable Rule",
					description = "A rule that can be toggled",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/toggleable-rule",
					create = function(_context: Rule.RuleContext): Rule.ListenerMap
						return { [NODE_TYPES.Local] = function(_node: Luau.AstLocal) end }
					end,
				}

				registry.registerRule(rule)

				local registeredRule = registry.getRuleById("toggleable-rule")
				expect(registeredRule ~= nil).is(true)
				if registeredRule then
					expect(registeredRule.enabled).is(true)
				end

				local enabled = registry.setRuleEnabled("toggleable-rule", false)
				expect(enabled).is(true)

				registeredRule = registry.getRuleById("toggleable-rule")
				if registeredRule then
					expect(registeredRule.enabled).is(false)
				end

				enabled = registry.setRuleEnabled("toggleable-rule", true)
				expect(enabled).is(true)

				registeredRule = registry.getRuleById("toggleable-rule")
				if registeredRule then
					expect(registeredRule.enabled).is(true)
				end
			end)

			test("should return false for non-existent rule", function(): ()
				local registry = Registry.createRuleRegistry()

				local enabled = registry.setRuleEnabled("non-existent-rule", false)
				expect(enabled).is(false)
			end)
		end)

		describe("setRuleOptions", function(): ()
			test("should update options for existing rule", function(): ()
				local registry = Registry.createRuleRegistry()
				local rule: Rule.Rule = {
					id = "configurable-rule",
					title = "Configurable Rule",
					description = "A rule with configurable options",
					category = "stylistic",
					fixable = "auto",
					docsUrl = "https://docs.example.com/rules/configurable-rule",
					create = function(_context: Rule.RuleContext): Rule.ListenerMap
						return { [NODE_TYPES.Local] = function(_node: Luau.AstLocal) end }
					end,
				}
				local initialOptions = { maxLength = 80 }
				local newOptions = { maxLength = 120, allowNested = true }

				registry.registerRule(rule, initialOptions)

				local registeredRule = registry.getRuleById("configurable-rule")
				expect(registeredRule ~= nil).is(true)
				if registeredRule then
					expect(registeredRule.options).is(initialOptions)
				end

				local setOption = registry.setRuleOptions("configurable-rule", newOptions)
				expect(setOption).is(true)

				registeredRule = registry.getRuleById("configurable-rule")
				if registeredRule then
					expect(registeredRule.options).is(newOptions)
				end
			end)

			test("should return false for non-existent rule", function(): ()
				local registry = Registry.createRuleRegistry()

				local setOption = registry.setRuleOptions("non-existent-rule", { some = "options" })
				expect(setOption).is(false)
			end)
		end)

		describe("clear", function(): ()
			test("should remove all rules from registry", function(): ()
				local registry = Registry.createRuleRegistry()
				local rules: { Rule.Rule } = {
					{
						id = "rule-1",
						title = "Rule 1",
						description = "First rule",
						category = "logical",
						fixable = "none",
						docsUrl = "https://docs.example.com/rules/rule-1",
						create = function(_context: Rule.RuleContext): Rule.ListenerMap
							return { [NODE_TYPES.Local] = function(_node: Luau.AstLocal) end }
						end,
					},
					{
						id = "rule-2",
						title = "Rule 2",
						description = "Second rule",
						category = "formatting",
						fixable = "auto",
						docsUrl = "https://docs.example.com/rules/rule-2",
						create = function(_context: Rule.RuleContext): Rule.ListenerMap
							return {
								[NODE_TYPES.Function] = function(_node: Luau.AstFunctionBody) end,
							}
						end,
					},
				}

				registry.registerRules(rules)
				expect(#registry.getAllRules()).is(2)
				expect(#registry.getAllNodeTypes()).is(2)

				registry.clear()

				expect(#registry.getAllRules()).is(0)
				expect(#registry.getAllNodeTypes()).is(0)
				expect(registry.isRuleRegistered("rule-1")).is(false)
				expect(registry.isRuleRegistered("rule-2")).is(false)
			end)
		end)
	end)
end

return pluginRegistryTestSuite
