# Rule API Finalization Questions

*Reference document for systematically finalizing the Rule API design*

## Current Status
- Working on standalone rule structure in `examples/example-rule.luau`
- Need to solidify API before moving to plugin system implementation
- Focus on making the rule API complete and intuitive

## Well-Defined Areas ✅
1. **Rule metadata structure** - The `Rule` type looks comprehensive
2. **Basic AST node types** - Good foundation with `ASTNode`, `CallExpression`, etc.
3. **Fix system** - `RuleFixer` provides good auto-fix capabilities

## Questions to Address

### 1. Visitor Integration with Lute ✅ RESOLVED
**Decision:** Use comprehensive enum-based registration covering all 56 Lute visitor methods

**Analysis Completed:** Created complete mapping showing `AstExpr | AstStat | AstType` covers 42/56 methods. Extended to include TypePack, Token, Local, and TableItem for 100% coverage.

**Final Approach:**
```luau
type VisitorNodeType = 
    | "Block" | "If" | "While" | "Repeat" | "Return" | "LocalDeclaration"
    | "For" | "ForIn" | "Assign" | "CompoundAssign" | "Function" 
    | "LocalFunction" | "TypeAlias" | "StatTypeFunction"
    | "Expression" | "LocalReference" | "Global" | "Call" | "Unary" | "Binary"
    | "AnonymousFunction" | "Table" | "TableItem" | "IndexName" | "IndexExpr"
    | "Group" | "InterpolatedString" | "TypeAssertion" | "IfExpression"
    | "Nil" | "String" | "Boolean" | "Number" | "Varargs"
    | "TypeReference" | "TypeBoolean" | "TypeString" | "TypeTypeof" 
    | "TypeGroup" | "TypeUnion" | "TypeIntersection" | "TypeArray"
    | "TypeTable" | "TypeFunction"
    | "TypePackExplicit" | "TypePackGeneric" | "TypePackVariadic"
    | "Token" | "Local"
```

**Benefits:** Type-safe registration, complete Lute coverage, direct method mapping (`"ForIn"` → `visitForIn`)

### 2. Rule Options/Configuration ✅ RESOLVED
**Decision:** Remove options field for now, address later

**Analysis:** The `options` field in `RuleContext` adds complexity without clear immediate value. Removed to simplify the initial API design.

**Changes Made:**
- Removed `options: { any }` from `RuleContext` type
- Rule configuration can be handled through `settings` field
- Options/configuration system can be added in future iteration

**Benefits:** Simplified API, reduced complexity, cleaner initial implementation

### 3. Error Handling ✅ RESOLVED
**Decision:** Simple isolation strategy with rule-level error boundaries

**Analysis:** Since invalid source code won't parse to AST, we don't need to handle invalid AST nodes. Focus on rule isolation and graceful degradation.

**Approach:**
- **Rule Isolation**: Use `pcall` around each rule execution to prevent one rule from crashing the entire linter
- **Error Response**: On rule error, disable the rule for remaining iterations and log to user
- **Future Enhancement**: Make error tolerance configurable (strict mode for CI vs. permissive for development)
- **Fix Generation**: Report errors in appropriate context (VSCode editor vs. CLI terminal) - details deferred for future exploration
- **Recovery Strategy**: Keep AST snapshots before applying fixes to enable rollback on failure

**Implementation Notes:**
- No try/catch mechanisms within rules - rules should be designed not to error
- `pcall` wrapper provides sufficient error boundary at rule execution level
- Performance impact of `pcall` per rule execution is acceptable

**Benefits:** Robust linter operation, isolated failures, graceful degradation

### 4. Rule Dependencies ✅ RESOLVED
**Decision:** Simple error reporting for now, defer complex dependency management

**Analysis:** Dependencies add significant complexity without clear immediate value. Keep the API fields but implement minimal validation.

**Approach:**
- **Dependency Validation**: Check if required dependencies are available at startup
- **Error Response**: Log error message and abort program if required dependencies are missing
- **Conflict Detection**: Log error and abort if conflicting rules are both enabled
- **No Ordering Logic**: Rules run in registration order, no dependency-based sorting
- **Future Enhancement**: Full dependency resolution system can be added later if needed

**Implementation:**
```luau
-- Keep existing API fields for future use
export type RuleDependency = {
    ruleId: string,
    required: boolean?,
    conflict: boolean?,
}

-- Simple validation at startup:
-- 1. Check all required dependencies are present
-- 2. Check no conflicting rules are both enabled
-- 3. Abort with clear error message if violations found
```

**Benefits:** Simple implementation, clear error messages, preserves API for future enhancement

### 5. Performance Contracts ✅ RESOLVED
**Decision:** Basic time limits to prevent infinite loops, defer detailed performance management

**Analysis:** Focus on preventing runaway rules while keeping performance monitoring simple for the initial implementation.

**Approach:**
- **Execution Time Limits**: Implement reasonable time limits per rule execution to prevent infinite loops
- **Adaptive Limits**: Consider device-relative limits rather than fixed timeouts (needs experimentation)
- **Memory Constraints**: Out of scope - good APIs should prevent memory issues, and Luau memory tracking is complex
- **AST Traversal Guidelines**: Defer detailed efficiency guidelines, trust developers to use visitor patterns appropriately
- **Performance Measurement**: Defer comprehensive performance monitoring to future iterations
- **API Design Enforcement**: Structure the API to make efficient patterns easy and inefficient patterns hard (enum-based visitors, no manual AST walking utilities)

**Implementation Strategy:**
```luau
-- Simple timeout mechanism per rule execution
-- Exact timeout values need experimentation based on:
-- - Device performance variations
-- - Typical rule complexity
-- - Balance between protection and usability
```

**Future Considerations:**
- Performance profiling and reporting tools
- Detailed AST traversal best practices documentation  
- Memory usage monitoring (if needed)
- Rule performance benchmarking framework
- Advanced enforcement mechanisms (performance monitoring, static analysis of rules)

**Benefits:** Prevents runaway rules, keeps implementation simple, room for future enhancement, guides developers toward efficient patterns

## API Finalization Complete ✅

**All 5 questions resolved! The Rule API design is now finalized and ready for implementation.**

**Completed ✅**
1. **Visitor Integration** - Enum-based approach with complete Lute coverage
2. **Rule Options/Configuration** - Simplified by removing options field  
3. **Error Handling** - Rule isolation with pcall boundaries and AST snapshots
4. **Rule Dependencies** - Simple validation with error reporting, complex management deferred
5. **Performance Contracts** - Basic time limits to prevent infinite loops, detailed monitoring deferred

## Implementation Ready
The Rule API is now sufficiently defined to begin implementation. All core design decisions have been made with a focus on:
- **Simplicity** - Minimal complexity for initial implementation
- **Extensibility** - Framework ready for future enhancements
- **Robustness** - Error isolation and graceful degradation
- **Practicality** - Real-world usage considerations

Proceed with implementing the plugin system using this finalized Rule API design.

---
*Created: December 2024*
*Context: Finalizing standalone rule API design*
