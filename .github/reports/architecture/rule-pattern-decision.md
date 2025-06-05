# Rule Pattern Architecture Decision

## Overview

This document outlines the architectural decision to use the **Listener Pattern** for rule implementation in the Luau linter, as opposed to the Visitor Pattern or other alternatives.

## Decision Summary

**We have chosen the Listener Pattern** for rule implementation because it provides the best balance of:
- Developer experience and ease of rule authoring
- Performance at scale (200+ rules)
- Maintainability and plugin ecosystem growth

## Pattern Comparison

### Visitor Pattern (Rejected)
```luau
-- Complex for rule authors
local rule = {
    createVisitor = function(context)
        local visitor = createVisitor()
        visitor.visitForIn = function(node: luau.AstStatForIn): boolean
            -- Rule logic here
            return true  -- Must remember to continue traversal
        end
        return visitor
    end
}
```

**Why Rejected:**
- ❌ High cognitive overhead for rule authors
- ❌ Manual issue collection and management
- ❌ Requires understanding of visitor pattern semantics
- ❌ Multiple traversals needed for multiple rules (O(n×rules))

### Listener Pattern (Chosen)
```luau
-- Simple and focused for rule authors
local rule = {
    id = "no-pairs",
    title = "Avoid pairs() function",
    description = "Use generalized iteration instead of pairs()",
    category = "logical",
    fixable = "auto",
    docsUrl = "https://docs.example.com/rules/no-pairs",
    
    create = function(context)
        return {
            ForInStatement = function(node: luau.AstStatForIn)
                -- Simple rule logic
                if shouldReport(node) then
                    context:report({
                        node = node,
                        message = "Use generalized iteration"
                    })
                end
            end
        }
    end
}

```

**Why Chosen:**
- ✅ Minimal cognitive overhead - just implement listener functions
- ✅ Framework manages traversal, batching, and issue collection
- ✅ Single traversal for all rules (O(n) regardless of rule count)
- ✅ Clear separation of concerns
- ✅ Proven at ESLint scale (200+ rules)
- ✅ Multiple node types with different logic per rule

## Performance Analysis

### Scalability with Rule Count

| Rules | Visitor Pattern | Listener Pattern |
|-------|----------------|------------------|
| 1 rule | 1× traversal | 1× traversal |
| 10 rules | 10× traversals | 1× traversal |
| 100 rules | 100× traversals | 1× traversal |
| 200+ rules | 200+× traversals | 1× traversal |

**Result:** Listener pattern scales O(1) with rule count, visitor pattern scales O(n).

### Real-World Performance
- **Small projects (1-5 rules):** Negligible difference
- **Production linters (50+ rules):** Listener pattern 10-50× faster
- **Enterprise setups (200+ rules):** Listener pattern 100-200× faster

## Developer Experience

### Learning Curve
```luau
-- Visitor Pattern: Must understand
-- - Visitor pattern concepts
-- - AST traversal mechanics
-- - Return value semantics (true/false)
-- - Manual issue management
-- - Lifecycle management

-- Listener Pattern: Just need to know
-- - Which node types you care about
-- - How to analyze the node
-- - How to report issues via context
-- - Return listener object from create function
```

### Rule Registration
```luau
-- Visitor: Complex setup
local visitor, issues = rule.createVisitor(context)
visitor.visitBlock(ast, visitor)
-- Manual issue collection...

-- Listener: Simple registration
ruleEngine:registerRule(rule)
-- Framework handles everything
```

## Implementation Standards

### Rule Structure
All rules must follow this interface:

```luau
export type Rule = {
    -- Metadata
    id: string,                    -- Unique rule identifier
    title: string,                 -- Human-readable title
    description: string,           -- Human-readable description
    category: RuleCategory,        -- Rule category (style, correctness, etc.)
    fixable: FixCategory,          -- Whether rule provides automatic fixes
    docsUrl: string,              -- Link to rule documentation
    
    -- Dependencies (optional)
    dependsOn: { RuleDependency }?,      -- Rules this depends on
    conflictsWith: { RuleDependency }?,  -- Rules this conflicts with
    
    -- Implementation
    create: (context: RuleContext) -> RuleListener,
}

export type RuleCategory = "formatting" | "stylistic" | "logical"
export type FixCategory = "none" | "auto" | "suggestion"
export type RuleDependency = {
    ruleId: string,
    required: boolean?,
    conflict: boolean?,
}

export type RuleListener = {
    [string]: (node: luau.AstNode) -> (),  -- Node type -> handler function
}
```

### Context Interface
The context provides utilities for rule authors:

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

## Ecosystem Benefits

### Plugin Development
- **Lower barrier to entry**: Anyone can write rules without deep AST knowledge
- **Faster development cycles**: Less boilerplate, focus on rule logic
- **Better testing**: Isolated rule logic is easier to unit test

### Community Growth
- **More contributors**: Simpler pattern encourages community rule development
- **Consistent quality**: Framework-provided utilities reduce implementation bugs
- **Documentation friendly**: Clear, simple examples in docs

## References

- [ESLint Rule Development](https://eslint.org/docs/developer-guide/working-with-rules)
- [Performance Analysis Results](../benchmarks/rule-pattern-performance.md)
- [Rule Author Guide](../guides/writing-rules.md)
