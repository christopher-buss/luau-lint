# Technical Overview

## Technologies Used

### **Core Runtime**
- **Lute** - Modern Luau runtime environment with comprehensive standard library.
  - Version: `0.1.0-nightly.20250531` (via Rokit).
  - Provides file system, networking, process, and system APIs.
  - Custom module system with path resolution.
  - Integration with Luau parser and AST.

### **Language & Type System**
- **Luau** - Statically typed Lua derivative with modern features.
  - Strict type checking enabled (`languageMode: "strict"`).
  - Advanced type functions and generics support.
  - String interpolation and modern iteration patterns.
  - Comprehensive AST access through `@lute/luau`.
- **Conceptual TypeScript-First Awareness:** Design principles are informed by TypeScript's type system capabilities for robust type-related rule handling, even though the primary implementation is Luau.

### **Rule Definition & Execution**
- **Listener Pattern:** Primary mechanism for rule definition, enabling single-pass AST traversal and efficient rule batching.
- **Query-Based Rules (Future):** Planned support for declarative, tree-sitter inspired S-expression patterns for advanced rule definitions. (Validated in Prototype)
- **Incremental Computation (Future):** Aiming for Salsa-inspired query memoization and demand-driven analysis to recompute only affected parts.

### **Testing Framework**
- **Tiniest** - Lightweight testing framework adapted for Lute runtime.
  - Custom integration for Lute environment.
  - Snapshot testing capabilities, including **inline snapshot tests** for clear error span visualization.
  - Pretty output formatting with colors and emojis.
  - Automatic test discovery and execution.

### **Error Handling**
- **@batteries/result** - Result type library for robust error handling.
  - Composable error handling patterns.
  - Explicit success/failure distinctions.
  - Integration with `pcall` for error isolation in rule execution.

### **Development Tools**
- **StyLua** - Code formatter for consistent Luau styling.
- **Selene** - Static analysis tool for basic linting (used for bootstrapping).
- **Rokit** - Toolchain manager for Roblox/Luau projects.

## Development Setup

### **Project Structure**
```
luau-lint/
├── src/                    # Core implementation
│   ├── plugin/            # Plugin system (engine, registry, context, rule APIs)
│   ├── core/              # Core utilities (error handling)
│   └── types.luau         # Advanced type utilities
├── tests/                 # Test suite
│   ├── plugin/           # Unit tests for plugin components
│   ├── integration/      # Integration tests for end-to-end scenarios
│   ├── helpers/          # Test utilities and fixtures
│   └── tiniest/          # Custom Tiniest test framework integration
├── docs/                 # User and developer documentation
├── examples/             # Example rules and usage
└── lute/                 # Lute runtime (submodule)
```

### **Configuration Files**
- **`.luaurc`** - Luau language configuration with module aliases.
- **`rokit.toml`** - Tool dependency management.
- **`stylua.toml`** - Code formatting configuration.
- **`selene.toml`** - Basic linting configuration (primarily for bootstrapping).
- **`luau-lint.toml` (Planned):** Project-specific linter configuration.

### **Module Aliases** (from `.luaurc`)
```json
{
    "Batteries": "./lute/batteries",
    "Std": "./lute/std/libs", 
    "Lute": "./lute/definitions",
    "Tiniest": "./tests/tiniest"
}
```

## Technical Constraints

### **Runtime Limitations**
- **Lute Environment**: All operations are constrained by Lute's capabilities.
- **No Direct Node.js/Shell Access**: File system, networking, and process management rely on Lute's APIs.

### **Performance Requirements**
- **Single-Pass Processing**: Listener-based rules execute in one AST traversal.
- **Memory Efficiency**: Handle large codebases (1000+ files) without excessive memory.
- **Rule Scalability**: Support 200+ rules efficiently.
- **Error Isolation**: Individual rule failures must not halt the entire linting process.

### **Type System Constraints**
- **Strict Luau Typing**: All code must compile under strict type checking.
- **Luau Generics**: Work within the capabilities of Luau's generic system.
- **Lute Module System**: Adhere to Lute's custom module resolution.

## Dependencies

### **Core Dependencies**
```luau
-- Runtime and parsing
local luau = require("@lute/luau")        -- AST parsing and analysis
local fs = require("@lute/fs")            -- File system operations

-- Error handling and utilities
local result = require("@batteries/result") -- Result type handling
```

### **Development Dependencies**
- **Lute Runtime**: Complete Luau execution environment.
- **Tiniest Framework**: Testing infrastructure with custom Lute adaptations.

### **External Tool Dependencies** (via `rokit.toml`)
```toml
[tools]
lute = "luau-lang/lute@0.1.0-nightly.20250531"
stylua = "JohnnyMorganz/StyLua@2.1.0"
```

## Performance Optimizations & Strategies

### **AST Processing**
- **Single Traversal (Listener Rules):** Process all listener-based rules in one pass.
- **Rule Batching:** Group rules by AST node type interest to minimize redundant work. (Validated in Prototype)
- **Lazy Evaluation:** Compute parent maps and other expensive AST utilities on demand.
- **Unified AST:** A single AST representation is used for all rules.

### **Caching Strategy (Future & Validated in Prototype for Queries)**
- **AST Caching:** Cache parsed ASTs for frequently accessed/unchanged files.
- **Rule Result Caching:** Cache results of rule executions, especially for query-based rules.
- **Content-Based Invalidation:** Use file content hashes to invalidate caches.

### **Incremental Re-Analysis (Future)**
- **Demand-Driven Analysis:** Only re-run rules on AST nodes affected by changes.
- **Dependency Tracking:** Track rule dependencies to minimize cascade re-computation.

### **Error Handling**
- **Isolation:** Use `pcall` to isolate rule failures, allowing other rules to continue.
- **Efficient Collection:** Aggregate errors without stopping execution.

## Integration Patterns

### **Plugin API Design**
- **Factory Pattern:** Used for creating core components (`Registry.createRuleRegistry()`, `Engine.createRuleEngine()`).
- **Builder Pattern (Implicit):** Used for rule definition objects.

### **Testing Patterns**
- **TDD-Driven:** Strict test-first discipline.
- **Fixture-Based:** Use of code fixtures for testing rules against various Luau constructs.
- **Snapshot Testing:** For validating complex outputs and error messages, including inline snapshots.

## Future Technical Considerations

### **Planned Integrations & Features**
- **CLI Framework:** Robust command-line interface.
- **Hierarchical Configuration System:** Type-safe configuration loading (`luau-lint.toml`).
- **Language Server (LSP):** For IDE integration and real-time linting.
- **Advanced Query Engine:** Full implementation of tree-sitter inspired query language for rules.
- **Incremental Computation Engine:** Salsa-inspired engine for highly performant re-linting.
- **Cross-File Analysis:** Capabilities for rules that need to analyze multiple files.

### **Performance Targets (Validated in Prototypes for some aspects)**
- **File Processing:** Aim for <5 seconds for 1000+ files.
- **Memory Usage:** Target <100MB for typical projects.
- **Scalability Projections:**
    - 100 plugins: Load time <1s.
    - 1000 rules: Batching efficiency >70%.
    - 10,000 AST nodes (for query system): Indexing <50ms.