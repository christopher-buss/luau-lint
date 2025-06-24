--!strict

--[=[
	@class LuauLintTestUtils

	Shared testing utilities for luau-lint packages

	This module provides common testing utilities, fixtures, and the
	"tiniest" testing framework for all luau-lint packages.

	@since v0.1.0
]=]

local TestFixtures = require("@self/test-fixtures")
local Tiniest = require("@self/tiniest/tiniest")

return {
	TestFixtures = TestFixtures,
	Tiniest = Tiniest,

	-- Re-export commonly used testing utilities
	expect = require("@self/tiniest/tiniest_expect"),
	snapshot = require("@self/tiniest/tiniest_snapshot"),
}
