--[[
	Global focus catalog — `*_focusactive` / `*_focuspassive`.
	1H + Focus off-hand utilities.
]]

local PassiveDefs = require(script.Parent.PassiveDefs)

local FocusAbilityDefs = {}

export type FocusAbilityKind = "Passive" | "Active"

export type FocusAbilityDef = {
	id: string,
	name: string,
	desc: string,
	kind: FocusAbilityKind,
	defaultCooldownSec: number?,
}

local CATALOG: { [string]: FocusAbilityDef } = {
	-- Actives
	fish_net_focusactive = {
		id = "fish_net_focusactive",
		name = "Fish Net",
		desc = "Throw a net · 22 stud range · 8 stud radius · Root all enemies hit",
		kind = "Active",
		defaultCooldownSec = 14,
	},
	grapple_hook_focusactive = {
		id = "grapple_hook_focusactive",
		name = "Grappling Hook",
		desc = "Throw hook · pull enemy to you · or zip to boss/world anchor",
		kind = "Active",
		defaultCooldownSec = 11,
	},
	smoke_bomb_focusactive = {
		id = "smoke_bomb_focusactive",
		name = "Smoke Bomb",
		desc = "Lob smoke · 20 stud · 9 stud radius · Heavy Slow on enemies",
		kind = "Active",
		defaultCooldownSec = 13,
	},
	healing_idol_focusactive = {
		id = "healing_idol_focusactive",
		name = "Healing Idol",
		desc = "Place idol · 18 stud · 10 stud radius · ally heal + Regen",
		kind = "Active",
		defaultCooldownSec = 16,
	},
	-- Passives (shared passives like lifesteal_passive live in PassiveDefs)
	spirit_charm_focuspassive = {
		id = "spirit_charm_focuspassive",
		name = "Spirit Charm",
		desc = "+14 Status Potency (flat)",
		kind = "Passive",
	},
	war_sigil_focuspassive = {
		id = "war_sigil_focuspassive",
		name = "War Sigil",
		desc = "Direct damage dealt +7%",
		kind = "Passive",
	},
	lucky_coin_focuspassive = {
		id = "lucky_coin_focuspassive",
		name = "Lucky Coin",
		desc = "Crit chance +8% (flat)",
		kind = "Passive",
	},
	iron_heart_focuspassive = {
		id = "iron_heart_focuspassive",
		name = "Iron Heart",
		desc = "+18 Buff Potency (flat) · stronger heals and HoTs",
		kind = "Passive",
	},
}

function FocusAbilityDefs.Get(abilityId: string): FocusAbilityDef?
	return CATALOG[abilityId]
end

function FocusAbilityDefs.AbilitySlot(abilityId: string, flavorName: string?, cooldownSec: number?): any
	local def = FocusAbilityDefs.Get(abilityId)
	if not def then
		error(`[FocusAbilityDefs] Unknown focus ability: {abilityId}`)
	end
	local slot: any = {
		id = def.id,
		name = flavorName or def.name,
		slotType = def.kind,
		desc = def.desc,
	}
	if def.kind == "Active" then
		slot.cooldownSec = cooldownSec or def.defaultCooldownSec or 12
	end
	return slot
end

function FocusAbilityDefs.NormalizeAbilities(abilities: { any }?): { any }
	local out: { any } = {}
	if not abilities then
		return out
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			if FocusAbilityDefs.Get(ab) then
				table.insert(out, FocusAbilityDefs.AbilitySlot(ab))
			elseif PassiveDefs.Get(ab) then
				table.insert(out, PassiveDefs.AbilitySlot(ab))
			else
				error(`[FocusAbilityDefs] Unknown focus ability: {ab}`)
			end
		elseif ab.slotType == "Passive" or ab.slotType == "Active" then
			local def = FocusAbilityDefs.Get(ab.id)
			if def then
				table.insert(out, FocusAbilityDefs.AbilitySlot(ab.id, ab.name, ab.cooldownSec))
			elseif ab.slotType == "Passive" and PassiveDefs.Get(ab.id) then
				table.insert(out, PassiveDefs.AbilitySlot(ab.id, ab.name))
			else
				table.insert(out, ab)
			end
		else
			table.insert(out, ab)
		end
	end
	return out
end

return FocusAbilityDefs
