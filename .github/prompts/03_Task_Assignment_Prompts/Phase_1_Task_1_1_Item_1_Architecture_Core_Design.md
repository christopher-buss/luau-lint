# APM Task Assignment: Core Architecture Patterns Design

## 1. Agent Role & APM Context

**Introduction:** You are activated as an Implementation Agent within the Agentic Project Management (APM) framework for the **Luau Linter** project.

**Your Role:** As an Implementation Agent, you are responsible for executing assigned tasks diligently, following the technical specifications provided, adhering to Test-Driven Development (TDD) principles, and logging your work meticulously to maintain project continuity and enable effective handovers.

**Workflow:** You will receive task assignments from the Manager Agent (via the User), execute them according to the provided specifications, and report back through the established Memory Bank logging system. Your work will form the foundation for subsequent agents and project phases.

**Test-Driven Development (TDD) Requirements:** This project follows strict TDD principles as outlined in `.github/instructions/test_driven_development.instructions.md`. For any code implementation tasks, you MUST:
- Check for existing tests BEFORE writing any code
- Create comprehensive tests BEFORE implementing functionality
- Follow the test-first development cycle: Review/Create Tests → Run Tests (should fail) → Implement Code → Run Tests (should pass) → Refactor
- Use the Tiniest testing framework (`@tiniest/tiniest_for_lute`) for all test creation
- Ensure test coverage for happy path, edge cases, and error conditions

## 2. Test-Driven Development (TDD) Requirements

**TDD Validation Step:** Before beginning any code implementation, you MUST follow these Test-Driven Development requirements as outlined in `.github/instructions/test_driven_development.instructions.md`:

**Pre-Implementation Checklist:**
- Check for existing tests: `find tests/ -name "*.luau" | grep architecture`
- Review any existing test files for patterns and coverage
- Identify gaps in test coverage for your assigned task

**TDD Cycle Enforcement:** For ALL code implementation, follow this strict cycle:
1. **Test First:** Write comprehensive tests defining expected behavior BEFORE implementing any code
2. **Test Structure:** Use Tiniest framework (`@tiniest/tiniest_for_lute`) with describe/test/expect patterns
3. **Run Tests:** Execute tests to ensure they fail initially (red phase)
4. **Implement:** Write minimal code to make tests pass (green phase)
5. **Refactor:** Improve code while keeping tests green

**Test Coverage Requirements:**
- Happy path scenarios for all core components
- Edge cases and boundary conditions
- Error conditions and invalid inputs
- Integration points with other components (CLI, config system, file processing)

**Deliverable Requirement:** Your task deliverables MUST include both the test files and implementation files. Tests are not optional.

## 3. Task Assignment

**Reference Implementation Plan:** This assignment corresponds to `Phase 1, Task 1.1, Item 1` in the Implementation Plan (`.github/context/implementation-plan.md`).

**Objective:** Design core architecture patterns for the fundamental linter architecture, establishing the main entry point, CLI structure, configuration system, file processing pipeline, and error handling strategies.

**Detailed Action Steps:**

You must design and document the following core architecture components:

1. **Main Entry Point and CLI Argument Parsing Structure:**
   - Design the main entry point structure for the Luau linter executable
   - Define command line argument parsing architecture (file paths, configuration files, flags, options)
   - Plan the CLI command structure and subcommands (if applicable)
   - Design help system and version information display architecture
   - Plan basic exit codes for different scenarios (success, warnings, errors, configuration issues)

2. **Project Configuration System (luau-lint.toml format):**
   - Design the configuration file format specification using TOML
   - Define configuration schema for rule management (enabling/disabling rules)
   - Plan configuration inheritance hierarchy (project, user, global levels)
   - Design configuration validation and error handling mechanisms
   - Define configuration file discovery and loading strategy

3. **File Discovery and Filtering Mechanisms:**
   - Design file discovery algorithms for .luau and .lua extensions
   - Plan include/exclude pattern systems (glob patterns, regex support)
   - Design directory traversal and recursive file finding logic
   - Plan integration with .gitignore and custom ignore patterns
   - Design file filtering pipeline for performance optimization

4. **Error Handling and Logging Strategies:**
   - Design comprehensive error handling hierarchy and classification
   - Plan logging levels and output formatting (debug, info, warn, error)
   - Design error reporting mechanisms for different failure types
   - Plan user-friendly error messages and diagnostic information
   - Design error recovery and graceful degradation strategies

5. **Hybrid Linter Architecture Integration:**
   - **CRITICAL GUIDANCE:** Follow hybrid linter principles from project context - leverage Lute for AST parsing performance
   - Design integration patterns with Lute's official Luau parser
   - Plan AST processing pipeline that maximizes Lute's capabilities
   - Design performance-optimized parsing strategy using Lute's visitor pattern established in POC
   - Plan memory management and resource utilization for large codebases

**Provide Necessary Context/Assets:**

- **Project Context:** This is a modern Luau linter aimed at providing ESLint-like extensibility while addressing limitations of existing tools like Selene
- **Technical Foundation:** Built on Lute runtime with access to official Luau parser
- **Existing Assets:** Reference the working POC in `examples/concept.luau` for established patterns
- **Configuration Files:** Existing `.luaurc` shows current Lute integration setup
- **Target Architecture:** Plugin-based system with autofix capabilities and cross-file analysis

**Constraints:**
- Must integrate seamlessly with existing Lute setup (see `rokit.toml` and `.luaurc`)
- Architecture must support future plugin system development (Phase 2)
- Must be extensible for autofix capabilities (Phase 3)
- Should follow Luau/Lute best practices and conventions

## 4. Expected Output & Deliverables

**Define Success:** Successful completion means producing a comprehensive architectural design document that clearly defines all core system components, their interactions, and implementation strategies, along with comprehensive test coverage for any implemented components.

**Specify Deliverables:** 
1. **Architecture Design Document** (`.github/reports/core-architecture-design.md`) containing:
   - Detailed component diagrams and interaction flows
   - Configuration file format specification with examples
   - CLI interface specification with command examples
   - Error handling hierarchy and logging strategy
   - File processing pipeline design
   - Integration plan with Lute/Luau parser

2. **Configuration Schema Examples:**
   - Sample `luau-lint.toml` configuration files (`.github/reports/config-examples/`)
   - Schema validation rules and documentation

3. **API Interface Definitions:**
   - Core module interface specifications (`.github/reports/api-specifications.md`)
   - Function signatures for key components
   - Data structure definitions

4. **Test Files** (if any code implementation is included):
   - Comprehensive test coverage using Tiniest framework
   - Test files following the naming convention: `*_test.luau`
   - Test coverage for all implemented components

**Format:** All documentation should be in Markdown format with clear sections, code examples, and architectural diagrams (ASCII art or mermaid syntax where helpful).

## 5. Memory Bank Logging Instructions

**Instruction:** Upon successful completion of this task, you **must** log your work comprehensively to the project's Memory Bank file at `.github/memory/Phase_1_Foundation/Task_1_1_Architecture_Log.md`.

**Format Adherence:** Adhere strictly to the established logging format as defined in `.github/prompts/02_Utility_Prompts_And_Format_Definitions/Memory_Bank_Log_Format.md`. Ensure your log includes:
- A reference to the assigned task `Phase 1, Task 1.1, Item 1` in the Implementation Plan
- A clear description of the architectural design decisions made
- Key design documents and specifications created
- Any critical architectural choices and their rationale
- Links to created files and documentation
- Test coverage information (if applicable)
- Confirmation of deliverables completion

## 6. Clarification Instruction

**Instruction:** If any part of this task assignment is unclear, please state your specific questions before proceeding. The architecture design is foundational to the entire project, so clarity is essential.
