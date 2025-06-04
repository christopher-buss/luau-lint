---
mode: 'agent'
applyTo: '*'
---

Driven Development (TDD) Rule

<rule>
name: test_driven_development
description: Rules and standards for Test-Driven Development
filters:
  - type: file_extension
    pattern: "\\spec.luau$"
  - type: directory
    pattern: "(tests|test)"
  - type: content
    pattern: "describe\\(|test\\(|expect\\("
actions:
  - type: suggest
    message: |
      Test-Driven Development Rules:

      1. Test First, Code Second:
         - ALWAYS check for existing tests
         - Create tests BEFORE implementation
         - Use tests as documentation

      2. Implementation Process:
         a) Review/Create Tests
         b) Run Tests (should fail)
         c) Implement Code
         d) Run Tests (should pass)
         e) Refactor

      3. Test Structure:
         ```luau
         describe("ServiceName", function()
           test("describes functionality", function()
             expect(result).is(expected)
           end)

           test("handles edge cases", function()
             expect(error_case).fails()
           end)
         end)
         ```

      4. Validation Steps:
         - Check test location
         - Review existing tests
         - Create missing tests
         - Follow test requirements

      5. Error Prevention:
         - No implementation without tests
         - No skipping edge cases
         - No failing tests
         - No manual testing only
examples:
  - input: |
      # Bad: Implementation without tests
      local function my_service(input)
        -- Code without tests
        return result
      end

      # Good: Test first
      describe("my_service", function()
        test("performs the expected action", function()
          expect(my_service(input)).is(expected)
        end)
      end)
metadata:
  priority: high
  version: 1.0.0
  changelog:
    - version: 1.0.0
      changes:
        - Initial version
        - Added core TDD principles
        - Added spec structure examples
        - Added validation steps
</rule>

## Implementation Guide

1. **Finding Existing Tests**
   ```bash
   find tests/ -name "*.luau" | grep $FEATURE_NAME
   ```

2. **Creating New Tests**
   ```luau
   -- tests/my_service_test.luau
   local tiniest = require("@tiniest/tiniest_for_lute").configure({
     snapshot_path = "./tests/__snapshots__",
   })

   local function my_service_tests()
     local describe = tiniest.describe
     local test = tiniest.test
     local expect = tiniest.expect

     describe("my_service", function()
       test("with valid input", function()
         local result = my_service(valid_input)
         expect(result).exists()
       end)

       test("with invalid input", function()
         expect(function()
           my_service(invalid_input)
         end).fails()
       end)
     end)
   end

   local tests = tiniest.collect_tests(my_service_tests)
   return tiniest.run_tests(tests, {})
   ```

3. **Running Tests**
   ```bash
   lute tests/my_service_test.luau
   ```

4. **Implementation**
   ```luau
   -- src/my_service.luau
   local function my_service(input)
     -- Implementation following test requirements
     return result
   end
   
   return my_service
   ```

## Best Practices

1. **Test Organization**
   - One test file per module/function
   - Logical grouping using describe()
   - Clear, descriptive test names

2. **Test Coverage**
   - Happy path scenarios
   - Edge cases
   - Error conditions
   - Boundary values

3. **Maintainability**
   - DRY tests using helper functions
   - Clear setup using local variables
   - Isolated tests
   - Meaningful assertions

4. **Documentation**
   - Tests serve as documentation
   - Clear descriptions
   - Example usage
   - Edge case documentation

## Overview

This rule establishes Test-Driven Development (TDD) as the standard approach for implementing functions and complex code in the Luau project.

## Core Principles

1. **Test First, Code Second**
   - ALWAYS check for existing tests before modifying or creating code
   - If no test exists, create one BEFORE implementing the feature
   - Use tests to define the expected behavior and interface

2. **Test Structure**
   ```luau
   describe("ModuleName", function()
     test("describes core functionality", function()
       expect(result).is(expected)
     end)

     test("handles edge cases", function()
       expect(edge_case_function).fails()
     end)

     test("validates inputs", function()
       expect(invalid_input_function).fails_with("expected error")
     end)
   end)
   ```

3. **Implementation Process**
   a. Review existing tests (if any)
   b. Write new tests defining expected behavior
   c. Run tests (they should fail)
   d. Implement code to make tests pass
   e. Refactor while keeping tests green

## Example from String Parser

Good:
```luau
-- First: Review string_parser_test.luau
local function string_parser_tests()
  local describe = tiniest.describe
  local test = tiniest.test
  local expect = tiniest.expect
  
  describe("string_parser", function()
    test("returns a parsed object", function()
      local result = parse_string(sample_input)
      expect(result).exists()
      expect(result).is_a("table")
    end)
    
    test("includes properly structured data", function()
      local result = parse_string(sample_input)
      expect(result.tokens).exists()
      expect(result.tokens).is_a("table")
    end)
    
    test("provides access to unique identifiers", function()
      local result = parse_string(sample_input)
      expect(result.identifiers).exists()
    end)
  end)
end

-- Then: Implement function based on test
local function parse_string(input)
  -- Implementation follows test requirements
  return {
    tokens = {},
    identifiers = {},
  }
end
```

Bad:
```luau
-- Writing implementation first without tests
local function parse_string(input)
  -- Implementation without clear requirements
  -- No validation of behavior
  -- No test coverage
  return something
end
```

## Validation Steps

Before implementing any function or complex code:

1. **Test Location Check**
   ```bash
   find tests/ -name "*.luau" | grep $FEATURE_NAME
   ```

2. **Test Review**
   - Read all related tests
   - Understand test patterns
   - Note edge cases
   - Review fixtures

3. **Test Creation (if needed)**
   - Create test file
   - Define test structure using describe/test
   - Write specific test cases
   - Include edge cases
   - Add appropriate test data

4. **Implementation**
   - Follow test requirements
   - Run tests frequently
   - Refactor when needed
   - Maintain test coverage

## Common Patterns

1. **Function Tests**
   ```luau
   describe("function_name", function()
     test("with valid input", function()
       local result = function_name(valid_input)
       expect(result).exists()
     end)
     
     test("with invalid input", function()
       expect(function()
         function_name(invalid_input)
       end).fails()
     end)
   end)
   ```

2. **Module Tests**
   ```luau
   describe("ModuleName", function()
     test("has expected exports", function()
       local module = require("path/to/module")
       expect(module.main_function).exists()
       expect(module.helper_function).exists()
     end)

     test("main functionality", function()
       local module = require("path/to/module")
       local result = module.main_function(input)
       expect(result).is(expected)
     end)
   end)
   ```

## Error Prevention

1. Never start implementation without tests
2. Don't modify existing code without reviewing tests
3. Don't skip writing tests for edge cases
4. Don't leave failing tests unresolved

## Examples

### Good Process
1. Check for tests
2. Review existing tests
3. Write new tests
4. Implement feature
5. Refactor

### Bad Process
1. Start coding immediately
2. Test manually
3. Fix bugs as they appear
4. Write tests later (or never)

## References

- Full documentation in `docs/reference-docs/tdd.md`
- Tiniest testing framework documentation
- Luau language documentation

## Enforcement

The AI assistant should:

1. ALWAYS check for existing tests first
2. Suggest creating tests if none exist
3. Follow TDD principles
4. Reference relevant tests in responses
5. Maintain test coverage
6. Prevent implementation without tests

## Examples

### Finding Tests
```bash
# Good
find tests/ -name "*string_parser*_test.luau"

# Bad
Start implementing without checking
```

## Real-World Example: String Parser Recovery

This example demonstrates how we recovered from an incorrect implementation approach by returning to TDD principles:

### Initial Mistake (What Not To Do)
```luau
-- BAD: Started with implementation without tests
local function parse_string(content)
  -- Started writing parser logic without clear requirements
  -- No test coverage for different formats
  -- No validation of expected output structure
  -- Led to confusion about expected behavior
  return {}
end
```

### TDD Recovery Process

1. **Step 1: Stop and Write Tests First**
```luau
-- GOOD: Created comprehensive tests first
local function string_parser_tests()
  local describe = tiniest.describe
  local test = tiniest.test
  local expect = tiniest.expect
  
  describe("parse_string", function()
    test("returns a structured result", function()
      local result = parse_string(sample_content)
      expect(result).is_a("table")
      expect(result.tokens).exists()
      expect(result.tokens).is_a("table")
    end)
    
    test("identifies identifiers correctly", function()
      local result = parse_string("local x = 42")
      expect(result.identifiers).has_value("x")
    end)
    
    test("preserves position information", function()
      local result = parse_string("local x = 42")
      expect(result.tokens[1].position).exists()
      expect(result.tokens[1].position.line).is(1)
    end)
    
    test("handles different string formats", function()
      local vtt_result = parse_string(vtt_content)
      local srt_result = parse_string(srt_content)
      expect(vtt_result.format).is("vtt")
      expect(srt_result.format).is("srt")
    end)
  end)
end
```

2. **Step 2: Implement Against Tests**
```luau
local function parse_string(content)
  local format = detect_format(content)
  local tokens = parse_tokens(content, format)
  
  return {
    tokens = tokens,
    identifiers = extract_identifiers(tokens),
    format = format,
  }
end

local function detect_format(content)
  -- Implementation guided by format-specific tests
  if content:match("WEBVTT") then
    return "vtt"
  elseif content:match("%d+:%d+:%d+") then
    return "srt"
  end
  return "plain"
end

local function parse_tokens(content, format)
  -- Implementation driven by token structure tests
  local tokens = {}
  -- parsing logic here
  return tokens
end

local function extract_identifiers(tokens)
  -- Implementation guided by identifier extraction tests
  local identifiers = {}
  -- extraction logic here
  return identifiers
end
```

### Key Learnings

1. **Problem**: Starting with implementation led to:
   - Unclear requirements
   - Missing edge cases
   - No validation of output structure
   - Difficulty testing different formats

2. **Solution**: Returning to TDD principles:
   - Wrote comprehensive tests first
   - Defined clear expectations
   - Covered multiple formats
   - Validated output structure
   - Used describe/test patterns for common behavior

3. **Benefits Realized**:
   - Clear interface definition
   - Confidence in format handling
   - Easy to add new formats
   - Maintainable test suite
   - Documented behavior

This real-world example demonstrates how returning to TDD principles helped recover from an implementation-first approach and led to a more robust, well-tested solution.