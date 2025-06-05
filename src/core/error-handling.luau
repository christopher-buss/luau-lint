--!strict

--[=[
	@class ErrorHandling
	
	Error Handling Module for luau-lint
	
	This module provides a comprehensive error handling system designed for the luau-lint
	static analysis tool. It offers type-safe error creation, wrapping, and handling
	mechanisms to ensure robust error management throughout the linting pipeline.
	
	## Key Features
	
	- **Type-safe error creation**: Structured LintError types with validation
	- **Error context tracking**: File paths, source locations, and error causes
	- **Configurable error handling**: Customizable error handling strategies 
	- **Graceful degradation**: Fallback mechanisms and retry logic
	- **Native error wrapping**: Converts Luau errors into structured LintErrors
	
	## Example Usage
	
	```luau
	local ErrorHandling = require("src/core/error-handling")
	
	-- Create a structured error
	local error = ErrorHandling.createLintError(
		"ParseError",
		"Unexpected token",
		{ filePath = "file.luau", location = { start = { line = 1, column = 5 } } }
	)
	
	-- Create an error handler
	local handler = ErrorHandling.createErrorHandler({ strict = true })
	handler.reportError(error)
	```
	
	@since v0.1.0
]=]

--[=[
	@type ErrorType "ParseError" | "ConfigError" | "RuleError" | "FileSystemError" | "ValidationError" | "InternalError"
	@within ErrorHandling
	
	Enumeration of all possible error types in the luau-lint system.
	Each type represents a different category of error that can occur during linting.
]=]
export type ErrorType =
	| "ParseError"
	| "ConfigError"
	| "RuleError"
	| "FileSystemError"
	| "ValidationError"
	| "InternalError"

--[=[
	@interface Position
	@within ErrorHandling
	.line number -- The line number (1-based)
	.column number -- The column number (1-based)  
	.offset number -- The character offset from start of file (0-based)
	
	Represents a specific position within a source file.
]=]
export type Position = {
	line: number,
	column: number,
	offset: number,
}

--[=[
	@interface Location
	@within ErrorHandling
	.start Position -- The starting position of the error
	.end Position -- The ending position of the error
	
	Represents a range within a source file where an error occurred.
]=]
export type Location = {
	start: Position,
	["end"]: Position,
}

--[=[
	@interface ErrorContext
	@within ErrorHandling
	.filePath string? -- Optional path to the file where the error occurred
	.location Location? -- Optional source location information
	.cause string? -- Optional description of the underlying cause
	.stack string? -- Optional stack trace information
	
	Additional context information that can be attached to errors.
	All fields are optional to allow for flexible error creation.
]=]
export type ErrorContext = {
	filePath: string?,
	location: Location?,
	cause: string?,
	stack: string?,
}

--[=[
	@interface LintError
	@within ErrorHandling
	.errorType ErrorType -- The category of error that occurred
	.message string -- Human-readable description of the error
	.filePath string? -- Optional path to the file where the error occurred
	.location Location? -- Optional source location where the error occurred
	.cause string? -- Optional description of the underlying cause
	.stack string? -- Optional stack trace for debugging
	
	The primary error structure used throughout luau-lint.
	Contains all necessary information for error reporting and handling.
]=]
export type LintError = {
	errorType: ErrorType,
	message: string,
	filePath: string?,
	location: Location?,
	cause: string?,
	stack: string?,
}

--[=[
	@type ErrorAction "continue" | "skip" | "abort" | "retry"
	@within ErrorHandling
	
	Actions that can be taken when an error occurs:
	- `continue`: Continue processing despite the error
	- `skip`: Skip the current item and move to the next
	- `abort`: Stop all processing immediately
	- `retry`: Attempt the operation again
]=]
export type ErrorAction = "continue" | "skip" | "abort" | "retry"

--[=[
	@interface ErrorHandlerOptions
	@within ErrorHandling
	.strict boolean? -- Whether to use strict error handling (fail fast)
	.maxErrors number? -- Maximum number of errors before aborting
	.failFast boolean? -- Whether to abort on first error
	
	Configuration options for customizing error handler behavior.
]=]
export type ErrorHandlerOptions = {
	strict: boolean?,
	maxErrors: number?,
	failFast: boolean?,
}

--[=[
	@interface ErrorHandler
	@within ErrorHandling
	.handleError (error: LintError) -> ErrorAction -- Determines action to take for an error
	.reportError (error: LintError) -> () -- Reports the error to output/logging
	.shouldContinue (error: LintError) -> boolean -- Determines if processing should continue
	
	Interface for handling errors throughout the linting process.
	Provides hooks for custom error handling, reporting, and flow control.
]=]
export type ErrorHandler = {
	handleError: (error: LintError) -> ErrorAction,
	reportError: (error: LintError) -> (),
	shouldContinue: (error: LintError) -> boolean,
}

--- Valid error types for validation
local VALID_ERROR_TYPES = {
	"ParseError",
	"ConfigError",
	"RuleError",
	"FileSystemError",
	"ValidationError",
	"InternalError",
}

--[=[
	Validates that an error type string is one of the allowed ErrorType values.
	
	@param errorType string -- The error type string to validate
	@return boolean -- True if the error type is valid, false otherwise
	
	@since v0.1.0
]=]
local function isValidErrorType(errorType: string): boolean
	for _, validType in VALID_ERROR_TYPES do
		if validType == errorType then
			return true
		end
	end

	return false
end

--[=[
	Checks if a value is already a properly structured LintError.
	
	Used internally to avoid double-wrapping errors and to validate error structures.
	
	@param value any -- The value to check
	@return boolean -- True if the value is a LintError, false otherwise
	
	@since v0.1.0
]=]
local function isLintError(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	local valueTable = value :: { [string]: any }
	return type(valueTable.errorType) == "string"
		and type(valueTable.message) == "string"
		and isValidErrorType(valueTable.errorType)
end

--[=[
	Creates a validated LintError with the specified type, message, and optional context.
	
	This is the primary function for creating structured errors throughout luau-lint.
	All error creation should go through this function to ensure consistency and validation.
	
	@param errorType ErrorType -- The category of error (e.g., "ParseError", "ConfigError")
	@param message string -- Human-readable description of what went wrong
	@param context ErrorContext? -- Optional additional context (file path, location, etc.)
	@return LintError -- A fully constructed and validated LintError
	
	@error "Invalid error type" -- Thrown when errorType is not a valid ErrorType
	
	@since v0.1.0
]=]
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

--[=[
	Wraps any error (LintError, string, or other value) into a LintError structure.
	
	This function is essential for converting native Luau errors and other error types
	into the structured LintError format used throughout luau-lint. If the input is
	already a LintError, it returns it unchanged to avoid double-wrapping.
	
	@param originalError any -- The error to wrap (can be string, table, LintError, etc.)
	@param context ErrorContext -- Context information to attach to the wrapped error
	@return LintError -- The original error if it's already a LintError, or a new wrapped LintError
	
	@since v0.1.0
]=]
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

--[=[
	Determines the default action to take for a given error type.
	
	Different error types have different default recovery behaviors:
	- Parse/Rule/Config/FileSystem/Validation errors: Continue processing
	- Internal errors: Abort processing (may indicate serious problems)
	
	@param error LintError -- The error to determine action for
	@return ErrorAction -- The recommended action ("continue", "skip", "abort", or "retry")
	
	@since v0.1.0
]=]
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

--[=[
	Determines whether processing should continue after an error.
	
	Most error types allow continuation except for critical internal errors
	which may indicate systemic problems requiring immediate attention.
	
	@param error LintError -- The error to evaluate
	@return boolean -- True if processing should continue, false if it should stop
	
	@since v0.1.0
]=]
local function getDefaultContinuation(error: LintError): boolean
	-- Most errors allow continuation, except critical internal errors
	return error.errorType ~= "InternalError"
end

--[=[
	Creates a configurable error handler with customizable behavior.
	
	Error handlers control how errors are processed, reported, and what actions
	are taken when errors occur. This function creates a handler with default
	behavior that can be customized through the options parameter.
	
	@param options ErrorHandlerOptions? -- Optional configuration for error handling behavior
	@return ErrorHandler -- A configured error handler with handleError, reportError, and shouldContinue methods
	
	@since v0.1.0
]=]
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

--[=[
	Executes a function with graceful error handling and fallback value.
	
	This utility function provides a safe way to execute potentially failing operations
	with a fallback value. If the function succeeds, its result is returned. If it fails,
	the fallback value is returned instead, preventing the error from propagating.
	
	@param fn () -> T -- The function to execute safely
	@param fallback T -- The value to return if the function fails
	@return T -- Either the function's result or the fallback value
	
	@since v0.1.0
]=]
local function handleGracefully<T>(fn: () -> T, fallback: T): T
	local success, result = pcall(fn)
	if success then
		return result
	else
		return fallback
	end
end

--[=[
	Retries a function multiple times with exponential backoff on failure.
	
	This utility provides resilience against transient failures by attempting
	the operation multiple times. Currently implements simple retry logic;
	future versions may add configurable delay between attempts.
	
	@param fn () -> T -- The function to retry on failure
	@param maxRetries number -- Maximum number of retry attempts
	@return T? -- The function's result if successful, nil if all retries failed
	
	@since v0.1.0
]=]
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

--[=[
	@prop createLintError (errorType: ErrorType, message: string, context: ErrorContext?) -> LintError
	@within ErrorHandling
	
	Creates a validated LintError with the specified type, message, and optional context.
	This is the primary function for creating structured errors throughout luau-lint.
]=]

--[=[
	@prop wrapError (originalError: any, context: ErrorContext) -> LintError  
	@within ErrorHandling
	
	Wraps any error into a LintError structure. Essential for converting native Luau errors
	and other error types into the structured format used throughout luau-lint.
]=]

--[=[
	@prop createErrorHandler (options: ErrorHandlerOptions?) -> ErrorHandler
	@within ErrorHandling
	
	Creates a configurable error handler with customizable behavior for processing,
	reporting, and determining actions when errors occur.
]=]

--[=[
	@prop handleGracefully <T>(fn: () -> T, fallback: T) -> T
	@within ErrorHandling
	
	Executes a function with graceful error handling and fallback value.
	Provides a safe way to execute potentially failing operations.
]=]

--[=[
	@prop retryWithBackoff <T>(fn: () -> T, maxRetries: number) -> T?
	@within ErrorHandling
	
	Retries a function multiple times on failure. Provides resilience against
	transient failures by attempting the operation multiple times.
]=]

-- Export the module
return {
	createLintError = createLintError,
	wrapError = wrapError,
	createErrorHandler = createErrorHandler,
	handleGracefully = handleGracefully,
	retryWithBackoff = retryWithBackoff,
}
