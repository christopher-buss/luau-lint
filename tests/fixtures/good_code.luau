-- Modern Luau code demonstrating efficient iteration patterns
local array = { 1, 2, 3, 4, 5 }

-- When you need numeric indices specifically, use numeric for loop
for i = 1, #array do
	print("Index:", i, "Value:", array[i])
end

-- Modern Luau: Direct iteration over key-value pairs (replaces ipairs)
for i, value in array do
	print("Index:", i, "Value:", value)
end

-- When you only need values (most common case)
for _, value in array do
	print("Processing:", value)
end

-- Dictionary iteration (replaces pairs)
local settings = {
	volume = 80,
	brightness = 100,
	theme = "dark",
}

for key, value in settings do
	print(key .. " =", value)
end

-- Complex iteration examples
local students = {
	{ name = "Alice", grade = 95 },
	{ name = "Bob", grade = 87 },
	{ name = "Charlie", grade = 92 },
}

-- Iterate over student records
for index, student in students do
	print("Student #" .. index .. ":", student.name, "Grade:", student.grade)
end

-- Iterate over student properties
for _, student in students do
	for property, value in student do
		print("  " .. property .. ":", value)
	end
end
