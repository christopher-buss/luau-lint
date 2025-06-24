--!strict

--[=[
	@class RuleRegistry

	Rule Registration System for luau-lint Plugin API

	This module implements the rule registration system that manages rule definitions,
	validates rule metadata, and provides efficient batching of rules by their node
	type interests. This enables the engine to handle 200+ rules efficiently by only
	calling relevant rules for each node type.

	## Key Features

	- **Rule Registration**: Clean API for registering rules with validation
	- **Node Type Batching**: Groups rules by the node types they listen to
	- **Rule Metadata**: Stores and retrieves rule metadata and configuration
	- **Validation**: Comprehensive validation of rule definitions
	- **Performance**: Optimized for handling hundreds of rules efficiently

	## Example Usage

	```luau
	local registry = RuleRegistry.createRuleRegistry()

	-- Register rules
	registry.registerRule(myRule)
	registry.registerRules({ rule1, rule2, rule3 })

	-- Get rules interested in specific node types
	local identifierRules = registry.getRulesForNodeType("Identifier")
	local allRules = registry.getAllRules()

	-- Check registration status
	local isRegistered = registry.isRuleRegistered("no-unused-variables")
	```

	@since v0.1.0
]=]

local Result = require("@batteries/result")
local ApiTypes = require("../api-types/api")
local Rule = require("../rule/rule")

type RuleType = ApiTypes.Rule
type RuleCreateFunction = ApiTypes.RuleCreateFunction
type ListenerMap = ApiTypes.ListenerMap
type NodeTag = ApiTypes.NodeTag

--[=[
	@interface RegisteredRule
	@within RuleRegistry
	.rule ApiTypes.Rule -- The original rule definition
	.nodeTypes { ApiTypes.NodeType } -- Array of node types this rule listens to
	.enabled boolean -- Whether the rule is currently enabled
	.options any? -- Rule-specific configuration options

	Internal representation of a registered rule with metadata.
]=]
export type RegisteredRule = {
	rule: RuleType,
	nodeTypes: { NodeTag },
	enabled: boolean,
	options: any?,
}

--[=[
	@interface RuleRegistry
	@within RuleRegistry
	.registerRule (rule: ApiTypes.Rule, options: any?) -> () -- Register a single rule
	.registerRules (rules: { ApiTypes.Rule }) -> () -- Register multiple rules
	.unregisterRule (ruleId: string) -> boolean -- Unregister a rule by ID
	.getAllRules () -> { RegisteredRule } -- Get all registered rules
	.getRuleById (ruleId: string) -> RegisteredRule? -- Get a specific rule by ID
	.getRulesForNodeType (nodeType: ApiTypes.NodeType) -> { RegisteredRule } -- Get rules interested in a node type
	.getAllNodeTypes () -> { ApiTypes.NodeType } -- Get all node types that have listeners
	.isRuleRegistered (ruleId: string) -> boolean -- Check if a rule is registered
	.setRuleEnabled (ruleId: string, enabled: boolean) -> boolean -- Enable/disable a rule
	.setRuleOptions (ruleId: string, options: any) -> boolean -- Update rule options
	.clear () -> () -- Remove all rules from registry

	Registry interface for managing rule definitions and metadata.
]=]
export type RuleRegistry = {
	registerRule: (rule: RuleType, options: any?) -> (),
	registerRules: (rules: { RuleType }) -> (),
	unregisterRule: (ruleId: string) -> boolean,
	getAllRules: () -> { RegisteredRule },
	getRuleById: (ruleId: string) -> RegisteredRule?,
	getRulesForNodeType: (nodeType: NodeTag) -> { RegisteredRule },
	getAllNodeTypes: () -> { NodeTag },
	isRuleRegistered: (ruleId: string) -> boolean,
	setRuleEnabled: (ruleId: string, enabled: boolean) -> boolean,
	setRuleOptions: (ruleId: string, options: any) -> boolean,
	clear: () -> (),
}

--[=[
	Creates a new rule registry instance.

	The registry manages rule definitions, validates them, and provides efficient
	access patterns for the rule execution engine.

	@return RuleRegistry -- A new registry instance

	@since v0.1.0
]=]
local function createRuleRegistry(): RuleRegistry
	-- Internal storage
	local rules: { [string]: RegisteredRule } = {}
	local nodeTypeToRules: { [NodeTag]: { RegisteredRule } } = {}

	--[=[
		Extracts node types from a rule's listener map.

		@param rule Rule -- The rule to analyze
		@return { NodeType } -- Array of node types the rule listens to

		@since v0.1.0
	]=]
	local function extractNodeTypes(rule: RuleType): { NodeTag }
		local status = Result.pcall(function(): ListenerMap
			return rule.create({} :: any)
		end)

		if not status.success then
			error(`Error while loading rule {rule.id}: {status.err}`)
		end

		local listeners = status.value

		-- Validate the listener map
		local isValid, errorMessage = Rule.validateListenerMap(listeners)
		if not isValid then
			error(`Invalid listener map for rule {rule.id}: {errorMessage}`)
		end

		-- Extract node types
		local nodeTypes: { NodeTag } = {}
		for nodeType in listeners :: { string } do
			table.insert(nodeTypes, nodeType)
		end

		return nodeTypes
	end

	--[=[
		Updates the node type index when a rule is added or removed.

		@param registeredRule RegisteredRule -- The rule to update index for
		@param add boolean -- True to add, false to remove

		@since v0.1.0
	]=]
	local function updateNodeTypeIndex(registeredRule: RegisteredRule, add: boolean)
		for _, nodeType in registeredRule.nodeTypes do
			if add then
				if not nodeTypeToRules[nodeType] then
					nodeTypeToRules[nodeType] = {}
				end
				table.insert(nodeTypeToRules[nodeType], registeredRule)
			else
				if nodeTypeToRules[nodeType] then
					-- Remove the rule from this node type's list
					for i, rule in nodeTypeToRules[nodeType] do
						if rule.rule.id == registeredRule.rule.id then
							table.remove(nodeTypeToRules[nodeType], i)
							break
						end
					end

					-- Clean up empty arrays
					if #nodeTypeToRules[nodeType] == 0 then
						nodeTypeToRules[nodeType] = nil
					end
				end
			end
		end
	end

	--[=[
		Registers a single rule with optional configuration.

		@param rule Rule -- The rule definition to register
		@param options any? -- Optional rule-specific configuration

		@error "RuleError" -- If rule validation fails or rule ID already exists

		@since v0.1.0
	]=]
	local function registerRule(rule: RuleType, options: any?): ()
		-- Validate the rule
		local isValid, errorMessage = Rule.validateRule(rule)
		if not isValid then
			error(`Invalid rule definition: {errorMessage}`)
		end

		-- Check for duplicate IDs
		if rules[rule.id] then
			error(`Rule with ID '{rule.id}' is already registered`)
		end

		-- Extract node types that this rule listens to
		local nodeTypes = extractNodeTypes(rule)

		-- Create registered rule entry
		local registeredRule: RegisteredRule = {
			rule = rule,
			nodeTypes = nodeTypes,
			enabled = true,
			options = options,
		}

		-- Store the rule
		rules[rule.id] = registeredRule

		-- Update node type index
		updateNodeTypeIndex(registeredRule, true)
	end

	--[=[
		Registers multiple rules at once.

		@param ruleList { Rule } -- Array of rule definitions to register

		@error "RuleError" -- If any rule validation fails

		@since v0.1.0
	]=]
	local function registerRules(ruleList: { RuleType }): ()
		for _, rule in ruleList do
			registerRule(rule)
		end
	end

	--[=[
		Unregister a rule by its ID.

		@param ruleId string -- The ID of the rule to unregister
		@return boolean -- True if rule was found and removed, false otherwise

		@since v0.1.0
	]=]
	local function unregisterRule(ruleId: string): boolean
		local registeredRule = rules[ruleId]
		if not registeredRule then
			return false
		end

		-- Remove from node type index
		updateNodeTypeIndex(registeredRule, false)

		-- Remove from main registry
		rules[ruleId] = nil

		return true
	end

	--[=[
		Gets all registered rules.

		@return { RegisteredRule } -- Array of all registered rules

		@since v0.1.0
	]=]
	local function getAllRules(): { RegisteredRule }
		local result: { RegisteredRule } = {}
		for _, registeredRule in rules do
			table.insert(result, registeredRule)
		end

		return result
	end

	--[=[
		Gets a specific rule by its ID.

		@param ruleId string -- The ID of the rule to retrieve
		@return RegisteredRule? -- The rule if found, nil otherwise

		@since v0.1.0
	]=]
	local function getRuleById(ruleId: string): RegisteredRule?
		return rules[ruleId]
	end

	--[=[
		Gets all rules that listen to a specific node type.

		@param nodeType NodeType -- The node type to get rules for
		@return { RegisteredRule } -- Array of rules interested in this node type

		@since v0.1.0
	]=]
	local function getRulesForNodeType(nodeType: NodeTag): { RegisteredRule }
		local nodeRules = nodeTypeToRules[nodeType]
		if not nodeRules then
			return {}
		end

		-- Filter by enabled rules only
		local result: { RegisteredRule } = {}
		for _, registeredRule in nodeRules do
			if registeredRule.enabled then
				table.insert(result, registeredRule)
			end
		end

		return result
	end

	--[=[
		Gets all node types that have at least one listener.

		@return { NodeType } -- Array of all node types with listeners

		@since v0.1.0
	]=]
	local function getAllNodeTypes(): { NodeTag }
		local result: { NodeTag } = {}

		for nodeType in nodeTypeToRules :: { string } do
			table.insert(result, nodeType)
		end

		return result
	end

	--[=[
		Checks if a rule is registered.

		@param ruleId string -- The rule ID to check
		@return boolean -- True if the rule is registered, false otherwise

		@since v0.1.0
	]=]
	local function isRuleRegistered(ruleId: string): boolean
		return rules[ruleId] ~= nil
	end

	--[=[
		Enables or disables a rule.

		@param ruleId string -- The rule ID to modify
		@param enabled boolean -- Whether the rule should be enabled
		@return boolean -- True if rule was found and updated, false otherwise

		@since v0.1.0
	]=]
	local function setRuleEnabled(ruleId: string, enabled: boolean): boolean
		local registeredRule = rules[ruleId]
		if not registeredRule then
			return false
		end

		registeredRule.enabled = enabled
		return true
	end

	--[=[
		Updates the options for a rule.

		@param ruleId string -- The rule ID to modify
		@param options any -- New options for the rule
		@return boolean -- True if rule was found and updated, false otherwise

		@since v0.1.0
	]=]
	local function setRuleOptions(ruleId: string, options: any): boolean
		local registeredRule = rules[ruleId]
		if not registeredRule then
			return false
		end

		registeredRule.options = options
		return true
	end

	--[=[
		Removes all rules from the registry.

		@since v0.1.0
	]=]
	local function clear(): ()
		rules = {}
		nodeTypeToRules = {}
	end

	-- Return the registry interface
	return {
		registerRule = registerRule,
		registerRules = registerRules,
		unregisterRule = unregisterRule,
		getAllRules = getAllRules,
		getRuleById = getRuleById,
		getRulesForNodeType = getRulesForNodeType,
		getAllNodeTypes = getAllNodeTypes,
		isRuleRegistered = isRuleRegistered,
		setRuleEnabled = setRuleEnabled,
		setRuleOptions = setRuleOptions,
		clear = clear,
	}
end

return {
	-- Factory function
	createRuleRegistry = createRuleRegistry,
}
