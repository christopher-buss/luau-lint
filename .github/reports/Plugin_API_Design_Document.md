# Plugin API Architecture Design Document
## Luau Linter Plugin System

### Executive Summary

This document outlines the design of a plugin system for the Luau Linter, enabling third-party rule development while maintaining performance through efficient AST visitor batching. The design adapts proven patterns from both traditional (ESLint) and modern linter architectures for the Luau/Lute ecosystem.

### Modern Linter Architecture Analysis

Recent research into post-ESLint linter architectures reveals several significant innovations that should inform our design:

#### Rust-Based Performance Innovations

**Clippy Architecture Insights:**
- Uses Rust's HIR (High-level Intermediate Representation) instead of just AST
- Implements declarative syntax patterns to reduce complexity
- Achieves substantial performance gains through zero-cost abstractions
- Plugin architecture through external crates using `dylint` for dynamic loading

**Oxc (Oxidation Compiler) Breakthrough Performance:**
- 50-100x faster than ESLint through Rust implementation
- Single-pass architecture with unified parsing and linting
- Memory efficiency through arena allocation patterns
- Parallel processing with proper dependency resolution

#### Query-Based Linting Systems

**Tree-sitter Query Innovation:**
- Declarative S-expression syntax for pattern matching
- Incremental parsing with minimal recomputation
- Query-based rule definition: `(function_declaration name: (identifier) @name)`
- Lossless syntax trees preserving all source information

#### Incremental Compilation Patterns

**Rust-analyzer Query-Based Architecture:**
- Persistent compilation database for incremental updates
- Query memoization with automatic cache invalidation
- Demand-driven analysis (only compute what's needed)
- Salsa-based incremental computation framework

**TypeScript Language Service Evolution:**
- Project service with file change tracking
- Symbol-based caching and cross-file dependency tracking
- Native port announcement (2025) promising 10x performance improvements
- Language service plugin architecture with decorator patterns

#### Key Architectural Patterns to Adopt

1. **Query-Based Rule Definition**: More declarative than imperative visitor patterns
2. **Incremental Computation**: Cache rule results and invalidate only affected nodes
3. **Unified AST Representation**: Single parse tree shared across all rules
4. **Arena Allocation**: Memory efficiency for large codebases
5. **Demand-Driven Analysis**: Only execute rules when results are needed

### Design Goals

1. **Efficient Rule Batching**: Multiple rules can execute on the same AST node type in a single traversal pass
2. **Developer Experience**: Simple, intuitive API incorporating modern declarative patterns
3. **Performance**: Minimal overhead with incremental computation support
4. **Extensibility**: Support for custom rule categories and configurations
5. **Type Safety**: Full Luau type checking support for plugin development
6. **Query-Based Rules**: Option for declarative pattern-based rule definition

### Core Requirements Analysis

Based on the existing `lute/batteries/syntax/visitor.luau` implementation:
- 50+ AST node visit methods available
- Current visitor pattern supports synchronous traversal
- Need to maintain compatibility with existing rule implementations
- Must support batch processing of multiple rules per node type

### Design Alternative 1: ESLint-Style Plugin Architecture

#### Plugin Structure
```luau
export type LuauPlugin = {
    meta: PluginMeta,
    configs?: { [string]: PluginConfig },
    rules: { [string]: Rule },
    processors?: { [string]: Processor }
}

export type PluginMeta = {
    name: string,
    version: string,
    description: string?,
    author: string?,
    repository: string?
}

export type Rule = {
    meta: RuleMeta,
    create: (context: RuleContext) -> RuleListener
}

export type RuleListener = {
    [string]: (node: ASTNode) -> ()
}
```

#### Rule Registration with Batching
```luau
-- Plugin Manager handles rule batching
local PluginManager = {}

function PluginManager:registerPlugin(name: string, plugin: LuauPlugin)
    for ruleName, rule in plugin.rules do
        local qualifiedName = name .. "/" .. ruleName
        self.rules[qualifiedName] = rule
        
        -- Build visitor method batches
        local listener = rule.create(self:createRuleContext(qualifiedName))
        for methodName, handler in listener do
            if not self.batches[methodName] then
                self.batches[methodName] = {}
            end
            table.insert(self.batches[methodName], {
                ruleName = qualifiedName,
                handler = handler
            })
        end
    end
end
```

#### Visitor Integration
```luau
-- Enhanced visitor that executes batched rules
local BatchedVisitor = {}

function BatchedVisitor:visitIdentifier(node: Identifier)
    -- Execute all rules registered for this node type
    local handlers = self.pluginManager.batches["visitIdentifier"]
    if handlers then
        for _, ruleHandler in handlers do
            ruleHandler.handler(node)
        end
    end
end
```

### Design Alternative 2: Hook-Based Architecture

#### Plugin Structure
```luau
export type LuauPlugin = {
    name: string,
    version: string,
    setup: (api: PluginAPI) -> (),
    teardown: (() -> ())?
}

export type PluginAPI = {
    registerRule: (name: string, rule: Rule) -> (),
    registerVisitorHook: (nodeType: string, priority: number, handler: VisitorHook) -> (),
    getConfig: (key: string) -> any,
    reportDiagnostic: (diagnostic: Diagnostic) -> ()
}
```

#### Hook-Based Rule Registration
```luau
function examplePlugin.setup(api: PluginAPI)
    api:registerRule("no-unused-vars", {
        meta = {
            description = "Detect unused variables",
            category = "best-practices"
        },
        create = function(context)
            return {
                visitLocalAssignStat = function(node)
                    -- Rule implementation
                end
            }
        end
    })
end
```

### Design Alternative 3: Modular Rule System

#### Plugin Structure
```luau
export type RuleModule = {
    name: string,
    category: RuleCategory,
    severity: RuleSeverity,
    visitor: VisitorMethods,
    config?: RuleConfig
}

export type VisitorMethods = {
    enter?: { [string]: (node: ASTNode, context: RuleContext) -> () },
    exit?: { [string]: (node: ASTNode, context: RuleContext) -> () }
}
```

#### Batch Processing Engine
```luau
local RuleBatcher = {}

function RuleBatcher:processNode(nodeType: string, node: ASTNode, phase: "enter" | "exit")
    local batch = self.batches[nodeType] and self.batches[nodeType][phase]
    if not batch then return end
    
    for _, ruleHandler in ipairs(batch) do
        local success, error = pcall(ruleHandler.handler, node, ruleHandler.context)
        if not success then
            self:reportRuleError(ruleHandler.ruleName, error)
        end
    end
end
```

### Design Alternative 4: Modern Query-Based Architecture

Inspired by tree-sitter queries, rust-analyzer's incremental computation, and Oxc's performance innovations.

#### Core Principles
1. **Declarative Rule Definition**: Rules defined as queries rather than imperative visitor code
2. **Incremental Computation**: Memoized results with fine-grained cache invalidation
3. **Demand-Driven Analysis**: Only compute rule results when requested
4. **Unified AST Processing**: Single parse tree shared across all rule evaluation

#### Query-Based Rule Definition

```luau
export type QueryRule = {
    meta: RuleMeta,
    -- Declarative S-expression query (inspired by tree-sitter)
    queries: { QueryPattern },
    -- Handler for matched nodes
    handler: (matches: { QueryMatch }, context: QueryContext) -> { Diagnostic }
}

export type QueryPattern = {
    pattern: string, -- S-expression pattern like "(function_declaration name: (identifier) @fn_name)"
    captures: { string }, -- Names of captured nodes
    predicates?: { QueryPredicate } -- Additional constraints
}

export type QueryPredicate = {
    type: "eq" | "match" | "not" | "has_child",
    capture: string,
    value: any
}

-- Example rule using query syntax
local noUnusedVariables: QueryRule = {
    meta = {
        name = "no-unused-variables",
        description = "Detects unused local variables",
        category = "correctness"
    },
    queries = {
        {
            -- Match local variable declarations
            pattern = "(local_declaration pattern: (identifier) @var_name)",
            captures = { "var_name" },
            predicates = {
                { type = "not", capture = "var_name", value = "_" } -- Skip underscore vars
            }
        }
    },
    handler = function(matches, context)
        local diagnostics = {}
        for _, match in matches do
            local varName = match.captures.var_name
            if not context:isVariableUsed(varName) then
                table.insert(diagnostics, {
                    node = match.node,
                    message = `Variable '{varName}' is declared but never used`,
                    severity = "warning"
                })
            end
        end
        return diagnostics
    end
}
```

#### Incremental Computation Engine

```luau
-- Salsa-inspired incremental computation system
export type RuleDatabase = {
    -- Memoized query results with dependency tracking
    queryCache: { [string]: QueryResult },
    -- File change tracking for cache invalidation
    fileDependencies: { [string]: { string } },
    -- AST node to rule result mapping
    nodeResults: { [ASTNode]: { RuleResult } }
}

function RuleDatabase:executeQuery(query: QueryPattern, ast: ASTNode): QueryResult
    local cacheKey = self:computeCacheKey(query, ast)
    
    -- Check if cached result is still valid
    if self.queryCache[cacheKey] and self:isCacheValid(cacheKey) then
        return self.queryCache[cacheKey]
    end
    
    -- Execute query and cache result with dependencies
    local result = self:runQuery(query, ast)
    self.queryCache[cacheKey] = result
    self:trackDependencies(cacheKey, ast)
    
    return result
end

function RuleDatabase:invalidateAffectedQueries(changedFiles: { string })
    for file in changedFiles do
        local affectedQueries = self.fileDependencies[file] or {}
        for queryKey in affectedQueries do
            self.queryCache[queryKey] = nil
        end
    end
end
```

#### Unified Processing Pipeline

```luau
export type QueryProcessor = {
    database: RuleDatabase,
    queryEngine: QueryEngine,
    rules: { QueryRule }
}

function QueryProcessor:analyzeFile(filePath: string, content: string): { Diagnostic }
    -- Single parse for all rules
    local ast = self:parseFile(content)
    
    -- Collect all unique query patterns from active rules
    local uniqueQueries = self:deduplicateQueries()
    
    -- Execute queries in batch (single traversal)
    local queryResults = {}
    for _, query in ipairs(uniqueQueries) do
        queryResults[query.id] = self.database:executeQuery(query, ast)
    end
    
    -- Apply rule handlers to query results
    local allDiagnostics = {}
    for _, rule in ipairs(self.rules) do
        for _, query in ipairs(rule.queries) do
            local matches = queryResults[query.id]
            local context = self:createQueryContext(filePath, ast)
            local diagnostics = rule.handler(matches, context)
            table.extend(allDiagnostics, diagnostics)
        end
    end
    
    return allDiagnostics
end
```

#### Advantages of Query-Based Architecture

**Performance Benefits:**
- Single AST traversal for all query patterns
- Incremental computation with fine-grained cache invalidation
- Demand-driven analysis (only compute when needed)
- Memory efficiency through shared AST representation

**Developer Experience:**
- Declarative rule definition reduces complexity
- Pattern matching syntax is more intuitive than visitor patterns
- Query reuse across multiple rules
- Built-in support for complex pattern matching

**Scalability:**
- Easy parallelization of independent queries
- Efficient memory usage through arena allocation
- Incremental updates for large codebases

## Updated Recommendations Based on Modern Linter Research

### Recommended Architecture: Progressive Hybrid Approach

Based on the analysis of modern linter architectures from Clippy, Oxc, tree-sitter, rust-analyzer, and TypeScript's evolution, we recommend implementing a **progressive hybrid approach** that combines the best of traditional and modern patterns:

#### Phase 1: Enhanced ESLint-Style Foundation (Immediate)
- Implement **Design Alternative 1** (ESLint-style) as the foundation
- Add **multi-pass execution model** to handle rule dependencies and fixes correctly
- Include **incremental AST node invalidation** for performance

#### Phase 2: Query-Based Rule Support (Medium-term)
- Add **Design Alternative 4** (Query-based) as an optional advanced rule definition method
- Implement tree-sitter inspired declarative patterns for common use cases
- Maintain backward compatibility with visitor-based rules

#### Phase 3: Incremental Computation Engine (Long-term)
- Implement rust-analyzer inspired **query memoization** with automatic cache invalidation
- Add **demand-driven analysis** (only compute what's needed when needed)
- Include **cross-file dependency tracking** for workspace-level optimizations

### Key Performance Optimizations to Implement

1. **Unified AST Processing**
   - Single parse tree shared across all rules (avoiding ESLint's per-rule parsing overhead)
   - Arena allocation patterns for memory efficiency
   - Parallel rule execution where dependencies allow

2. **Smart Caching Strategy**
   ```luau
   -- Cache rule results per file with content-based invalidation
   export type RuleCache = {
       fileHashes: { [string]: string },
       ruleResults: { [string]: { [string]: { Diagnostic } } },
       astNodes: { [string]: ASTNode }
   }
   ```

3. **Incremental Re-Analysis**
   - Only re-run rules on AST nodes affected by changes
   - Track rule dependencies to minimize cascade re-computation
   - Use content-based hashing for efficient change detection

### Implementation Priorities

**High Priority (Phase 1):**
1. Multi-pass execution engine to handle rule conflicts
2. Enhanced rule context API with fix suggestion support
3. Efficient rule batching by AST node type
4. Plugin discovery and loading mechanism

**Medium Priority (Phase 2):**
1. Query-based rule definition support
2. Declarative pattern matching for common lint patterns
3. Advanced rule configuration and composition
4. Language Server Protocol integration

**Low Priority (Phase 3):**
1. Full incremental computation engine
2. Cross-file analysis and caching
3. Advanced parallelization and memory optimization
4. Plugin ecosystem tooling (scaffolding, testing, publishing)

### Modern Pattern Adoption Strategy

**Immediately Adopt:**
- Multi-pass execution (ESLint proven pattern)
- Unified AST representation (Oxc inspiration)
- Rule result caching with invalidation

**Gradually Adopt:**
- Query-based declarative rules (tree-sitter inspiration)
- Incremental computation (rust-analyzer inspiration)
- Advanced dependency tracking

**Research Further:**
- Arena allocation patterns (Rust-specific, may not apply to Luau)
- Native compilation opportunities (TypeScript's Go port inspiration)
- Language server deep integration patterns

### Architecture Decision Record

**Decision**: Implement progressive hybrid approach starting with enhanced ESLint-style foundation

**Rationale**:
1. **Proven Stability**: ESLint's multi-pass model has handled millions of codebases successfully
2. **Incremental Adoption**: Teams can migrate gradually from visitor patterns to query-based rules  
3. **Performance Benefits**: Modern optimizations (caching, batching, incremental) can be added incrementally
4. **Developer Familiarity**: ESLint patterns are well-understood by the ecosystem
5. **Future-Proofing**: Architecture supports evolution toward more advanced patterns

**Consequences**:
- Initial implementation complexity is moderate vs. simple batching
- Plugin developers have multiple rule definition options
- Performance will improve incrementally rather than revolutionary jump
- Maintains compatibility with existing Luau/Lute ecosystem patterns

### Success Metrics

**Performance Targets:**
- 50% reduction in lint time vs. current sequential rule execution
- 90% cache hit rate for unchanged files in incremental mode
- Sub-100ms response time for single-file analysis

**Developer Experience Targets:**
- Plugin setup time < 5 minutes for new developers
- Rule creation time < 30 minutes for experienced developers
- Zero-configuration plugin loading for common use cases

---

*This document represents our research-informed approach to building a modern, performant plugin system for the Luau Linter while maintaining the proven stability patterns from the ESLint ecosystem and incorporating cutting-edge innovations from Rust-based tooling.*