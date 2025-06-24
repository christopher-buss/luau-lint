--!strict

--[=[
	@class RecommendedRules
	
	Default recommended rules for luau-lint
	
	This plugin contains the core set of rules that are recommended for
	most Luau projects. These rules enforce best practices and help
	catch common issues.
	
	@since v0.1.0
]=]

local GeneralizedIteration = require("./rules/generalized-iteration")

-- Export all rules in this plugin
return {
	rules = {
		GeneralizedIteration,
	},
	
	-- Plugin metadata
	name = "recommended-rules",
	version = "0.1.0",
	description = "Default recommended rules for luau-lint",
}