--[[
	Merge WeaponFrame parts → ResolvedWeapon combat profile.
]]

local ItemDefs = require(script.Parent.Parent.Config.ItemDefs)
local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local CombatKind = require(script.Parent.CombatKind)

local WeaponResolver = {}

export type ResolvedWeapon = {
	frameUuid: string,
	complete: boolean,
	handleType: string?,
	family: string?,
	subFamily: string?,
	kind: string?,
	element: string,
	scaling: string?,
	baseDamage: number,
	asTier: string?,
	attackSpeedMult: number,
	abilities: { any }?,
	familyPerk: string?,
	displayName: string,
	handleDefId: string?,
	bladeDefId: string?,
	pommelDefId: string?,
	gemDefId: string?,
	handleMeshKey: string?,
	bladeMeshKey: string?,
	pommelMeshKey: string?,
}

local EMPTY: ResolvedWeapon = {
	frameUuid = "",
	complete = false,
	handleType = nil,
	family = nil,
	subFamily = nil,
	kind = nil,
	element = "Neutral",
	scaling = "STR",
	baseDamage = CombatConfig.DefaultWeaponBase,
	asTier = "B",
	attackSpeedMult = 1,
	abilities = {},
	familyPerk = nil,
	displayName = "Incomplete Weapon",
	handleDefId = nil,
	bladeDefId = nil,
	pommelDefId = nil,
	gemDefId = nil,
	handleMeshKey = nil,
	bladeMeshKey = nil,
	pommelMeshKey = nil,
}

local function defFor(inst: any?): any?
	if not inst then
		return nil
	end
	return ItemDefs.Get(inst.defId)
end

function WeaponResolver.ResolveFrame(userId: number, frameInst: any, inventoryFind: (number, string) -> any?): ResolvedWeapon
	if not frameInst or frameInst.defId ~= "weapon_frame" then
		return table.clone(EMPTY)
	end

	local parts = frameInst.parts or {}
	local handleInst = parts.handle and inventoryFind(userId, parts.handle)
	local bladeInst = parts.blade and inventoryFind(userId, parts.blade)
	local pommelInst = parts.pommel and inventoryFind(userId, parts.pommel)
	local gemInst = frameInst.gemUuid and inventoryFind(userId, frameInst.gemUuid)

	local handleDef = defFor(handleInst)
	local bladeDef = defFor(bladeInst)
	local pommelDef = defFor(pommelInst)
	local gemDef = defFor(gemInst)

	local complete = handleDef ~= nil and bladeDef ~= nil and pommelDef ~= nil
	if not complete then
		local partial = table.clone(EMPTY)
		partial.frameUuid = frameInst.uuid
		partial.displayName = "Incomplete Frame"
		return partial
	end

	local bladeMult = bladeDef.bladeDamageMult or 1
	local pommelDmg = pommelDef.damageMult or 1
	local pommelAs = pommelDef.attackSpeedMult or 1
	local upgradeMult = 1
	if bladeInst and typeof((bladeInst :: any).upgradeLevel) == "number" then
		local UpgradeDefs = require(script.Parent.Parent.Config.UpgradeDefs)
		local lvl = (bladeInst :: any).upgradeLevel
		if lvl > 0 then
			upgradeMult = 1 + lvl * UpgradeDefs.DamagePctPerLevel
		end
	end
	local baseDamage = math.floor((handleDef.baseDamage or CombatConfig.DefaultWeaponBase) * bladeMult * pommelDmg * upgradeMult + 0.5)

	local element = "Neutral"
	if gemDef and gemDef.element then
		element = gemDef.element
	end

	local displayName = bladeDef.name or "Blade"

	local abilities = {}
	if bladeDef.abilities then
		for _, ab in bladeDef.abilities do
			table.insert(abilities, ab)
		end
	end

	return {
		frameUuid = frameInst.uuid,
		complete = true,
		handleType = handleDef.handleType,
		family = bladeDef.family,
		subFamily = bladeDef.subFamily,
		kind = CombatKind.Resolve(handleDef.handleType, bladeDef.family, bladeDef.combatKind or bladeDef.kind),
		element = element,
		scaling = handleDef.scaling or "STR",
		baseDamage = baseDamage,
		asTier = handleDef.asTier or handleDef.baseAsTier or "B",
		attackSpeedMult = pommelAs,
		abilities = abilities,
		familyPerk = bladeDef.familyPerk,
		displayName = displayName,
		handleDefId = handleDef.id,
		bladeDefId = bladeDef.id,
		pommelDefId = pommelDef.id,
		gemDefId = gemDef and gemDef.id or nil,
		handleMeshKey = handleDef.meshKey,
		bladeMeshKey = bladeDef.meshKey,
		pommelMeshKey = pommelDef.meshKey,
	}
end

--- Build a pseudo-def for WeaponFamilyConfig compatibility
function WeaponResolver.AsItemDef(resolved: ResolvedWeapon): any
	return {
		id = resolved.frameUuid,
		name = resolved.displayName,
		kind = resolved.kind,
		family = resolved.family,
		subFamily = resolved.subFamily,
		element = resolved.element,
		scaling = resolved.scaling,
		asTier = resolved.asTier,
		baseDamage = resolved.baseDamage,
		attackSpeedMult = resolved.attackSpeedMult,
		familyPerk = resolved.familyPerk,
		bladeDefId = resolved.bladeDefId,
		abilities = resolved.abilities,
	}
end

function WeaponResolver.IsWeaponFrame(inst: any?): boolean
	return inst ~= nil and inst.defId == "weapon_frame"
end

return WeaponResolver
