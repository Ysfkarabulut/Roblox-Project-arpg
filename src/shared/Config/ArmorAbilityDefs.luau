--[[
	Global armor ability catalog — `*_armorpassive` / `*_armoractive`.
	Item defs reference by id; Combat params for actives → AbilityRuntime.
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
	carapace_armorpassive = {
		id = "carapace_armorpassive",
		name = "Carapace",
		desc = "When you take Direct HP damage: 10% chance apply chest element status to attacker (not chip; no chain)",
		kind = "Passive",
	},
	unbound_hide_armorpassive = {
		id = "unbound_hide_armorpassive",
		name = "Unbound Hide",
		desc = "Direct taken −3% (after DR) · no Thorn",
		kind = "Passive",
	},
	helm_pulse_armoractive = {
		id = "helm_pulse_armoractive",
		name = "Helm Pulse",
		desc = "Self: next 2 light attacks apply armor element · 6s window · stam 0",
		kind = "Active",
		defaultCooldownSec = 14,
	},
	stone_focus_armorpassive = {
		id = "stone_focus_armorpassive",
		name = "Stone Focus",
		desc = "Fortify from any source: duration +0.5s",
		kind = "Passive",
	},
	hand_touch_armoractive = {
		id = "hand_touch_armoractive",
		name = "Element Touch",
		desc = "Touch strike · 6 stud · 120% main WeaponBase · armor element · stam 0",
		kind = "Active",
		defaultCooldownSec = 11,
	},
	dodge_step_armorpassive = {
		id = "dodge_step_armorpassive",
		name = "Element Step",
		desc = "On Dodge start: armor element status to enemies in 4 stud radius at dodge origin",
		kind = "Passive",
	},
	quiet_step_armorpassive = {
		id = "quiet_step_armorpassive",
		name = "Quiet Step",
		desc = "Dodge stamina cost −8%",
		kind = "Passive",
	},
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

function ArmorAbilityDefs.NormalizeAbilities(abilities: { any }?): { any }
	local out: { any } = {}
	if not abilities then
		return out
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			table.insert(out, ArmorAbilityDefs.AbilitySlot(ab))
		elseif ab.slotType == "Passive" or ab.slotType == "Active" then
			table.insert(out, ArmorAbilityDefs.HydrateAbilitySlot(ab))
		else
			table.insert(out, ab)
		end
	end
	return out
end

return ArmorAbilityDefs
