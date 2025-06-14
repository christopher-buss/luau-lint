-- Modern Luau code using generalized iteration
local array = { 1, 2, 3, 4, 5 }

-- Modern Luau: Direct iteration over values (no ipairs needed)
for i, value in ipairs(array) do
	print(value)
end

-- -- Modern Luau: Still direct iteration (no ipairs needed)
for index, item in ipairs(array) do
	print("Processing:", item)
end

-- -- Modern Luau: Direct iteration with unused index
for _, element in pairs(array) do
	print(element)
end

-- -- Additional examples of modern Luau iteration:

-- -- Dictionary/map iteration (no pairs needed)
local userData = { name = "Alice", age = 30, city = "Tokyo" }
for key, value in pairs(userData) do
	print(key .. ":", value)
end

-- -- Mixed table iteration (Luau handles both array and hash parts)
local mixedTable = { 10, 20, x = 100, y = 200 }
for k, v in pairs(mixedTable) do
	print(k, v)
end

-- -- Nested table iteration
local matrix = { { 1, 2 }, { 3, 4 }, { 5, 6 } }
for i, row in ipairs(matrix) do
	for j, value in ipairs(row) do
		print("matrix[" .. i .. "][" .. j .. "] =", value)
	end
end
