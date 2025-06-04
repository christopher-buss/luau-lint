--!strict

--[[
	Configuration Module for luau-lint
	
	This module provides comprehensive configuration management that:
	- Loads and validates configuration from files and tables
	- Provides sensible defaults for all configuration options
	- Supports configuration merging and inheritance
	- Handles rule configuration parsing and validation
	- Manages file ignore patterns and path resolution
	
	Key Features:
	- Type-safe configuration loading and validation
	- Flexible rule configuration (string or complex table format)
	- Configuration file discovery and priority handling
	- Path resolution and ignore pattern matching
	- Comprehensive validation with helpful error messages
]]

-- Export types for external use
export type SeverityLevel = "off" | "warn" | "error"

export type RuleConfig = {
	level: SeverityLevel,
	options: { [string]: any }?,
}

export type LintConfig = {
	rules: { [string]: string | RuleConfig },
	ignorePatterns: { string },
	extensions: { string },
	severity: SeverityLevel,
	failOnWarnings: boolean,
}

-- Valid severity levels for validation
local VALID_SEVERITY_LEVELS = { "off", "warn", "error" }

-- Default configuration
local DEFAULT_CONFIG: LintConfig = {
	rules = {
		["unused-variable"] = "warn",
		["undefined-global"] = "error",
	},
	ignorePatterns = { "*.generated.luau", "**/node_modules/**" },
	extensions = { ".luau", ".lua" },
	severity = "warn",
	failOnWarnings = false,
}

-- Helper function to validate severity levels
local function isValidSeverityLevel(level: string): boolean
	for _, validLevel in VALID_SEVERITY_LEVELS do
		if validLevel == level then
			return true
		end
	end
	return false
end

-- Helper function to deep clone a table
local function deepClone(original: any): any
	if type(original) ~= "table" then
		return original
	end

	local copy = {}
	for key, value in original do
		copy[key] = deepClone(value)
	end
	return copy
end

-- Get default configuration
local function getDefaultConfig(): LintConfig
	return deepClone(DEFAULT_CONFIG)
end

local function loadConfig(configData: any): LintConfig
	-- TODO: Implement
	error("loadConfig not implemented yet")
end

local function findConfigFiles(searchPath: string): { string }
	-- TODO: Implement
	error("findConfigFiles not implemented yet")
end

local function selectConfigFile(configPaths: { string }): string
	-- TODO: Implement
	error("selectConfigFile not implemented yet")
end

local function mergeConfigs(baseConfig: LintConfig, overrideConfig: any): LintConfig
	-- TODO: Implement
	error("mergeConfigs not implemented yet")
end

local function parseRuleConfig(ruleConfigInput: any): RuleConfig
	-- TODO: Implement
	error("parseRuleConfig not implemented yet")
end

local function validateConfig(config: any): boolean
	-- TODO: Implement
	error("validateConfig not implemented yet")
end

local function resolveConfigPaths(config: LintConfig, basePath: string): LintConfig
	-- TODO: Implement
	error("resolveConfigPaths not implemented yet")
end

local function shouldIgnoreFile(filePath: string, config: LintConfig): boolean
	-- TODO: Implement
	error("shouldIgnoreFile not implemented yet")
end

local function getEffectiveRuleConfig(ruleName: string, config: LintConfig): RuleConfig?
	-- TODO: Implement
	error("getEffectiveRuleConfig not implemented yet")
end

-- Export the module
return {
	getDefaultConfig = getDefaultConfig,
	loadConfig = loadConfig,
	findConfigFiles = findConfigFiles,
	selectConfigFile = selectConfigFile,
	mergeConfigs = mergeConfigs,
	parseRuleConfig = parseRuleConfig,
	validateConfig = validateConfig,
	resolveConfigPaths = resolveConfigPaths,
	shouldIgnoreFile = shouldIgnoreFile,
	getEffectiveRuleConfig = getEffectiveRuleConfig,
}
