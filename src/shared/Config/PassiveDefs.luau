--[[
	Global passive catalog — shared ids across weapons, armor, and focus.
	Stable suffixes: `*_weaponpassive`, `*_armorpassive`, `lifesteal_passive`, etc.
]]

local PassiveDefs = {}

export type PassiveCategory = "Proc" | "Stat"

export type PassiveDef = {
	id: string,
	name: string,
	desc: string,
	category: PassiveCategory,
	critChanceFlat: number?,
	statusPotencyFlat: number?,
	buffPotencyFlat: number?,
	directMult: number?,
	laProcChance: number?,
	lifestealPct: number?,
}

local CATALOG: { [string]: PassiveDef } = {
	status_weaponpassive = {
		id = "status_weaponpassive",
		name = "Status",
		desc = "Light-attack L1/L2: 15% gem status · L3 guaranteed",
		category = "Proc",
		laProcChance = 0.15,
	},
	keen_weaponpassive = {
		id = "keen_weaponpassive",
		name = "Keen",
		desc = "Crit Chance +5% (flat)",
		category = "Stat",
		critChanceFlat = 5,
	},
	potency_weaponpassive = {
		id = "potency_weaponpassive",
		name = "Potency",
		desc = "+12 Status Potency (flat)",
		category = "Stat",
		statusPotencyFlat = 12,
	},
	direct_weaponpassive = {
		id = "direct_weaponpassive",
		name = "Direct",
		desc = "Direct damage +3%",
		category = "Stat",
		directMult = 1.03,
	},
	buff_weaponpassive = {
		id = "buff_weaponpassive",
		name = "Buff",
		desc = "+10 Buff Potency (flat)",
		category = "Stat",
		buffPotencyFlat = 10,
	},
	lifesteal_passive = {
		id = "lifesteal_passive",
		name = "Lifesteal",
		desc = "Heal 5% of direct damage dealt (LA + abilities)",
		category = "Proc",
		lifestealPct = 0.05,
	},
}

function PassiveDefs.Get(abilityId: string): PassiveDef?
	return CATALOG[abilityId]
end

function PassiveDefs.List(): { PassiveDef }
	local out: { PassiveDef } = {}
	for _, def in CATALOG do
		table.insert(out, def)
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	return out
end

function PassiveDefs.IsProc(abilityId: string): boolean
	local def = PassiveDefs.Get(abilityId)
	return def ~= nil and def.category == "Proc"
end

function PassiveDefs.LaProcChance(abilityId: string): number?
	local def = PassiveDefs.Get(abilityId)
	if def and def.category == "Proc" then
		return def.laProcChance
	end
	return nil
end

function PassiveDefs.LifestealPct(abilityId: string): number?
	local def = PassiveDefs.Get(abilityId)
	if def and def.lifestealPct then
		return def.lifestealPct
	end
	return nil
end

function PassiveDefs.ApplyStatBonus(bonus: any, abilityId: string, scale: number?)
	local def = PassiveDefs.Get(abilityId)
	if not def or def.category ~= "Stat" then
		return
	end
	local s = scale or 1
	if def.critChanceFlat then
		bonus.critChanceFlat += def.critChanceFlat * s
	end
	if def.statusPotencyFlat then
		bonus.statusPotencyFlat += def.statusPotencyFlat * s
	end
	if def.buffPotencyFlat then
		bonus.buffPotencyFlat += def.buffPotencyFlat * s
	end
	if def.directMult then
		local delta = def.directMult - 1
		bonus.directMult *= 1 + delta * s
	end
end

function PassiveDefs.AbilitySlot(abilityId: string, flavorName: string?): any
	local def = PassiveDefs.Get(abilityId)
	if not def then
		error(`[PassiveDefs] Unknown passive: {abilityId}`)
	end
	return {
		id = def.id,
		name = flavorName or def.name,
		slotType = "Passive",
		desc = def.desc,
	}
end

function PassiveDefs.HydrateAbilitySlot(slot: any): any
	if not slot or slot.slotType ~= "Passive" then
		return slot
	end
	local def = PassiveDefs.Get(slot.id)
	if not def then
		error(`[PassiveDefs] Unknown passive: {tostring(slot.id)}`)
	end
	return {
		id = def.id,
		name = slot.name or def.name,
		slotType = "Passive",
		desc = slot.desc or def.desc,
	}
end

function PassiveDefs.NormalizeAbilities(abilities: { any }?): { any }
	local out: { any } = {}
	if not abilities then
		return out
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			table.insert(out, PassiveDefs.AbilitySlot(ab))
		elseif ab.slotType == "Passive" then
			table.insert(out, PassiveDefs.HydrateAbilitySlot(ab))
		else
			table.insert(out, ab)
		end
	end
	return out
end

return PassiveDefs
