#!/usr/bin/env lute
--!strict

-- Simple test runner script
local tiniest_module = require("./packages/test-utils/src/tiniest/tiniest_for_lute")
local fs = require("@lute/fs")

-- Configure tiniest
local tiniest = tiniest_module.configure({
	snapshot_path = "./tests/__snapshots__",
	save_snapshots = true,
})

-- List of test files to run from the new package-based structure
local testFiles = {
	"./tests/packages/cli/args.spec",
	"./tests/packages/cli/output.spec", 
	"./tests/packages/core/error-handling.spec",
	"./tests/packages/plugin-api/registry.spec",
	"./tests/packages/plugin-api/rule.spec",
	"./tests/packages/plugin-api/plugin-api.spec",
	"./tests/packages/plugin-api/context.spec",
}

print("Running test suite...")
print("===================")

-- Function to run all test suites
local function runAllTests()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest.expect
	
	-- Add a simple test to verify the framework works
	describe("Test Framework", function()
		test("basic arithmetic", function()
			expect(2 + 2).is(4)
		end)
		
		test("string concatenation", function()
			expect("hello" .. " " .. "world").is("hello world")
		end)
	end)
	
	-- Load and run each test file
	for _, testFile in testFiles do
		local success, testSuite = pcall(require, testFile)
		
		if success and type(testSuite) == "function" then
			print(`Loading test suite: {testFile}`)
			testSuite(describe, test, expect)
		else
			print(`Failed to load test suite {testFile}: {testSuite}`)
		end
	end
end

-- Collect and run all tests
local tests = tiniest.collect_tests(runAllTests)
local results = tiniest.run_tests(tests, {})

-- Print results summary
print("\nTest Results:")
print("=============")
print(`Total tests: {#tests}`)
print(`Passed: {results.status_tally.pass}`)
print(`Failed: {results.status_tally.fail}`)

if results.status_tally.fail > 0 then
	print("\nFailed tests:")
	for test, result in results.individual do
		if result.status == "fail" then
			print(`  - {table.concat(test.labels, " > ")}`)
			print(`    Error: {result.error.message}`)
		end
	end
	-- Exit with error code
	error("Tests failed", 0)
else
	print("\nAll tests passed! ✅")
end