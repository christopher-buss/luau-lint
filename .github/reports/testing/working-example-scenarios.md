# Working Example Integration Test Scenarios

## Overview

This document provides concrete, working examples of integration test scenarios that demonstrate the current capabilities of the Luau Linter plugin system. These examples follow TDD principles and can be executed to validate system integration.

## Scenario 1: Complete File Processing Workflow

### Purpose
Demonstrates the end-to-end file processing pipeline from AST parsing through issue reporting.

### Test Implementation

```luau
-- Working Example: Complete File Processing Integration Test
local function completeWorkflowExample(
    describe: DescribeFunction,
    test: TestFunction,
    expect: ExpectFunction
): ()
    describe("Working Example: Complete File Processing", function(): ()
        test("processes bad_code.luau through complete pipeline", function(): ()
            -- Step 1: Initialize plugin system
            local registry = Registry.createRegistry()
            
            -- Register actual working rules
            local noUnusedVarsRule = {
                id = "no-unused-variables",
                title = "No Unused Variables",
                description = "Detects variables that are declared but never used",
                category = "correctness",
                severity = "warning",
                create = function(context)
                    local declared = {}
                    local used = {}
                    
                    return {
                        ["Local"] = function(node)
                            -- Track variable declarations
                            for _, binding in node.bindings do
                                if binding.name then
                                    declared[binding.name] = {
                                        name = binding.name,
                                        node = binding,
                                        location = binding.location,
                                    }
                                end
                            end
                        end,
                        
                        ["Identifier"] = function(node)
                            -- Mark variables as used
                            if declared[node.name] then
                                used[node.name] = true
                            end
                        end,
                        
                        ["Program:exit"] = function(node)
                            -- Report unused variables at program end
                            for name, info in declared do
                                if not used[name] then
                                    context.report({
                                        message = `Variable '{name}' is declared but never used`,
                                        node = info.node,
                                        loc = info.location,
                                    })
                                end
                            end
                        end,
                    }
                end,
            }
            
            Registry.registerRule(registry, noUnusedVarsRule)
            
            -- Step 2: Create engine
            local engine = Engine.createRuleEngine(registry)
            expect(engine).exists()
            expect(type(engine.lintFile)).is("function")
            
            -- Step 3: Load and parse test file
            local sourceText = fs.readfile("./tests/fixtures/bad_code.luau")
            expect(sourceText).exists()
            expect(#sourceText).is_greater_than(0)
            
            local parseResult = Luau.parse(sourceText, {})
            expect(parseResult.success).is(true)
            expect(parseResult.root).exists()
            
            -- Step 4: Execute linting
            local lintResult = engine.lintFile(
                parseResult.root,
                sourceText,
                "bad_code.luau"
            )
            
            -- Step 5: Validate results structure
            expect(lintResult).exists()
            expect(type(lintResult.issues)).is("table")
            expect(type(lintResult.errors)).is("table")
            expect(lintResult.lintStats).exists()
            
            -- Step 6: Validate specific results
            -- bad_code.luau should have some unused variables
            expect(#lintResult.issues).is_greater_than(0)
            
            -- Each issue should have proper structure
            for _, issue in lintResult.issues do
                expect(issue.ruleId).is("no-unused-variables")
                expect(issue.message).contains("never used")
                expect(issue.node).exists()
            end
            
            -- No errors should occur during processing
            expect(#lintResult.errors).is(0)
            
            -- Statistics should be populated
            expect(lintResult.lintStats.nodesVisited).is_greater_than(0)
            expect(lintResult.lintStats.rulesExecuted).is_greater_than(0)
            expect(lintResult.lintStats.issuesFound).is(#lintResult.issues)
            
            print(`✓ Successfully processed file with {lintResult.lintStats.nodesVisited} nodes`)
            print(`✓ Found {#lintResult.issues} issues using {lintResult.lintStats.rulesExecuted} rules`)
        end)
    end)
end
```

### Expected Output
- File processes without errors
- Unused variables detected and reported
- Statistics collected and accurate
- Issue structure is complete and valid

## Scenario 2: Multi-Rule Coordination

### Purpose
Demonstrates how multiple rules work together on the same file without interfering with each other.

### Test Implementation

```luau
-- Working Example: Multi-Rule Coordination
local function multiRuleCoordinationExample(
    describe: DescribeFunction,
    test: TestFunction,
    expect: ExpectFunction
): ()
    describe("Working Example: Multi-Rule Coordination", function(): ()
        test("coordinates multiple rules on modern_code.luau", function(): ()
            local registry = Registry.createRegistry()
            
            -- Rule 1: Detect unused variables
            local unusedVarRule = {
                id = "no-unused-vars",
                title = "No Unused Variables",
                description = "Detects unused variables",
                category = "correctness", 
                severity = "warning",
                create = function(context)
                    -- Implementation similar to previous example
                    return {
                        ["Local"] = function(node)
                            -- Track declarations
                        end,
                        ["Identifier"] = function(node)
                            -- Track usage
                        end,
                        ["Program:exit"] = function(node)
                            -- Report unused
                        end,
                    }
                end,
            }
            
            -- Rule 2: Suggest modern iteration patterns
            local modernIterationRule = {
                id = "modern-iteration",
                title = "Modern Iteration",
                description = "Suggests modern Luau iteration over ipairs/pairs",
                category = "style",
                severity = "suggestion",
                create = function(context)
                    return {
                        ["Call"] = function(node)
                            if node.func and node.func.name then
                                local funcName = node.func.name
                                if funcName == "ipairs" or funcName == "pairs" then
                                    context.report({
                                        message = `Consider using modern Luau iteration instead of {funcName}()`,
                                        node = node,
                                        fix = {
                                            type = "replace",
                                            location = node.location,
                                            text = "-- Use: for key, value in table do",
                                        },
                                    })
                                end
                            end
                        end,
                    }
                end,
            }
            
            -- Rule 3: Consistent naming conventions
            local namingRule = {
                id = "consistent-naming",
                title = "Consistent Naming",
                description = "Enforces consistent naming conventions",
                category = "style",
                severity = "info",
                create = function(context)
                    return {
                        ["Local"] = function(node)
                            for _, binding in node.bindings do
                                if binding.name then
                                    local name = binding.name
                                    -- Check for camelCase vs snake_case consistency
                                    if string.match(name, "[A-Z]") and string.match(name, "_") then
                                        context.report({
                                            message = `Variable '{name}' mixes camelCase and snake_case`,
                                            node = binding,
                                        })
                                    end
                                end
                            end
                        end,
                    }
                end,
            }
            
            -- Register all rules
            Registry.registerRule(registry, unusedVarRule)
            Registry.registerRule(registry, modernIterationRule)
            Registry.registerRule(registry, namingRule)
            
            expect(#registry.getAllRules()).is(3)
            
            -- Create engine and process file
            local engine = Engine.createRuleEngine(registry)
            
            local sourceText = fs.readfile("./tests/fixtures/modern_code.luau")
            local parseResult = Luau.parse(sourceText, {})
            expect(parseResult.success).is(true)
            
            local lintResult = engine.lintFile(
                parseResult.root,
                sourceText,
                "modern_code.luau"
            )
            
            -- Validate multi-rule coordination
            expect(lintResult).exists()
            expect(#lintResult.errors).is(0)  -- No rule execution errors
            
            -- Should have issues from different rules
            local ruleIdsSeen = {}
            for _, issue in lintResult.issues do
                ruleIdsSeen[issue.ruleId] = true
                
                -- Each issue should be properly attributed
                expect(issue.ruleId).is_one_of({
                    "no-unused-vars",
                    "modern-iteration", 
                    "consistent-naming"
                })
                
                expect(issue.message).is_a("string")
                expect(#issue.message).is_greater_than(0)
            end
            
            -- Verify rules ran independently
            expect(lintResult.lintStats.rulesExecuted).is(3)
            
            print(`✓ Coordinated {lintResult.lintStats.rulesExecuted} rules successfully`)
            print(`✓ Rules found issues: {table.concat(Object.keys(ruleIdsSeen), ", ")}`)
        end)
    end)
end
```

### Expected Output
- All three rules execute without interference
- Issues are properly attributed to correct rules
- No rule execution errors occur
- Statistics accurately reflect multi-rule execution

## Scenario 3: Error Handling and Recovery

### Purpose
Demonstrates robust error handling when individual rules fail while maintaining overall system stability.

### Test Implementation

```luau
-- Working Example: Error Handling and Recovery
local function errorHandlingExample(
    describe: DescribeFunction,
    test: TestFunction,
    expect: ExpectFunction
): ()
    describe("Working Example: Error Handling and Recovery", function(): ()
        test("handles rule errors while continuing execution", function(): ()
            local registry = Registry.createRegistry()
            
            -- Working rule
            local goodRule = {
                id = "good-rule",
                title = "Good Rule",
                description = "A rule that works correctly",
                category = "test",
                severity = "info",
                create = function(context)
                    return {
                        ["Local"] = function(node)
                            context.report({
                                message = "Good rule executed successfully", 
                                node = node,
                            })
                        end,
                    }
                end,
            }
            
            -- Faulty rule that throws errors
            local faultyRule = {
                id = "faulty-rule",
                title = "Faulty Rule", 
                description = "A rule that throws errors",
                category = "test",
                severity = "error",
                create = function(context)
                    return {
                        ["Local"] = function(node)
                            -- Intentionally throw an error
                            error("Intentional test error from faulty rule")
                        end,
                    }
                end,
            }
            
            -- Another working rule
            local anotherGoodRule = {
                id = "another-good-rule",
                title = "Another Good Rule",
                description = "Another rule that works correctly",
                category = "test", 
                severity = "warning",
                create = function(context)
                    return {
                        ["Identifier"] = function(node)
                            if node.name == "test" then
                                context.report({
                                    message = "Found test identifier",
                                    node = node,
                                })
                            end
                        end,
                    }
                end,
            }
            
            Registry.registerRule(registry, goodRule)
            Registry.registerRule(registry, faultyRule)
            Registry.registerRule(registry, anotherGoodRule)
            
            local engine = Engine.createRuleEngine(registry)
            
            -- Test code that will trigger all rules
            local sourceText = "local test = 42\nlocal other = test"
            local parseResult = Luau.parse(sourceText, {})
            expect(parseResult.success).is(true)
            
            local lintResult = engine.lintFile(
                parseResult.root,
                sourceText,
                "error_test.luau"
            )
            
            -- Validate error handling
            expect(lintResult).exists()
            
            -- Should have captured the error from faulty rule
            expect(#lintResult.errors).is_at_least(1)
            
            local faultyRuleError = nil
            for _, error in lintResult.errors do
                if error.ruleId == "faulty-rule" then
                    faultyRuleError = error
                    break
                end
            end
            
            expect(faultyRuleError).exists()
            expect(faultyRuleError.type).is("RuleError")
            expect(faultyRuleError.message).contains("Intentional test error")
            
            -- Should still have issues from working rules
            expect(#lintResult.issues).is_at_least(1)
            
            local goodRuleIssues = 0
            local anotherGoodRuleIssues = 0
            
            for _, issue in lintResult.issues do
                if issue.ruleId == "good-rule" then
                    goodRuleIssues = goodRuleIssues + 1
                elseif issue.ruleId == "another-good-rule" then
                    anotherGoodRuleIssues = anotherGoodRuleIssues + 1
                end
            end
            
            -- Working rules should have executed successfully
            expect(goodRuleIssues).is_greater_than(0)
            expect(anotherGoodRuleIssues).is_greater_than(0)
            
            -- System should have continued processing despite error
            expect(lintResult.lintStats.rulesExecuted).is(3)
            expect(lintResult.lintStats.nodesVisited).is_greater_than(0)
            
            print(`✓ Handled {#lintResult.errors} rule errors gracefully`)
            print(`✓ Working rules produced {#lintResult.issues} issues`)
            print(`✓ System continued processing {lintResult.lintStats.nodesVisited} nodes`)
        end)
    end)
end
```

### Expected Output
- Faulty rule error is captured and reported
- Working rules continue to execute normally  
- System maintains stability despite individual rule failures
- Statistics accurately reflect partial execution

## Scenario 4: Configuration Integration

### Purpose
Demonstrates how configuration affects rule behavior across the integrated system.

### Test Implementation

```luau
-- Working Example: Configuration Integration
local function configurationIntegrationExample(
    describe: DescribeFunction,
    test: TestFunction,
    expect: ExpectFunction
): ()
    describe("Working Example: Configuration Integration", function(): ()
        test("applies configuration to affect rule behavior", function(): ()
            -- Step 1: Create configurable rule
            local configurableRule = {
                id = "configurable-rule",
                title = "Configurable Rule",
                description = "A rule that changes behavior based on configuration",
                category = "style",
                severity = "warning",
                create = function(context)
                    -- Access rule configuration
                    local config = context.getRuleConfig("configurable-rule") or {}
                    local maxLineLength = config.maxLineLength or 80
                    local checkComments = config.checkComments ~= false
                    
                    return {
                        ["Program"] = function(node)
                            -- Simulate line length checking
                            local lines = string.split(context.sourceText, "\n")
                            
                            for lineNum, line in ipairs(lines) do
                                if #line > maxLineLength then
                                    context.report({
                                        message = `Line {lineNum} exceeds {maxLineLength} characters ({#line})`,
                                        loc = {
                                            start = { line = lineNum, column = maxLineLength + 1 },
                                            ["end"] = { line = lineNum, column = #line },
                                        },
                                    })
                                end
                                
                                if checkComments and string.match(line, "^%s*%-%-") then
                                    if not string.match(line, "^%s*%-%-[A-Z]") then
                                        context.report({
                                            message = `Comment on line {lineNum} should start with capital letter`,
                                            loc = {
                                                start = { line = lineNum, column = 1 },
                                                ["end"] = { line = lineNum, column = #line },
                                            },
                                        })
                                    end
                                end
                            end
                        end,
                    }
                end,
            }
            
            -- Step 2: Test with default configuration
            local registry1 = Registry.createRegistry()
            Registry.registerRule(registry1, configurableRule)
            
            local engine1 = Engine.createRuleEngine(registry1)
            
            local testCode = [[
                -- this is a comment that should trigger the rule
                local veryLongVariableNameThatWillDefinitelyExceedTheDefaultLineLengthLimitOf80Characters = 42
                -- This is a properly formatted comment
                local short = 1
            ]]
            
            local parseResult = Luau.parse(testCode, {})
            expect(parseResult.success).is(true)
            
            local result1 = engine1.lintFile(parseResult.root, testCode, "test.luau")
            
            -- Should find issues with default config (80 char limit, check comments)
            expect(#result1.issues).is_at_least(2)  -- Long line + lowercase comment
            
            -- Step 3: Test with custom configuration
            local customConfig = {
                rules = {
                    ["configurable-rule"] = {
                        maxLineLength = 120,  -- More lenient line length
                        checkComments = false,  -- Disable comment checking
                    },
                },
            }
            
            -- Apply configuration to context (this would normally be done by config loader)
            local registry2 = Registry.createRegistry()
            Registry.registerRule(registry2, configurableRule)
            
            -- Create engine with configuration
            local engine2 = Engine.createRuleEngine(registry2, { config = customConfig })
            
            local result2 = engine2.lintFile(parseResult.root, testCode, "test.luau")
            
            -- Should find fewer issues with lenient config
            expect(#result2.issues).is_less_than(#result1.issues)
            
            -- Verify configuration was applied
            local hasLongLineIssue = false
            local hasCommentIssue = false
            
            for _, issue in result2.issues do
                if string.match(issue.message, "exceeds.*characters") then
                    hasLongLineIssue = true
                elseif string.match(issue.message, "Comment.*capital letter") then
                    hasCommentIssue = true
                end
            end
            
            -- With 120 char limit, long line should not be flagged
            expect(hasLongLineIssue).is(false)
            -- With checkComments disabled, comment issue should not be flagged  
            expect(hasCommentIssue).is(false)
            
            print(`✓ Default config found {#result1.issues} issues`)
            print(`✓ Custom config found {#result2.issues} issues`)
            print("✓ Configuration successfully affected rule behavior")
        end)
    end)
end
```

### Expected Output
- Default configuration produces more issues
- Custom configuration produces fewer issues
- Rule behavior changes based on configuration values
- Configuration is properly applied and accessible to rules

## Scenario 5: Performance Integration

### Purpose
Demonstrates system performance under realistic workloads and validates scalability.

### Test Implementation

```luau
-- Working Example: Performance Integration  
local function performanceIntegrationExample(
    describe: DescribeFunction,
    test: TestFunction,
    expect: ExpectFunction
): ()
    describe("Working Example: Performance Integration", function(): ()
        test("processes large files efficiently", function(): ()
            -- Step 1: Create performance-focused rules
            local simpleRule = {
                id = "simple-rule",
                title = "Simple Rule",
                description = "A lightweight rule for performance testing",
                category = "performance",
                severity = "info",
                create = function(context)
                    local nodeCount = 0
                    return {
                        ["Local"] = function(node)
                            nodeCount = nodeCount + 1
                            if nodeCount % 10 == 0 then
                                context.report({
                                    message = `Processed {nodeCount} local declarations`,
                                    node = node,
                                })
                            end
                        end,
                    }
                end,
            }
            
            local complexRule = {
                id = "complex-rule", 
                title = "Complex Rule",
                description = "A more complex rule for performance testing",
                category = "performance",
                severity = "warning",
                create = function(context)
                    local identifiers = {}
                    return {
                        ["Identifier"] = function(node)
                            identifiers[node.name] = (identifiers[node.name] or 0) + 1
                        end,
                        ["Program:exit"] = function(node)
                            for name, count in identifiers do
                                if count > 5 then
                                    context.report({
                                        message = `Identifier '{name}' used {count} times`,
                                        node = node,
                                    })
                                end
                            end
                        end,
                    }
                end,
            }
            
            -- Step 2: Generate large test file
            local largeCode = "-- Performance test file\n"
            for i = 1, 200 do
                largeCode = largeCode .. `local variable{i} = {i}\n`
                largeCode = largeCode .. `print(variable{i})\n`
                if i % 10 == 0 then
                    largeCode = largeCode .. `-- Checkpoint at variable {i}\n`
                end
            end
            
            -- Add some repeated identifier usage
            for i = 1, 50 do
                largeCode = largeCode .. `local repeated = variable{i % 10}\n`
            end
            
            expect(#largeCode).is_greater_than(5000)  -- Ensure substantial size
            
            -- Step 3: Setup registry and engine
            local registry = Registry.createRegistry()
            Registry.registerRule(registry, simpleRule)
            Registry.registerRule(registry, complexRule)
            
            local engine = Engine.createRuleEngine(registry)
            
            -- Step 4: Parse large file
            local parseStart = os.clock()
            local parseResult = Luau.parse(largeCode, {})
            local parseEnd = os.clock()
            
            expect(parseResult.success).is(true)
            expect(parseEnd - parseStart).is_less_than(0.5)  -- Parse should be fast
            
            -- Step 5: Execute linting with timing
            local lintStart = os.clock()
            local lintResult = engine.lintFile(
                parseResult.root,
                largeCode,
                "large_performance_test.luau"
            )
            local lintEnd = os.clock()
            
            local lintTime = lintEnd - lintStart
            
            -- Step 6: Validate performance results
            expect(lintResult).exists()
            expect(#lintResult.errors).is(0)  -- No errors during processing
            expect(lintTime).is_less_than(2.0)  -- Should complete in under 2 seconds
            
            -- Validate processing statistics
            expect(lintResult.lintStats.nodesVisited).is_greater_than(400)  -- Many nodes processed
            expect(lintResult.lintStats.rulesExecuted).is(2)
            expect(lintResult.lintStats.issuesFound).is(#lintResult.issues)
            
            -- Should find issues from both rules
            local simpleRuleIssues = 0
            local complexRuleIssues = 0
            
            for _, issue in lintResult.issues do
                if issue.ruleId == "simple-rule" then
                    simpleRuleIssues = simpleRuleIssues + 1
                elseif issue.ruleId == "complex-rule" then
                    complexRuleIssues = complexRuleIssues + 1
                end
            end
            
            expect(simpleRuleIssues).is_greater_than(0)
            expect(complexRuleIssues).is_greater_than(0)
            
            -- Memory usage should be reasonable (basic check)
            expect(collectgarbage("count")).is_less_than(10000)  -- Less than 10MB
            
            print(`✓ Parsed {#string.split(largeCode, "\n")} lines in {parseEnd - parseStart:.3f}s`)
            print(`✓ Linted {lintResult.lintStats.nodesVisited} nodes in {lintTime:.3f}s`)
            print(`✓ Found {#lintResult.issues} issues with {lintResult.lintStats.rulesExecuted} rules`)
            print(`✓ Memory usage: {collectgarbage("count"):.1f}KB`)
        end)
        
        test("scales with multiple rules", function(): ()
            -- Test with many rules to verify scalability
            local registry = Registry.createRegistry()
            
            -- Register multiple similar rules
            for i = 1, 20 do
                local rule = {
                    id = `perf-rule-{i}`,
                    title = `Performance Rule {i}`,
                    description = `Performance test rule number {i}`,
                    category = "performance",
                    severity = "info",
                    create = function(context)
                        return {
                            ["Local"] = function(node)
                                if node.bindings and #node.bindings > 0 then
                                    context.report({
                                        message = `Rule {i}: Found local declaration`,
                                        node = node,
                                    })
                                end
                            end,
                        }
                    end,
                }
                Registry.registerRule(registry, rule)
            end
            
            local engine = Engine.createRuleEngine(registry)
            
            local testCode = ""
            for i = 1, 50 do
                testCode = testCode .. `local var{i} = {i}\n`
            end
            
            local parseResult = Luau.parse(testCode, {})
            expect(parseResult.success).is(true)
            
            local startTime = os.clock()
            local lintResult = engine.lintFile(parseResult.root, testCode, "multi_rule_test.luau")
            local endTime = os.clock()
            
            expect(endTime - startTime).is_less_than(1.0)  -- Should scale reasonably
            expect(#lintResult.errors).is(0)
            expect(lintResult.lintStats.rulesExecuted).is(20)
            
            -- Should have many issues (20 rules × ~50 locals)
            expect(#lintResult.issues).is_at_least(500)
            
            print(`✓ Executed {lintResult.lintStats.rulesExecuted} rules in {endTime - startTime:.3f}s`)
            print(`✓ Generated {#lintResult.issues} issues from rule coordination`)
        end)
    end)
end
```

### Expected Output
- Large files process within acceptable time limits
- Memory usage remains reasonable
- System scales appropriately with file size and rule count
- Performance statistics are accurate and meaningful

## Integration Test Execution

### Running the Examples

```bash
# Run all integration tests
lute tests/integration/integration-test-scenarios.spec.luau

# Run specific working examples
lute tests/integration/working-examples.spec.luau

# Run with verbose output
lute tests/integration/working-examples.spec.luau --verbose
```

### Expected Success Criteria

Each working example should:
- ✅ Execute without errors
- ✅ Produce expected results
- ✅ Demonstrate integration between components
- ✅ Validate current system capabilities
- ✅ Complete within performance expectations

## Continuous Validation

These working examples serve as:

1. **Integration Smoke Tests**: Quick validation that core integration points work
2. **Regression Prevention**: Catch integration breaks during development
3. **Capability Demonstration**: Show what the system can currently do
4. **Performance Baseline**: Establish performance expectations
5. **Development Guidance**: Examples for implementing new integration scenarios

## Next Steps

1. **Implement Basic Examples**: Start with Scenario 1 (Complete Workflow)
2. **Validate Current System**: Ensure examples work with existing code
3. **Extend Test Coverage**: Add more specific integration scenarios
4. **Performance Monitoring**: Track metrics over time
5. **Documentation Updates**: Keep examples current with system changes

These working examples provide concrete validation of the Luau Linter plugin system integration while demonstrating real-world usage patterns and establishing quality benchmarks for ongoing development.
