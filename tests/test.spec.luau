--!strict

local tiniest = require("@tiniest/tiniest_for_lute").configure({
	snapshot_path = "./tests/__snapshots__",
	save_snapshots = true,
})

-- Import all test suite modules
-- local configuration_test_suite = require("./core/configuration.spec")
local error_handling_test_suite = require("./core/error-handling.spec")

local function run_all_tests()
	local describe = tiniest.describe
	local test = tiniest.test
	local expect = tiniest.expect

	-- Run core module tests
	error_handling_test_suite(describe, test, expect)
	-- configuration_test_suite(describe, test, expect)

	-- Example test to verify runner works
	describe("Test Runner", function()
		test("can run basic tests", function()
			expect(2 + 2).is(4)
		end)
	end)
end

local tests = tiniest.collect_tests(run_all_tests)
tiniest.run_tests(tests, {})
