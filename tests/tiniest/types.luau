--!strict

--[[
    Type definitions for the tiniest testing framework Based on dphfox/tiniest,
    licensed under BSD

    This file provides comprehensive type definitions for all tiniest framework
    functions to improve type safety in test files.
]]

-- Core tiniest framework types
export type Test = {
	labels: { string },
	run: () -> (),
}

export type ErrorReport = {
	type: "tiniest.ErrorReport",
	message: string,
	trace: string,
	code: {
		snippet: string,
		line: string,
	}?,
}

export type TestRunResult = PassTestRunResult | FailTestRunResult

export type PassTestRunResult = {
	status: "pass",
}

export type FailTestRunResult = {
	status: "fail",
	error: ErrorReport,
}

export type RunResult = {
	tests: { Test },
	status_tally: {
		pass: number,
		fail: number,
	},
	individual: { [Test]: TestRunResult },
}

-- Expectation chain interface - supports fluent API
export type ExpectChain = {
	-- Existence checks
	exists: () -> ExpectChain,
	never_exists: () -> ExpectChain,

	-- Equality checks
	is: (expected: any) -> ExpectChain,
	never_is: (expected: any) -> ExpectChain,

	-- Boolean checks
	is_true: () -> ExpectChain,
	never_is_true: () -> ExpectChain,

	-- Type checks
	is_a: (typeName: string) -> ExpectChain,
	never_is_a: (typeName: string) -> ExpectChain,

	-- Object/table property checks
	has_key: (key: any) -> ExpectChain,
	never_has_key: (key: any) -> ExpectChain,
	has_value: (value: any) -> ExpectChain,
	never_has_value: (value: any) -> ExpectChain,

	-- String checks
	starts_with: (prefix: string) -> ExpectChain,
	never_starts_with: (prefix: string) -> ExpectChain,
	ends_with: (suffix: string) -> ExpectChain,
	never_ends_with: (suffix: string) -> ExpectChain,
	includes: (substring: string) -> ExpectChain,
	never_includes: (substring: string) -> ExpectChain,

	-- Snapshot testing
	matches_snapshot: (key: string?) -> ExpectChain,

	-- Error checks (function failure testing)
	fails: () -> ExpectChain,
	never_fails: () -> ExpectChain,
	fails_with: (expectedMessage: string) -> ExpectChain,
	never_fails_with: (expectedMessage: string) -> ExpectChain,
}

-- Test framework function signatures
export type DescribeFunction = (label: string, testSuite: () -> ()) -> ()
export type TestFunction = (label: string, testImplementation: () -> ()) -> ()
export type ExpectFunction = (actual: any) -> ExpectChain

-- Configuration types for tiniest_for_lute
export type TiniestOptions = {
	snapshot_path: string?,
	save_snapshots: boolean?,
	pretty: {
		disable_colour: boolean?,
		disable_emoji: boolean?,
		disable_unicode: boolean?,
		disable_output: {
			after_run: boolean?,
		}?,
	}?,
}

-- Plugin system types
export type Plugin = {
	notify: (event: string, ...any) -> (),
}

export type FrameworkOptions = {
	plugins: { Plugin }?,
}

export type RunOptions = {}

-- Main framework interface returned by configure()
export type TiniestFramework = {
	describe: DescribeFunction,
	test: TestFunction,
	collect_tests: (testSuite: () -> ()) -> { Test },
	run_tests: (tests: { Test }, options: RunOptions) -> RunResult,
}

-- Configured instance with expect function
export type TiniestForLuteFramework = {
	describe: DescribeFunction,
	test: TestFunction,
	expect: ExpectFunction,
	collect_tests: (testSuite: () -> ()) -> { Test },
	run_tests: (tests: { Test }, options: RunOptions) -> RunResult,
	save_snapshots: () -> (),
}

return nil
