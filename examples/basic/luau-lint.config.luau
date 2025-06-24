--!strict

--[=[
	Basic luau-lint configuration example
	
	This shows a minimal configuration for a typical Luau project.
]=]

return {
	-- Enable recommended rules plugin
	plugins = {
		"@luau-lint/recommended-rules",
	},
	
	-- Configure individual rules
	rules = {
		["generalized-iteration"] = "error",
	},
	
	-- This is a root configuration file
	root = true,
}