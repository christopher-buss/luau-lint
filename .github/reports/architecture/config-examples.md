# Configuration Schema Examples

This document provides comprehensive examples of `luau-lint.toml` configuration files for different project setups and use cases.

## Basic Project Configuration

### Minimal Configuration
```toml
# luau-lint.toml - Minimal setup
[rules]
"modern-iteration" = "warn"
"unused-variables" = "error"
```

### Standard Project Configuration
```toml
# luau-lint.toml - Standard Luau project
[project]
name = "my-luau-app"
version = "1.0.0"

[lint]
language_mode = "strict"

[rules]
# Core modernization rules
"modern-iteration" = "warn"
"unused-variables" = "error" 
"deprecated-apis" = "warn"
"type-annotations" = "warn"
"naming-convention" = "warn"

# Code quality rules
"no-unused-imports" = "error"
"prefer-const" = "warn"
"no-duplicate-keys" = "error"

[rules.config]
"naming-convention" = { 
    style = "camelCase", 
    ignore_globals = true,
    prefixes = { functions = "fn", types = "T" }
}
"unused-variables" = { 
    ignore_prefixes = ["_", "unused"],
    ignore_rest_siblings = true 
}

[files]
include = [
    "src/**/*.luau",
    "scripts/**/*.lua" 
]
exclude = [
    "src/generated/**",
    "**/node_modules/**"
]

[output]
format = "text"
color = "auto"
max_problems = 25
```

## Roblox Game Development Configuration

```toml
# luau-lint.toml - Roblox game project
[project]
name = "roblox-game"
version = "1.0.0"
environment = "roblox"

[lint]
language_mode = "strict"

[rules]
# Roblox-specific rules
"roblox-api-usage" = "warn"
"modern-iteration" = "error"
"unused-variables" = "error"
"deprecated-apis" = "error"
"type-annotations" = "warn"
"naming-convention" = "error"

# Performance rules for games
"no-expensive-loops" = "warn"
"prefer-object-pooling" = "info"
"limit-recursive-calls" = "warn"

[rules.config]
"naming-convention" = {
    style = "PascalCase",
    ignore_globals = false,
    roblox_services = "PascalCase",
    events = "camelCase"
}
"no-expensive-loops" = {
    max_iterations = 1000,
    warn_threshold = 100
}

[files]
include = [
    "src/**/*.luau",
    "ServerScriptService/**/*.luau",
    "ReplicatedStorage/**/*.luau",
    "StarterPlayerScripts/**/*.luau"
]
exclude = [
    "**/Packages/**",
    "**/node_modules/**",
    "**/_Index/**"
]
ignore_files = [".gitignore", ".robloxignore"]

[performance]
parallel = true
max_workers = 6
parallel_threshold = 5
```

## Library Development Configuration

```toml
# luau-lint.toml - Luau library project
[project]
name = "luau-utils-lib"
version = "2.1.0"
type = "library"

[lint]
language_mode = "strict"

[rules]
# Strict rules for library code
"type-annotations" = "error"
"unused-variables" = "error"
"modern-iteration" = "error"
"deprecated-apis" = "error"
"naming-convention" = "error"
"no-any-types" = "warn"

# Documentation rules
"require-jsdoc" = "warn"
"valid-jsdoc" = "error"

# API design rules
"prefer-readonly" = "warn"
"explicit-return-types" = "error"
"no-implicit-any" = "error"

[rules.config]
"naming-convention" = {
    style = "camelCase",
    constants = "SCREAMING_SNAKE_CASE",
    types = "PascalCase",
    private_prefix = "_"
}
"require-jsdoc" = {
    require_return = true,
    require_param_description = true,
    require_returns_description = true
}

[files]
include = ["src/**/*.luau", "lib/**/*.luau"]
exclude = [
    "tests/**",
    "examples/**",
    "**/node_modules/**"
]

[output]
format = "text"
color = "auto"
max_problems = 0  # Show all problems for library code
```

## Team Development Configuration

```toml
# luau-lint.toml - Large team project
[project]
name = "team-project"
version = "3.2.1"

[lint]
language_mode = "strict"

[rules]
# Enforced team standards
"modern-iteration" = "error"
"unused-variables" = "error"
"deprecated-apis" = "error"
"type-annotations" = "error"
"naming-convention" = "error"

# Code consistency rules
"indent-style" = "error"
"max-line-length" = "warn" 
"no-trailing-spaces" = "error"
"consistent-quotes" = "error"

# Team collaboration rules
"no-console-log" = "warn"
"require-file-header" = "error"
"max-function-length" = "warn"
"max-file-lines" = "warn"

[rules.config]
"naming-convention" = {
    style = "camelCase",
    constants = "SCREAMING_SNAKE_CASE",
    types = "PascalCase",
    files = "kebab-case"
}
"max-line-length" = { limit = 120 }
"max-function-length" = { max = 50 }
"max-file-lines" = { max = 300 }
"require-file-header" = {
    pattern = "^-- Copyright \\d{4} Team Name.*$"
}
"consistent-quotes" = { prefer = "double" }

[files]
include = [
    "src/**/*.luau",
    "shared/**/*.luau",
    "client/**/*.luau",
    "server/**/*.luau"
]
exclude = [
    "**/generated/**",
    "**/vendor/**", 
    "**/third-party/**",
    "**/*.test.luau"
]

[output]
format = "json"  # For CI integration
color = "never"
max_problems = 100

[performance]
parallel = true
max_workers = 8
parallel_threshold = 10
```

## Monorepo Configuration

```toml
# luau-lint.toml - Monorepo root configuration
[project]
name = "monorepo"
version = "1.0.0"
type = "monorepo"

# Shared rules across all packages
[rules]
"modern-iteration" = "warn"
"unused-variables" = "error"
"deprecated-apis" = "warn"

[files]
include = ["packages/**/*.luau", "apps/**/*.luau"]
exclude = [
    "**/node_modules/**",
    "**/dist/**",
    "**/*.d.luau"
]

# Package-specific overrides
[overrides]
# Stricter rules for core packages
[[overrides]]
files = ["packages/core/**/*.luau"]
rules = {
    "type-annotations" = "error",
    "no-any-types" = "error",
    "require-jsdoc" = "warn"
}

# Relaxed rules for examples
[[overrides]]
files = ["examples/**/*.luau", "**/*.example.luau"]
rules = {
    "type-annotations" = "off",
    "unused-variables" = "warn",
    "no-console-log" = "off"
}

# Test files
[[overrides]]
files = ["**/*.test.luau", "**/*.spec.luau"]
rules = {
    "no-unused-expressions" = "off",
    "max-function-length" = "off"
}
```

## Performance-Focused Configuration

```toml
# luau-lint.toml - Performance-critical project
[project]
name = "high-performance-app"
version = "1.0.0"

[lint]
language_mode = "strict"

[rules]
# Performance rules
"no-expensive-loops" = "error"
"prefer-local-functions" = "warn"
"avoid-table-creation-in-loops" = "error"
"prefer-numeric-for" = "warn"
"no-string-concatenation-in-loops" = "error"

# Memory management
"prefer-object-pooling" = "warn"
"avoid-closure-creation" = "warn"
"limit-recursive-calls" = "error"

# General rules
"modern-iteration" = "error"
"unused-variables" = "error"
"type-annotations" = "warn"

[rules.config]
"no-expensive-loops" = {
    max_iterations = 10000,
    warn_threshold = 1000,
    check_nested = true
}
"limit-recursive-calls" = {
    max_depth = 50,
    warn_depth = 20
}
"no-string-concatenation-in-loops" = {
    suggest_table_concat = true
}

[performance]
parallel = true
max_workers = 16  # Use all cores for large codebases
parallel_threshold = 1  # Parallelize even small files
```

## Plugin Configuration Example

```toml
# luau-lint.toml - With custom plugins
[project]
name = "plugin-demo"
version = "1.0.0"

[plugins]
# Plugin search paths
search_paths = [
    "./plugins",
    "~/.luau-lint/plugins",
    "/usr/local/share/luau-lint/plugins"
]

# Load specific plugins
load = [
    "@company/luau-rules",
    "@roblox/game-dev-rules", 
    "local-custom-rules"
]

# Plugin-specific configuration
[plugins.config]
"@company/luau-rules" = {
    company_standards = "strict",
    enforce_header = true,
    header_template = "company-header.txt"
}

"@roblox/game-dev-rules" = {
    target_platform = "roblox",
    performance_mode = "strict",
    memory_checks = true
}

"local-custom-rules" = {
    project_specific = true,
    debug_mode = false
}

[rules]
# Built-in rules
"modern-iteration" = "warn"
"unused-variables" = "error"

# Plugin rules
"@company/require-license-header" = "error"
"@company/no-internal-imports" = "error"
"@roblox/prefer-instance-events" = "warn"
"@roblox/no-blocking-operations" = "error"
"local-custom-rules/project-naming" = "warn"
```

## Environment-Specific Configuration

```toml
# luau-lint.toml - Multi-environment project
[project]
name = "multi-env-project"
version = "1.0.0"

# Base configuration
[rules]
"modern-iteration" = "warn"
"unused-variables" = "error"

# Environment-specific overrides
[environments]

[environments.development]
rules = {
    "no-console-log" = "off",
    "no-debugger" = "warn",
    "unused-variables" = "warn"
}
output = { format = "text", color = "auto" }

[environments.production]
rules = {
    "no-console-log" = "error",
    "no-debugger" = "error", 
    "unused-variables" = "error",
    "type-annotations" = "error"
}
output = { format = "json", color = "never" }

[environments.testing]
rules = {
    "no-unused-expressions" = "off",
    "max-function-length" = "off",
    "no-console-log" = "off"
}
files = {
    include = ["**/*.test.luau", "**/*.spec.luau"],
    exclude = []
}
```

## Schema Validation Rules

### Configuration Schema (JSON Schema equivalent)

```json
{
  "type": "object",
  "properties": {
    "project": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+"},
        "type": {"enum": ["application", "library", "monorepo"]}
      }
    },
    "lint": {
      "type": "object", 
      "properties": {
        "language_mode": {"enum": ["nonstrict", "strict", "nocheck"]}
      }
    },
    "rules": {
      "type": "object",
      "patternProperties": {
        "^[a-zA-Z0-9-_/@]+$": {
          "oneOf": [
            {"enum": ["error", "warn", "off"]},
            {
              "type": "object",
              "properties": {
                "level": {"enum": ["error", "warn", "off"]},
                "config": {"type": "object"}
              },
              "required": ["level"]
            }
          ]
        }
      }
    },
    "files": {
      "type": "object",
      "properties": {
        "include": {"type": "array", "items": {"type": "string"}},
        "exclude": {"type": "array", "items": {"type": "string"}},
        "ignore_files": {"type": "array", "items": {"type": "string"}}
      }
    },
    "output": {
      "type": "object",
      "properties": {
        "format": {"enum": ["text", "json", "junit", "checkstyle"]},
        "color": {"enum": ["auto", "always", "never"]},
        "max_problems": {"type": "integer", "minimum": 0}
      }
    },
    "performance": {
      "type": "object",
      "properties": {
        "parallel": {"type": "boolean"},
        "max_workers": {"type": "integer", "minimum": 1},
        "parallel_threshold": {"type": "integer", "minimum": 0}
      }
    }
  }
}
```

These configuration examples demonstrate the flexibility and power of the luau-lint configuration system, supporting everything from simple projects to complex enterprise environments with custom plugins and multi-environment deployments.
