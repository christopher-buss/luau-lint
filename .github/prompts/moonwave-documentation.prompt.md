# Moonwave Documentation Prompt for luau-lint

## Overview
This prompt file guides the creation of comprehensive moonwave-style documentation for functions in the luau-lint project. Follow these patterns to ensure consistent, high-quality documentation that integrates seamlessly with moonwave documentation generation.

## Documentation Format

### Basic Function Documentation Template

```luau
--[=[
	Brief description of what the function does.
	
	More detailed explanation if needed, including:
	- Purpose and use cases
	- Important behavior notes
	- Performance considerations
	- Related functions or concepts
	
	@param paramName paramType -- Description of the parameter
	@param optionalParam paramType? -- Optional parameter description
	@return returnType -- Description of what is returned
	@since v0.1.0
	@tag category -- Optional: utility, core, rules, etc.
]=]
function functionName(paramName: ParamType, optionalParam: OptionalType?): ReturnType
	-- Implementation
end
```

### Class Documentation Template

```luau
--[=[
	@class ClassName
	
	Brief description of the class and its purpose.
	
	Detailed explanation including:
	- What this class represents
	- Key responsibilities
	- Usage patterns
	- Related classes
	
	@since v0.1.0
	@tag core
]=]
local ClassName = {}
ClassName.__index = ClassName
```

### Method Documentation Template

```luau
--[=[
	Brief description of the method.
	
	Detailed explanation of:
	- What the method accomplishes
	- When to use this method
	- Side effects or state changes
	- Error conditions
	
	@param self ClassName -- The instance
	@param param ParamType -- Parameter description
	@return ReturnType -- Return value description
	@error "ErrorType" -- Potential error description
	@since v0.1.0
]=]
function ClassName:methodName(param: ParamType): ReturnType
	-- Implementation
end
```

### Type Definition Documentation

```luau
--[=[
	@type TypeName Description
	@within ModuleName
	
	Detailed description of the type including:
	- What it represents
	- Valid values or structure
	- Usage examples
	- Related types
]=]
export type TypeName = {
	field1: string,
	field2: number?,
	field3: { string },
}
```

### Interface Documentation

```luau
--[=[
	@interface InterfaceName
	@within ModuleName
	.field1 string -- Description of field1
	.field2 number? -- Optional field description
	@field field3 { string } -- Alternative field syntax
	
	Description of what this interface represents and how it's used.
]=]
```

## Luau-lint Specific Patterns

### Rule Documentation

```luau
--[=[
	@class Rule
	
	Interface for defining linting rules in the luau-lint system.
	Rules use a listener pattern to register callbacks for specific AST node types.
	
	## Example Usage
	
	```luau
	local myRule: Rule = {
		id = "no-unused-vars",
		title = "Disallow unused variables",
		description = "Variables that are declared but never used should be removed",
		category = "logical",
		fixable = "auto",
		docsUrl = "https://example.com/rules/no-unused-vars",
		
		create = function(context: RuleContext): RuleListener
			return {
				LocalDeclaration = function(node: luau.AstStatLocal)
					-- Rule implementation
				end
			end
		end
	}
	```
	
	@since v0.1.0
	@tag rules
]=]
```

### Context Methods Documentation

```luau
--[=[
	Reports a linting issue for the given AST node.
	
	This is the primary method for rule implementations to report violations.
	The context will handle formatting, severity, and output generation.
	
	@param issue LintIssue -- The issue to report
	@since v0.1.0
]=]
function RuleContext:report(issue: LintIssue): ()
	-- Implementation
end

--[=[
	Creates an automatic fix for a linting issue.
	
	Fixes can be applied automatically when the `--fix` flag is used.
	Ensure fixes are safe and don't change program semantics.
	
	@param description string -- Human-readable description of the fix
	@param range luau.Location -- The location range to replace
	@param replacement string -- The replacement text
	@return Fix -- The fix object
	@since v0.1.0
]=]
function RuleContext:createFix(description: string, range: luau.Location, replacement: string): Fix
	-- Implementation
end
```

### AST Node Type Documentation

```luau
--[=[
	@type NodeType string
	@within Rule
	
	String literal type representing supported AST node types for rule listeners.
	
	Common node types include:
	- `"Call"` - Function call expressions
	- `"LocalDeclaration"` - Local variable declarations  
	- `"Global"` - Global variable references
	- `"Binary"` - Binary operations
	- `"Block"` - Statement blocks
	
	See the complete list in `src/plugin/rule.luau`.
]=]
export type NodeType = 
	| "AnonymousFunction"
	| "Assign" 
	| "Binary"
	| "Block"
	| "Boolean"
	| "Call"
	-- ... other types
```

## Documentation Tags Reference

### Core Tags
- `@class ClassName` - Defines a class
- `@param name type -- description` - Documents parameters
- `@return type -- description` - Documents return values
- `@since version` - Version when added
- `@deprecated version -- reason` - Marks as deprecated

### Specialized Tags
- `@yields` - Function yields/suspends execution
- `@error "ErrorType" -- description` - Documents potential errors
- `@tag category` - Groups functions by category
- `@external TypeName url` - Links to external type documentation

### Luau-lint Specific Tags
- `@tag rules` - Rule-related functions
- `@tag core` - Core engine functionality
- `@tag utility` - Utility functions
- `@tag ast` - AST manipulation functions

## Best Practices

### 1. Write for Function Consumers, Not Maintainers

**IMPORTANT**: Documentation should focus on helping consumers understand **what** a function does and **how** to use it, not **how** it's implemented internally. Maintainers can read the code for implementation details.

**Good - Consumer Focused**:
```luau
--[=[
    Validates rule configuration and reports any missing required fields or invalid values.
    Use this before registering a rule to ensure it will work correctly with the linter engine.
    
    @param config RuleConfig -- The rule configuration to validate
    @return boolean -- True if configuration is valid and ready to use
    @error "InvalidConfig" -- When required fields are missing or invalid
]=]
```

**Poor - Implementation Focused**:
```luau
--[=[
    Iterates through config fields, checks against required schema,
    validates types using internal validation helpers, and returns boolean result.
    
    @param config RuleConfig 
    @return boolean
]=]
```

### 2. Provide High-Level Purpose and Intent

Start with **what** the function accomplishes and **why** someone would use it:

```luau
--[=[
    Creates a reusable rule context that provides utilities for reporting issues and creating fixes.
    Use this when implementing custom rules to access linter functionality like issue reporting,
    source code inspection, and automatic fix generation.
    
    ## Example
    ```luau
    local context = createRuleContext(filename, sourceCode, config)
    
    -- Report an issue
    context:report({
        node = problematicNode,
        message = "Variable is unused",
        severity = "warning"
    })
    
    -- Create an automatic fix
    local fix = context:createFix("Remove unused variable", nodeRange, "")
    ```
    
    @param filename string -- Path to file being linted (for error reporting)
    @param sourceCode string -- Full source text of the file
    @param config RuleConfig -- Configuration for the specific rule
    @return RuleContext -- Context object with linting utilities
]=]
```

### 3. Focus on Practical Usage Over Implementation

**Good**:
```luau
--[=[
    Registers a custom rule with the linter engine so it will be executed during linting.
    Call this during plugin initialization to make your rule available.
    
    @param rule Rule -- The rule definition with metadata and implementation
]=]
```

**Poor**:
```luau
--[=[
    Adds rule to internal registry hashtable and validates metadata schema.
    
    @param rule Rule
]=]
```

### 4. Include Examples for Non-Trivial Functions

For any function that requires setup, configuration, or has non-obvious usage patterns:

```luau
--[=[
    Creates a new AST visitor that calls registered listeners when specific node types are encountered.
    Use this to implement rule logic that responds to specific parts of the syntax tree.
    
    ## Basic Usage
    ```luau
    local visitor = createVisitor({
        Call = function(node)
            -- Handle function calls
        end,
        Local = function(node)
            -- Handle local variable declarations
        end
    })
    
    visitor:visit(astRoot)
    ```
    
    ## With Enter/Exit Listeners
    ```luau
    local visitor = createVisitor({
        Block = {
            enter = function(node) 
                -- Entering a new scope
            end,
            exit = function(node)
                -- Leaving scope
            end
        }
    })
    ```
    
    @param listeners ListenerMap -- Map of node types to callback functions
    @return Visitor -- Visitor instance ready to traverse AST
]=]
```

### 5. Answer "Should I Use This Function?"

Help consumers quickly determine if this is the right function for their needs:

```luau
--[=[
    Parses Luau source code into an Abstract Syntax Tree for analysis.
    Use this when you need to analyze code structure programmatically, such as
    in custom rules or code analysis tools. For simple text-based checks,
    consider string matching instead.
    
    The returned AST provides structured access to all language constructs
    including expressions, statements, types, and comments.
    
    @param source string -- Valid Luau source code
    @param filename string? -- Optional filename for error reporting
    @return AstStatBlock -- Root AST node containing the entire program
    @error "SyntaxError" -- When source code has syntax errors
]=]
```

### 6. Describe Expected Inputs and Outputs Clearly

Be specific about what the function expects and what it produces:

```luau
--[=[
    Converts a source code location range into a human-readable string format.
    Useful for displaying error messages and issue reports to users.
    
    Input ranges should have valid line/column coordinates within the source file.
    Output format is "filename:line:column-line:column" for ranges spanning multiple
    positions, or "filename:line:column" for single positions.
    
    @param range SourceRange -- Location range with start/end positions  
    @param filename string -- Name of source file (displayed in output)
    @return string -- Formatted location string for user display
]=]
```

### 7. Highlight Important Constraints or Assumptions

```luau
--[=[
    Applies automatic fixes to source code and returns the modified text.
    
    **Important**: Only applies fixes that are marked as "safe" to prevent
    unintended behavior changes. Fixes are applied in reverse order to
    preserve location accuracy.
    
    @param sourceCode string -- Original source code
    @param fixes Fix[] -- Array of fixes to apply (must be from same source)
    @return string -- Source code with fixes applied
    @error "ConflictingFixes" -- When fixes overlap or conflict
]=]
```

### 8. When to Include Examples - Complexity Guidelines

**Include examples when functions have ANY of these characteristics:**

#### High Complexity Indicators
- **Multiple parameters with interdependencies**
  ```luau
  -- NEEDS EXAMPLE: Parameters affect each other
  function createVisitor(listeners: ListenerMap, options: VisitorOptions): Visitor
  ```

- **Configuration objects or complex data structures**
  ```luau
  -- NEEDS EXAMPLE: RuleMetadata structure isn't obvious
  function createRule(metadata: RuleMetadata): Rule
  ```

- **Callback patterns or higher-order functions**
  ```luau
  -- NEEDS EXAMPLE: Callback usage pattern unclear
  function registerListener(nodeType: NodeType, callback: NodeListener): void
  ```

- **Multiple usage patterns or overloads**
  ```luau
  -- NEEDS EXAMPLE: Different ways to call it
  function report(issue: RuleIssue): void
  function report(message: string, node: AstNode): void
  ```

- **Setup/teardown sequences**
  ```luau
  -- NEEDS EXAMPLE: Order of operations matters
  function initializeContext(config: Config): RuleContext
  ```

- **Return values that require further action**
  ```luau
  -- NEEDS EXAMPLE: What to do with the result
  function createFix(range: SourceRange, text: string): RuleFix
  ```

#### Low Complexity - Examples Optional
- **Simple parameter transformation**
  ```luau
  -- NO EXAMPLE NEEDED: Purpose is obvious
  function add(a: number, b: number): number
  function lowercase(text: string): string
  function isValid(rule: Rule): boolean
  ```

- **Simple getters/setters**
  ```luau
  -- NO EXAMPLE NEEDED: Standard property access
  function getId(): string
  function setEnabled(enabled: boolean): void
  ```

- **Single-purpose utility functions**
  ```luau
  -- NO EXAMPLE NEEDED: Name explains everything
  function trimWhitespace(text: string): string
  function formatError(message: string): string
  ```

#### Borderline Cases - Use Judgment

**Include example if:**
- Function name doesn't clearly indicate all requirements
- Parameters have non-obvious constraints or formats
- Function is part of a larger workflow
- Return value format isn't standard

**Example Decision Tree:**
```luau
-- BORDERLINE: Could go either way
function validateRule(rule: any): (boolean, string?)
```

**Decision:** Include example because:
- Return type is a tuple (non-obvious)
- Error message format matters to users
- Users need to know how to handle both success/failure cases

```luau
--[=[
    ## Example
    ```luau
    local isValid, errorMsg = validateRule(myRule)
    if not isValid then
        print("Rule validation failed:", errorMsg)
        return
    end
    -- Continue with valid rule...
    ```
]=]
```

#### Type Definitions - Example Guidelines

**Types typically DON'T need examples:**
- **Simple object types with self-explanatory fields**: Fields are clearly documented and usage is obvious from the structure
  ```luau
  -- NO EXAMPLE NEEDED: Fields are self-explanatory
  export type RuleMetadata = {
      id: string,           -- Clear what this contains
      title: string,        -- Obvious usage
      description: string,  -- Self-evident
      category: RuleCategory,
  }
  ```

- **Simple type aliases**: `type UserId = string`
- **Basic structures**: `type Point = { x: number, y: number }`
- **Enum-like unions**: `type Status = "pending" | "complete" | "failed"`

**Types that DO need examples:**
- **Complex types where usage isn't obvious from structure**: Type looks complex but usage is actually simple
  ```luau
  --[=[
      @type StringWithAutocompleteOptions string
      @within Utilities
      
      String type that provides autocomplete for predefined options while still accepting any string value.
      
      ## Example
      ```luau
      -- Provides autocomplete for "red", "green", "blue" but accepts any string
      function setColor(color: StringWithAutocompleteOptions<"red" | "green" | "blue">)
          -- Can use predefined options (with autocomplete)
          setColor("red")    -- ✓ Autocompleted
          setColor("green")  -- ✓ Autocompleted
          
          -- Can also use any other string
          setColor("#FF5733") -- ✓ Also valid
          setColor("purple")  -- ✓ Also valid
      end
      ```
  ]=]
  ```

- **Types with non-obvious constraints or validation rules**
- **Generic types with complex instantiation patterns**  
- **Types that require specific calling conventions**

#### Quick Reference Checklist

**Include example if you answer "yes" to any:**
- [ ] Does this function take more than 2 parameters?
- [ ] Do parameters have format requirements? (URLs, patterns, etc.)
- [ ] Is this a callback/listener registration?
- [ ] Does the return value require specific handling?
- [ ] Is this part of a multi-step workflow?
- [ ] Would a new user struggle to call this correctly on first try?

**Skip example if all are "yes":**
- [ ] Function name clearly describes the action
- [ ] Parameters are self-explanatory primitives
- [ ] Return value is standard (boolean, string, number)
- [ ] No special calling conventions or patterns
- [ ] Function is purely functional (no side effects to worry about)

## Module-Level Documentation

```luau
--[=[
	@class ModuleName
	
	Module description explaining:
	- Purpose and scope
	- Key exports
	- Usage patterns
	- Dependencies
	
	@since v0.1.0
]=]
local ModuleName = {}

-- Export types and functions with individual documentation
return ModuleName
```

## Integration with Existing Patterns

This documentation style integrates with the existing luau-lint project patterns:

1. **Maintains consistency** with existing markdown documentation in `docs/`
2. **Follows Luau conventions** used throughout the codebase
3. **Supports the plugin architecture** with appropriate tags and categorization
4. **Enables automatic documentation generation** via moonwave
5. **Provides IDE support** through properly formatted comments

## Usage Instructions

1. **Apply to all public functions and classes** in the `src/` directory
2. **Use appropriate tags** to categorize functionality
3. **Include examples** for complex APIs
4. **Document error conditions** and edge cases
5. **Keep descriptions current** with implementation changes
6. **Follow the listener pattern documentation** for rule-related code

This documentation style ensures that the luau-lint project maintains professional, comprehensive documentation that aids both contributors and users of the linting system.
