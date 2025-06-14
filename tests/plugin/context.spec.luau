--!strict
local Result = require("@Batteries/result")

local Context = require("../../src/plugin/context")
local Rule = require("../../src/plugin/rule")
local types = require("../tiniest/types")

type DescribeFunction = types.DescribeFunction
type TestFunction = types.TestFunction
type ExpectFunction = types.ExpectFunction

local mockContext = Context.new({
	cwd = "/path/to/project",
	filename = "test.luau",
	sourceText = "local x = print('hello')",
})

local mockNode = {
	tag = "call",
	location = {
		start = { line = 1, column = 11, offset = 11 },
		finish = { line = 1, column = 24, offset = 24 },
	},
} :: Rule.LintNode

local function ruleContextTestSuite(
	describe: DescribeFunction,
	test: TestFunction,
	expect: ExpectFunction
): ()
	describe("context", function(): ()
		describe("extends", function(): ()
			test("should create extended context with new properties", function(): ()
				local extendedContext = mockContext:extend({
					report = function() end,
					ruleId = "test-rule",
				})

				expect(extendedContext.filename).is("test.luau")
				expect(extendedContext.sourceText).is("local x = print('hello')")
				expect(extendedContext.ruleId).is("test-rule")
			end)

			test("should freeze the extended object", function(): ()
				local extendedContext = mockContext:extend({
					report = function() end,
					ruleId = "test-rule",
				})

				local stats = Result.pcall(function(): nil
					extendedContext.ruleId = "hello"
					return nil
				end)

				expect(stats.success).is(false)
			end)
		end)

		describe("issue reporting", function(): ()
			test("should report issues with proper format", function(): ()
				local reportedIssues = {}

				local context = mockContext:extend({
					report = function(self, issue): ()
						table.insert(reportedIssues, issue)
					end,
					ruleId = "test-rule",
				})

				context:report({
					node = mockNode,
					message = "Avoid using print",
					location = mockNode.location,
				})

				expect(#reportedIssues).is(1)
				expect(reportedIssues[1].message).is("Avoid using print")
				expect(reportedIssues[1].node).is(mockNode)
			end)
		end)

		describe("fix creation", function(): ()
			test("should create fixes with proper format", function(): ()
				local range = {
					start = { line = 1, column = 11, offset = 10 },
					finish = { line = 1, column = 25, offset = 24 },
				}
				local fix = mockContext:createFix(range, "")

				expect(fix.range).is(range)
				expect(fix.text).is("")
			end)
		end)

		describe("source text access", function(): ()
			test("should get source text for node", function(): ()
				local sourceText = mockContext:getSourceText(mockNode)
				expect(sourceText).is("print('hello')")
			end)
		end)

		describe("context extension", function(): ()
			test("should create extended context with new properties", function(): ()
				local extendedContext = mockContext:extend({
					report = function() end,
					ruleId = "test-rule",
				})

				expect(extendedContext.filename).is("test.luau")
				expect(extendedContext.sourceText).is("local x = print('hello')")
				expect(extendedContext.ruleId).is("test-rule")
			end)
		end)
	end)
end

return ruleContextTestSuite
