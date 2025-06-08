# Development Tasks

This file documents the specific tasks and workflows needed to move the Luau Linter project forward, based on the current implementation state and strategic analysis.

## Current Implementation Gap Analysis

**Critical Finding**: The project has completed sophisticated Phase 2 work (Plugin API) but skipped foundational Phase 1 requirements, creating a dependency gap that prevents basic functionality.

## Task 1: Foundation Recovery - CLI Interface
**Priority**: URGENT  
**Dependencies**: None  
**Estimated Effort**: 2-3 days  

### Goal
Create a basic command-line interface that allows users to run the linter on files and directories.

### Files to Create/Modify
- `src/cli/main.luau` - Main CLI entry point
- `src/cli/args.luau` - Command-line argument parsing
- `src/cli/output.luau` - Output formatting (text, JSON)
- `src/cli/exit-codes.luau` - Standard exit codes

### Implementation Steps
1. **Create basic CLI structure**
   - Implement argument parsing using Lute's process APIs
   - Support basic flags: `--help`, `--version`, `--config`, `--fix`
   - Handle file/directory path arguments

2. **Integrate with Plugin API**
   - Import and use existing `createLinter()` function
   - Connect CLI file discovery with rule engine
   - Route linting results to output formatters

3. **Add output formatting**
   - Implement text formatter for human-readable output
   - Add JSON formatter for tooling integration
   - Include statistics and error reporting

4. **Create main executable**
   - Set up proper entry point that can be executed via Lute
   - Handle errors gracefully and return appropriate exit codes

### Success Criteria
- Users can run `lute src/cli/main.luau <files>` to lint Luau files
- Output shows rule violations in a clear format
- CLI handles basic error cases (file not found, parse errors)

---

## Task 2: File Processing Pipeline
**Priority**: URGENT  
**Dependencies**: CLI Interface (Task 1)  
**Estimated Effort**: 2-3 days  

### Goal
Implement file discovery, filtering, and AST parsing integration to bridge CLI and Plugin API.

### Files to Create/Modify
- `src/core/file-processor.luau` - Main file processing logic
- `src/core/file-discovery.luau` - File discovery and filtering
- `src/core/ast-integration.luau` - Lute AST parsing integration

### Implementation Steps
1. **File Discovery System**
   - Recursive directory traversal using Lute's `fs` APIs
   - Support for `.luau` and `.lua` file extensions
   - Basic ignore patterns (`.git/`, `node_modules/`, etc.)

2. **AST Parsing Integration**
   - Connect with Lute's Luau parser (`@lute/luau`)
   - Handle parsing errors gracefully
   - Convert Lute AST format to Plugin API expectations

3. **Parallel Processing Foundation**
   - Basic parallel file processing using Lute's task system
   - Error isolation - single file errors don't halt entire process
   - Progress reporting for large directories

4. **Integration Layer**
   - Connect file processing with rule engine
   - Aggregate results from multiple files
   - Handle cross-file dependencies (future foundation)

### Success Criteria
- CLI can process directories recursively
- Individual file parsing errors don't crash the entire process
- Plugin API receives properly formatted AST nodes
- Performance is reasonable for medium-sized projects (100+ files)

---

## Task 3: Basic Configuration System
**Priority**: HIGH  
**Dependencies**: File Processing Pipeline (Task 2)  
**Estimated Effort**: 1-2 days  

### Goal
Implement basic `luau-lint.toml` configuration support for rule enabling/disabling.

### Files to Create/Modify
- `src/config/loader.luau` - Configuration file loading
- `src/config/schema.luau` - Configuration validation
- `src/config/defaults.luau` - Default configuration

### Implementation Steps
1. **TOML Configuration Loading**
   - Use `@batteries/toml` for parsing
   - Support basic rule enabling: `[rules]` section with `rule-id = true/false`
   - Handle configuration file discovery (project root)

2. **Schema Validation**
   - Validate configuration structure
   - Provide helpful error messages for invalid configs
   - Support basic rule options

3. **Integration with Plugin API**
   - Connect configuration with `RuleRegistry.setRuleEnabled()`
   - Pass rule options to registry
   - Override defaults with user configuration

### Success Criteria
- Users can create `luau-lint.toml` to enable/disable rules
- Invalid configurations show helpful error messages
- Plugin API respects configuration settings

---

## Task 4: Built-in Rules Implementation
**Priority**: HIGH  
**Dependencies**: Configuration System (Task 3)  
**Estimated Effort**: 3-4 days  

### Goal
Implement essential built-in rules using the Plugin API to provide immediate value.

### Files to Create/Modify
- `src/rules/unused-variables.luau` - Detect unused local variables
- `src/rules/undefined-variables.luau` - Detect undefined variables
- `src/rules/modern-iteration.luau` - Suggest modern iteration patterns
- `src/rules/index.luau` - Export all built-in rules

### Implementation Steps
1. **Port Existing POC Rules**
   - Convert existing `ipairs`/`pairs` detection to listener pattern
   - Add comprehensive configuration options
   - Implement auto-fix capabilities where possible

2. **Implement Core Rules**
   - **unused-variables**: Track variable declarations and usage
   - **undefined-variables**: Track variable definitions and references
   - **modern-iteration**: Detect legacy iteration patterns

3. **Add Rule Metadata**
   - Proper categorization ("logical", "stylistic", "formatting")
   - Documentation URLs and examples
   - Fixable flags for auto-fix support

4. **Integration and Testing**
   - Register rules in default configuration
   - Add comprehensive test cases
   - Validate rule performance with Plugin API

### Success Criteria
- At least 3-5 useful built-in rules working end-to-end
- Rules follow Plugin API patterns consistently
- Rules have good test coverage and examples

---

## Task 5: End-to-End Integration Testing
**Priority**: MEDIUM  
**Dependencies**: Built-in Rules (Task 4)  
**Estimated Effort**: 1-2 days  

### Goal
Validate the complete linting workflow from CLI to rule execution.

### Implementation Steps
1. **Integration Test Suite**
   - Test complete CLI → file processing → rule execution → output flow
   - Test error handling at each integration point
   - Validate configuration loading and rule enabling/disabling

2. **Performance Validation**
   - Test with medium-sized projects (100+ files)
   - Measure and validate performance targets
   - Ensure rule batching is working effectively

3. **User Experience Testing**
   - Test with real Luau projects
   - Validate output formatting and error messages
   - Test configuration file creation and usage

### Success Criteria
- Complete linting workflow works reliably
- Performance meets basic requirements
- User experience is intuitive and helpful

---

## Post-Foundation Enhancement Tasks

### Task 6: Advanced Configuration System
**Dependencies**: Task 5 completion  
**Implementation**: Hierarchical configuration, rule options, cascading configs

### Task 7: Auto-fix Engine Implementation  
**Dependencies**: Task 5 completion  
**Implementation**: Extend Plugin API with comprehensive auto-fix capabilities

### Task 8: IDE Integration & Language Server
**Dependencies**: Task 6 completion  
**Implementation**: LSP server for real-time linting in editors

### Task 9: Performance Optimization & Caching
**Dependencies**: Task 7 completion  
**Implementation**: Caching system, incremental analysis, parallel processing optimization

---

## Development Workflow Guidelines

### Phase Recovery Strategy
1. **Foundation First**: Complete Tasks 1-3 before advancing to rule implementation
2. **Integration Validation**: Test each integration point thoroughly
3. **Plugin API Preservation**: Maintain the excellent Plugin API architecture while building foundations
4. **Incremental Delivery**: Each task should produce a working, testable increment

### Testing Strategy
- **Unit Tests**: Continue TDD approach established in Plugin API
- **Integration Tests**: New focus on end-to-end workflow testing
- **Performance Tests**: Validate scalability claims (200+ rules, 1000+ files)
- **User Experience Tests**: Real-world usage validation

### Quality Standards
- Maintain the high code quality established in Plugin API work
- Comprehensive error handling using `@batteries/result`
- Full type safety with strict Luau typing
- Extensive documentation and examples

This task breakdown provides a clear path from the current state (sophisticated Plugin API) to a functional linter while preserving the excellent architectural work already completed.