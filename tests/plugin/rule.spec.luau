--!strict

local Luau = require("@Lute/Luau")
local Rule = require("../../src/plugin/rule")
local types = require("../tiniest/types")

type DescribeFunction = types.DescribeFunction
type TestFunction = types.TestFunction
type ExpectFunction = types.ExpectFunction

local NODE_TYPES = Rule.NODE_TYPES

local function pluginRuleTestSuite(
	describe: DescribeFunction,
	test: TestFunction,
	expect: ExpectFunction
): ()
	describe("Rule Module", function(): ()
		describe("validateRule", function(): ()
			test("should validate a correct rule definition", function(): ()
				local validRule: Rule.Rule = {
					id = "test-rule",
					title = "Test Rule",
					description = "A test rule for validation",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_: Rule.RuleContext): Rule.ListenerMap
						return {
							[NODE_TYPES.Local] = function(_node: Luau.AstLocal)
								-- Simple test handler
							end,
						}
					end,
				}

				local isValid, errorMessage = Rule.validateRule(validRule)
				expect(isValid).is(true)
				expect(errorMessage).is(nil)
			end)

			test("should reject rule with missing id", function(): ()
				local invalidRule = {
					title = "Test Rule",
					description = "A test rule for validation",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_context)
						return {}
					end,
				}

				local isValid, errorMessage = Rule.validateRule(invalidRule)
				expect(isValid).is(false)
				expect(errorMessage).is("Rule.id must be a non-empty string")
			end)

			test("should reject rule with invalid category", function(): ()
				local invalidRule = {
					id = "test-rule",
					title = "Test Rule",
					description = "A test rule for validation",
					category = "invalid-category",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_context)
						return {}
					end,
				}

				local isValid, errorMessage = Rule.validateRule(invalidRule)
				expect(isValid).is(false)
				expect(errorMessage).is(
					"Rule.category must be one of: formatting, logical, stylistic"
				)
			end)

			test("should reject rule with invalid fixable category", function(): ()
				local invalidRule = {
					id = "test-rule",
					title = "Test Rule",
					description = "A test rule for validation",
					category = "logical",
					fixable = "invalid-fix",
					docsUrl = "https://docs.example.com/rules/test-rule",
					create = function(_context)
						return {}
					end,
				}

				local isValid, errorMessage = Rule.validateRule(invalidRule)
				expect(isValid).is(false)
				expect(errorMessage).is("Rule.fixable must be one of: none, auto, suggestion")
			end)

			test("should reject rule with missing create function", function(): ()
				local invalidRule = {
					id = "test-rule",
					title = "Test Rule",
					description = "A test rule for validation",
					category = "logical",
					fixable = "none",
					docsUrl = "https://docs.example.com/rules/test-rule",
				}

				local isValid, errorMessage = Rule.validateRule(invalidRule)
				expect(isValid).is(false)
				expect(errorMessage).is("Rule.create must be a function")
			end)

			test("should reject non-table input", function(): ()
				local isValid, errorMessage = Rule.validateRule("not a table")
				expect(isValid).is(false)
				expect(errorMessage).is("Rule must be a table")
			end)
		end)

		describe("validateListenerMap", function(): ()
			test("should validate simple function listeners", function(): ()
				local validListeners: Rule.ListenerMap = {
					[NODE_TYPES.Local] = function(_node)
						-- Handle local declarations
					end,
					[NODE_TYPES.Call] = function(_node)
						-- Handle function calls
					end,
				}

				local isValid, errorMessage = Rule.validateListenerMap(validListeners)
				expect(isValid).is(true)
				expect(errorMessage).is(nil)
			end)

			test("should validate enter/exit listeners", function(): ()
				local validListeners: Rule.ListenerMap = {
					[NODE_TYPES.Function] = {
						enter = function(_node)
							-- Entering function
						end,
						exit = function(_node)
							-- Exiting function
						end,
					},
					[NODE_TYPES.Block] = {
						enter = function(_node)
							-- Entering block
						end,
					},
				}

				local isValid, errorMessage = Rule.validateListenerMap(validListeners)
				expect(isValid).is(true)
				expect(errorMessage).is(nil)
			end)

			test("should reject invalid node type", function(): ()
				local invalidListeners = {
					InvalidNodeType = function(_node)
						-- This node type doesn't exist
					end,
				}

				local isValid, errorMessage = Rule.validateListenerMap(invalidListeners)
				expect(isValid).is(false)
				expect(errorMessage).is("Listener for InvalidNodeType must be a valid node type")
			end)

			test("should reject non-function listener", function(): ()
				local invalidListeners = {
					[NODE_TYPES.Local] = "not a function",
				}

				local isValid, errorMessage = Rule.validateListenerMap(invalidListeners :: any)
				expect(isValid).is(false)
				expect(errorMessage).is(
					"Listener for local must be a function or object with enter/exit functions"
				)
			end)

			test("should reject enter/exit object with no functions", function(): ()
				local invalidListeners = {
					[NODE_TYPES.Local] = {},
				}

				local isValid, errorMessage = Rule.validateListenerMap(invalidListeners :: any)
				expect(isValid).is(false)
				expect(errorMessage).is(
					"Listener for local must have at least enter or exit function"
				)
			end)

			test("should reject enter/exit object with invalid enter type", function(): ()
				local invalidListeners = {
					[NODE_TYPES.Local] = {
						enter = "not a function",
					},
				}

				local isValid, errorMessage = Rule.validateListenerMap(invalidListeners :: any)
				expect(isValid).is(false)
				expect(errorMessage).is("Listener for local.enter must be a function")
			end)

			test("should reject non-table input", function(): ()
				local isValid, errorMessage = Rule.validateListenerMap("not a table" :: any)
				expect(isValid).is(false)
				expect(errorMessage).is("Listener map must be a table")
			end)
		end)

		describe("isValidCategory", function(): ()
			test("should accept valid categories", function(): ()
				expect(Rule.isValidCategory("formatting")).is(true)
				expect(Rule.isValidCategory("logical")).is(true)
				expect(Rule.isValidCategory("stylistic")).is(true)
			end)

			test("should reject invalid categories", function(): ()
				expect(Rule.isValidCategory("invalid")).is(false)
				expect(Rule.isValidCategory("")).is(false)
				expect(Rule.isValidCategory("LOGICAL")).is(false) -- case sensitive
			end)
		end)
	end)
end

return pluginRuleTestSuite
