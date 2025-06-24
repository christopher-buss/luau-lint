--!strict

--[=[
	@class LuauLintPluginAPI

	Public API for luau-lint plugin authors

	This module provides the complete API surface that plugin authors need
	to create custom rules for luau-lint.

	@since v0.1.0
]=]

local PluginAPI = require("@self/plugin-api")

return {
	PluginAPI = PluginAPI,
}
