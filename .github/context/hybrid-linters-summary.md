# Hybrid Linters and Modern Linter Design: Comprehensive Summary

*A synthesis of "Hybrid Linters: The Best of Both Worlds" and "If I Wrote a Linter" series by Joshua K. Goldberg*

## Executive Summary

This document synthesizes insights from multiple articles about the future of web development linters, focusing on hybrid architectures that combine native speed with TypeScript approachability, and comprehensive developer experience improvements.

## Core Concepts

### The Hybrid Linter Architecture

**Definition**: A linter that uses native speed languages (Rust, Go) for performance-critical components while maintaining TypeScript/JavaScript for user-facing functionality.

**Key Components**:
- **Native Speed**: File intake and type information processing
- **JavaScript/TypeScript**: Coordination logic and lint rules
- **Rationale**: Achieves ~90% of native performance while maintaining developer approachability

### Performance Justifications

**Performance Data** (from proof of concept):
- ~90ms to lint 100 files
- ~350ms to lint 1,000 files  
- ~2.9s to lint 10,000 files

**Why Hybrid Works**:
- 70% of linting time is spent on file intake and type information
- JavaScript engines excel at optimizing lint rule data structures
- Most linting occurs on changed files, not entire codebases
- Native linters with JS plugins already operate at hybrid speeds

## Architecture Principles

### 1. TypeScript-First Type Awareness

**Current Problem**: 
- TypeScript is the only tool providing full TypeScript type information
- Typed linting performance is poor with current TypeScript 5.x
- Type checking effectively runs twice (tsc + typed linting)

**Solution**:
- Use TypeScript's Go port (10x performance improvement)
- Make typed linting always available by default
- Use TypeScript's native AST instead of dual ESTree/TypeScript conversion

### 2. Built-In Language Support

**Core Languages** (first-party support):
- JavaScript and TypeScript
- JSON
- Markdown  
- YML

**Benefits**:
- Eliminates need for separate language-specific plugins
- Consistent configuration across all file types
- Reduced setup complexity

### 3. Formatting Coordination

**Concept**: Linter coordinates both linting and formatting
- Provides "postlint" hooks for formatting
- Single configuration file for both concerns
- Eliminates separate formatter configuration

### 4. Cross-File Intelligence

**Enhanced Capabilities**:
- Native support for embedding within TypeScript language service
- Rich cross-file fixes and suggestions
- File system operations (renames, permissions)
- Programmable fix/suggestion targeting

## Developer Experience Innovations

### 1. Error-Only Reporting

**Rationale**: Eliminate warning/error distinction
- Warnings tend to persist and train developers to ignore reports
- Use yellow squiggles for all lint errors vs. red for type errors
- Gradual onboarding through bulk suppressions, not warnings

### 2. Comprehensive Rule Reports

**Structure**:
- **Primary**: Single sentence explaining the issue
- **Secondary**: Detailed explanation
- **Suggestions**: Fix recommendations  
- **Shortcut URL**: Direct link to documentation

**Rich CLI Display**:
- Interactive focused view (few reports at a time)
- Syntax-highlighted code snippets
- Rich colors and formatting
- Fallback for primitive terminals

### 3. Standardized Rule Design

**Naming Conventions**:
- No abbreviations (e.g., `constant-binary-expressions` not `no-const-bin-expr`)
- Always plural (describes what rules target)
- No prefixes (rules named for behavior/syntax they target)

**Option Conventions**:
- Object format with descriptive keys
- Consistent prefixes: `allow*`, `check*`, `ignore*`
- Always plural option names
- Boolean options default to `false`
- Array options default to empty

**Categories**:
- **Formatting**: Don't change AST
- **Stylistic**: Change AST but not logic
- **Logical**: Change code logic

### 4. Type-Safe Configuration

**Plugin Definition**:
```typescript
import { createRule, createPlugin } from "@joshuakgoldberg/linter";
import { z } from "zod";

const someRule = createRule({
  options: {
    option: z.string(),
  },
});

export const myPlugin = createPlugin({
  name: "My Plugin", 
  rules: [someRule],
  settings: {
    mySetting: z.string(),
  },
});
```

**Usage**:
```typescript
// if-i-wrote-a-linter.config.ts
import { defineConfig, ts } from "@joshuakgoldberg/linter";

export default defineConfig({
  ignore: ["lib/"],
  use: [
    {
      glob: "**/*.ts",
      rules: [
        ts.configs.logical,
        ts.configs.stylistic,
        ts.rules({
          ruleA: false,
          ruleB: true,
          ruleC: { someOption: true },
        }),
      ],
    },
  ],
});
```

### 5. Enhanced Testing

**Inline Snapshot Tests**:
```typescript
ruleTester.run(rule, {
  invalid: [
    {
      code: `let value = 123;`,
      output: `const value = 123;`, 
      report: `
        let value = 123;
            ^^^^^
            [preferConst] Prefer using 'const' for variables that are never reassigned.
      `,
    },
  ],
});
```

**Benefits**:
- Visual display of error spans
- Auto-updatable snapshots
- Clearer test maintenance

### 6. Workspace Support

**Native Monorepo Support**:
```typescript
// Root config
export default defineConfig({
  use: [
    { glob: "**/*.ts", rules: [ts.configs.logical] }
  ],
  workspaces: ["packages/*"],
});

// Package-specific config  
export default defineConfig({
  from: "../..",
  use: [
    { glob: "**/*.ts", rules: [example.configs.recommended] }
  ],
});
```

## Ecosystem Benefits

### Developer Approachability

**JavaScript/TypeScript Rules Advantages**:
- Most web developers know JS/TS, not Rust/Go
- Lower barrier to entry for custom rules
- Direct import of shared packages/design tokens
- Larger contributor base leads to better tools

**Evidence**:
- Custom rules are common in large/long-lived teams
- Teams writing custom rules prefer familiar languages
- Dual-language ecosystems have fewer contributors

### Performance vs. Approachability Balance

**Hybrid Approach Benefits**:
- Retains ~90% of native speed performance
- Maintains JavaScript ecosystem compatibility
- Enables gradual migration from existing tooling
- Supports rich editor integrations

**Trade-offs Acknowledged**:
- Slightly slower than pure native implementations
- Additional complexity in architecture
- Requires FFI or IPC coordination

## Implementation Considerations

### Technical Challenges

**FFI vs. IPC vs. WebAssembly**:
- **FFI**: Fastest but shared memory complexity
- **IPC**: Safer but serialization overhead  
- **WebAssembly**: Ideal but Go output still suboptimal

**Current Recommendation**: FFI for maximum performance until WebAssembly improves

### Configuration Philosophy

**Principles**:
- Type safety throughout (rules, options, settings)
- Clear separation of concerns (glob, rules, settings)
- Explicit over implicit configuration
- Standard Schema validation for runtime safety

### Migration Strategy

**From Current Tools**:
- Built-in TypeScript support eliminates extension rules
- Single tool replaces linter + formatter + type checker coordination
- Gradual onboarding through bulk suppressions
- Native workspace support for monorepos

## Future Considerations

### Potential Challenges

**Adoption Barriers**:
- Significant departure from current ESLint ecosystem
- Learning curve for new configuration format
- Migration effort for existing large codebases

**Technical Unknowns**:
- FFI stability across platforms
- Performance at extreme scale
- Editor extension integration complexity

### Success Metrics

**Developer Experience**:
- Reduced configuration complexity
- Faster onboarding for new team members
- Higher adoption of custom rules
- Improved rule contribution rates

**Performance Goals**:
- Match or exceed native linter speeds for common workflows
- Eliminate duplicate type checking in CI
- Sub-second feedback in development

## Conclusion

The hybrid linter approach represents a thoughtful balance between the performance benefits of native speed tooling and the approachability advantages of JavaScript/TypeScript development. By strategically applying native optimization to performance bottlenecks while maintaining developer-friendly interfaces for customization and extension, this approach could deliver both the speed modern development demands and the accessibility that fosters healthy open-source ecosystems.

The comprehensive developer experience improvements - from type-safe configuration to rich error reporting to standardized conventions - address many pain points in current linting workflows. While implementation challenges exist, the potential for creating a more unified, performant, and approachable linting ecosystem makes this an compelling direction for the future of web development tooling.

---

*This summary synthesizes content from:*
- *"Hybrid Linters: The Best of Both Worlds" (March 2025)*
- *"If I Wrote a Linter, Part 1: Architecture" (May 2025)*  
- *"If I Wrote a Linter, Part 2: Developer Experience" (May 2025)*

*By Joshua K. Goldberg - typescript-eslint and ESLint team member*
