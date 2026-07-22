--[[
	Global armor ability catalog — `*_armorpassive` and `*_armoractive` ids.
	Armor item defs reference by id; runtime hooks TBD per passive/active.
]]

local ArmorAbilityDefs = {}

export type ArmorAbilityKind = "Passive" | "Active"

export type ArmorAbilityDef = {
	id: string,
	name: string,
	desc: string,
	kind: ArmorAbilityKind,
	defaultCooldownSec: number?,
}

local CATALOG: { [string]: ArmorAbilityDef } = {
	-- Add armor passives/actives here when armor is redesigned.
}

function ArmorAbilityDefs.Get(abilityId: string): ArmorAbilityDef?
	return CATALOG[abilityId]
end

function ArmorAbilityDefs.List(): { ArmorAbilityDef }
	local out: { ArmorAbilityDef } = {}
	for _, def in CATALOG do
		table.insert(out, def)
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	return out
end

function ArmorAbilityDefs.AbilitySlot(abilityId: string, flavorName: string?, cooldownSec: number?): any
	local def = ArmorAbilityDefs.Get(abilityId)
	if not def then
		error(`[ArmorAbilityDefs] Unknown armor ability: {abilityId}`)
	end
	local slot: any = {
		id = def.id,
		name = flavorName or def.name,
		slotType = def.kind,
		desc = def.desc,
	}
	if def.kind == "Active" then
		slot.cooldownSec = cooldownSec or def.defaultCooldownSec or 10
	end
	return slot
end

function ArmorAbilityDefs.HydrateAbilitySlot(slot: any): any
	if not slot or (slot.slotType ~= "Passive" and slot.slotType ~= "Active") then
		return slot
	end
	local def = ArmorAbilityDefs.Get(slot.id)
	if not def then
		error(`[ArmorAbilityDefs] Unknown armor ability: {tostring(slot.id)}`)
	end
	local out: any = {
		id = def.id,
		name = slot.name or def.name,
		slotType = def.kind,
		desc = slot.desc or def.desc,
	}
	if def.kind == "Active" then
		out.cooldownSec = slot.cooldownSec or def.defaultCooldownSec or 10
	end
	return out
end

return ArmorAbilityDefs
