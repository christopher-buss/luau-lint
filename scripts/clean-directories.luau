#!/usr/bin/env lune

--[[
    Clean Directories Script for luau-lint

    This script recursively removes all directories with specified names
    throughout the project. Useful for cleaning up generated files like
    luau_packages, node_modules, .pesde, etc.

    Usage:
        lune run scripts/clean-directories.luau
        lune run scripts/clean-directories.luau -- --dirs luau_packages .pesde
        lune run scripts/clean-directories.luau -- --dry-run
        lune run scripts/clean-directories.luau -- --help

    Examples:
        # Clean default directories (luau_packages)
        lune run scripts/clean-directories.luau

        # Clean specific directories
        lune run scripts/clean-directories.luau -- --dirs luau_packages .pesde node_modules

        # Preview what would be deleted without actually deleting
        lune run scripts/clean-directories.luau -- --dry-run
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

-- Configuration
local DEFAULT_CLEAN_DIRS = {
	"luau_packages",
	".pesde",
}

local EXCLUDED_PATHS = {
	".git",
	"target",
	"dist",
	"build",
}

-- ANSI color codes for pretty output
local colors = {
	reset = "\27[0m",
	green = "\27[32m",
	blue = "\27[34m",
	yellow = "\27[33m",
	red = "\27[31m",
	gray = "\27[90m",
	bold = "\27[1m",
}

local function log(color: string, prefix: string, message: string)
	print(`{color}{colors.bold}{prefix}{colors.reset} {message}`)
end

local function logInfo(message: string)
	log(colors.blue, "ℹ", message)
end

local function logSuccess(message: string)
	log(colors.green, "✅", message)
end

local function logWarning(message: string)
	log(colors.yellow, "⚠", message)
end

local function logError(message: string)
	log(colors.red, "❌", message)
end

local function logDebug(message: string)
	log(colors.gray, "🔍", message)
end

local function showHelp()
	print("Clean Directories Script")
	print("Usage: lune run scripts/clean-directories.luau [OPTIONS]")
	print("")
	print("Options:")
	print("  --dirs <names...>    Specify directory names to clean (space-separated)")
	print("  --dry-run           Show what would be deleted without actually deleting")
	print("  --force             Skip confirmation prompt (use with caution)")
	print("  --help              Show this help message")
	print("")
	print("Examples:")
	print("  lune run scripts/clean-directories.luau")
	print("  lune run scripts/clean-directories.luau -- --dirs luau_packages .pesde")
	print("  lune run scripts/clean-directories.luau -- --dry-run")
	print("  lune run scripts/clean-directories.luau -- --force")
	print("")
	print(`Default directories to clean: {table.concat(DEFAULT_CLEAN_DIRS, ", ")}`)
end

-- Parse command line arguments
local function parseArgs(): ({ string }, boolean, boolean)
	local args = process.args
	local dirsToClean = DEFAULT_CLEAN_DIRS
	local dryRun = false
	local force = false

	local i = 1
	while i <= #args do
		local arg = args[i]

		if arg == "--help" or arg == "-h" then
			showHelp()
			process.exit(0)
		elseif arg == "--dry-run" then
			dryRun = true
		elseif arg == "--force" then
			force = true
		elseif arg == "--dirs" then
			-- Collect all directory names after --dirs
			dirsToClean = {}
			i += 1
			while i <= #args and string.sub(args[i], 1, 2) ~= "--" do
				table.insert(dirsToClean, args[i])
				i += 1
			end
			i -= 1 -- Adjust for the outer loop increment
		end

		i += 1
	end

	return dirsToClean, dryRun, force
end

-- Check if a path should be excluded from traversal
local function isExcludedPath(path: string): boolean
	for _, excluded in EXCLUDED_PATHS do
		if string.find(path, excluded, 1, true) then
			return true
		end
	end
	return false
end

-- Recursively find all directories with specified names
local function findDirectories(rootPath: string, targetNames: { string }): { string }
	local found = {}

	local function traverse(currentPath: string)
		-- Skip excluded paths
		if isExcludedPath(currentPath) then
			return
		end

		-- Check if current path exists and is a directory
		if not fs.isDir(currentPath) then
			return
		end

		local entries = fs.readDir(currentPath)

		for _, entry in entries do
			local fullPath = `{currentPath}/{entry}`

			-- Check if this entry is one of our target directories
			local isTargetDir = false
			for _, targetName in targetNames do
				if entry == targetName and fs.isDir(fullPath) then
					table.insert(found, fullPath)
					-- Don't traverse into directories we're going to delete
					isTargetDir = true
					break
				end
			end

			-- Recursively traverse subdirectories (but not target directories)
			if not isTargetDir and fs.isDir(fullPath) and not isExcludedPath(fullPath) then
				traverse(fullPath)
			end
		end
	end

	traverse(rootPath)
	return found
end

-- Get human-readable size of a directory
local function getDirectorySize(path: string): string
	-- Simple size estimation by counting files
	local function countFiles(dirPath: string): number
		if not fs.isDir(dirPath) then
			return 0
		end

		local count = 0
		for entry in fs.readDir(dirPath) do
			local fullPath = `{dirPath}/{entry}`
			if fs.isFile(fullPath) then
				count += 1
			elseif fs.isDir(fullPath) then
				count += countFiles(fullPath)
			end
		end
		return count
	end

	local success, fileCount = pcall(countFiles, path)
	if not success or fileCount == 0 then
		return "empty"
	elseif fileCount < 10 then
		return `{fileCount} files`
	elseif fileCount < 100 then
		return `~{math.floor(fileCount / 10) * 10} files`
	else
		return `~{math.floor(fileCount / 100) * 100}+ files`
	end
end

-- Remove a directory and all its contents
local function removeDirectory(path: string): boolean
	local success, err = pcall(function()
		fs.removeDir(path)
		return nil
	end)

	if not success then
		logError(`Failed to remove {path}: {err}`)
		return false
	end

	return true
end

-- Main script logic
local function main()
	local dirsToClean, dryRun, force = parseArgs()

	if dryRun then
		logWarning("DRY RUN MODE - No files will actually be deleted")
	end

	logInfo(`Searching for directories: {table.concat(dirsToClean, ", ")}`)

	-- Find all matching directories
	local foundDirs = findDirectories(".", dirsToClean)

	if #foundDirs == 0 then
		logInfo("No directories found to clean")
		return
	end

	logInfo(`Found {#foundDirs} director{#foundDirs > 1 and "ies" or "y"}:`)

	-- Show what will be deleted
	for _, dirPath in foundDirs do
		local size = getDirectorySize(dirPath)
		if dryRun then
			logDebug(`Would delete: {dirPath} ({size})`)
		else
			logDebug(`Will delete: {dirPath} ({size})`)
		end
	end

	if dryRun then
		logInfo("Dry run complete. Use without --dry-run to actually delete directories.")
		return
	end

	-- Confirm deletion for safety
	local confirmed = force

	if not force then
		local success, result = pcall(
			stdio.prompt,
			"confirm",
			`About to delete {#foundDirs} director{#foundDirs > 1 and "ies" or "y"}. Continue?`
		)

		if success then
			confirmed = result
		else
			-- Fallback for non-interactive environments
			logWarning(
				"Running in non-interactive environment. Use --force to proceed automatically."
			)
			logInfo("Operation cancelled")
			return
		end

		if not confirmed then
			logInfo("Operation cancelled")
			return
		end
	else
		logWarning("Force mode enabled - skipping confirmation")
	end

	-- Delete directories
	local deletedCount = 0
	local failedCount = 0

	for _, dirPath in foundDirs do
		logInfo(`Deleting {dirPath}...`)

		if removeDirectory(dirPath) then
			logSuccess(`Deleted {dirPath}`)
			deletedCount += 1
		else
			failedCount += 1
		end
	end

	-- Summary
	if failedCount == 0 then
		logSuccess(
			`Successfully deleted {deletedCount} director{deletedCount > 1 and "ies" or "y"}`
		)
	else
		logWarning(`Deleted {deletedCount}, failed {failedCount}`)
	end

	if deletedCount > 0 then
		logInfo("Clean up complete! You may want to run 'pesde install' to reinstall dependencies.")
	end
end

-- Run the script
main()
