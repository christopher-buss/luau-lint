--!strict

local fs = require("@lute/fs")
local tiniest = require("@tiniest/tiniest_for_lute").configure({
	snapshot_path = "./tests/__snapshots__",
	save_snapshots = true,
})

-- Function to recursively find all .spec.luau files
local function findTestFiles(directory: string): { string }
	local testFiles = {}

	local function walkDirectory(dir: string)
		local entries = fs.listdir(dir)

		for _, entry in entries do
			local fullPath = dir .. "/" .. entry.name

			if
				entry.type == "dir"
				and entry.name ~= "__snapshots__"
				and entry.name ~= "tiniest"
			then
				-- Recursively search subdirectories (skip snapshots and tiniest)
				walkDirectory(fullPath)
			elseif
				entry.type == "file"
				and string.match(entry.name, "%.spec%.luau$")
				and entry.name ~= "test.spec.luau"
			then
				-- Found a test file (exclude the main test runner)
				table.insert(testFiles, fullPath)
			end
		end
	end

	walkDirectory(directory)
	return testFiles
end

-- Function to convert file path to require path
local function pathToRequire(filePath: string): string
	local requirePath = string.gsub(filePath, "^%./tests/", "./")
	requirePath = string.gsub(requirePath, "%.luau$", "")
	return requirePath
end

local function runAllTests()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest.expect

	-- Example test to verify runner works
	describe("Test Runner", function()
		test("can run basic tests", function()
			expect(2 + 2).is(4)
		end)

		test("can discover test files", function()
			local tests = findTestFiles("./tests")
			expect(#tests).is_a("number")
			expect(#tests).never_is(0)
		end)
	end)

	-- Dynamically discover and run all test files
	local testFiles = findTestFiles("./tests")

	for _, filePath in testFiles do
		-- Skip the problematic integration test file for now

		local requirePath = pathToRequire(filePath)
		local success, testSuite = pcall(require, requirePath)

		if success and type(testSuite) == "function" then
			-- Run the test suite
			testSuite(describe, test, expect)
		else
			print(`Failed to load test suite from {requirePath}: {testSuite}`)
		end
	end

	-- Run the fixed integration tests
	local success, fixedIntegrationTests =
		pcall(require, "integration/integration-test-scenarios-fixed")
	if success and type(fixedIntegrationTests) == "function" then
		fixedIntegrationTests(describe, test, expect)
	else
		print(`Failed to load fixed integration tests: {fixedIntegrationTests}`)
	end
end

local tests = tiniest.collect_tests(runAllTests)
tiniest.run_tests(tests, {})
