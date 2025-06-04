-- Test file with modern Luau iteration that should pass linting
local data = { 10, 20, 30, 40, 50 }

-- Modern Luau: No ipairs needed
for i, value in data do
	print("Item", i, ":", value)
end

-- Modern Luau: Dictionary iteration without pairs
local config = { debug = true, timeout = 5000 }
for key, val in config do
	print(key, "=", val)
end

-- Legacy code that would be flagged (commented out)
-- for i, v in ipairs(data) do
--     print(v)  -- This would trigger our linter
-- end
