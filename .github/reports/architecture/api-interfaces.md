# Core API Interface Definitions

This document defines the core module interfaces and function signatures for the luau-lint architecture components.

## 1. Rule Interface

### Rule Module Type Definition
```luau
export type Rule = {
    id: string,
    name: string, 
    description: string,
    category: RuleCategory,
    severity: RuleSeverity,
    fixable: boolean,
    
    -- Core rule execution
    check: (context: RuleContext) -> RuleResult,
    fix: ((context: RuleContext) -> FixResult)?,
    
    -- Rule metadata
    getSchema: () -> RuleSchema,
    getDocumentation: () -> RuleDocumentation,
}

export type RuleCategory = "style" | "correctness" | "performance" | "security" | "complexity"
export type RuleSeverity = "error" | "warning" | "info" | "hint"

export type RuleContext = {
    node: AstNode,
    sourceCode: string,
    filePath: string,
    config: RuleConfig,
    reporter: Reporter,
    astVisitor: AstVisitor,
}

export type RuleResult = {
    violations: {Violation},
    suggestions: {Suggestion}?,
}

export type Violation = {
    message: string,
    location: Location,
    severity: RuleSeverity,
    ruleId: string,
    fixable: boolean,
}

export type FixResult = {
    fixed: boolean,
    changes: {TextChange},
    message: string?,
}
```

### Rule Registration Functions
```luau
-- Rule registry management
export function registerRule(rule: Rule): boolean
export function unregisterRule(ruleId: string): boolean
export function getRules(): {[string]: Rule}
export function getRule(ruleId: string): Rule?
export function validateRule(rule: Rule): ValidationResult

-- Rule filtering and querying
export function getRulesByCategory(category: RuleCategory): {Rule}
export function getRulesBySeverity(severity: RuleSeverity): {Rule}
export function getFixableRules(): {Rule}
```

## 2. Configuration Manager Interface

### Configuration Types
```luau
export type ConfigurationManager = {
    -- Configuration loading
    loadConfig: (filePath: string?) -> ConfigResult,
    mergeConfigs: (base: Config, override: Config) -> Config,
    validateConfig: (config: Config) -> ValidationResult,
    
    -- Rule configuration
    getRuleConfig: (ruleId: string) -> RuleConfig?,
    setRuleConfig: (ruleId: string, config: RuleConfig) -> (),
    
    -- File pattern management
    getIncludePatterns: () -> {string},
    getExcludePatterns: () -> {string},
    shouldProcessFile: (filePath: string) -> boolean,
}

export type Config = {
    rules: {[string]: RuleConfig},
    include: {string},
    exclude: {string},
    plugins: {string}?,
    extends: {string}?,
    environment: EnvironmentConfig?,
    output: OutputConfig?,
    performance: PerformanceConfig?,
}

export type RuleConfig = "off" | "warn" | "error" | {
    level: "off" | "warn" | "error",
    options: {[string]: any}?,
}

export type ConfigResult = {
    success: boolean,
    config: Config?,
    errors: {ConfigError},
    warnings: {ConfigWarning},
}
```

### Configuration Manager Functions
```luau
-- Configuration discovery and loading
export function findConfigFile(startPath: string): string?
export function loadConfigFromFile(filePath: string): ConfigResult
export function loadConfigFromString(content: string): ConfigResult
export function createDefaultConfig(): Config

-- Configuration validation and processing
export function validateConfigSchema(config: any): ValidationResult
export function normalizeConfig(config: Config): Config
export function resolveConfigExtends(config: Config): ConfigResult
```

## 3. File Discovery Interface

### File Discovery Types
```luau
export type FileDiscovery = {
    -- File discovery
    findFiles: (patterns: {string}, options: DiscoveryOptions?) -> {string},
    filterFiles: (files: {string}, includePatterns: {string}, excludePatterns: {string}) -> {string},
    
    -- File validation
    isLuauFile: (filePath: string) -> boolean,
    canReadFile: (filePath: string) -> boolean,
    getFileInfo: (filePath: string) -> FileInfo?,
}

export type DiscoveryOptions = {
    followSymlinks: boolean?,
    maxDepth: number?,
    ignoreHidden: boolean?,
    parallelism: number?,
}

export type FileInfo = {
    path: string,
    size: number,
    modifiedTime: number,
    isDirectory: boolean,
    isSymlink: boolean,
}
```

### File Discovery Functions
```luau
-- Pattern matching and filtering
export function matchesPattern(filePath: string, pattern: string): boolean
export function expandGlobPatterns(patterns: {string}): {string}
export function resolveFilePaths(paths: {string}): {string}

-- File system utilities
export function getWorkspaceRoot(startPath: string): string?
export function resolveRelativePath(basePath: string, relativePath: string): string
export function normalizeFilePath(filePath: string): string
```

## 4. Pipeline Interface

### Pipeline Types
```luau
export type Pipeline = {
    -- Pipeline execution
    processFile: (filePath: string, options: ProcessOptions?) -> ProcessResult,
    processFiles: (filePaths: {string}, options: ProcessOptions?) -> {ProcessResult},
    
    -- Pipeline configuration
    addStage: (stage: PipelineStage) -> (),
    removeStage: (stageName: string) -> boolean,
    getStages: () -> {PipelineStage},
}

export type PipelineStage = {
    name: string,
    order: number,
    execute: (context: StageContext) -> StageResult,
    canSkip: ((context: StageContext) -> boolean)?,
}

export type ProcessOptions = {
    parallel: boolean?,
    maxWorkers: number?,
    timeout: number?,
    skipCache: boolean?,
    dryRun: boolean?,
}

export type ProcessResult = {
    filePath: string,
    success: boolean,
    violations: {Violation},
    fixes: {FixResult}?,
    duration: number,
    errors: {ProcessError}?,
}

export type StageContext = {
    filePath: string,
    sourceCode: string,
    ast: AstNode?,
    config: Config,
    rules: {Rule},
    reporter: Reporter,
}

export type StageResult = {
    success: boolean,
    data: any?,
    errors: {StageError}?,
    shouldContinue: boolean,
}
```

### Pipeline Functions
```luau
-- Pipeline creation and management
export function createPipeline(stages: {PipelineStage}): Pipeline
export function createDefaultPipeline(): Pipeline
export function clonePipeline(pipeline: Pipeline): Pipeline

-- Stage utilities
export function createParseStage(): PipelineStage
export function createLintStage(): PipelineStage
export function createFixStage(): PipelineStage
export function createReportStage(): PipelineStage
```

## 5. Reporter Interface

### Reporter Types
```luau
export type Reporter = {
    -- Violation reporting
    reportViolation: (violation: Violation) -> (),
    reportError: (error: LintError) -> (),
    reportWarning: (warning: LintWarning) -> (),
    
    -- Output generation
    generateReport: (results: {ProcessResult}) -> Report,
    formatReport: (report: Report, format: OutputFormat) -> string,
    
    -- Statistics
    getStatistics: () -> LintStatistics,
}

export type Report = {
    summary: ReportSummary,
    fileResults: {FileResult},
    errors: {LintError},
    warnings: {LintWarning},
    statistics: LintStatistics,
}

export type ReportSummary = {
    totalFiles: number,
    processedFiles: number,
    errorFiles: number,
    totalViolations: number,
    errorViolations: number,
    warningViolations: number,
    fixableViolations: number,
    duration: number,
}

export type FileResult = {
    filePath: string,
    violations: {Violation},
    errorCount: number,
    warningCount: number,
    fixableCount: number,
}

export type OutputFormat = "text" | "json" | "xml" | "checkstyle" | "sarif"
```

### Reporter Functions
```luau
-- Reporter creation
export function createConsoleReporter(options: ConsoleOptions?): Reporter
export function createFileReporter(filePath: string, format: OutputFormat): Reporter
export function createMultiReporter(reporters: {Reporter}): Reporter

-- Formatting utilities
export function formatViolation(violation: Violation, format: OutputFormat): string
export function formatLocation(location: Location): string
export function colorizeOutput(text: string, color: string): string
```

## 6. AST Visitor Interface

### AST Visitor Types
```luau
export type AstVisitor = {
    -- Node traversal
    visit: (node: AstNode, callback: NodeCallback) -> (),
    visitChildren: (node: AstNode, callback: NodeCallback) -> (),
    
    -- Selective traversal
    visitByType: (nodeType: string, callback: NodeCallback) -> (),
    visitWithFilter: (filter: NodeFilter, callback: NodeCallback) -> (),
    
    -- Traversal control
    stop: () -> (),
    skip: () -> (),
    getCurrentPath: () -> {AstNode},
}

export type NodeCallback = (node: AstNode, path: {AstNode}) -> ()
export type NodeFilter = (node: AstNode) -> boolean

export type AstNode = {
    type: string,
    location: Location,
    children: {AstNode}?,
    parent: AstNode?,
    [string]: any, -- Node-specific properties
}

export type Location = {
    start: Position,
    ["end"]: Position,
}

export type Position = {
    line: number,
    column: number,
    offset: number,
}
```

### AST Visitor Functions
```luau
-- Visitor creation
export function createAstVisitor(ast: AstNode): AstVisitor
export function createFilteredVisitor(ast: AstNode, filter: NodeFilter): AstVisitor

-- Traversal utilities
export function getNodePath(node: AstNode): {AstNode}
export function findNodes(ast: AstNode, predicate: NodeFilter): {AstNode}
export function getNodeByLocation(ast: AstNode, location: Location): AstNode?
```

## 7. Error Handling Interface

### Error Types
```luau
export type LintError = {
    type: ErrorType,
    message: string,
    filePath: string?,
    location: Location?,
    cause: string?,
    stack: string?,
}

export type ErrorType = 
    | "ParseError"
    | "ConfigError" 
    | "RuleError"
    | "FileSystemError"
    | "ValidationError"
    | "InternalError"

export type ErrorHandler = {
    handleError: (error: LintError) -> ErrorAction,
    reportError: (error: LintError) -> (),
    shouldContinue: (error: LintError) -> boolean,
}

export type ErrorAction = "continue" | "skip" | "abort" | "retry"
```

### Error Handling Functions
```luau
-- Error creation
export function createLintError(type: ErrorType, message: string, context: ErrorContext?): LintError
export function wrapError(originalError: any, context: ErrorContext): LintError

-- Error handling
export function createErrorHandler(options: ErrorHandlerOptions?): ErrorHandler
export function handleGracefully<T>(fn: () -> T, fallback: T): T
export function retryWithBackoff<T>(fn: () -> T, maxRetries: number): T?
```

## 8. Cache Interface

### Cache Types
```luau
export type Cache = {
    -- Basic operations
    get: (key: string) -> any?,
    set: (key: string, value: any, ttl: number?) -> (),
    has: (key: string) -> boolean,
    delete: (key: string) -> boolean,
    clear: () -> (),
    
    -- Statistics
    getStats: () -> CacheStats,
}

export type CacheStats = {
    hits: number,
    misses: number,
    entries: number,
    hitRate: number,
}
```

### Cache Functions
```luau
-- Cache creation
export function createMemoryCache(maxSize: number?): Cache
export function createFileCache(cacheDir: string): Cache
export function createNullCache(): Cache

-- Cache utilities
export function generateCacheKey(filePath: string, content: string): string
export function isCacheValid(filePath: string, cacheEntry: any): boolean
```

## 9. CLI Interface

### CLI Types
```luau
export type CliCommand = {
    name: string,
    description: string,
    options: {CliOption},
    handler: (args: CliArgs) -> number,
}

export type CliOption = {
    name: string,
    shortName: string?,
    description: string,
    type: "string" | "number" | "boolean" | "array",
    required: boolean?,
    default: any?,
}

export type CliArgs = {
    command: string,
    files: {string},
    options: {[string]: any},
}
```

### CLI Functions
```luau
-- Command management
export function registerCommand(command: CliCommand): ()
export function parseArgs(args: {string}): CliArgs
export function printHelp(command: string?): ()
export function printVersion(): ()

-- Utility functions
export function validateArgs(args: CliArgs): ValidationResult
export function expandFileArgs(files: {string}): {string}
```

## 10. Plugin Interface (Future)

### Plugin Types
```luau
export type Plugin = {
    name: string,
    version: string,
    rules: {Rule}?,
    processors: {FileProcessor}?,
    formatters: {Formatter}?,
    
    initialize: (context: PluginContext) -> (),
    cleanup: () -> (),
}

export type PluginContext = {
    registerRule: (rule: Rule) -> (),
    registerProcessor: (processor: FileProcessor) -> (),
    registerFormatter: (formatter: Formatter) -> (),
    getConfig: () -> Config,
}
```

This interface definition provides a comprehensive foundation for implementing the luau-lint architecture, ensuring type safety and clear contracts between components.
