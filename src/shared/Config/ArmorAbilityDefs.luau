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
	warbound_armorpassive = {
		id = "warbound_armorpassive",
		name = "Warbound",
		desc = "Direct damage dealt +5%",
		kind = "Passive",
	},
	phantom_step_armorpassive = {
		id = "phantom_step_armorpassive",
		name = "Phantom Step",
		desc = "Crit chance +6% (flat)",
		kind = "Passive",
	},
	arcanist_mind_armorpassive = {
		id = "arcanist_mind_armorpassive",
		name = "Arcanist Mind",
		desc = "+14 Status Potency (flat)",
		kind = "Passive",
	},
	lifeweaver_grace_armorpassive = {
		id = "lifeweaver_grace_armorpassive",
		name = "Lifeweaver Grace",
		desc = "+12 Buff Potency (flat)",
		kind = "Passive",
	},
	ward_step_armorpassive = {
		id = "ward_step_armorpassive",
		name = "Ward Step",
		desc = "On Dodge: self Regen 5 HP/s for 3s",
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
	charger_armoractive = {
		id = "charger_armoractive",
		name = "Iron Charge",
		desc = "Dash forward · 115% weapon base · armor element · brief hyper armor",
		kind = "Active",
		defaultCooldownSec = 9,
	},
	disengage_armoractive = {
		id = "disengage_armoractive",
		name = "Shadow Retreat",
		desc = "Back-dash 10 stud · CC immunity 1.2s · no damage",
		kind = "Active",
		defaultCooldownSec = 10,
	},
	crushing_palm_armoractive = {
		id = "crushing_palm_armoractive",
		name = "Crushing Palm",
		desc = "Single target · 170% weapon base · armor element",
		kind = "Active",
		defaultCooldownSec = 10,
	},
	nova_burst_armoractive = {
		id = "nova_burst_armoractive",
		name = "Element Nova",
		desc = "AoE burst · 9 stud radius · 100% weapon base · armor element",
		kind = "Active",
		defaultCooldownSec = 12,
	},
	shove_palm_armoractive = {
		id = "shove_palm_armoractive",
		name = "Seismic Shove",
		desc = "Single · 85% weapon base · knockback · armor element",
		kind = "Active",
		defaultCooldownSec = 9,
	},
	fan_volley_armoractive = {
		id = "fan_volley_armoractive",
		name = "Gale Fan",
		desc = "Cone · 14 stud · 3 hits × 55% · armor element",
		kind = "Active",
		defaultCooldownSec = 10,
	},
	arc_bolt_armoractive = {
		id = "arc_bolt_armoractive",
		name = "Arc Bolt",
		desc = "Ranged bolt · 26 stud · 135% weapon base · armor element",
		kind = "Active",
		defaultCooldownSec = 9,
	},
	war_frenzy_armoractive = {
		id = "war_frenzy_armoractive",
		name = "Battle Frenzy",
		desc = "Self: +8% damage dealt for 4s",
		kind = "Active",
		defaultCooldownSec = 14,
	},
	lifewave_armoractive = {
		id = "lifewave_armoractive",
		name = "Tidewave",
		desc = "Ally cone heal · 16 stud · 38 base HP",
		kind = "Active",
		defaultCooldownSec = 12,
	},
	mend_touch_armoractive = {
		id = "mend_touch_armoractive",
		name = "Mend Touch",
		desc = "Single ally heal · 18 stud · 55 base HP",
		kind = "Active",
		defaultCooldownSec = 10,
	},
	riposte_bash_armoractive = {
		id = "riposte_bash_armoractive",
		name = "Riposte Bash",
		desc = "Quick shield bash · 7 stud · 125% weapon base",
		kind = "Active",
		defaultCooldownSec = 7,
	},
	shield_ram_armoractive = {
		id = "shield_ram_armoractive",
		name = "Shield Ram",
		desc = "Shield charge · 9 stud · 105% + knockback",
		kind = "Active",
		defaultCooldownSec = 11,
	},
	bulwark_wall_armoractive = {
		id = "bulwark_wall_armoractive",
		name = "Bulwark",
		desc = "Self Fortify 5s · −15% damage taken",
		kind = "Active",
		defaultCooldownSec = 16,
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
	fortifyaura_armorpassive = {
		id = "fortifyaura_armorpassive",
		name = "Fortify Aura",
		desc = "When you apply Fortify: allies within 8 stud gain Fortify 50% duration at 50% strength",
		kind = "Passive",
	},
	thorn_reflect_armorpassive = {
		id = "thorn_reflect_armorpassive",
		name = "Thorn",
		desc = "Reflect 20% of direct HP damage taken back to the attacker",
		kind = "Passive",
	},
	stormgrasp_armorpassive = {
		id = "stormgrasp_armorpassive",
		name = "Stormgrasp",
		desc = "+10 Status Potency (flat)",
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
