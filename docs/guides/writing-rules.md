# Writing Rules Guide

Learn how to create custom linting rules using the Luau linter's listener pattern.

## Quick Start

A rule is a simple object with a `create` function that returns listeners for specific AST node types:

```luau
local myRule = {
    id = "no-global-print",
    title = "Avoid global print function",
    description = "Use a proper logging function instead of global print",
    category = "logical",
    fixable = "none",
    docsUrl = "https://docs.example.com/rules/no-global-print",
    
    create = function(context)
        return {
            ExprCall = function(node: luau.AstExprCall)
                if node.func.type == "AstExprGlobal" and node.func.name == "print" then
                    context:report({
                        node = node,
                        message = "Use a proper logging function instead of global print"
                    })
                end
            end
        }
    end
}
```

## Rule Structure

### Required Fields

```luau
export type Rule = {
    -- Metadata
    id: string,                    -- Unique rule identifier
    title: string,                 -- Human-readable title
    description: string,           -- Human-readable description
    category: RuleCategory,        -- Rule category (style, correctness, etc.)
    fixable: FixCategory,          -- Whether rule provides automatic fixes
    docsUrl: string,              -- Link to rule documentation
    
    -- Implementation
    create: (context: RuleContext) -> RuleListener,
}

export type RuleCategory = "formatting" | "stylistic" | "logical"
export type FixCategory = "none" | "auto" | "suggestion"

export type RuleListener = {
    [string]: (node: luau.AstNode) -> (),  -- Node type -> handler function
}
```

### Optional Fields

```luau
export type Rule = {
    -- ... required fields ...
    
    -- Dependencies (optional)
    dependsOn: { RuleDependency }?,      -- Rules this depends on
    conflictsWith: { RuleDependency }?,  -- Rules this conflicts with
}

export type RuleDependency = {
    ruleId: string,
    required: boolean?,
    conflict: boolean?,
}
```

## AST Node Types

Common node types you can listen for:

### Statements
- `"StatBlock"` - Block of statements
- `"StatIf"` - If statements
- `"StatWhile"` - While loops
- `"StatRepeat"` - Repeat loops
- `"StatFor"` - Numeric for loops
- `"StatForIn"` - Iterator for loops
- `"StatReturn"` - Return statements
- `"StatLocal"` - Local variable declarations
- `"StatAssign"` - Variable assignments
- `"StatFunction"` - Function declarations

### Expressions  
- `"ExprCall"` - Function calls
- `"ExprLocal"` - Local variable references
- `"ExprGlobal"` - Global variable references
- `"ExprTable"` - Table constructors
- `"ExprFunction"` - Anonymous functions
- `"ExprBinary"` - Binary operations (+, -, etc.)
- `"ExprUnary"` - Unary operations (-, not, #)
- `"ExprIndexName"` - Dot notation (obj.field)
- `"ExprIndexExpr"` - Bracket notation (obj[key])

## Context API

The `context` parameter provides utilities for rule implementation:

```luau
export type RuleContext = {
    -- Source information
    filename: string,
    sourceText: string,
    
    -- Issue reporting
    report: (issue: LintIssue) -> (),
    reportAt: (node: luau.AstNode, message: string) -> (),
    
    -- Fix utilities
    createFix: (description: string, range: luau.Location, replacement: string) -> Fix,
    
    -- AST utilities
    getSourceText: (node: luau.AstNode) -> string,
    getParent: (node: luau.AstNode) -> luau.AstNode?,
    findNodesOfType: (nodeType: string, root: luau.AstNode?) -> { luau.AstNode },
    
    -- Configuration
    getOption: (key: string) -> any,
    getRuleConfig: () -> { [string]: any }?,
}
```

### Issue Reporting

```luau
-- Basic issue reporting
context:report({
    node = node,
    message = "Issue description"
})

-- Shorthand for simple cases
context:reportAt(node, "Issue description")
```

### Source Text Access

```luau
-- Get source text for a node
local nodeText = context:getSourceText(node)

-- Get text for a specific range
local rangeText = context:getSourceText(someLocation)
```

### AST Navigation

```luau
-- Find parent node
local parent = context:getParent(node)

-- Find all nodes of a type
local allCalls = context:findNodesOfType("ExprCall")
local callsInFunction = context:findNodesOfType("ExprCall", functionNode)
```

### Configuration Access

```luau
-- Get rule-specific config
local maxLength = context:getOption("maxLength") or 80
local config = context:getRuleConfig()

-- Access global settings
local strictMode = context:getGlobalOption("strict")
```

## Creating Fixes

Rules can provide automatic fixes for issues:

```luau
create = function(context)
    return {
        ExprGroup = function(node)
            if shouldReport(node) then
                local fix = context:createFix(
                    "Remove unnecessary parentheses",
                    node.location,
                    "fixed code here"
                )
                
                context:report({
                    node = node,
                    message = "Unnecessary parentheses",
                    fix = fix
                })
            end
        end
    }
end
```

## Example Rules

### 1. No Unused Variables

```luau
local noUnusedVars = {
    id = "no-unused-vars",
    title = "No unused variables",
    description = "Variables should be used after declaration",
    category = "logical",
    fixable = "none",
    docsUrl = "https://docs.example.com/rules/no-unused-vars",
    
    create = function(context)
        local declaredVars = {}
        local usedVars = {}
        
        return {
            StatLocal = function(node: luau.AstStatLocal)
                -- Track variable declarations
                for _, var in node.vars do
                    if var.name and var.name ~= "_" then  -- Ignore underscore variables
                        declaredVars[var.name] = {
                            node = var,
                            location = var.location
                        }
                    end
                end
            end,
            
            ExprLocal = function(node: luau.AstExprLocal)
                -- Track variable usage
                if node.local then
                    usedVars[node.local.name] = true
                end
            end,
            
            StatBlock = function(node: luau.AstStatBlock)
                -- At end of scope, check for unused variables
                for varName, varInfo in declaredVars do
                    if not usedVars[varName] then
                        context:report({
                            node = varInfo.node,
                            message = `Variable '{varName}' is declared but never used`
                        })
                    end
                end
                
                -- Reset for next scope
                declaredVars = {}
                usedVars = {}
            end
        }
    end
}
```

### 2. Prefer Modern Iteration

```luau
local preferModernIteration = {
    id = "prefer-modern-iteration", 
    title = "Prefer modern iteration",
    description = "Use generalized iteration instead of ipairs/pairs",
    category = "stylistic",
    fixable = "auto",
    docsUrl = "https://docs.example.com/rules/prefer-modern-iteration",

    create = function(context: RuleContext)
        return {
            StatForIn = function(node: luau.AstStatForIn)
                if #node.values ~= 1 then
                    return
                end
                
                local iteratorExpr = node.values[1]
                if iteratorExpr.type ~= "ExprCall" or iteratorExpr.func.type ~= "ExprGlobal" then
                    return
                end

                local funcName = iteratorExpr.func.name
                if funcName ~= "ipairs" and funcName ~= "pairs" then
                    return
                end

                local fix = context:createFix(
                    `Remove {funcName}() wrapper`,
                    iteratorExpr.location,
                    context:getSourceText(iteratorExpr.args[1])
                )

                context:report({
                    node = iteratorExpr,
                    message = `Use generalized iteration instead of {funcName}()`,
                    fix = fix
                })             
            end
        }
    end
}
```

### 2. Enforce String Formatting

```luau
local enforceStringFormat = {
    id = "enforce-string-format",
    title = "Enforce string interpolation",
    description = "Use string interpolation instead of concatenation",
    category = "stylistic", 
    fixable = "suggestion",
    docsUrl = "https://docs.example.com/rules/enforce-string-format",
    
    create = function(context)
        return {
            ExprBinary = function(node: luau.AstExprBinary)
                if node.op == ".." then  -- String concatenation
                    local allowShort = context:getOption("allowShortConcatenation")
                    local complexity = calculateComplexity(node)
                    
                    if not allowShort or complexity > 2 then
                        context:report({
                            node = node,
                            message = "Consider using string interpolation instead of concatenation"
                        })
                    end
                end
            end
        }
    end
}
```

### Configuration Schemas

Define rule configuration and access it through the context:

```luau
local maxLineLength = {
    id = "max-line-length",
    title = "Maximum line length",
    description = "Enforce maximum line length",
    category = "formatting",
    fixable = "none",
    docsUrl = "https://docs.example.com/rules/max-line-length",
    
    create = function(context)
        return {
            StatBlock = function(node)  -- Check at file level
                local maxLength = context:getOption("maxLength") or 120
                local ignoreComments = context:getOption("ignoreComments") or true
                
                -- Check line lengths...
            end
        }
    end
}
```

## Testing Rules

Rules should be thoroughly tested:

```luau
-- tests/rules/my-rule.spec.luau
local myRule = require("../src/rules/my-rule")
local testRule = require("../test-utils/rule-tester")

testRule(myRule, {
    valid = {
        "local x = 1",
        "function foo() end",
    },
    invalid = {
        {
            code = "print('hello')",
            errors = { { message = "Use a proper logging function" } }
        },
        {
            code = "global_var = 42", 
            errors = { { message = "Avoid global variables" } }
        }
    }
})
```

## Best Practices

### 1. Keep Rules Focused
- One rule should check one specific pattern
- Avoid complex rules that check multiple unrelated things
- Use the listener pattern to focus on specific node types

### 2. Provide Clear Messages
- Messages should explain what's wrong and why
- Include suggestions for fixes when possible

### 3. Consider Performance
- Use specific node types in your listener object rather than listening to everything
- Avoid expensive operations in frequently-called handlers
- Remember: the framework traverses once for all rules

### 4. Handle Edge Cases
- Test with malformed or unusual code
- Use defensive programming (check for nil, etc.)

### 5. Provide Configuration
- Make rules configurable when reasonable
- Use good defaults that work for most users
- Access configuration via `context:getOption()`


See the [Plugin Development Guide](./plugin-development.md) for more details on creating and distributing rule packages.

