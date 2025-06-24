-- Enhanced Test Fixtures for Integration Testing
-- This file provides utilities for managing and accessing test fixtures
-- for comprehensive integration testing scenarios

--!strict

local fs = require("@lute/fs")

--[=[
    @class TestFixtures
    
    Test Fixture Management for Luau Linter Integration Tests
    
    Provides structured access to test fixtures, mock data, and test scenarios
    for comprehensive integration testing of the plugin system.
]=]

local TestFixtures = {}

-- Base fixture paths
local FIXTURES_BASE = "./tests/fixtures"
local INTEGRATION_BASE = "./tests/fixtures/integration"

-- Core fixture definitions
TestFixtures.Core = {
	-- Existing fixtures
	goodCode = `{FIXTURES_BASE}/good_code.luau`,
	badCode = `{FIXTURES_BASE}/bad_code.luau`,
	modernCode = `{FIXTURES_BASE}/modern_code.luau`,
	beforeAfterExample = `{FIXTURES_BASE}/before_after_example.luau`,
	config = `{FIXTURES_BASE}/.luau-lint.luau`,

	-- New integration-specific fixtures
	complexProject = `{INTEGRATION_BASE}/complex-project`,
	errorScenarios = `{INTEGRATION_BASE}/error-scenarios`,
	performanceTests = `{INTEGRATION_BASE}/performance`,
	configurationTests = `{INTEGRATION_BASE}/configurations`,
}

-- Project structure fixtures
TestFixtures.Projects = {
	simple = {
		name = "simple-project",
		path = `{INTEGRATION_BASE}/projects/simple-project`,
		files = {
			main = "main.luau",
			config = ".luau-lint.luau",
		},
		description = "Basic single-file project for integration testing",
	},

	multiFile = {
		name = "multi-file-project",
		path = `{INTEGRATION_BASE}/projects/multi-file-project`,
		files = {
			main = "src/main.luau",
			utils = "src/utils.luau",
			types = "src/types.luau",
			test = "tests/test.luau",
			config = ".luau-lint.luau",
		},
		description = "Complex multi-file project with various code patterns",
	},

	errorProject = {
		name = "error-project",
		path = `{INTEGRATION_BASE}/projects/error-project`,
		files = {
			parseError = "parse-error.luau",
			runtimeError = "runtime-error.luau",
			configError = ".luau-lint.luau",
		},
		description = "Project with various error scenarios for error handling tests",
	},
}

-- Code sample fixtures for specific test scenarios
TestFixtures.CodeSamples = {
	modernLuau = {
		path = `{INTEGRATION_BASE}/code-samples/modern-luau`,
		files = {
			iteration = "modern-iteration.luau",
			types = "type-annotations.luau",
			generics = "generics.luau",
			async = "async-patterns.luau",
		},
		description = "Modern Luau patterns and features",
	},

	legacyLuau = {
		path = `{INTEGRATION_BASE}/code-samples/legacy-luau`,
		files = {
			oldIteration = "old-iteration.luau",
			oldPatterns = "legacy-patterns.luau",
			mixedStyles = "mixed-styles.luau",
		},
		description = "Legacy Luau patterns for modernization testing",
	},

	edgeCases = {
		path = `{INTEGRATION_BASE}/code-samples/edge-cases`,
		files = {
			emptyFile = "empty.luau",
			whitespaceOnly = "whitespace-only.luau",
			commentsOnly = "comments-only.luau",
			longLines = "long-lines.luau",
			deepNesting = "deep-nesting.luau",
			largeFile = "large-file.luau",
		},
		description = "Edge case scenarios for robust testing",
	},

	performance = {
		path = `{INTEGRATION_BASE}/code-samples/performance`,
		files = {
			large = "large-file.luau",
			manyVariables = "many-variables.luau",
			deepNesting = "deep-nesting.luau",
			complexExpressions = "complex-expressions.luau",
		},
		description = "Files designed for performance testing",
	},
}

-- Configuration fixtures
TestFixtures.Configurations = {
	strict = {
		path = `{INTEGRATION_BASE}/configurations/strict-config.luau`,
		description = "Strict configuration with all rules enabled",
		rules = {
			["no-unused-variables"] = "error",
			["modern-iteration"] = "error",
			["consistent-naming"] = "error",
			["no-undefined-variables"] = "error",
		},
	},

	lenient = {
		path = `{INTEGRATION_BASE}/configurations/lenient-config.luau`,
		description = "Lenient configuration with minimal rules",
		rules = {
			["no-unused-variables"] = "warn",
			["modern-iteration"] = "off",
		},
	},

	customRules = {
		path = `{INTEGRATION_BASE}/configurations/custom-rules-config.luau`,
		description = "Configuration with custom rule settings",
		rules = {
			["configurable-rule"] = {
				maxLineLength = 120,
				checkComments = false,
				allowedPatterns = { "test_.*", "mock_.*" },
			},
		},
	},

	invalid = {
		path = `{INTEGRATION_BASE}/configurations/invalid-config.luau`,
		description = "Invalid configuration for error testing",
		content = "invalid lua syntax = =",
	},
}

-- Mock rule definitions for testing
TestFixtures.MockRules = {
	noUnusedVariables = {
		id = "no-unused-variables",
		title = "No Unused Variables",
		description = "Detects variables that are declared but never used",
		category = "correctness",
		severity = "warning",
		create = function(context)
			local declared = {}
			local used = {}

			return {
				["Local"] = function(node)
					for _, binding in node.bindings do
						if binding.name then
							declared[binding.name] = {
								name = binding.name,
								node = binding,
								location = binding.location,
							}
						end
					end
				end,

				["Identifier"] = function(node)
					if declared[node.name] then
						used[node.name] = true
					end
				end,

				["Program:exit"] = function(node)
					for name, info in declared do
						if not used[name] then
							context.report({
								message = `Variable '{name}' is declared but never used`,
								node = info.node,
								loc = info.location,
							})
						end
					end
				end,
			}
		end,
	},

	modernIteration = {
		id = "modern-iteration",
		title = "Modern Iteration Patterns",
		description = "Suggests modern Luau iteration patterns over ipairs/pairs",
		category = "style",
		severity = "suggestion",
		create = function(context)
			return {
				["Call"] = function(node)
					if node.func and node.func.name then
						local funcName = node.func.name
						if funcName == "ipairs" or funcName == "pairs" then
							context.report({
								message = `Consider using modern Luau iteration instead of {funcName}()`,
								node = node,
								fix = context.createFix(
									node.location,
									"-- Use: for key, value in table do"
								),
							})
						end
					end
				end,
			}
		end,
	},

	consistentNaming = {
		id = "consistent-naming",
		title = "Consistent Naming",
		description = "Enforces consistent naming conventions",
		category = "style",
		severity = "info",
		create = function(context)
			return {
				["Local"] = function(node)
					for _, binding in node.bindings do
						if binding.name then
							local name = binding.name
							if string.match(name, "[A-Z]") and string.match(name, "_") then
								context.report({
									message = `Variable '{name}' mixes camelCase and snake_case`,
									node = binding,
								})
							end
						end
					end
				end,
			}
		end,
	},

	faultyRule = {
		id = "faulty-rule",
		title = "Faulty Rule",
		description = "A rule that throws errors for testing error handling",
		category = "test",
		severity = "error",
		create = function(context)
			return {
				["Local"] = function(node)
					error("Intentional test error from faulty rule")
				end,
			}
		end,
	},

	performanceRule = {
		id = "performance-rule",
		title = "Performance Test Rule",
		description = "A rule designed for performance testing",
		category = "performance",
		severity = "info",
		create = function(context)
			local nodeCount = 0
			return {
				["Local"] = function(node)
					nodeCount = nodeCount + 1
					if nodeCount % 50 == 0 then
						context.report({
							message = `Processed {nodeCount} nodes`,
							node = node,
						})
					end
				end,
			}
		end,
	},
}

-- Utility functions for fixture management
function TestFixtures.loadFixture(fixturePath: string): string?
	local success, content = pcall(fs.readfile, fixturePath)
	if success then
		return content
	else
		warn(`Failed to load fixture: {fixturePath}`)
		return nil
	end
end

function TestFixtures.fixtureExists(fixturePath: string): boolean
	return fs.isfile(fixturePath)
end

function TestFixtures.createTestProject(projectName: string, files: { [string]: string }): boolean
	local projectPath = `{INTEGRATION_BASE}/projects/{projectName}`

	-- Create project directory
	local success = pcall(fs.mkdir, projectPath)
	if not success then
		return false
	end

	-- Create files
	for filePath, content in files do
		local fullPath = `{projectPath}/{filePath}`
		local dir = string.match(fullPath, "(.+)/[^/]+$")
		if dir then
			pcall(fs.mkdir, dir)
		end

		local writeSuccess = pcall(fs.writefile, fullPath, content)
		if not writeSuccess then
			return false
		end
	end

	return true
end

function TestFixtures.generateLargeFile(lineCount: number): string
	local content = "-- Generated large file for performance testing\n"

	for i = 1, lineCount do
		content = content .. `local variable{i} = {i} + math.random()\n`

		if i % 10 == 0 then
			content = content .. `-- Checkpoint at line {i}\n`
		end

		if i % 25 == 0 then
			content = content .. `print("Processing variable", variable{i})\n`
		end
	end

	return content
end

function TestFixtures.generateComplexNesting(depth: number): string
	local content = "-- Generated complex nesting for testing\n"

	for i = 1, depth do
		content = content .. string.rep("  ", i - 1) .. `if condition{i} then\n`
	end

	content = content .. string.rep("  ", depth) .. `print("Deep nesting level {depth}")\n`

	for i = depth, 1, -1 do
		content = content .. string.rep("  ", i - 1) .. "end\n"
	end

	return content
end

-- Expected results for validation
TestFixtures.ExpectedResults = {
	simpleProject = {
		issueCount = 2,
		errorCount = 0,
		rules = { "no-unused-variables", "modern-iteration" },
	},

	multiFileProject = {
		issueCount = 5,
		errorCount = 0,
		rules = { "no-unused-variables", "modern-iteration", "consistent-naming" },
	},

	errorProject = {
		issueCount = 0,
		errorCount = 3,
		errorTypes = { "ParseError", "RuleError", "ConfigError" },
	},

	performanceTest = {
		maxExecutionTime = 2.0, -- seconds
		maxMemoryUsage = 10000, -- KB
		minNodesProcessed = 100,
	},
}

-- Validation helpers
function TestFixtures.validateLintResult(result, expectedResult)
	local validations = {}

	if expectedResult.issueCount then
		table.insert(validations, {
			name = "Issue Count",
			expected = expectedResult.issueCount,
			actual = #result.issues,
			passed = #result.issues == expectedResult.issueCount,
		})
	end

	if expectedResult.errorCount then
		table.insert(validations, {
			name = "Error Count",
			expected = expectedResult.errorCount,
			actual = #result.errors,
			passed = #result.errors == expectedResult.errorCount,
		})
	end

	if expectedResult.rules then
		local foundRules = {}
		for _, issue in result.issues do
			foundRules[issue.ruleId] = true
		end

		for _, expectedRule in expectedResult.rules do
			table.insert(validations, {
				name = `Rule {expectedRule}`,
				expected = true,
				actual = foundRules[expectedRule] or false,
				passed = foundRules[expectedRule] == true,
			})
		end
	end

	return validations
end

-- Test fixture creation utilities
function TestFixtures.ensureFixturesExist()
	local required = {
		FIXTURES_BASE,
		INTEGRATION_BASE,
		`{INTEGRATION_BASE}/projects`,
		`{INTEGRATION_BASE}/code-samples`,
		`{INTEGRATION_BASE}/configurations`,
		`{INTEGRATION_BASE}/expected-results`,
	}

	for _, dir in required do
		if not fs.isdir(dir) then
			local success = pcall(fs.mkdir, dir)
			if not success then
				warn(`Failed to create fixture directory: {dir}`)
			end
		end
	end
end

-- Initialize fixture directories on module load
TestFixtures.ensureFixturesExist()

return TestFixtures
