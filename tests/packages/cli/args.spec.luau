--!strict
local Args = require("../../../packages/cli/src/args") -- Relative path to the module being tested
local TiniestFramework = require("../../../packages/test-utils/src/tiniest/tiniest_for_lute")

-- Configure Tiniest for Lute environment
local Tiniest = TiniestFramework.configure({
	-- Default options; snapshot_path can be configured if needed for other tests
	-- snapshot_path = "./__snapshots__",
	-- save_snapshots = false,
})

local describe, it, expect = Tiniest.describe, Tiniest.test, Tiniest.expect -- Use Tiniest.test for 'it'

local function defineTests()
	describe("CLI Argument Parser (Args.parse)", function()
		it("should parse --help flag", function()
			local parsed = Args.parse({ "--help" })
			expect(parsed.help).is(true)
			expect(parsed.version).is(false)
			expect(#parsed.files).is(0)
			expect(#parsed.errors).is(0)
		end)

		it("should parse --version flag", function()
			local parsed = Args.parse({ "--version" })
			expect(parsed.version).is(true)
			expect(parsed.help).is(false)
			expect(#parsed.files).is(0)
			expect(#parsed.errors).is(0)
		end)

		it("should parse --config flag with a path", function()
			local parsed = Args.parse({ "--config", "./luau-lint.toml" })
			expect(parsed.configPath).is("./luau-lint.toml")
			expect(#parsed.errors).is(0)
		end)

		it("should report an error if --config is missing its path", function()
			local parsed = Args.parse({ "--config" })
			expect(parsed.configPath).is(nil)
			expect(#parsed.errors > 0).is_true()
			expect(string.match(parsed.errors[1], "--config flag requires a path argument") ~= nil).is_true()
		end)

		it("should parse --fix flag", function()
			local parsed = Args.parse({ "--fix" })
			expect(parsed.fix).is(true)
			expect(#parsed.errors).is(0)
		end)

		it("should parse file paths", function()
			local parsed = Args.parse({ "./src/file1.luau", "another/file.luau" })
			expect(#parsed.files).is(2)
			expect(parsed.files[1]).is("./src/file1.luau")
			expect(parsed.files[2]).is("another/file.luau")
			expect(#parsed.errors).is(0)
		end)

		it("should parse a mix of flags and file paths", function()
			local parsed = Args.parse({ "--fix", "./src/", "--config", "custom.toml", "test.luau" })
			expect(parsed.fix).is(true)
			expect(parsed.configPath).is("custom.toml")
			expect(#parsed.files).is(2)
			expect(parsed.files[1]).is("./src/")
			expect(parsed.files[2]).is("test.luau")
			expect(#parsed.errors).is(0)
		end)

		it("should handle unknown flags", function()
			local parsed = Args.parse({ "--unknown-flag", "--another", "file.luau" })
			expect(#parsed.unknownFlags).is(2)
			expect(parsed.unknownFlags[1]).is("--unknown-flag")
			expect(parsed.unknownFlags[2]).is("--another")
			expect(#parsed.files).is(1)
			expect(parsed.files[1]).is("file.luau")
			expect(#parsed.errors).is(0)
		end)

		it("should handle short unknown flags", function()
			local parsed = Args.parse({ "-u", "-v", "file.luau" })
			expect(#parsed.unknownFlags).is(2)
			expect(parsed.unknownFlags[1]).is("-u")
			expect(parsed.unknownFlags[2]).is("-v")
			expect(#parsed.files).is(1)
		end)

		it("should handle empty arguments", function()
			local parsed = Args.parse({})
			expect(parsed.help).is(false)
			expect(parsed.version).is(false)
			expect(parsed.fix).is(false)
			expect(parsed.configPath).is(nil)
			expect(#parsed.files).is(0)
			expect(#parsed.unknownFlags).is(0)
			expect(#parsed.errors).is(0)
		end)

		it(
			"should correctly identify files even if they look like flags after a known flag that takes an argument",
			function()
				local parsed = Args.parse({ "--config", "--fix" }) -- Here --fix is the path for --config
				expect(parsed.configPath).is("--fix")
				expect(parsed.fix).is(false) -- --fix was consumed as path
				expect(#parsed.files).is(0)
				expect(#parsed.errors).is(0)
			end
		)

		it("should parse multiple files after flags", function()
			local parsed = Args.parse({
				"--fix",
				"file1.luau",
				"file2.luau",
				"--config",
				"my.toml",
				"file3.luau",
			})
			expect(parsed.fix).is(true)
			expect(parsed.configPath).is("my.toml")
			expect(#parsed.files).is(3)
			expect(parsed.files[1]).is("file1.luau")
			expect(parsed.files[2]).is("file2.luau")
			expect(parsed.files[3]).is("file3.luau")
		end)
	end)
end

local collectedTests = Tiniest.collect_tests(defineTests)
Tiniest.run_tests(collectedTests, {}) -- Pass collected tests and empty options table
