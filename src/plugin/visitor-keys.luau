local VisitorKeys: { [string]: { string } } = {
	-- AstExprGroup
	["group"] = {
		"openParens",
		"expression",
		"closeParens",
	},

	-- AstExprConstantNil
	["nil"] = {
		-- Token fields inherited
	},

	-- AstExprConstantBool
	["boolean"] = {
		"value",
		-- Token fields inherited
	},

	-- AstExprConstantNumber
	["number"] = {
		"value",
		-- Token fields inherited
	},

	-- AstExprConstantString
	["string"] = {
		"quoteStyle",
		"blockDepth",
		-- Token fields inherited
	},

	-- AstExprLocal
	["local"] = {
		"token",
		"local",
		"upvalue",
	},

	-- AstExprGlobal
	["global"] = {
		"name",
	},

	-- AstExprVarargs
	["vararg"] = {
		-- Token fields inherited
	},

	-- AstExprCall
	["call"] = {
		"func",
		"openParens",
		"arguments",
		"closeParens",
		"self",
		"argLocation",
	},

	-- AstExprIndexName
	["indexname"] = {
		"expression",
		"accessor",
		"index",
		"indexLocation",
	},

	-- AstExprIndexExpr
	["index"] = {
		"expression",
		"openBrackets",
		"index",
		"closeBrackets",
	},

	-- AstExprFunction
	["function"] = {
		"attributes",
		"functionKeyword",
		"body",
	},

	-- AstExprTable
	["table"] = {
		"openBrace",
		"entries",
		"closeBrace",
	},

	-- AstExprUnary
	["unary"] = {
		"operator",
		"operand",
	},

	-- AstExprBinary
	["binary"] = {
		"lhsoperand",
		"operator",
		"rhsoperand",
	},

	-- AstExprInterpString
	["interpolatedstring"] = {
		"strings",
		"expressions",
	},

	-- AstExprTypeAssertion
	["cast"] = {
		"operand",
		"operator",
		"annotation",
	},

	-- AstExprIfElse
	["conditional"] = {
		"ifKeyword",
		"condition",
		"thenKeyword",
		"consequent",
		"elseifs",
		"elseKeyword",
		"antecedent",
	},

	-- AstExprError
	["error"] = {
		"expressions",
	},

	-- AstStatBlock
	["block"] = {
		"statements",
	},

	-- AstStatWhile
	["while"] = {
		"whileKeyword",
		"condition",
		"doKeyword",
		"body",
		"endKeyword",
	},

	-- AstStatRepeat
	["repeat"] = {
		"repeatKeyword",
		"body",
		"untilKeyword",
		"condition",
	},

	-- AstStatBreak
	["break"] = {
		-- Token fields inherited
	},

	-- AstStatContinue
	["continue"] = {
		-- Token fields inherited
	},

	-- AstStatReturn
	["return"] = {
		"returnKeyword",
		"expressions",
	},

	-- -- AstStatLocal
	-- ["local"] = {
	-- 	"localKeyword",
	-- 	"variables",
	-- 	"equals",
	-- 	"values",
	-- },

	-- AstStatExpr
	["expression"] = {
		"expression",
	},

	-- AstStatFor
	["for"] = {
		"forKeyword",
		"variable",
		"equals",
		"from",
		"toComma",
		"to",
		"stepComma",
		"step",
		"doKeyword",
		"body",
		"endKeyword",
	},

	-- AstStatForIn
	["forin"] = {
		"forKeyword",
		"variables",
		"inKeyword",
		"values",
		"doKeyword",
		"body",
		"endKeyword",
	},

	-- AstStatAssign
	["assign"] = {
		"variables",
		"equals",
		"values",
	},

	-- AstStatCompoundAssign
	["compoundassign"] = {
		"variable",
		"operator",
		"value",
	},

	-- AstStatLocalFunction
	["localfunction"] = {
		"attributes",
		"localKeyword",
		"functionKeyword",
		"name",
		"body",
	},

	-- AstStatTypeAlias
	["typealias"] = {
		"export",
		"typeToken",
		"name",
		"openGenerics",
		"generics",
		"genericPacks",
		"closeGenerics",
		"equals",
		"type",
	},

	-- AstStatTypeFunction
	["typefunction"] = {
		"export",
		"type",
		"functionKeyword",
		"name",
		"body",
	},

	-- AstGenericType
	["generic"] = {
		"name",
		"equals",
		"default",
	},

	-- AstGenericTypePack
	["genericpack"] = {
		"name",
		"ellipsis",
		"equals",
		"default",
	},

	-- AstTypeReference
	["reference"] = {
		"prefix",
		"prefixPoint",
		"name",
		"openParameters",
		"parameters",
		"closeParameters",
	},

	-- AstTypeTypeof
	["typeof"] = {
		"typeof",
		"openParens",
		"expression",
		"closeParens",
	},

	-- AstTypeOptional (from union serialization)
	["optional"] = {
		-- Token fields inherited
	},

	-- AstTypeUnion
	["union"] = {
		"leading",
		"types",
	},

	-- AstTypeIntersection
	["intersection"] = {
		"leading",
		"types",
	},

	-- AstTypeTable (array variant)
	["array"] = {
		"openBrace",
		"access",
		"type",
		"closeBrace",
	},

	-- AstTypePackExplicit
	["explicit"] = {
		"openParens",
		"types",
		"tailType",
		"closeParens",
	},

	-- AstTypePackVariadic
	["variadic"] = {
		"ellipsis",
		"type",
	},

	-- AstAttribute
	["attribute"] = {
		-- Token fields inherited
	},

	-- Eof
	["eof"] = {
		-- Token fields inherited
	},

	-- AstStatFunction
	["statfunction"] = {
		"attributes",
		"functionKeyword",
		"name",
		"body",
	},

	["expranonymousfunction"] = {
		"attributes",
		"functionKeyword",
		"body",
	},

	["statlocal"] = {
		"localKeyword",
		"variables",
		"equals",
		"values",
	},

	["exprlocal"] = {
		"token",
		"local",
		"upvalue",
	},
}

type DiscriminatorPattern = {
	nodeType: string,
	check: (node: any) -> boolean,
}

-- Define discriminator patterns for ambiguous tags
local DiscriminatorPatterns: { [string]: { DiscriminatorPattern } } = {
	["function"] = {
		{
			nodeType = "statfunction",
			check = function(node: any): boolean
				return node.name ~= nil
			end,
		},
		{
			nodeType = "expranonymousfunction",
			check = function(node: any): boolean
				return node.name == nil
			end,
		},
	},
	["local"] = {
		{
			nodeType = "statlocal",
			check = function(node: any): boolean
				return node.variables ~= nil and node.localKeyword ~= nil
			end,
		},
		{
			nodeType = "exprlocal",
			check = function(node: any): boolean
				return node.token ~= nil and node["local"] ~= nil
			end,
		},
	},
}

local function getNodeType(node: any): string
	if not node or type(node) ~= "table" or not node.tag then
		return "unknown"
	end

	local tag = node.tag :: string
	local patterns = DiscriminatorPatterns[tag]
	if patterns == nil then
		return tag
	end

	for _, pattern in patterns do
		if pattern.check(node) then
			return pattern.nodeType
		end
	end

	-- Fallback if no pattern matches
	print(`Could not discriminate node type for tag "${tag}"`)
	return tag
end

return {
	DiscriminatorPatterns = DiscriminatorPatterns,
	VisitorKeys = VisitorKeys,
	getNodeType = getNodeType,
}
