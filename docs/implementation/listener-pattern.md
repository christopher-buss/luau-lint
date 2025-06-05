# Listener Pattern Implementation

This document outlines the technical implementation of the listener pattern for the Luau linter.

## Architecture Overview

The listener pattern implementation consists of three main components:

1. **Rule Engine** - Manages rule registration and execution
2. **Rule Context** - Provides utilities for rule authors  
3. **AST Traversal** - Efficient single-pass traversal with batched rule execution

## Core Interfaces

### Rule Definition

```luau
export type Rule = {
    -- Metadata
    id: string,
    description: string,
    category: string,
    
    -- Execution configuration
    nodeTypes: { string },
    severity: ("error" | "warning" | "info")?,
    
    -- Implementation
    handle: (node: luau.AstNode, context: RuleContext) -> (),
    
    -- Optional configuration
    defaultConfig: { [string]: any }?,
    schema: { [string]: any }?,
    
    -- Lifecycle hooks
    beforeFile: ((context: RuleContext) -> ())?,
    afterFile: ((context: RuleContext) -> ())?,
}
```

### Rule Context

```luau
export type RuleContext = {
    -- File information
    filename: string,
    sourceText: string,
    
    -- Issue reporting
    report: (issue: LintIssue) -> (),
    reportAt: (node: luau.AstNode, message: string, severity: string?) -> (),
    
    -- Fix creation
    createFix: (description: string, range: luau.Location, replacement: string) -> Fix,
    
    -- AST utilities
    getSourceText: (node: luau.AstNode) -> string,
    getParent: (node: luau.AstNode) -> luau.AstNode?,
    findNodesOfType: (nodeType: string, root: luau.AstNode?) -> { luau.AstNode },
    
    -- Configuration access
    getOption: (key: string) -> any,
    getRuleConfig: () -> { [string]: any }?,
    getGlobalOption: (key: string) -> any,
}
```

### Lint Issue

```luau
export type LintIssue = {
    ruleId: string,
    message: string,
    severity: "error" | "warning" | "info",
    node: luau.AstNode,
    location: luau.Location,
    fix: Fix?,
    data: { [string]: any }?,
}
```

## Rule Engine Implementation

### Registration System

```luau
local RuleEngine = {}
RuleEngine.__index = RuleEngine

function RuleEngine.new()
    return setmetatable({
        rules = {},
        listeners = {}, -- [nodeType] = { rule1, rule2, ... }
        globalConfig = {},
    }, RuleEngine)
end

function RuleEngine:registerRule(rule: Rule)
    -- Validate rule
    if not rule.id or not rule.handle then
        error("Rule must have id and handle function")
    end
    
    -- Store rule
    self.rules[rule.id] = rule
    
    -- Register listeners for each node type
    for _, nodeType in rule.nodeTypes do
        if not self.listeners[nodeType] then
            self.listeners[nodeType] = {}
        end
        table.insert(self.listeners[nodeType], rule)
    end
end

function RuleEngine:registerPlugin(plugin)
    for _, rule in plugin.rules do
        self:registerRule(rule)
    end
end
```

### File Processing

```luau
function RuleEngine:lintFile(filename: string, sourceText: string): { LintIssue }
    -- Parse source code
    local parseResult = luau.parse(sourceText)
    if not parseResult.success then
        return { {
            ruleId = "parse-error",
            message = parseResult.error,
            severity = "error",
            location = parseResult.location or { begin = { line = 0, column = 0 } }
        } }
    end
    
    local ast = parseResult.root
    local issues = {}
    
    -- Create context
    local context = self:createContext(filename, sourceText, issues)
    
    -- Execute beforeFile hooks
    for _, rule in self.rules do
        if rule.beforeFile then
            rule.beforeFile(context)
        end
    end
    
    -- Traverse AST with batched rule execution
    self:traverseWithListeners(ast, context)
    
    -- Execute afterFile hooks
    for _, rule in self.rules do
        if rule.afterFile then
            rule.afterFile(context)
        end
    end
    
    return issues
end
```

### Efficient AST Traversal

```luau
function RuleEngine:traverseWithListeners(node: luau.AstNode, context: RuleContext)
    -- Call listeners for this node type
    local nodeListeners = self.listeners[node.type]
    if nodeListeners then
        for _, rule in nodeListeners do
            -- Error isolation per rule
            local success, err = pcall(rule.handle, node, context)
            if not success then
                table.insert(context.issues, {
                    ruleId = rule.id,
                    message = `Rule error: {err}`,
                    severity = "error",
                    node = node,
                    location = node.location
                })
            end
        end
    end
    
    -- Recursively traverse child nodes
    self:traverseChildren(node, context)
end

function RuleEngine:traverseChildren(node: luau.AstNode, context: RuleContext)
    -- Use visitor pattern to traverse all child nodes
    local visitor = require("@batteries/syntax/visitor").createVisitor()
    
    -- Override all visit methods to call our listener dispatch
    for _, visitMethod in {
        "visitBlock", "visitIf", "visitWhile", "visitRepeat", 
        "visitFor", "visitForIn", "visitReturn", "visitLocal",
        "visitAssign", "visitFunction", "visitCall", "visitBinary"
        -- ... all other visit methods
    } do
        visitor[visitMethod] = function(childNode)
            self:traverseWithListeners(childNode, context)
            return true  -- Continue traversal
        end
    end
    
    -- Start traversal
    require("@batteries/syntax/visitor").visitBlock(node, visitor)
end
```

## Context Implementation

### Context Creation

```luau
function RuleEngine:createContext(filename: string, sourceText: string, issues: { LintIssue }): RuleContext
    local parentMap = self:buildParentMap(ast)
    
    local context = {
        filename = filename,
        sourceText = sourceText,
        issues = issues,
        parentMap = parentMap,
        currentRule = nil, -- Set during rule execution
        
        report = function(issue: LintIssue)
            issue.ruleId = context.currentRule.id
            table.insert(issues, issue)
        end,
        
        reportAt = function(node: luau.AstNode, message: string, severity: string?)
            table.insert(issues, {
                ruleId = context.currentRule.id,
                message = message,
                severity = severity or context.currentRule.severity or "warning",
                node = node,
                location = node.location
            })
        end,
        
        createFix = function(description: string, range: luau.Location, replacement: string): Fix
            return {
                description = description,
                range = range,
                replacement = replacement
            }
        end,
        
        getSourceText = function(nodeOrLocation)
            if type(nodeOrLocation) == "table" and nodeOrLocation.location then
                return extractSourceText(sourceText, nodeOrLocation.location)
            else
                return extractSourceText(sourceText, nodeOrLocation)
            end
        end,
        
        getParent = function(node: luau.AstNode): luau.AstNode?
            return parentMap[node]
        end,
        
        findNodesOfType = function(nodeType: string, root: luau.AstNode?): { luau.AstNode }
            return findNodesOfTypeImpl(nodeType, root or ast)
        end,
        
        getOption = function(key: string): any
            local ruleConfig = context.currentRule.config or context.currentRule.defaultConfig
            return ruleConfig and ruleConfig[key]
        end,
        
        getRuleConfig = function(): { [string]: any }?
            return context.currentRule.config or context.currentRule.defaultConfig
        end,
        
        getGlobalOption = function(key: string): any
            return self.globalConfig[key]
        end
    }
    
    return context
end
```

### Parent Map Building

```luau
function RuleEngine:buildParentMap(ast: luau.AstStatBlock): { [luau.AstNode]: luau.AstNode }
    local parentMap = {}
    
    local function buildMap(node: luau.AstNode, parent: luau.AstNode?)
        if parent then
            parentMap[node] = parent
        end
        
        -- Use visitor to traverse and build parent relationships
        local mapVisitor = require("@batteries/syntax/visitor").createVisitor()
        
        -- Override methods to track parent-child relationships
        for _, visitMethod in getAllVisitMethods() do
            mapVisitor[visitMethod] = function(child)
                buildMap(child, node)
                return true
            end
        end
        
        require("@batteries/syntax/visitor").visitNode(node, mapVisitor)
    end
    
    buildMap(ast, nil)
    return parentMap
end
```

## Performance Optimizations

### Rule Batching

Rules are automatically batched by node type to minimize traversal overhead:

```luau
-- Instead of:
-- Rule 1: Traverse AST looking for CallExpression
-- Rule 2: Traverse AST looking for CallExpression  
-- Rule 3: Traverse AST looking for CallExpression

-- We do:
-- Single traversal: When we find CallExpression, notify Rules 1, 2, 3
```

### Lazy Parent Map

Parent relationships are only computed when first accessed:

```luau
function RuleEngine:createContext(...)
    local parentMap = nil
    
    local context = {
        getParent = function(node)
            if not parentMap then
                parentMap = self:buildParentMap(ast)
            end
            return parentMap[node]
        end
    }
end
```

### Error Isolation

Rule errors don't crash the entire linting process:

```luau
local success, err = pcall(rule.handle, node, context)
if not success then
    -- Log error and continue with other rules
    context:reportAt(node, `Rule '{rule.id}' error: {err}`, "error")
end
```

## Integration Points

### Plugin System

```luau
-- Plugin registration
ruleEngine:registerPlugin({
    name = "my-plugin",
    version = "1.0.0", 
    rules = {
        require("./rules/no-unused-vars"),
        require("./rules/prefer-const")
    }
})
```

### Configuration System

```luau
-- Rule configuration
ruleEngine:configure({
    rules = {
        ["no-unused-vars"] = { severity = "error" },
        ["prefer-const"] = { 
            checkObjects = true,
            severity = "warning" 
        }
    }
})
```

### CLI Integration

```luau
-- Command line interface
local cli = require("../cli/linter-cli")
cli:run({
    files = { "src/**/*.luau" },
    rules = { "recommended", "style" },
    fix = true
})
```

This implementation provides the foundation for a scalable, performant rule system that can handle 200+ rules efficiently while maintaining a simple API for rule authors.
