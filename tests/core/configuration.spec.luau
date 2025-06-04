--!strict

-- Import the configuration module (will be created)
local configuration = require("../../src/core/configuration")

-- Export the test suite function for the central test runner
local function configuration_test_suite(describe, test, expect)
	describe("Configuration Module", function()
		describe("Default configuration", function()
			test("should provide sensible defaults", function()
				local defaultConfig = configuration.getDefaultConfig()

				expect(defaultConfig.rules).exists()
				expect(defaultConfig.ignorePatterns).exists()
				expect(defaultConfig.extensions).exists()
				expect(defaultConfig.severity).is("warn")
				expect(defaultConfig.failOnWarnings).is(false)
			end)

			test("should include default rule configurations", function()
				local defaultConfig = configuration.getDefaultConfig()

				-- Should have some default rules enabled
				expect(defaultConfig.rules["unused-variable"]).exists()
				expect(defaultConfig.rules["undefined-global"]).exists()
			end)
		end)

		describe("Configuration loading", function()
			test("should load configuration from table", function()
				local configData = {
					rules = {
						["unused-variable"] = "error",
						["undefined-global"] = "warn",
					},
					ignorePatterns = { "*.generated.luau" },
					severity = "error",
				}

				local config = configuration.loadConfig(configData)

				expect(config.rules["unused-variable"]).is("error")
				expect(config.rules["undefined-global"]).is("warn")
				expect(config.ignorePatterns[1]).is("*.generated.luau")
				expect(config.severity).is("error")
			end)

			test("should merge with defaults when loading partial config", function()
				local partialConfig = {
					rules = {
						["unused-variable"] = "error",
					},
				}

				local config = configuration.loadConfig(partialConfig)

				-- Should have our override
				expect(config.rules["unused-variable"]).is("error")
				-- Should have defaults for other rules
				expect(config.rules["undefined-global"]).exists()
				-- Should have default settings
				expect(config.severity).is("warn") -- default
				expect(config.failOnWarnings).is(false) -- default
			end)

			test("should validate rule severity levels", function()
				local configWithInvalidSeverity = {
					rules = {
						["unused-variable"] = "invalid-level",
					},
				}

				expect(function()
					configuration.loadConfig(configWithInvalidSeverity)
				end).fails()
			end)

			test("should validate global severity level", function()
				local configWithInvalidGlobalSeverity = {
					severity = "invalid-severity",
				}

				expect(function()
					configuration.loadConfig(configWithInvalidGlobalSeverity)
				end).fails()
			end)
		end)

		describe("Configuration file discovery", function()
			test("should find .luau-lint.luau files", function()
				local configPaths = configuration.findConfigFiles("./tests/fixtures")

				-- Should find config files in the fixtures directory
				expect(type(configPaths)).is("table")
			end)

			test("should prioritize .luau-lint.luau over .luau-lint.toml", function()
				-- If both exist, .luau should take priority
				local selectedPath = configuration.selectConfigFile({
					"./tests/fixtures/.luau-lint.toml",
					"./tests/fixtures/.luau-lint.luau",
				})

				expect(selectedPath:find("%.luau$") ~= nil).is_true()
			end)
		end)

		describe("Configuration merging", function()
			test("should merge multiple configurations in priority order", function()
				local baseConfig = {
					rules = {
						["unused-variable"] = "warn",
						["undefined-global"] = "warn",
					},
					severity = "warn",
				}

				local overrideConfig = {
					rules = {
						["unused-variable"] = "error", -- Override
					},
					ignorePatterns = { "*.generated.luau" }, -- Add new
				}

				local merged = configuration.mergeConfigs(baseConfig, overrideConfig)

				expect(merged.rules["unused-variable"]).is("error") -- Overridden
				expect(merged.rules["undefined-global"]).is("warn") -- Preserved
				expect(merged.severity).is("warn") -- Preserved from base
				expect(merged.ignorePatterns[1]).is("*.generated.luau") -- Added
			end)

			test("should handle nested rule configurations", function()
				local baseConfig = {
					rules = {
						["custom-rule"] = {
							level = "warn",
							options = { maxLength = 100 },
						},
					},
				}

				local overrideConfig = {
					rules = {
						["custom-rule"] = {
							level = "error", -- Override level
							options = { maxDepth = 5 }, -- Override options
						},
					},
				}

				local merged = configuration.mergeConfigs(baseConfig, overrideConfig)

				expect(merged.rules["custom-rule"].level).is("error")
				expect(merged.rules["custom-rule"].options.maxDepth).is(5)
				-- Should completely replace options, not merge them
				expect(merged.rules["custom-rule"].options.maxLength).is(nil)
			end)
		end)

		describe("Rule configuration parsing", function()
			test("should parse simple string rule configurations", function()
				local ruleConfig = configuration.parseRuleConfig("error")

				expect(ruleConfig.level).is("error")
				expect(ruleConfig.options).is(nil)
			end)

			test("should parse complex table rule configurations", function()
				local complexRule = {
					level = "warn",
					options = {
						maxLength = 80,
						allowedPatterns = { "^test_" },
					},
				}

				local ruleConfig = configuration.parseRuleConfig(complexRule)

				expect(ruleConfig.level).is("warn")
				expect(ruleConfig.options.maxLength).is(80)
				expect(ruleConfig.options.allowedPatterns[1]).is("^test_")
			end)

			test("should validate rule configuration structure", function()
				local invalidRule = {
					level = "invalid-level",
					options = "not-a-table",
				}

				expect(function()
					configuration.parseRuleConfig(invalidRule)
				end).fails()
			end)
		end)

		describe("Configuration validation", function()
			test("should validate complete configuration schema", function()
				local validConfig = {
					rules = {
						["unused-variable"] = "error",
						["custom-rule"] = {
							level = "warn",
							options = { maxLength = 100 },
						},
					},
					ignorePatterns = { "*.generated.luau", "**/build/**" },
					extensions = { ".luau", ".lua" },
					severity = "warn",
					failOnWarnings = false,
				}

				local isValid = configuration.validateConfig(validConfig)
				expect(isValid).is_true()
			end)

			test("should reject configurations with unknown properties", function()
				local invalidConfig = {
					rules = {},
					unknownProperty = "invalid",
				}

				local isValid = configuration.validateConfig(invalidConfig)
				expect(isValid).is(false)
			end)

			test("should reject configurations with invalid rule names", function()
				local invalidConfig = {
					rules = {
						[""] = "error", -- Empty rule name
						["invalid rule name"] = "warn", -- Spaces in name
					},
				}

				local isValid = configuration.validateConfig(invalidConfig)
				expect(isValid).is(false)
			end)
		end)

		describe("Configuration utilities", function()
			test("should resolve relative paths in configuration", function()
				local config = {
					ignorePatterns = { "./build/**", "../shared/generated/**" },
				}

				local resolved = configuration.resolveConfigPaths(config, "/project/src")

				expect(resolved.ignorePatterns[1]:find("/project/src/build") ~= nil).is_true()
				expect(resolved.ignorePatterns[2]:find("/project/shared/generated") ~= nil).is_true()
			end)

			test("should check if file matches ignore patterns", function()
				local config = {
					ignorePatterns = { "*.generated.luau", "**/node_modules/**", "build/**" },
				}

				expect(configuration.shouldIgnoreFile("test.generated.luau", config)).is_true()
				expect(configuration.shouldIgnoreFile("src/node_modules/lib.luau", config)).is_true()
				expect(configuration.shouldIgnoreFile("build/output.luau", config)).is_true()
				expect(configuration.shouldIgnoreFile("src/main.luau", config)).is(false)
			end)

			test("should get effective rule configuration", function()
				local config = {
					rules = {
						["unused-variable"] = "error",
						["custom-rule"] = {
							level = "warn",
							options = { maxLength = 80 },
						},
					},
					severity = "warn",
				}

				local simpleRule = configuration.getEffectiveRuleConfig("unused-variable", config)
				expect(simpleRule.level).is("error")
				expect(simpleRule.options).is(nil)

				local complexRule = configuration.getEffectiveRuleConfig("custom-rule", config)
				expect(complexRule.level).is("warn")
				expect(complexRule.options.maxLength).is(80)

				-- Should return nil for unknown rules
				local unknownRule = configuration.getEffectiveRuleConfig("unknown-rule", config)
				expect(unknownRule).is(nil)
			end)
		end)
	end)
end

-- Export the test suite function
return configuration_test_suite
