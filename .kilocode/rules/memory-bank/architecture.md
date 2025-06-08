# System Architecture

## Overview

Luau Linter adopts a **Progressive Hybrid Architecture**, starting with an enhanced ESLint-style foundation (Listener Pattern, single-pass AST traversal) and incrementally incorporating modern linter innovations. The system is designed for high performance (200+ rules, 1000+ files), developer-friendly extensibility, and robust static analysis for the Luau programming language.

## Core Architectural Principles

- **Listener Pattern as Primary:** The primary mechanism for rule definition, enabling efficient single-pass AST traversal and rule batching. (Validated in Prototype)
- **Single-Pass AST Traversal:** All rules are processed in one traversal, minimizing overhead and maximizing performance.
- **Efficient Rule Batching:** Multiple rules interested in the same AST node type are executed in a single visit, significantly reducing redundant computations. (Validated in Prototype)
- **Query-Based Rule Support (Future):** Planned support for declarative, tree-sitter inspired query patterns for advanced rule definitions. (Validated in Prototype)
- **Incremental Computation (Future):** Aiming for Salsa-inspired query memoization and demand-driven analysis to only recompute affected parts of the codebase.
- **Unified AST Representation:** A single, shared AST (from Lute's Luau parser) is used for all rules, avoiding per-rule parsing overhead.
- **Smart Caching:** Strategies for caching rule results and ASTs to speed up subsequent linting runs.
- **TypeScript-First Type Awareness (Conceptual):** While Luau is the target, principles of strong type system integration (like TypeScript's Go port for performance) inform design for type-related rules.
- **Cross-File Intelligence (Future):** Planned support for rules that require analysis across multiple files.
- **Error Isolation:** Individual rule failures are caught and reported without halting the entire linting process, ensuring robustness.
- **Result-Based Error Handling:** Utilizes `@batteries/result` for explicit and composable error management.

## Core Architecture Diagram

```mermaid
graph TB
    CLI[CLI Interface] --> Engine[Rule Engine]
    Config[Configuration System] --> Engine
    Engine --> Registry[Rule Registry]
    Engine --> Context[Rule Context]
    Registry --> Rules[Individual Rules (Listener & Query-based)]
    Context --> ErrorHandling[Error Handling]
    Context --> Fixer[Auto-fix System]
    Engine --> ASTTraversal[AST Traversal Engine]
    ASTTraversal --> LuauParser[Luau Parser (@lute/luau)]
    ASTTraversal --> Cache[AST & Rule Result Cache]
    Engine --> IncrementalEngine[Incremental Computation Engine (Future)]
```

## Source Code Structure (Key Components)

### **Core Plugin System** ([`src/plugin/`](src/plugin/))
- [`plugin-api.luau`](src/plugin/plugin-api.luau:1): Main API exports, `createRule`, `createPlugin`.
- [`engine.luau`](src/plugin/engine.luau:1): Rule execution engine, single-pass traversal, rule batching logic.
- [`registry.luau`](src/plugin/registry.luau:1): Rule registration, validation, and management. (Validated in Prototype)
- [`context.luau`](src/plugin/context.luau:1): `RuleContext` implementation with reporting, fixing, and AST utilities.
- [`rule.luau`](src/plugin/rule.luau:1): `Rule` and `RuleListener` interface definitions, validation.

### **Core Systems** ([`src/core/`](src/core/))
- [`error-handling.luau`](src/core/error-handling.luau:1): Structured `LintError` management.

### **Type System** ([`src/types.luau`](src/types.luau:1))
- Advanced type utilities and helper functions.

### **Testing Infrastructure** ([`tests/`](tests/))
- Comprehensive test framework using Tiniest, with fixtures, integration tests, and snapshot testing. (Validated in Prototype)

## Key Technical Decisions & Rationale

1.  **Listener Pattern Architecture:**
    -   **Decision:** Primary rule definition mechanism.
    -   **Rationale:** Optimal performance via single-pass traversal and rule batching; familiar ESLint-like API; supports simple functions and enter/exit handlers. (See [`rule-pattern-decision.md`](.github/reports/architecture/rule-pattern-decision.md:1))
2.  **Progressive Hybrid Approach:**
    -   **Decision:** Start with ESLint-style foundation, incrementally add modern features (query-based rules, incremental computation).
    -   **Rationale:** Balances stability and familiarity with cutting-edge performance and developer experience. (See [`Plugin_API_Design_Document.md`](.github/reports/Plugin_API_Design_Document.md:1))
3.  **Single-Pass AST Traversal with Rule Batching:**
    -   **Decision:** Process all rules in one AST pass, executing batches of rules per node type.
    -   **Rationale:** Dramatically improves performance for large rule sets; scales efficiently with rule count. (Validated in Prototype)
4.  **Unified AST & Parser Integration:**
    -   **Decision:** Use `@lute/luau` for AST parsing, providing a single AST for all rules.
    -   **Rationale:** Avoids per-rule parsing; ensures consistency; leverages Lute's performance.
5.  **Error Isolation & Robust Handling:**
    -   **Decision:** Rule failures are isolated; use `Result` types for error management.
    -   **Rationale:** Production robustness; better developer experience; clear error paths.

## Design Patterns

- **Listener (Observer):** Core pattern for rule execution. Rules subscribe to AST node types.
- **Factory:** Used for creating core components like `RuleRegistry`, `RuleEngine`, `RuleContext`.
- **Builder:** Implicit in rule definition objects.
- **Strategy:** Different rule execution strategies (simple function, enter/exit listeners, query-based handlers).

## Rule & Context Interfaces (Listener Pattern)

Based on [`rule-pattern-decision.md`](.github/reports/architecture/rule-pattern-decision.md:1):

### Rule Interface
```luau
export type Rule = {
    id: string,
    title: string,
    description: string,
    category: "formatting" | "stylistic" | "logical", -- RuleCategory
    fixable: "none" | "auto" | "suggestion", -- FixCategory
    docsUrl: string,
    dependsOn: { RuleDependency }?,
    conflictsWith: { RuleDependency }?,
    create: (context: RuleContext) -> RuleListener,
}

export type RuleListener = {
    [string]: (node: luau.AstNode) -> (), -- Node type string -> handler
}
```

### RuleContext Interface
```luau
export type RuleContext = {
    filename: string,
    sourceText: string,
    report: (issue: LintIssue) -> (),
    createFix: (description: string, range: luau.Location, replacement: string) -> Fix,
    getSourceText: (node: luau.AstNode) -> string,
    getParent: (node: luau.AstNode) -> luau.AstNode?,
    findNodesOfType: (nodeType: string, root: luau.AstNode?) -> { luau.AstNode },
    getOption: (key: string) -> any,
    getRuleConfig: () -> { [string]: any }?,
}
```

## Performance Architecture

- **Rule Batching:** Multiple rules interested in the same node type are processed in a single visit.
- **Single AST Traversal:** Minimizes redundant parsing and tree walking.
- **Lazy Initialization:** Components like parent maps or complex AST utilities are computed on demand.
- **Caching (Future):** ASTs and rule results will be cached to speed up re-linting of unchanged or minimally changed files.
- **Incremental Analysis (Future):** Only re-linting parts of the code affected by changes.
- **Error Recovery:** `pcall` isolates rule failures, allowing other rules to continue.

## Future Architecture Evolution (Progressive Hybrid Model)

- **Phase 1 (Current Focus):** Enhanced ESLint-style foundation with Listener Pattern, rule batching, and robust `RuleContext`.
- **Phase 2: Query-Based Rules & CLI/Config:**
    - Introduce declarative, tree-sitter inspired query-based rule definitions as an alternative/addition to listeners. (Validated in Prototype)
    - Implement CLI and hierarchical configuration system.
- **Phase 3: Incremental Computation & Language Server:**
    - Develop a Salsa-inspired incremental computation engine for demand-driven analysis and memoization.
    - Implement Language Server Protocol (LSP) for IDE integration.
- **Phase 4: Advanced Features & Ecosystem:**
    - Cross-file analysis capabilities.
    - Plugin marketplace and advanced tooling.

This progressive approach allows for a stable, performant core while gradually integrating advanced features from modern linter research, ensuring both current effectiveness and future adaptability.