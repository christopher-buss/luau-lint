# APM Task Assignment: Plugin API Listener Pattern Architecture Implementation

## 1. Agent Role & APM Context

**Introduction:** You are activated as an Implementation Agent within the Agentic Project Management (APM) framework for the **Luau Linter** project. Your mission is to implement the core plugin API using the listener pattern architecture that enables users to create custom linting rules with ESLint-like developer experience.

**Your Role:** As an Implementation Agent, you must execute assigned tasks diligently, follow strict Test-Driven Development (TDD) principles, and log your work meticulously to the Memory Bank. You are responsible for implementing production-quality code that forms the foundation of the entire plugin ecosystem.

**Workflow:** You will work closely with the Manager Agent (via the User) and must maintain comprehensive documentation of your progress. All your work will be logged to the Memory Bank for future agents and project continuity.

## 2. Special TDD Requirements - ONE TEST AT A TIME

**CRITICAL INSTRUCTION:** This task requires a **modified TDD approach** with **human validation at each step**. You MUST follow this exact cycle:

1. **Write ONE test** that defines a specific piece of expected behavior
2. **Ask the user if the test is good** before proceeding
3. **Implement the minimal code** to make that ONE test pass
4. **Ask the user if the implementation is good** before proceeding
5. **Repeat** for the next piece of functionality

**DO NOT:**
- Write multiple tests at once
- Implement code for untested functionality
- Skip the user validation steps
- Move to the next test without user approval

**Test Framework:** Use the Tiniest framework (`@tiniest/tiniest_for_lute`) with describe/test/expect patterns as established in the project.

## 3. Test-Driven Development (TDD) Requirements

**TDD Validation Step:** Before beginning any code implementation, you MUST follow these Test-Driven Development requirements as outlined in `.github/instructions/test_driven_development.instructions.md`:

**Pre-Implementation Checklist:**
- Check for existing tests: `find tests/ -name "*.spec.luau" | grep -E "(plugin|rule|api)"`
- Review existing test files in `tests/` directory for patterns and coverage
- Identify gaps in test coverage for your assigned task
- Review existing fixtures in `tests/fixtures/` for test data patterns

**TDD Cycle Enforcement:** For ALL code implementation, follow this strict cycle:
1. **Test First:** Write ONE comprehensive test defining expected behavior BEFORE implementing any code
2. **User Validation:** Ask user to approve the test before proceeding
3. **Test Structure:** Use Tiniest framework with describe/test/expect patterns
4. **Run Tests:** Execute tests to ensure they fail initially (red phase)
5. **Implement:** Write minimal code to make the ONE test pass (green phase)
6. **User Validation:** Ask user to approve the implementation before proceeding
7. **Refactor:** Improve code while keeping tests green
8. **Repeat:** Move to next test only after user approval

**Test Coverage Requirements:**
- Happy path scenarios for each API method
- Edge cases and boundary conditions
- Error conditions and invalid inputs
- Integration points with AST traversal system
- Rule registration and execution scenarios

**Deliverable Requirement:** Your task deliverables MUST include both the test files and implementation files. Tests are not optional and must be validated by the user at each step.

## 4. Task Assignment

**Reference Implementation Plan:** This assignment corresponds to `Phase 2, Task 2.1 - Agent_Plugin_API: Plugin System Architecture` in the Implementation Plan (`.github/context/implementation-plan.md`).

**Objective:** Implement the core plugin API with listener pattern architecture that allows users to create custom linting rules with ESLint-like developer experience, following the comprehensive design specifications already created.

**Reference Documents:** You MUST study these documents before beginning:
- `.github/reports/architecture/api-interfaces.md` - Core API interface definitions
- `.github/reports/architecture/listener-pattern.md` - Listener pattern implementation details
- `.github/reports/architecture/rule-pattern-decision.md` - Architectural decision rationale
- `docs/guides/writing-rules.md` - Rule development guide

**Detailed Action Steps (ONE TEST AT A TIME):**

### Step 1: Rule Interface Implementation
- **Test First:** Write ONE test for basic Rule interface creation (id, description, category fields)
- **Ask User:** Validate test before implementing
- **Implement:** Create the Rule type definition as specified in `api-interfaces.md`
- **Ask User:** Validate implementation before proceeding

### Step 2: RuleContext Core Methods
- **Test First:** Write ONE test for RuleContext reporting functionality (`report` method)
- **Ask User:** Validate test before implementing
- **Implement:** Create RuleContext with basic reporting capability
- **Ask User:** Validate implementation before proceeding

### Step 3: Rule Registration System
- **Test First:** Write ONE test for rule registration with validation
- **Ask User:** Validate test before implementing
- **Implement:** Create rule registration system with basic validation
- **Ask User:** Validate implementation before proceeding

### Step 4: Node Type Batching
- **Test First:** Write ONE test for node type interest registration
- **Ask User:** Validate test before implementing
- **Implement:** Add node type batching for performance optimization
- **Ask User:** Validate implementation before proceeding

**Continue this pattern for all remaining functionality...**

**Critical Implementation Guidelines:**
- Follow the **listener pattern specification** exactly as defined in the architecture documents
- Implement **Rule interface** with listener-based node handling as defined in `api-interfaces.md`
- Create **RuleContext** with reporting, fixing, and AST utility methods
- Build **rule registration system** with node type batching for performance
- Use **single-pass AST traversal** with batched rule execution approach
- Ensure all code follows the established patterns in `examples/` directory

## 5. Expected Output & Deliverables

**Define Success:** Successful completion requires:
- Complete implementation of Rule interface as per design specifications
- Functional RuleContext with all specified utility methods
- Working rule registration and execution system
- Comprehensive test coverage with user-validated tests at each step
- All tests passing and demonstrating the listener pattern functionality
- Integration with existing AST parsing infrastructure from Lute

**Specify Deliverables:**
- `src/plugin/` directory with core plugin API implementation
- `src/plugin/rule.luau` - Rule interface and types
- `src/plugin/context.luau` - RuleContext implementation
- `src/plugin/registry.luau` - Rule registration system
- `src/plugin/engine.luau` - Rule execution engine
- `tests/plugin/` directory with comprehensive test coverage
- All tests following the ONE-AT-A-TIME validation approach
- Updated documentation in `.github/reports/` reflecting any implementation decisions

**Documentation Location Standard:** All design documents, reports, and architectural documentation should be placed in `.github/reports/` directory for centralized project documentation and future reference.

## 6. Performance and Integration Requirements

**Performance Considerations:**
- Implement **rule interest registration** to minimize unnecessary method calls
- Use **node type batching** so multiple rules can process the same node type in a single pass
- Design for **200+ rules** scenario with optimal performance
- Minimize memory allocation during rule execution

**Integration Requirements:**
- Must integrate seamlessly with Lute's AST parsing capabilities
- Follow existing code patterns established in `examples/` directory
- Ensure compatibility with existing test infrastructure in `tests/`
- Design API to be familiar to developers coming from ESLint

## 7. Memory Bank Logging Instructions

**Instruction:** Upon successful completion of this task, you **must** log your work comprehensively to the project's Memory Bank system.

**Format Adherence:** Adhere strictly to the established logging format. Ensure your log includes:
- Reference to `Phase 2, Task 2.1` in the Implementation Plan
- Clear description of the listener pattern implementation approach
- Each test-implementation cycle with user validation points
- Key architectural decisions made during implementation
- Code snippets for the core API interfaces created
- Integration points with existing Lute infrastructure
- Performance optimization techniques implemented
- Confirmation of successful execution with all tests passing

## 8. Clarification Instruction

**Instruction:** If any part of this task assignment is unclear, please state your specific questions before proceeding. Pay particular attention to:
- The ONE-TEST-AT-A-TIME requirement with user validation
- The listener pattern specifications in the reference documents
- Integration requirements with existing Lute infrastructure
- Performance optimization expectations for 200+ rules

## 9. Getting Started Checklist

Before writing your first test, complete this checklist:

1. [ ] Read all reference documents in `.github/reports/architecture/`
2. [ ] Review existing test patterns in `tests/` directory
3. [ ] Examine code examples in `examples/` directory
4. [ ] Understand Lute AST integration points
5. [ ] Plan your first test for Rule interface basic functionality
6. [ ] Confirm understanding of ONE-TEST-AT-A-TIME requirement

**Remember:** Start with ONE test, get user approval, then implement. Do not proceed to the next test without explicit user validation.
