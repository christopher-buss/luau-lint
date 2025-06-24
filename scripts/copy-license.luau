#!/usr/bin/env lune

--[[
    Copy License Script for luau-lint

    This script copies the root LICENSE file to each package directory
    in the packages/ folder to ensure all publishable packages have
    the proper licensing information.

    Usage: lune run scripts/copy-license.luau
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

-- Configuration
local ROOT_LICENSE_PATH = "LICENSE"
local PACKAGES_DIR = "packages"

-- ANSI color codes for pretty output
local colors = {
    reset = "\27[0m",
    green = "\27[32m",
    blue = "\27[34m",
    yellow = "\27[33m",
    red = "\27[31m",
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

-- Main script logic
local function main()
    logInfo("Starting license copy process...")

    -- Check if root LICENSE exists
    if not fs.isFile(ROOT_LICENSE_PATH) then
        logError(`Root LICENSE file not found at: {ROOT_LICENSE_PATH}`)
        process.exit(1)
    end

    -- Check if packages directory exists
    if not fs.isDir(PACKAGES_DIR) then
        logError(`Packages directory not found at: {PACKAGES_DIR}`)
        process.exit(1)
    end

    -- Read the root LICENSE content
    local licenseContent = fs.readFile(ROOT_LICENSE_PATH)
    logInfo(`Read LICENSE file ({#licenseContent} characters)`)

    -- Get all package directories
    local packageDirs = {}
    local entries = fs.readDir(PACKAGES_DIR)
    for _, entry in entries do
        local packagePath = `{PACKAGES_DIR}/{entry}`
        if fs.isDir(packagePath) then
            table.insert(packageDirs, entry)
        end
    end

    if #packageDirs == 0 then
        logWarning("No package directories found")
        return
    end

    logInfo(`Found {#packageDirs} package(s): {table.concat(packageDirs, ", ")}`)

    -- Copy LICENSE to each package
    local copiedCount = 0
    local skippedCount = 0

    for _, packageName in packageDirs do
        local packagePath = `{PACKAGES_DIR}/{packageName}`
        local packageLicensePath = `{packagePath}/LICENSE`

        -- Check if package LICENSE already exists and is identical
        if fs.isFile(packageLicensePath) then
            local existingContent = fs.readFile(packageLicensePath)
            if existingContent == licenseContent then
                logInfo(`{packageName}: LICENSE already up to date`)
                skippedCount += 1
                continue
            end
        end

        -- Copy the LICENSE
        fs.writeFile(packageLicensePath, licenseContent)
        logSuccess(`{packageName}: LICENSE copied`)
        copiedCount += 1
    end

    -- Summary
    logInfo(`Process complete! Copied: {copiedCount}, Skipped: {skippedCount}, Total: {#packageDirs}`)

    if copiedCount > 0 then
        logSuccess("All packages now have the correct LICENSE file")
    end
end

-- Run the script
main()