-- Example .luau-lint.luau configuration file for testing
return {
	rules = {
		["unused-variable"] = "warn",
		["undefined-global"] = "error",
	},
	ignorePatterns = { "*.generated.luau" },
	severity = "warn",
}
