--!strict

--[=[
	@class LuauLintCLI

	Command-line interface for luau-lint

	This module provides the main entry point for the luau-lint CLI package.

	@since v0.1.0
]=]

local Args = require("@self/args")
local Main = require("@self/main")
local Output = require("@self/output")

return {
	Args = Args,
	Main = Main,
	Output = Output,
}
