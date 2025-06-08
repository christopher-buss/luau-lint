# Luau Linter: Product Overview

## Why This Project Exists

**Luau Linter** addresses critical gaps in the Luau/Roblox development ecosystem by providing modern static analysis tooling that the community has been lacking. While other languages have mature linting ecosystems (ESLint for JavaScript, Clippy for Rust), Luau developers have been limited to basic tools like Selene.

## Problems It Solves

### 1. **Lack of Extensible Linting**
- No plugin system for custom rules
- Limited rule customization options
- Difficult to add organization-specific checks

### 2. **Performance Issues with Existing Tools**
- Multiple AST traversals for different rules
- No rule batching or optimization
- Poor scalability for large codebases (1000+ files)

### 3. **Poor Developer Experience**
- Complex rule authoring process
- Limited auto-fix capabilities  
- Insufficient integration with modern workflows

### 4. **Modern Luau Features Underutilized**
- Existing tools don't encourage modern Luau patterns
- No guidance for migrating from legacy code
- Missing checks for performance optimizations

## How It Should Work

### **Core User Experience**
```bash
# Install and run
npm install -g luau-lint
luau-lint src/ --fix

# Results with modern formatting
✓ 15 files linted
⚠ 3 issues found (2 fixable)
→ Use modern iteration instead of ipairs() [auto-fixable]
→ Remove unused variable 'temp' [auto-fixable] 
→ Consider string interpolation over concatenation [suggestion]
```

### **Rule Author Experience**
```luau
-- Simple, intuitive rule creation
local myRule = {
    id = "no-unused-vars",
    title = "No unused variables", 
    description = "Variables should be used after declaration",
    category = "logical",
    fixable = "auto",
    
    create = function(context)
        return {
            LocalDeclaration = function(node)
                -- Rule logic here
                context:report({
                    message = "Variable is unused",
                    node = node,
                    fix = context:createFix(node.range, "")
                })
            end
        }
    end
}
```

### **Integration Experience**
- **IDE Integration**: Real-time linting in VS Code, IntelliJ
- **CI/CD Integration**: Fail builds on errors, auto-fix in PRs
- **Configuration**: ESLint-style config files with rule presets

## Developer Experience Innovations

Building on research from modern linter design, Luau Linter incorporates cutting-edge developer experience innovations:

### **1. Error-Only Reporting**
- **No Warning/Error Distinction**: Eliminates the training effect where developers ignore persistent warnings
- **Visual Clarity**: Yellow squiggles for lint errors vs. red for type errors
- **Gradual Onboarding**: Bulk suppressions enable teams to adopt rules incrementally without warning noise

### **2. Comprehensive Rule Reports**
- **Structured Messages**: Primary single-sentence explanation + detailed secondary information
- **Actionable Suggestions**: Clear fix recommendations with examples
- **Direct Documentation Links**: Shortcut URLs to rule documentation
- **Rich CLI Display**: Interactive focused view with syntax-highlighted code snippets, rich colors, and fallback for primitive terminals

### **3. Standardized Rule Design**
- **Consistent Naming**: No abbreviations, always plural, descriptive of what rules target
- **Standardized Options**: Object format with descriptive keys (`allow*`, `check*`, `ignore*` prefixes)
- **Clear Categories**:
  - **Formatting**: Don't change AST structure
  - **Stylistic**: Change AST but not logic
  - **Logical**: Change code logic and behavior

### **4. Type-Safe Configuration**
- **Runtime Validation**: Schema-validated configuration with clear error messages
- **IDE Support**: Full autocomplete and validation in configuration files
- **Composable Configs**: Extend and override configurations with type safety

### **5. Enhanced Testing Experience**
- **Inline Snapshot Tests**: Visual display of error spans with auto-updatable snapshots
- **Clear Test Maintenance**: Easier to understand and update test expectations
- **Rich Error Visualization**: See exactly where rules trigger and what they report

### **6. Native Workspace Support**
- **Monorepo-First**: Built-in support for multi-package projects
- **Hierarchical Configuration**: Package-specific overrides with inheritance
- **Cross-Package Analysis**: Rules that understand workspace boundaries and dependencies

## User Experience Goals

### **For Developers**
- **Zero Configuration**: Works out of the box with sensible defaults.
- **Fast Feedback**: Sub-second linting for typical projects.
- **Helpful Messages**: Clear, comprehensive rule reports with explanations, fix suggestions, and direct documentation links. Error-only reporting (no warnings) to encourage immediate action.
- **Modern Tooling**: Integration with contemporary development workflows, including native monorepo/workspace support.
- **Type-Safe Configuration**: Ensuring reliability and ease of setup.

### **For Teams**
- **Consistency**: Unified code style across team members
- **Customization**: Team-specific rules and configurations  
- **Automation**: Automated fixes in pull requests
- **Metrics**: Code quality insights and improvement tracking

### **For Rule Authors**
- **Simple API**: ESLint-inspired, intuitive Listener Pattern interface, with potential for future query-based definitions.
- **Powerful Context**: Rich `RuleContext` utilities for AST analysis, source manipulation, and reporting.
- **Type Safety**: Full Luau type support for rule development and configuration.
- **Testing Support**: Comprehensive testing utilities, including inline snapshot tests for clear error span visualization.
- **Standardized Design**: Clear naming and option conventions for rules.
- **Approachability**: Lower barrier to entry, encouraging community contributions and custom rule development.

### **For Organizations**
- **Scalability**: Handle large monorepos (1000+ files, 200+ rules)
- **Performance**: Single-pass execution, efficient rule batching
- **Extensibility**: Plugin ecosystem for domain-specific rules
- **Governance**: Centralized rule management and distribution

## Success Metrics

### **Technical Performance**
- Lint 1000+ files in <5 seconds
- Support 200+ rules simultaneously
- Memory usage <100MB for typical projects
- Single-pass AST traversal efficiency

### **Developer Adoption**
- Intuitive API that developers learn quickly (e.g., plugin setup < 5 mins, rule creation < 30 mins for experienced devs).
- Comprehensive documentation and examples.
- Active plugin ecosystem development, fostered by an approachable rule authoring experience.
- Positive community feedback and high contribution rates.
- Reduced configuration complexity compared to managing multiple tools (linter, formatter).

### **Code Quality Impact**
- Measurable reduction in bugs caught by linter
- Improved code consistency across projects
- Faster code review cycles with automated fixes
- Better adherence to modern Luau best practices