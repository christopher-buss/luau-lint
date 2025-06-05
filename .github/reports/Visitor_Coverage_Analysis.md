# Visitor Coverage Analysis for Rule API

## Executive Summary

The analysis of Lute's visitor system shows that using `AstExpr | AstStat | AstType` as the basis for enum-based visitor registration provides **substantial but not complete** coverage of all visitor methods. To achieve 100% coverage, we need to extend the union to include additional types.

## Complete Coverage Solution

```luau
-- Complete visitor target enumeration
type VisitorTarget = AstExpr | AstStat | AstType | AstTypePack | AstLocal | Token | AstExprTableItem
```

## Detailed Coverage Analysis

### ✅ Covered by AstExpr | AstStat | AstType (42/56 methods)

#### Statement Visitors (14/14) ✅
- `visitBlock: AstStatBlock`
- `visitIf: AstStatIf`
- `visitWhile: AstStatWhile` 
- `visitRepeat: AstStatRepeat`
- `visitReturn: AstStatReturn`
- `visitLocalDeclaration: AstStatLocal`
- `visitFor: AstStatFor`
- `visitForIn: AstStatForIn`
- `visitAssign: AstStatAssign`
- `visitCompoundAssign: AstStatCompoundAssign`
- `visitFunction: AstStatFunction`
- `visitLocalFunction: AstStatLocalFunction`
- `visitTypeAlias: AstStatTypeAlias`
- `visitStatTypeFunction: AstStatTypeFunction`

#### Expression Visitors (15/15) ✅
- `visitExpression: AstExpr` (general)
- `visitLocalReference: AstExprLocal`
- `visitGlobal: AstExprGlobal`
- `visitCall: AstExprCall`
- `visitUnary: AstExprUnary`
- `visitBinary: AstExprBinary`
- `visitAnonymousFunction: AstExprAnonymousFunction`
- `visitTable: AstExprTable`
- `visitIndexName: AstExprIndexName`
- `visitIndexExpr: AstExprIndexExpr`
- `visitGroup: AstExprGroup`
- `visitInterpolatedString: AstExprInterpString`
- `visitTypeAssertion: AstExprTypeAssertion`
- `visitIfExpression: AstExprIfElse`
- `visitVarargs: AstExprVarargs`

#### Type Visitors (10/10) ✅
- `visitTypeReference: AstTypeReference`
- `visitTypeBoolean: AstTypeSingletonBool`
- `visitTypeString: AstTypeSingletonString`
- `visitTypeTypeof: AstTypeTypeof`
- `visitTypeGroup: AstTypeGroup`
- `visitTypeUnion: AstTypeUnion`
- `visitTypeIntersection: AstTypeIntersection`
- `visitTypeArray: AstTypeArray`
- `visitTypeTable: AstTypeTable`
- `visitTypeFunction: AstTypeFunction`

#### Constant Expression Visitors (3/3) ✅
- `visitNil: AstExprConstantNil`
- `visitString: AstExprConstantString`
- `visitBoolean: AstExprConstantBool`
- `visitNumber: AstExprConstantNumber`

### ❌ Missing from AstExpr | AstStat | AstType (14/56 methods)

#### Type Pack Visitors (3 methods)
- `visitTypePackExplicit: AstTypePackExplicit`
- `visitTypePackGeneric: AstTypePackGeneric`
- `visitTypePackVariadic: AstTypePackVariadic`

#### Component/Token Visitors (3 methods)
- `visitToken: Token`
- `visitLocal: AstLocal`
- `visitTableItem: AstExprTableItem`

#### End Visitors (8 methods)
- `visitBlockEnd: AstStatBlock`
- `visitLocalDeclarationEnd: AstStatLocal`
- `visitExpressionEnd: AstExpr`
- (Plus 5 other "End" methods)

## Recommendation

For the Rule API, we should use the **complete coverage approach**:

```luau
-- Rule visitor registration using comprehensive enum
type VisitorNodeType = 
    -- Statements
    | "Block" | "If" | "While" | "Repeat" | "Return" | "LocalDeclaration"
    | "For" | "ForIn" | "Assign" | "CompoundAssign" | "Function" 
    | "LocalFunction" | "TypeAlias" | "StatTypeFunction"
    
    -- Expressions  
    | "Expression" | "LocalReference" | "Global" | "Call" | "Unary" | "Binary"
    | "AnonymousFunction" | "Table" | "TableItem" | "IndexName" | "IndexExpr"
    | "Group" | "InterpolatedString" | "TypeAssertion" | "IfExpression"
    | "Nil" | "String" | "Boolean" | "Number" | "Varargs"
    
    -- Types
    | "TypeReference" | "TypeBoolean" | "TypeString" | "TypeTypeof" 
    | "TypeGroup" | "TypeUnion" | "TypeIntersection" | "TypeArray"
    | "TypeTable" | "TypeFunction"
    
    -- Type Packs
    | "TypePackExplicit" | "TypePackGeneric" | "TypePackVariadic"
    
    -- Components
    | "Token" | "Local"
```

This provides complete coverage of all 56 visitor methods in Lute's system and ensures rules can register for any AST node type they need to analyze.

## Implementation Notes

1. **Visitor Method Mapping**: Each enum value maps directly to a `visit{EnumValue}` method in Lute's visitor interface
2. **Type Safety**: The enum approach provides compile-time validation that registered visitor types are valid
3. **Extensibility**: If Lute adds new AST node types, we simply extend the enum
4. **Performance**: Enum-based registration is more efficient than string-based registration with runtime validation
