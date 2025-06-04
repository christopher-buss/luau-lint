-- Before and After: Luau Generalized Iteration Examples

-- ❌ BEFORE: Legacy approach with ipairs/pairs
--[[
local items = {"apple", "banana", "cherry"}

-- Old way - unnecessary ipairs wrapper
for i, item in ipairs(items) do
    print(i, item)
end

-- Old way - unnecessary pairs wrapper  
local settings = {theme = "dark", volume = 50}
for key, value in pairs(settings) do
    print(key .. ":", value)
end
--]]

-- ✅ AFTER: Modern Luau generalized iteration

local items = { "apple", "banana", "cherry" }

-- Modern way - direct iteration (Luau 5.1+)
for i, item in items do
	print(i, item)
end

-- When you only need values
for _, item in items do
	print("Processing:", item)
end

-- When you need specific numeric control
for i = 1, #items do
	print("Item at position", i, "is", items[i])
end

-- Dictionary/map iteration
local settings = { theme = "dark", volume = 50 }
for key, value in settings do
	print(key .. ":", value)
end

-- Mixed tables work seamlessly
local mixedData = { 100, 200, name = "test", active = true }
for k, v in mixedData do
	print(k, "->", v)
end

-- Nested structures
local gameData = {
	players = {
		{ name = "Alice", score = 150 },
		{ name = "Bob", score = 120 },
	},
	settings = {
		difficulty = "hard",
		sound = true,
	},
}

-- Iterate players
for i, player in gameData.players do
	print("Player", i .. ":", player.name, "Score:", player.score)
end

-- Iterate settings
for setting, value in gameData.settings do
	print("Game setting", setting .. ":", value)
end

--[[
BENEFITS OF MODERN LUAU ITERATION:
1. Cleaner syntax - no wrapper functions
2. Better performance - direct iteration
3. Unified approach - same syntax for arrays and dictionaries
4. Less typing - shorter code
5. Better type inference in TypeScript/Luau
--]]
