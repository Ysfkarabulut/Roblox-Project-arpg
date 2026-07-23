--[[
	Global weapon active catalog — stable `*_weaponactive` ids.
	Combat params live in AbilityRuntime; this file is the assignable catalog + slot builder.
]]

local WeaponActiveDefs = {}

export type WeaponActiveDef = {
	id: string,
	name: string,
	desc: string,
	defaultCooldownSec: number,
	usesGemElement: boolean,
}

local CATALOG: { [string]: WeaponActiveDef } = {
	strike_weaponactive = {
		id = "strike_weaponactive",
		name = "Strike",
		desc = "Melee thrust · 130% weapon base · gem status on hit",
		defaultCooldownSec = 9,
		usesGemElement = true,
	},
	strike_r_weaponactive = {
		id = "strike_r_weaponactive",
		name = "Strike+",
		desc = "Melee thrust · 145% weapon base · gem status on hit",
		defaultCooldownSec = 8,
		usesGemElement = true,
	},
	bolt_weaponactive = {
		id = "bolt_weaponactive",
		name = "Bolt",
		desc = "Projectile · 130% weapon base · gem status on hit",
		defaultCooldownSec = 9,
		usesGemElement = true,
	},
	bolt_r_weaponactive = {
		id = "bolt_r_weaponactive",
		name = "Bolt+",
		desc = "Projectile · 145% weapon base · gem status on hit",
		defaultCooldownSec = 8,
		usesGemElement = true,
	},
	cone_weaponactive = {
		id = "cone_weaponactive",
		name = "Cone",
		desc = "Cone sweep · 115% weapon base · gem status on hit",
		defaultCooldownSec = 9,
		usesGemElement = true,
	},
	cone_r_weaponactive = {
		id = "cone_r_weaponactive",
		name = "Cone+",
		desc = "Cone sweep · 125% weapon base · gem status on hit",
		defaultCooldownSec = 9,
		usesGemElement = true,
	},
	slam_r_weaponactive = {
		id = "slam_r_weaponactive",
		name = "Slam+",
		desc = "AoE slam · 155% weapon base · gem status on hit",
		defaultCooldownSec = 10,
		usesGemElement = true,
	},
	burst_weaponactive = {
		id = "burst_weaponactive",
		name = "Burst",
		desc = "Self buff · Fortify 3s",
		defaultCooldownSec = 14,
		usesGemElement = false,
	},
	dash_weaponactive = {
		id = "dash_weaponactive",
		name = "Dash",
		desc = "Dash strike · 120% weapon base · gem status on hit",
		defaultCooldownSec = 8,
		usesGemElement = true,
	},
	heal_weaponactive = {
		id = "heal_weaponactive",
		name = "Heal",
		desc = "Self heal · scales with Buff Potency",
		defaultCooldownSec = 12,
		usesGemElement = false,
	},
	mend_weaponactive = {
		id = "mend_weaponactive",
		name = "Mend",
		desc = "Ally heal · aim teammate · scales with Buff Potency",
		defaultCooldownSec = 11,
		usesGemElement = false,
	},
	renew_weaponactive = {
		id = "renew_weaponactive",
		name = "Renew",
		desc = "Ally HoT · aim teammate · scales with Buff Potency duration",
		defaultCooldownSec = 14,
		usesGemElement = false,
	},
	salve_weaponactive = {
		id = "salve_weaponactive",
		name = "Salve",
		desc = "Cone ally heal · scales with Buff Potency",
		defaultCooldownSec = 12,
		usesGemElement = false,
	},
	well_weaponactive = {
		id = "well_weaponactive",
		name = "Well",
		desc = "Circle ally heal at aim point · scales with Buff Potency",
		defaultCooldownSec = 13,
		usesGemElement = false,
	},
	hot_weaponactive = {
		id = "hot_weaponactive",
		name = "Rejuvenate",
		desc = "Self HoT · scales with Buff Potency duration",
		defaultCooldownSec = 14,
		usesGemElement = false,
	},
	fortify_weaponactive = {
		id = "fortify_weaponactive",
		name = "Fortify",
		desc = "Self Fortify · −10% direct taken · scales with Buff Potency duration",
		defaultCooldownSec = 14,
		usesGemElement = false,
	},
	frenzy_weaponactive = {
		id = "frenzy_weaponactive",
		name = "Frenzy",
		desc = "Self Frenzy · +8% damage dealt · scales with Buff Potency duration",
		defaultCooldownSec = 12,
		usesGemElement = false,
	},
	fan_of_knives_weaponactive = {
		id = "fan_of_knives_weaponactive",
		name = "Fan of Knives",
		desc = "Boss · cone volley · 3 hits · gem status",
		defaultCooldownSec = 10,
		usesGemElement = true,
	},
	gale_volley_weaponactive = {
		id = "gale_volley_weaponactive",
		name = "Gale Volley",
		desc = "Boss · ranged cone · 3 arrows · gem status",
		defaultCooldownSec = 11,
		usesGemElement = true,
	},
	pierce_bolt_weaponactive = {
		id = "pierce_bolt_weaponactive",
		name = "Piercing Bolt",
		desc = "Boss · line pierce · gem status on each hit",
		defaultCooldownSec = 12,
		usesGemElement = true,
	},
}

function WeaponActiveDefs.Get(abilityId: string): WeaponActiveDef?
	return CATALOG[abilityId]
end

function WeaponActiveDefs.List(): { WeaponActiveDef }
	local out: { WeaponActiveDef } = {}
	for _, def in CATALOG do
		table.insert(out, def)
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	return out
end

function WeaponActiveDefs.UsesGemElement(abilityId: string): boolean
	local def = WeaponActiveDefs.Get(abilityId)
	return def ~= nil and def.usesGemElement == true
end

function WeaponActiveDefs.AbilitySlot(abilityId: string, flavorName: string?, cooldownSec: number?): any
	local def = WeaponActiveDefs.Get(abilityId)
	if not def then
		error(`[WeaponActiveDefs] Unknown active: {abilityId}`)
	end
	return {
		id = def.id,
		name = flavorName or def.name,
		slotType = "Active",
		cooldownSec = cooldownSec or def.defaultCooldownSec,
		desc = def.desc,
	}
end

function WeaponActiveDefs.HydrateAbilitySlot(slot: any): any
	if not slot or slot.slotType ~= "Active" then
		return slot
	end
	local def = WeaponActiveDefs.Get(slot.id)
	if not def then
		error(`[WeaponActiveDefs] Unknown active: {tostring(slot.id)}`)
	end
	return {
		id = def.id,
		name = slot.name or def.name,
		slotType = "Active",
		cooldownSec = slot.cooldownSec or def.defaultCooldownSec,
		desc = slot.desc or def.desc,
	}
end

return WeaponActiveDefs
