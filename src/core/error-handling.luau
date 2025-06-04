--!strict

--[[
	Error Handling Module for luau-lint
	
	This module provides a comprehensive error handling system that:
	- Creates typed, structured errors with context information
	- Wraps native Luau errors into our error system
	- Provides configurable error handlers for different scenarios
	- Offers utilities for graceful error handling and retry logic
	
	Key Features:
	- Type-safe error creation and validation
	- Error context tracking (file paths, locations, causes)
	- Configurable error handling strategies 
	- Graceful degradation and retry mechanisms
]]

export type ErrorType =
	| "ParseError"
	| "ConfigError"
	| "RuleError"
	| "FileSystemError"
	| "ValidationError"
	| "InternalError"

export type Position = {
	line: number,
	column: number,
	offset: number,
}

export type Location = {
	start: Position,
	["end"]: Position,
}

export type ErrorContext = {
	filePath: string?,
	location: Location?,
	cause: string?,
	stack: string?,
}

export type LintError = {
	errorType: ErrorType,
	message: string,
	filePath: string?,
	location: Location?,
	cause: string?,
	stack: string?,
}

export type ErrorAction = "continue" | "skip" | "abort" | "retry"

export type ErrorHandlerOptions = {
	strict: boolean?,
	maxErrors: number?,
	failFast: boolean?,
}

export type ErrorHandler = {
	handleError: (error: LintError) -> ErrorAction,
	reportError: (error: LintError) -> (),
	shouldContinue: (error: LintError) -> boolean,
}

-- Valid error types for validation
local VALID_ERROR_TYPES = {
	"ParseError",
	"ConfigError",
	"RuleError",
	"FileSystemError",
	"ValidationError",
	"InternalError",
}

-- Helper function to validate error type
local function isValidErrorType(errorType: string): boolean
	for _, validType in VALID_ERROR_TYPES do
		if validType == errorType then
			return true
		end
	end

	return false
end

-- Helper function to check if something is already a LintError
local function isLintError(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	local valueTable = value :: Map<string, any>
	return type(valueTable.errorType) == "string"
		and type(valueTable.message) == "string"
		and isValidErrorType(valueTable.errorType)
end

-- Create a LintError with validation
local function createLintError(
	errorType: ErrorType,
	message: string,
	context: ErrorContext?
): LintError
	if not isValidErrorType(errorType) then
		error(
			`Invalid error type: {errorType}. Must be one of: {table.concat(VALID_ERROR_TYPES, ", ")}`
		)
	end

	local lintError: LintError = {
		errorType = errorType,
		message = message,
		filePath = if context then context.filePath else nil,
		location = if context then context.location else nil,
		cause = if context then context.cause else nil,
		stack = if context then context.stack else nil,
	}

	return lintError
end

-- Wrap any error into a LintError
local function wrapError(originalError: any, context: ErrorContext): LintError
	-- If it's already a LintError, return as-is
	if isLintError(originalError) then
		return originalError
	end

	-- Convert to string representation
	local errorMessage = tostring(originalError)

	-- Create wrapped error
	local wrappedError = createLintError("InternalError", `Wrapped error: {errorMessage}`, {
		filePath = context.filePath,
		location = context.location,
		cause = errorMessage,
		stack = context.stack or debug.traceback(),
	})

	return wrappedError
end

-- Default error handler behavior
local function getDefaultAction(error: LintError): ErrorAction
	-- Different error types have different default behaviors
	if error.errorType == "ParseError" then
		return "continue" -- Continue with other files even if one fails to parse
	elseif error.errorType == "RuleError" then
		return "continue" -- Continue with other rules even if one fails
	elseif error.errorType == "ConfigError" then
		return "continue" -- Continue with defaults if config fails
	elseif error.errorType == "FileSystemError" then
		return "continue" -- Continue with other files
	elseif error.errorType == "ValidationError" then
		return "continue" -- Continue processing
	else -- InternalError
		return "abort" -- Internal errors might indicate serious problems
	end
end

local function getDefaultContinuation(error: LintError): boolean
	-- Most errors allow continuation, except critical internal errors
	return error.errorType ~= "InternalError"
end

-- Create an error handler with optional configuration
local function createErrorHandler(options: ErrorHandlerOptions?): ErrorHandler
	local _opts = options or {} -- Store for future use

	local errorHandler: ErrorHandler = {
		handleError = function(error: LintError): ErrorAction
			-- For now, use default behavior
			-- In the future, this could be customized based on options
			return getDefaultAction(error)
		end,

		reportError = function(error: LintError): ()
			-- For now, just print to stdout (io.stderr not available in lute)
			-- In the future, this could use a proper logging system
			print(`Error [{error.errorType}]: {error.message}`)
			if error.filePath then
				print(` in {error.filePath}`)
			end
			if error.location then
				print(` at line {error.location.start.line}, column {error.location.start.column}`)
			end
		end,

		shouldContinue = function(error: LintError): boolean
			return getDefaultContinuation(error)
		end,
	}

	return errorHandler
end

-- Gracefully handle function execution with fallback
local function handleGracefully<T>(fn: () -> T, fallback: T): T
	local success, result = pcall(fn)
	if success then
		return result
	else
		return fallback
	end
end

-- Retry function with exponential backoff
local function retryWithBackoff<T>(fn: () -> T, maxRetries: number): T?
	for _ = 1, maxRetries do
		local success, result = pcall(fn)
		if success then
			return result
		end

		-- If not the last attempt, could add delay here
		-- TODO: Add task.wait() when Lute supports it
	end

	return nil
end

-- Export the module
return {
	createLintError = createLintError,
	wrapError = wrapError,
	createErrorHandler = createErrorHandler,
	handleGracefully = handleGracefully,
	retryWithBackoff = retryWithBackoff,
}
