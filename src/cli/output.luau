-- src/cli/output.luau
-- Handles formatting of linting results.

local PluginApi = require("../plugin/plugin-api")
local json = require("../../lute/batteries/json")

type LintResult = PluginApi.LintResult

export type FormatterOptions = {
	showSourceContext: boolean?, -- For text formatter
}

local function formatAsText(results: { LintResult }, optionsParam: FormatterOptions?): string
	local output = {}
	local totalIssues = 0
	local totalFixable = 0
	local filesWithIssues = 0

	local showSourceCtx = false
	if optionsParam and optionsParam.showSourceContext ~= nil then
		showSourceCtx = optionsParam.showSourceContext
	end

	for _, result in results do
		totalIssues += result.lintStats.issuesFound
		totalFixable += result.lintStats.fixableIssues
		-- if result.errorCount == 0 then
		-- 	continue
		-- end

		filesWithIssues += 1
		-- table.insert(output, `\nFile: {result.filePath}`)

		for _, issue in result.issues do
			local start = issue.loc and issue.loc.start
			local finish = issue.loc and issue.loc.finish
			if start == nil then
				-- TODO: This is optional, do we need to change that? Can we
				-- just populate them from the node provided?
				error("Missing location information for issue")
			end

			local lineInfo = `{start.line + 1}:{start.column + 1}`
			if finish and finish.line and finish.column then
				lineInfo ..= `-{finish.line + 1}:{finish.column + 1}`
			end

			local fixableMark = if issue.fix then " (fixable)" else ""
			table.insert(output, `  [{lineInfo}] {issue.message} ({issue.ruleId}){fixableMark}`)

			-- if not showSourceCtx or result.source == nil then
			-- 	continue
			-- end

			-- -- Basic source context (can be improved)
			-- local lines = string.split(result.source, "\n")
			-- if issue.line >= 1 and issue.line <= #lines then
			-- 	table.insert(output, `    > {lines[issue.line]}`)
			-- end
		end
	end

	if totalIssues > 0 then
		table.insert(
			output,
			1,
			`Found {totalIssues} issue(s) in {filesWithIssues} file(s) ({totalFixable} fixable).`
		)
	else
		table.insert(output, "No issues found. ✨")
	end

	return table.concat(output, "\n")
end

local function formatAsJson(results: { LintResult }, prettyPrint: boolean?): string
	local overallSummary = {
		totalIssues = 0,
		totalFixableIssues = 0,
		filesScanned = #results,
		filesWithIssues = 0,
	}

	local serializableResults = {}

	for _, result in results do
		overallSummary.totalIssues += result.errorCount
		overallSummary.totalFixableIssues += result.fixableErrorCount
		if result.errorCount > 0 then
			overallSummary.filesWithIssues += 1
		end
		-- Create a serializable version of each result, omitting non-serializable parts like 'fixer' functions
		local resIssues = {}
		for _, issue in ipairs(result.issues) do
			table.insert(resIssues, {
				ruleId = issue.ruleId,
				message = issue.message,
				line = issue.line,
				column = issue.column,
				endLine = if issue.endLine then issue.endLine else json.NULL,
				endColumn = if issue.endColumn then issue.endColumn else json.NULL,
			})
		end
		table.insert(serializableResults, {
			filePath = result.filePath,
			issues = resIssues,
			errorCount = result.errorCount,
			fixableErrorCount = result.fixableErrorCount,
			-- source = result.source, -- Optionally include source, but can make JSON large
		})
	end

	local outputData = {
		summary = overallSummary,
		results = serializableResults,
	}

	return json.serialize(outputData, prettyPrint or false) :: string
end

return {
	formatAsText = formatAsText,
	formatAsJson = formatAsJson,
}
