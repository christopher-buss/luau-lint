--!strict

--[=[
	@class LuauLintConfig

	Configuration system for luau-lint

	This module handles loading, validating, and managing luau-lint configuration.

	@since v0.1.0
]=]

export type LuauLintConfig = {
	plugins: { string }?,
	rules: { [string]: "error" | "warn" | "off" }?,
	extends: { string }?,
	root: boolean?,
}

local function loadConfig(configPath: string?): LuauLintConfig
	-- Basic default configuration
	local config: LuauLintConfig = {
		plugins = { "@luau-lint/recommended-rules" },
		rules = {
			["generalized-iteration"] = "error" :: ("error" | "warn" | "off"),
		},
		root = true,
	}
	return config
end

local function validateConfig(config: LuauLintConfig): (boolean, string?)
	-- Basic validation
	return true, nil
end

return {
	loadConfig = loadConfig,
	validateConfig = validateConfig,
}
