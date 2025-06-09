-- src/cli/main.luau
-- Main command-line interface entry point for Luau Linter.

local Args = require("./args")
local Fs = require("@lute/fs")
local Luau = require("@lute/luau")
local OutputFormatter = require("./output")
local Parser = require("@batteries/syntax/parser")
local PluginApi = require("../plugin/plugin-api")
local Process = require("@lute/process") -- Import process type definitions
local Result = require("@batteries/result")
local Rule = require("../plugin/rule")
local pp = require("@batteries/pp")
-- local FileProcessor = require("../core/file-processor") -- To be created
-- local ConfigLoader = require("../config/loader") -- To be created

local VERSION = "0.0.1-alpha" -- Placeholder version

local function displayHelp(): ()
	print("Luau Linter - Help")
	print("Usage: lute src/cli/main.luau [options] <files...>")
	print("\nOptions:")
	print("  --help         Show this help message.")
	print("  --version      Show version information.")
	print("  --config <path> Path to a configuration file.")
	print("  --fix          Attempt to automatically fix issues.")
	print("\nExamples:")
	print("  lute src/cli/main.luau ./src")
	print("  lute src/cli/main.luau --fix ./src/myFile.luau")
end

local function displayVersion(): ()
	print(`Luau Linter Version: {VERSION}`)
end

local generalizedIterationRule: Rule.Rule = {
	id = "generalizedIteration",
	title = "Use direct table iteration instead of pairs() and ipairs()",
	description = "Luau's generalized iteration allows direct table iteration using `for k, v in "
		.. "table do` syntax without `pairs()` or `ipairs()`. This provides unified iteration "
		.. "semantics that automatically handles both arrays and dictionaries with consistent "
		.. "behavior. Using the older functions adds unnecessary verbosity when direct iteration "
		.. "accomplishes the same result more elegantly.",
	category = "logical",
	fixable = "auto",
	docsUrl = "https://example.com/docs/generalized-iteration",

	create = function(context: PluginApi.RuleContext): Rule.ListenerMap
		return {
			[Rule.NODE_TYPES.ForIn] = function(node: Luau.AstStatForIn & Rule.LintNode): ()
				if #node.values == 0 then
					return
				end

				local firstValue = node.values[1].node
				if firstValue.tag ~= "call" or firstValue.func.tag ~= "global" then
					return
				end

				local funcName = firstValue.func.name.text

				if funcName ~= "ipairs" and funcName ~= "pairs" then
					return
				end

				print(context:getSourceText(node, -1, 5))

				-- remove #funcName from start of text
				-- local fixedText = string.gsub(node.source, "#%s*" ..
				-- funcName, "")

				print("reporting error")

				context:report({
					node = node,
					message = "Use generalized iteration",
					fix = {
						range = node.location,
						text = "",
					},
				})
			end,
		}
	end,
}

-- Placeholder for actual file processing and linting logic
-- This will be expanded significantly in subsequent tasks.
local function runLinter(parsedArgs: Args.ParsedArgs): number
	print("Running linter...")

	if #parsedArgs.files == 0 then
		print("No files specified to lint.")
		displayHelp()
		return 1 -- Indicate error
	end

	-- Placeholder: Load configuration (Task 3)
	-- local config = ConfigLoader.load(parsedArgs.configPath)
	local placeholderConfig = { rules = { generalizedIterationRule } } -- Default to no rules enabled for now

	local status = Result.pcall(function()
		return table.pack(PluginApi.createLinter(placeholderConfig.rules))
	end)

	if status.success == false then
		print(
			"Error: Failed to initialize the linting engine (pcall failed). Details: "
				.. tostring(status.err)
		)
		return 1
	end

	print(`Linting files: {table.concat(parsedArgs.files, ", ")}`)

	local allResults: { PluginApi.LintResult } = {}

	local engine = status.value[2] :: PluginApi.RuleEngine

	for _, filePath in parsedArgs.files do
		local content: string?

		-- Placeholder: File Processing (Task 2)
		local processStatus = Result.pcall(function()
			local file = Fs.open(filePath, "r")
			content = Fs.read(file)
			return Parser.parse(content)
		end)

		assert(type(content) == "string", "Expected content to be a string")

		if processStatus.success == false then
			print(`Error processing file {filePath}: {processStatus.err}`)
			table.insert(allResults, {
				filePath = filePath,
				issues = {},
				errorCount = 1,
				fixableErrorCount = 0,
				source = nil,
			})
			continue
		end

		-- Simulate linting a file

		local ast = processStatus.value

		local lintResult: PluginApi.LintResult
		local lintStatus = Result.pcall(function(): PluginApi.LintResult
			return engine.lintFile(ast, content, filePath)
		end)

		if lintStatus.success then
			lintResult = lintStatus.value
		else
			-- temp, shouldn't crash program
			error(`Error during linting of {filePath}: {tostring(lintStatus.err)}`)
		end

		table.insert(allResults, lintResult)
	end

	local outputText = OutputFormatter.formatAsText(allResults, { showSourceContext = true })
	print(outputText)

	local exitCode = 0
	for _, res in allResults do
		if #res.errors > 0 then
			exitCode = 1
			break
		end
	end

	return exitCode
end

local function main()
	local currentProcess = Process

	-- TEMPORARY: Hard-coded file for testing
	-- This bypasses the need for command-line argument parsing
	local parsedArgs: Args.ParsedArgs = {
		files = { "tests\\fixtures\\bad_code.luau" }, -- File to lint for testing
		help = false,
		version = false,
		configPath = nil,
		fix = false,
		errors = {} :: { any },
		unknownFlags = {},
	}

	if #parsedArgs.errors > 0 then
		for _, err in parsedArgs.errors do
			print(`Error: {err}`)
		end
		displayHelp()
		if currentProcess and type(currentProcess.exit) == "function" then
			currentProcess.exit(2)
		end
		return
	end

	if parsedArgs.help then
		displayHelp()
		if currentProcess and type(currentProcess.exit) == "function" then
			currentProcess.exit(0)
		end
		return
	end

	if parsedArgs.version then
		displayVersion()
		if currentProcess and type(currentProcess.exit) == "function" then
			currentProcess.exit(0)
		end
		return
	end

	if #parsedArgs.unknownFlags > 0 then
		print("Unknown flags: " .. table.concat(parsedArgs.unknownFlags, ", "))
		displayHelp()
		if currentProcess and type(currentProcess.exit) == "function" then
			currentProcess.exit(2)
		end
		return
	end

	local exitCodeValue = runLinter(parsedArgs :: Args.ParsedArgs)
	if type(exitCodeValue) ~= "number" then
		print("Error: Linter did not return a valid numeric exit code. Defaulting to 3.")
		exitCodeValue = 3
	end

	if currentProcess and type(currentProcess.exit) == "function" then
		currentProcess.exit(exitCodeValue)
	else
		if exitCodeValue ~= 0 then
			print(
				"Linter finished with issues or errors. Simulated exit code: "
					.. tostring(exitCodeValue)
			)
		else
			print("Linter finished successfully. (Simulated exit)")
		end
	end
end

main()
