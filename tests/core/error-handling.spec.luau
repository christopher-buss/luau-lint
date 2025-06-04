--!strict
local errorHandling = require("../../src/core/error-handling")
local types = require("../tiniest/types")

type DescribeFunction = types.DescribeFunction
type TestFunction = types.TestFunction
type ExpectFunction = types.ExpectFunction

type ErrorContext = errorHandling.ErrorContext
type ErrorHandlerOptions = errorHandling.ErrorHandlerOptions
type ErrorType = errorHandling.ErrorType
type Location = errorHandling.Location
type Position = errorHandling.Position

local function error_handling_test_suite(
	describe: DescribeFunction,
	test: TestFunction,
	expect: ExpectFunction
): ()
	describe("Error Handling Module", function(): ()
		describe("LintError creation", function(): ()
			test("should create a basic LintError with required fields", function(): ()
				local err = errorHandling.createLintError("ParseError", "Test error message")

				expect(err.errorType).is("ParseError")
				expect(err.message).is("Test error message")
				expect(err.filePath).is(nil)
				expect(err.location).is(nil)
				expect(err.cause).is(nil)
				expect(err.stack).is(nil)
			end)

			test("should create a LintError with optional context", function(): ()
				local context: ErrorContext = {
					filePath = "test.luau",
					location = {
						start = { line = 1, column = 5, offset = 4 },
						["end"] = { line = 1, column = 10, offset = 9 },
					},
					cause = "Syntax error",
					stack = nil,
				}

				local error = errorHandling.createLintError("ParseError", "Parse failed", context)

				expect(error.errorType).is("ParseError")
				expect(error.message).is("Parse failed")
				expect(error.filePath).is("test.luau")
				expect(error.location).exists()
				assert(error.location, "Luau")
				expect(error.location.start.line).is(1)
				expect(error.cause).is("Syntax error")
			end)

			test("should validate error types", function(): ()
				-- Test all valid error types
				local validTypes: Array<ErrorType> = {
					"ParseError",
					"ConfigError",
					"RuleError",
					"FileSystemError",
					"ValidationError",
					"InternalError",
				}

				for _, errorType in validTypes do
					local error = errorHandling.createLintError(errorType, "Test message")
					expect(error.errorType).is(errorType)
				end
			end)

			test("should reject invalid error types", function()
				expect(function(): ()
					errorHandling.createLintError("InvalidType" :: any, "Test message")
				end).fails()
			end)
		end)

		describe("Error wrapping", function(): ()
			test("should wrap native Luau errors", function(): ()
				local originalError = "Division by zero"
				local context: ErrorContext = {
					filePath = "test.luau",
					location = nil,
					cause = nil,
					stack = nil,
				}

				local wrappedError = errorHandling.wrapError(originalError, context)

				expect(wrappedError.errorType).is("InternalError")
				expect(wrappedError.message:find("Division by zero") ~= nil).is_true()
				expect(wrappedError.filePath).is("test.luau")
				expect(wrappedError.cause).exists()
			end)

			test("should preserve LintError if already wrapped", function(): ()
				local originalError =
					errorHandling.createLintError("ParseError", "Original message")
				local context: ErrorContext = {
					filePath = "test.luau",
					location = nil,
					cause = nil,
					stack = nil,
				}

				local result = errorHandling.wrapError(originalError, context)

				-- Should return the same error, not double-wrap
				expect(result).is(originalError)
			end)
		end)

		describe("ErrorHandler creation and usage", function(): ()
			test("should create default error handler", function(): ()
				local handler = errorHandling.createErrorHandler()

				expect(handler.handleError).exists()
				expect(handler.reportError).exists()
				expect(handler.shouldContinue).exists()
			end)

			test("should handle errors with default behavior", function(): ()
				local handler = errorHandling.createErrorHandler()
				local error = errorHandling.createLintError("RuleError", "Rule failed")

				local action = handler.handleError(error)
				expect(action).is("continue") -- Default behavior for rule errors
			end)

			test("should determine continuation based on error type", function(): ()
				local handler = errorHandling.createErrorHandler()

				-- Different error types should have different continuation behavior
				local parseError = errorHandling.createLintError("ParseError", "Parse failed")
				local ruleError = errorHandling.createLintError("RuleError", "Rule failed")
				local internalError =
					errorHandling.createLintError("InternalError", "Internal error")

				expect(handler.shouldContinue(parseError)).is(true) -- Parse errors should allow continuation
				expect(handler.shouldContinue(ruleError)).is(true) -- Rule errors should allow continuation
				expect(handler.shouldContinue(internalError)).is(false) -- Internal errors might not
			end)

			test("should support custom error handler options", function(): ()
				local options: ErrorHandlerOptions = {
					strict = true,
					maxErrors = 5,
					failFast = false,
				}

				local handler = errorHandling.createErrorHandler(options)
				expect(handler).exists()
			end)
		end)

		describe("Graceful error handling utilities", function(): ()
			test("should handle function gracefully with fallback", function(): ()
				local function failingFunction(): string
					error("This function always fails")
				end

				local result = errorHandling.handleGracefully(failingFunction, "fallback value")
				expect(result).is("fallback value")
			end)

			test("should return actual result when function succeeds", function(): ()
				local function successFunction(): string
					return "success result"
				end

				local result = errorHandling.handleGracefully(successFunction, "fallback value")
				expect(result).is("success result")
			end)

			test("should retry with backoff on failure", function(): ()
				local attempts = 0
				local function flakyFunction(): string
					attempts += 1
					if attempts < 3 then
						error("Temporary failure")
					end
					return "success after retries"
				end

				local result = errorHandling.retryWithBackoff(flakyFunction, 5)
				expect(result).is("success after retries")
				expect(attempts).is(3)
			end)

			test("should return nil after max retries exceeded", function(): ()
				local function alwaysFailingFunction(): string
					error("Always fails")
				end

				local result = errorHandling.retryWithBackoff(alwaysFailingFunction, 2)
				expect(result).is(nil)
			end)
		end)
	end)
end

-- Export the test suite function
return error_handling_test_suite
