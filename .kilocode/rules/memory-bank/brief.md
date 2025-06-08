# Luau Linter: Project Foundation & Scope Document

## Project Overview

**Luau Linter** is a modern, extensible linting tool for the Luau programming language, designed to provide robust static analysis, enforce code quality, and enable a thriving plugin ecosystem. Inspired by the success of ESLint and informed by cutting-edge research in linter and language tooling, Luau Linter aims to deliver high performance, developer-friendly extensibility, and future-proof architecture for the Roblox/Luau community.

## Current Strategic Status

**Critical Situation**: The project has completed sophisticated Phase 2 work (Plugin API architecture) but lacks foundational Phase 1 infrastructure, creating a **dependency gap** that prevents basic functionality. We have a world-class internal engine but no way for users to actually run the linter.

**Immediate Focus**: **Foundation Gap Recovery** - Build operational foundations (CLI, configuration, file processing) to create a functional linter that showcases the excellent Plugin API architecture.

## Core Goals

1.  **Extensibility:** Enable third-party rule and plugin development with a simple, powerful API. The primary rule definition mechanism is the **Listener Pattern** ✅ **COMPLETE**, with considerations for future **Query-Based** rule support for declarative pattern matching.
2.  **Performance:** Achieve **single-pass AST traversal** for all rules ✅ **COMPLETE**, **efficient rule batching** by node type ✅ **COMPLETE**, and scalable performance for large codebases (1000+ files, 200+ rules). This includes leveraging Lute for AST parsing performance and aiming for sub-second feedback in development.
3.  **Developer Experience:** Provide an intuitive, ESLint-like API for rule authors ✅ **COMPLETE**, comprehensive documentation ✅ **COMPLETE**, rich error reporting ✅ **COMPLETE**, type-safe configuration ❌ **PENDING**, and a low barrier to entry for community contributions.
4.  **Modern Architecture:** Adopt a **Progressive Hybrid Approach** ✅ **COMPLETE**, incorporating innovations from modern linters (e.g., Rust-based, query-based systems like tree-sitter, incremental computation as in rust-analyzer). This includes a unified AST representation ✅ **COMPLETE**, smart caching ❌ **PENDING**, and incremental re-analysis capabilities ❌ **PENDING**.
5.  **Robust Testing:** Enforce strict TDD ✅ **COMPLETE**, provide comprehensive test infrastructure (including inline snapshot tests) ✅ **COMPLETE**, and ensure high test coverage for all core and plugin components ✅ **COMPLETE**.
6. **Production Readiness:** Support IDE integration ❌ **PENDING**, configuration cascading ❌ **PENDING**, autofix ⚠️ **PARTIAL** (infrastructure complete), cross-file analysis ❌ **PENDING**, and robust error handling ✅ **COMPLETE** for real-world use.

## Core Requirements

- **Plugin System:**
  - Listener pattern for rule implementation (single AST traversal, rule batching)
  - Query-based rule support for declarative pattern matching
  - Plugin API with lifecycle hooks, configuration, and metadata
  - RuleContext utilities for reporting, fixing, and AST navigation
- **Rule Engine:**
  - Efficient execution of multiple rules per node type
  - Issue collection, aggregation, and fix application
  - Performance monitoring and error isolation
- **Testing Infrastructure:**
  - Tiniest-based test framework with fixtures, integration, and regression tests
  - Automated test execution and coverage reporting
- **Configuration System:**
  - Hierarchical config loading (project, user, global)
  - Rule enabling/disabling, plugin loading, and schema validation
- **CLI & File Processing:**
  - Command-line interface for file selection, config, and output
  - File filtering, parallel processing, and AST parsing integration
- **Documentation & Ecosystem:**
  - Centralized, versioned documentation for users and plugin authors
  - Memory Bank and logging for agentic project management

## Project Scope

**In Scope:**
- Core linter engine and plugin system
- Built-in and third-party rule support
- Query-based and listener-based rule APIs
- Comprehensive test and validation framework
- CLI, configuration, and file processing pipeline
- IDE integration and autofix support
- Documentation, onboarding, and community contribution guides

**Out of Scope (Initial Release):**
- Full language server implementation (may be future phase)
- Marketplace for plugin distribution (future phase)
- Deep cross-project analysis (future phase)

## Architectural Principles

-   **Single Source of Truth:** This document defines the project’s scope, requirements, and goals. All architectural and implementation decisions must align with it.
-   **Research-Informed:** Design choices are grounded in analysis of modern linter architectures (e.g., ESLint, Clippy, Oxc, tree-sitter, rust-analyzer) and validated through prototypes. Key decisions include the Listener Pattern for rules and a Progressive Hybrid Architecture.
-   **TDD-Driven:** All code and features must be developed with strict test-first discipline, utilizing a comprehensive testing framework.
-   **Performance-First:** Optimize for large-scale, real-world codebases and plugin ecosystems through single-pass traversal, rule batching, caching, and incremental analysis.
-   **Community-Oriented:** Lower barriers for plugin authors and contributors; prioritize clear documentation, intuitive APIs, and extensibility.
-   **Progressive Hybrid Approach:** Start with a stable foundation (enhanced ESLint-style) and incrementally adopt advanced patterns like query-based rules and full incremental computation, balancing performance with developer approachability.

## References
- `.github/reports/Plugin_API_Design_Document.md` — Plugin system and modern linter research
- `.github/reports/architecture/rule-pattern-decision.md` — Listener pattern rationale
- `.github/reports/prototypes/VALIDATION_REPORT.md` — Prototype validation and performance benchmarks
- `.github/context/implementation-plan.md` — Implementation phases and task breakdown
- `.github/reports/IMPLEMENTATION_PROGRESS_REPORT.md` — Current implementation state and dependency gap analysis

## Current Implementation Status

### ✅ **Phase 2 Complete (Plugin API)**
- **[`src/plugin/plugin-api.luau`](src/plugin/plugin-api.luau:1)** (203 lines) - Complete main API
- **[`src/plugin/engine.luau`](src/plugin/engine.luau:1)** (387 lines) - Full rule execution engine with single-pass traversal and rule batching
- **[`src/plugin/registry.luau`](src/plugin/registry.luau:1)** (407 lines) - Complete rule registration system with node type batching
- **[`src/plugin/context.luau`](src/plugin/context.luau:1)** - Rich context API for rule authors
- **[`src/plugin/rule.luau`](src/plugin/rule.luau:1)** - Advanced type definitions and validation
- **Testing Infrastructure** - 35 passing tests with comprehensive validation

### ❌ **Phase 1 Missing (Foundation)**
- **CLI Interface** - No command-line interface for users
- **Configuration System** - No `luau-lint.toml` support
- **File Processing Pipeline** - No file discovery or source text reading
- **Integration Layer** - No way to connect Plugin API with file processing

### 🎯 **Immediate Next Steps**
1. **Foundation Recovery** - Build CLI, file processing, and configuration systems
2. **Plugin API Integration** - Connect foundation layer with existing Plugin API
3. **Built-in Rules** - Implement essential rules using the Plugin API
4. **End-to-End Validation** - Test complete linting workflow

---

**This document is the canonical reference for project scope, requirements, and goals. All future design, implementation, and documentation must be consistent with its contents.**
