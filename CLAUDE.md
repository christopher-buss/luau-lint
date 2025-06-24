# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Environment Setup
```bash
# Install all development tools via Rokit
rokit install

# Install workspace dependencies via Pesde
pesde install
```

### Build and Development
```bash
# Type check a specific package
lute check packages/core/src/

# Type check all packages
lute check packages/*/src/

# Run the CLI (development)
lute run packages/cli/src/main.luau [args]

# Format code
stylua packages/ plugins/

# Verify Pesde workspace
pesde list

# Copy LICENSE to all packages
lune run scripts/copy-license.luau
```

### Testing
```bash
# Run all tests using the test runner
lute run run-tests.luau

# Run tests for a specific package using the tiniest framework directly
lute run packages/test-utils/src/tiniest/tiniest.luau tests/packages/core/

# Run specific test file
lute run tests/packages/core/error-handling.spec.luau
```

## Architecture Overview

### Plugin-First Architecture
This is a **plugin-first linter** where ALL rules are implemented as plugins, including the "recommended" rules. The core engine contains NO rule implementations - it only provides the execution framework.

### Package Structure
- **`packages/core`**: Rule execution engine, registry, AST traversal, issue reporting
- **`packages/plugin-api`**: Public API for rule authors (types, interfaces, utilities)
- **`packages/cli`**: Command-line interface that orchestrates the linting process
- **`packages/config`**: Configuration loading and validation
- **`packages/test-utils`**: Shared testing framework ("tiniest") and utilities
- **`plugins/recommended-rules`**: Default rule set implemented as a plugin

### Key Design Principles

#### Rule Engine (`packages/core/src/engine/engine.luau`)
- **Single-pass AST traversal**: Visits each node exactly once
- **Rule batching**: Only calls rules interested in specific node types
- **Error isolation**: Rule failures don't stop execution
- **Context management**: Provides isolated context per rule

#### Rule API (`packages/plugin-api/src/rule.luau`)
- **Listener pattern**: Rules return listener objects for AST node types
- **Type safety**: Full TypeScript-style type definitions
- **Auto-fix support**: Rules can provide automatic code fixes
- **Rich metadata**: Rules include categories, documentation URLs, dependencies

#### Plugin System
Rules are discovered via Pesde package metadata:
```toml
[luau-lint-plugin]
plugin = true
rules = ["generalized-iteration"]
categories = ["recommended", "performance"]
```

### Package Dependencies (Pesde Workspace)
```
luau_lint/cli
├── luau_lint/core
├── luau_lint/plugin_api
└── luau_lint/config

luau_lint/core
├── luau_lint/plugin_api
└── luau_lint/test_utils (dev)

luau_lint/recommended_rules
└── luau_lint/plugin_api
```

### Import Migration Status
⚠️ **Current State**: The codebase is mid-migration from relative imports to Pesde package names.

**Old pattern** (being phased out):
```luau
local Context = require("../context/context")
local Rule = require("@luau-lint/plugin-api/rule")
```

**New pattern** (target):
```luau
local Context = require("luau_lint/core/context")
local Rule = require("luau_lint/plugin_api")
```

### Rule Implementation Example
See `plugins/recommended-rules/src/rules/generalized-iteration.luau` for a complete rule implementation that:
- Detects `pairs()` and `ipairs()` usage in for-loops
- Suggests direct table iteration
- Provides automatic fixes
- Follows the listener pattern

### AST Traversal Pattern
The engine uses visitor keys (`packages/core/src/traversal/visitor-keys.luau`) to efficiently traverse Luau AST nodes, calling registered rule listeners only for node types they care about.

### Error Handling Strategy
- **Rule errors**: Isolated per rule, don't stop execution
- **Engine errors**: Collected and reported separately
- **Type errors**: Currently some Luau syntax parsing issues exist (not Pesde-related)

## Development Context

### Project Status
This project is currently in **Phase 2** of a monorepo migration. Phase 1 (Pesde workspace setup) is complete. Current focus is on completing import path migration and build verification.

### Key Documentation
- `docs/current-status-summary.md`: Real-time project status and next steps
- `docs/pesde-migration-action-plan.md`: Strategic roadmap and implementation phases
- `luau-lint-project-analysis.md`: Original comprehensive analysis

### Toolchain
- **Rokit**: Tool manager (installs Lute, StyLua, Pesde)
- **Pesde**: Package manager with workspace support
- **Lute**: Luau execution environment and type checker
- **StyLua**: Code formatter

### Multi-Runtime Support
The linter is designed to work across multiple Luau runtimes:
- **Roblox**: Game development platform
- **Lune**: Server-side Luau runtime
- **Pure Luau**: Standalone scripts

## AI Assistant Guidelines

### Search Tool Selection (Exa vs Tavily)

When performing web searches, choose between Exa and Tavily based on the search context:

#### Use **Exa Search** for:
- **Deep research**: Academic papers (`research_paper_search_exa`), company intelligence (`company_research_exa`)
- **Discovery tasks**: Finding novel content, competitive analysis (`competitor_finder_exa`)
- **Specialized domains**: GitHub repositories (`github_search_exa`), LinkedIn profiles (`linkedin_search_exa`)
- **Semantic queries**: Complex, nuanced search intent requiring understanding
- **Authoritative sources**: Wikipedia articles (`wikipedia_search_exa`) for factual information

#### Use **Tavily Search** for:
- **Current events**: Breaking news with `topic="news"` and time filtering
- **Fast facts**: Quick, reliable information retrieval for RAG systems
- **General web search**: Broad, comprehensive results with domain filtering
- **Content extraction**: Specific URL analysis (`tavily-extract`, `tavily-crawl`)
- **Autonomous tasks**: Consistent, reliable performance for automated workflows

#### Quick Decision Tree:
1. Academic/research-focused? → **Exa**
2. Current news/events needed? → **Tavily** 
3. Complex semantic query? → **Exa**
4. Fast, reliable facts? → **Tavily**
5. Building RAG system? → **Tavily**
6. Novel content discovery? → **Exa**