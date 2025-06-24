-- src/cli/args.luau
-- Placeholder for command-line argument parsing logic
-- Will be implemented to support --help, --version, --config, --fix flags
-- and file/directory path handling.

-- TODO: Replace with actual Lute process API usage for argument access

export type ParsedArgs = {
	help: boolean,
	version: boolean,
	configPath: string?,
	fix: boolean,
	files: { string },
	unknownFlags: { string }, -- To store any unrecognized flags
	errors: { string }, -- To store parsing errors
}

local function parse(args: { string }): ParsedArgs
	local parsedArgs: ParsedArgs = {
		help = false,
		version = false,
		configPath = nil,
		fix = false,
		files = {},
		unknownFlags = {},
		errors = {},
	}

	local i = 1
	while i <= #args do
		local arg = args[i]
		local isKnownFlag = false
		if arg == "--help" then
			parsedArgs.help = true
			isKnownFlag = true
		elseif arg == "--version" then
			parsedArgs.version = true
			isKnownFlag = true
		elseif arg == "--config" then
			i += 1
			if i <= #args then
				parsedArgs.configPath = args[i]
			else
				table.insert(parsedArgs.errors, "--config flag requires a path argument.")
			end
			isKnownFlag = true
		elseif arg == "--fix" then
			parsedArgs.fix = true
			isKnownFlag = true
		end

		if not isKnownFlag then
			if string.sub(arg, 1, 1) == "-" then -- Argument starts with '-'
				table.insert(parsedArgs.unknownFlags, arg)
			else
				table.insert(parsedArgs.files, arg)
			end
		end
		i += 1
	end

	if #parsedArgs.files == 0 and not parsedArgs.help and not parsedArgs.version then
		-- If no files are provided and it's not help/version, it might be an error
		-- or we might default to current directory later in file-processor.
		-- For now, let main.luau decide.
	end

	return parsedArgs
end

return {
	parse = parse,
}
