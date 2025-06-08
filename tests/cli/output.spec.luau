--!strict
local OutputFormatter = require("../../src/cli/output")
local TiniestFramework = require("../tiniest/tiniest_for_lute")
local json = require("../../lute/batteries/json") -- Import Lute's JSON battery

local Tiniest = TiniestFramework.configure({})
local describe, it, expect = Tiniest.describe, Tiniest.test, Tiniest.expect

local function defineOutputTests()
	describe("CLI Output Formatter (OutputFormatter)", function()
		local mockResultsNoIssues: { OutputFormatter.LintResult } = {
			{
				filePath = "src/cleanFile.luau",
				issues = {},
				errorCount = 0,
				fixableErrorCount = 0,
				source = "local a = 1\nlocal b = 2",
			},
		}

		local mockResultsWithIssues: { OutputFormatter.LintResult } = {
			{
				filePath = "src/problemFile.luau",
				issues = {
					{
						ruleId = "no-vars",
						message = "Too many variables",
						line = 1,
						column = 7,
						endLine = 1,
						endColumn = 10,
						fixer = true,
					},
					{ ruleId = "indent", message = "Bad indentation", line = 2, column = 1 },
				},
				errorCount = 2,
				fixableErrorCount = 1,
				source = "local var1 = 10\n  local var2 = 20",
			},
			{
				filePath = "src/anotherProblem.luau",
				issues = {
					{
						ruleId = "naming",
						message = "Bad name",
						line = 5,
						column = 3,
						fixer = false,
					},
				},
				errorCount = 1,
				fixableErrorCount = 0,
				source = "\n\n\n\n  local bad_name = 30",
			},
		}

		local mockEmptyResults: { OutputFormatter.LintResult } = {}

		describe("formatAsText", function()
			it("should report no issues found for clean results", function()
				local output = OutputFormatter.formatAsText(mockResultsNoIssues)
				expect(string.match(output, "No issues found. ✨") ~= nil).is_true()
			end)

			it("should correctly format multiple issues from multiple files", function()
				local output = OutputFormatter.formatAsText(mockResultsWithIssues)
				expect(
					string.match(output, "Found 3 issue%(s%) in 2 file%(s%) %(1 fixable%).") ~= nil
				).is_true() -- Escaped ( ) .
				expect(string.match(output, "File: src/problemFile%.luau") ~= nil).is_true() -- Escaped .
				expect(
					string.match(
						output,
						"%[1:7%-1:10%] Too many variables %(no%-vars%) %(fixable%)"
					) ~= nil
				).is_true() -- Escaped [ ] ( ) -
				expect(string.match(output, "%[2:1%] Bad indentation %(indent%)") ~= nil).is_true() -- Escaped [ ] ( )
				expect(string.match(output, "File: src/anotherProblem%.luau") ~= nil).is_true() -- Escaped .
				expect(string.match(output, "%[5:3%] Bad name %(naming%)") ~= nil).is_true() -- Escaped [ ] ( )
			end)

			it(
				"should include source context if option is enabled and source is present",
				function()
					local output = OutputFormatter.formatAsText(
						mockResultsWithIssues,
						{ showSourceContext = true }
					)
					expect(string.match(output, "> local var1 = 10") ~= nil).is_true()
					expect(string.match(output, ">   local var2 = 20") ~= nil).is_true()
					expect(string.match(output, ">   local bad_name = 30") ~= nil).is_true()
				end
			)

			it("should not include source context if option is disabled", function()
				local output = OutputFormatter.formatAsText(
					mockResultsWithIssues,
					{ showSourceContext = false }
				)
				expect(string.match(output, "> local var1 = 10") == nil).is_true()
			end)

			it("should handle empty results gracefully", function()
				local output = OutputFormatter.formatAsText(mockEmptyResults)
				expect(string.match(output, "No issues found. ✨") ~= nil).is_true()
			end)
		end)

		describe("formatAsJson", function()
			it("should produce correct JSON for no issues", function()
				local jsonString = OutputFormatter.formatAsJson(mockResultsNoIssues)
				local success, jsonData = pcall(json.deserialize, jsonString)
				expect(success).is_true()
				expect(type(jsonData)).is("table")
				expect(jsonData.summary.totalIssues).is(0)
				expect(jsonData.summary.filesScanned).is(1)
				expect(jsonData.summary.filesWithIssues).is(0)
				if type(jsonData.results) == "table" then
					expect(#jsonData.results).is(1)
					if jsonData.results[1] then
						local issuesTable = jsonData.results[1].issues
						if type(issuesTable) == "table" then
							expect(#issuesTable).is(0)
						else
							expect(false).is(true) -- Fail test if issues is not a table
						end
						expect(jsonData.results[1].filePath).is("src/cleanFile.luau")
					else
						expect(false).is(true) -- Fail test if results[1] is nil
					end
				else
					expect(false).is(true) -- Fail test if results is not a table
				end
			end)

			it("should produce correct JSON for results with issues", function()
				local jsonString = OutputFormatter.formatAsJson(mockResultsWithIssues, false) -- Test WITHOUT prettyPrint to avoid potential buffer issues
				local success, jsonData = pcall(json.deserialize, jsonString)
				expect(success).is_true()
				expect(type(jsonData)).is("table")
				expect(jsonData.summary.totalIssues).is(3)
				expect(jsonData.summary.totalFixableIssues).is(1)
				expect(jsonData.summary.filesScanned).is(2)
				expect(jsonData.summary.filesWithIssues).is(2)

				if type(jsonData.results) ~= "table" then
					expect(false).is(true) -- Fail test
					return
				end
				expect(#jsonData.results).is(2)

				local result1 = jsonData.results[1]
				expect(type(result1)).is("table")
				expect(result1.filePath).is("src/problemFile.luau")
				expect(result1.errorCount).is(2)
				expect(result1.fixableErrorCount).is(1)
				if type(result1.issues) ~= "table" then
					expect(false).is(true) -- Fail test
					return
				end
				expect(#result1.issues).is(2)
				expect(type(result1.issues[1])).is("table")
				expect(result1.issues[1].ruleId).is("no-vars")
				expect(result1.issues[1].message).is("Too many variables")
				expect(result1.issues[1].line).is(1)
				expect(result1.issues[1].column).is(7)
				expect(result1.issues[1].endLine).is(1)
				expect(result1.issues[1].endColumn).is(10)

				local result2 = jsonData.results[2]
				expect(type(result2)).is("table")
				expect(result2.filePath).is("src/anotherProblem.luau")
				expect(result2.errorCount).is(1)
				if type(result2.issues) ~= "table" then
					expect(false).is(true) -- Fail test
					return
				end
				expect(#result2.issues).is(1)
				expect(type(result2.issues[1])).is("table")
				expect(result2.issues[1].ruleId).is("naming")
				expect(result2.issues[1].message).is("Bad name")
				expect(result2.issues[1].line).is(5)
				expect(result2.issues[1].column).is(3)
				expect(result2.issues[1].endLine).is(json.NULL) -- Check for json.NULL
				expect(result2.issues[1].endColumn).is(json.NULL)
			end)

			it("should handle empty results gracefully for JSON output", function()
				local jsonString = OutputFormatter.formatAsJson(mockEmptyResults)
				local success, jsonData = pcall(json.deserialize, jsonString)
				expect(success).is_true()
				expect(type(jsonData)).is("table")
				expect(jsonData.summary.totalIssues).is(0)
				expect(jsonData.summary.filesScanned).is(0)
				if type(jsonData.results) == "table" then
					expect(#jsonData.results).is(0)
				else
					expect(false).is(true) -- Fail test if results is not a table
				end
			end)
		end)
	end)
end

local collectedTests = Tiniest.collect_tests(defineOutputTests)
Tiniest.run_tests(collectedTests, {})
