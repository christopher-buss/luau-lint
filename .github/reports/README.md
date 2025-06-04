# Project Reports

This directory contains comprehensive reports and documentation generated during the development of the luau-lint project.

## Directory Structure

### `/architecture/`
Contains core architecture design documents and specifications:

- **`core-design.md`** - Complete architectural overview including component relationships, CLI structure, configuration system, file processing pipeline, error handling strategies, and Mermaid diagrams
- **`config-examples.md`** - Comprehensive configuration examples for different project types (basic, Roblox, library, team, monorepo, performance-focused, plugin-enabled, multi-environment)
- **`api-interfaces.md`** - Complete API interface definitions with function signatures for all core components (Rule, ConfigurationManager, Pipeline, Reporter, AstVisitor, ErrorHandler, Cache, CLI, Plugin interfaces)

## Purpose

These reports serve as:

1. **Design Documentation** - Detailed specifications for implementation teams
2. **Reference Material** - API contracts and configuration schemas
3. **Decision Records** - Architectural decisions and rationale
4. **Implementation Guides** - Examples and patterns for developers

## Usage

- **Developers**: Reference these documents when implementing core components
- **Reviewers**: Use for architectural validation and code review
- **Maintainers**: Update as the project evolves and new requirements emerge
- **Contributors**: Understand the project architecture and design patterns

## Maintenance

These reports should be updated when:
- Core architecture changes are made
- New configuration options are added
- API interfaces are modified
- New project types or examples are needed

## Related Documentation

- **Memory Bank Logs**: `.github/memory/` - Contains development progress and decision logs
- **Context Documents**: `.github/context/` - Contains project planning and requirements
- **Implementation Plan**: `.github/context/implementation-plan.md` - Overall project roadmap
