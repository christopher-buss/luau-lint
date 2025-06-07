Concept for AST Node Type Mapping.

```luau
export type TagToAstTypeMap = {
	["anonymousfunction"]: Luau.AstExprAnonymousFunction,
	["assign"]: Luau.AstStatAssign,
	["binary"]: Luau.AstExprBinary,
	["block"]: Luau.AstStatBlock,
	["boolean"]: Luau.AstExprConstantBool,
	["call"]: Luau.AstExprCall,
	["compoundassign"]: Luau.AstStatCompoundAssign,
	["expression"]: Luau.AstStatExpr,
	["for"]: Luau.AstStatFor,
	["forin"]: Luau.AstStatForIn,
	["function"]: Luau.AstStatFunction,
	["global"]: Luau.AstExprGlobal,
	["group"]: Luau.AstExprGroup,
	["if"]: Luau.AstStatIf,
	["ifexpression"]: Luau.AstExprIfElse,
	["indexexpr"]: Luau.AstExprIndexExpr,
	["indexname"]: Luau.AstExprIndexName,
	["interpolatedstring"]: Luau.AstExprInterpString,
	["local"]: Luau.AstExprLocal,
	["localdeclaration"]: Luau.AstStatLocal,
	["localfunction"]: Luau.AstStatLocalFunction,
	["localreference"]: Luau.AstLocal,
	["nil"]: Luau.AstExprConstantNil,
	["number"]: Luau.AstExprConstantNumber,
	["repeat"]: Luau.AstStatRepeat,
	["return"]: Luau.AstStatReturn,
	["stattypefunction"]: Luau.AstStatTypeFunction,
	["string"]: Luau.AstExprConstantString,
	["table"]: Luau.AstExprTable,
	["tableitem"]: Luau.AstExprTableItem,
	["token"]: Luau.Token,
	["typealias"]: Luau.AstStatTypeAlias,
	["typearray"]: Luau.AstTypeArray,
	["typeassertion"]: Luau.AstExprTypeAssertion,
	["typeboolean"]: Luau.AstTypeSingletonBool,
	["typefunction"]: Luau.AstTypeFunction,
	["typegroup"]: Luau.AstTypeGroup,
	["typeintersection"]: Luau.AstTypeIntersection,
	["typepackexplicit"]: Luau.AstTypePackExplicit,
	["typepackgeneric"]: Luau.AstTypePackGeneric,
	["typepackvariadic"]: Luau.AstTypePackVariadic,
	["typereference"]: Luau.AstTypeReference,
	["typestring"]: Luau.AstTypeSingletonString,
	["typetable"]: Luau.AstTypeTable,
	["typetypeof"]: Luau.AstTypeTypeof,
	["typeunion"]: Luau.AstTypeUnion,
	["unary"]: Luau.AstExprUnary,
	["varargs"]: Luau.AstExprVarargs,
	["while"]: Luau.AstStatWhile,
}
```

```luau
--> AST Type Mapping -------------------------------------------------------------------
--[=[
    Gets the AST type corresponding to a string literal tag at runtime.
    
    Usage:
    local function x()
        return {
            ["group"] = function(node) -- node is Luau.AstExprGroup
                -- handle group node
            end,
            ["binary"] = function(node) -- node is Luau.AstExprBinary
                -- handle binary node
            end
        }
    end 
]=]
export type function GetAstType(input: type)
	-- Assert that the tag is a string literal
	assert_is(input, "tag", input, "singleton")

	local tag_value = input:value()
	assert_is(types.singleton(tag_value), "tag value", "string")

	-- Get the type from the mapping
	local mapping_type = types.singleton(TagToAstTypeMap)
	local ast_type = mapping_type:readproperty(input)

	if ast_type then
		return ast_type:components()
	else
		error(`Unknown AST tag: '{tag_value}'`)
	end
end
```