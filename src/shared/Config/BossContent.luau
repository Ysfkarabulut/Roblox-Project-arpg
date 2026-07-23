--[[
	Boss-exclusive weapon blades — not in lootbox / starter grants.
	Drop source: PvE boss kill (The Eye v1 roster).
]]

local PassiveDefs = require(script.Parent.PassiveDefs)
local WeaponActiveDefs = require(script.Parent.WeaponActiveDefs)

local BossContent = {}

local BLADES = {
	{
		id = "b_boss_gaze_shiv",
		name = "Gaze Shiv",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		rarity = "BossExclusive",
		bossId = "eye",
		familyPerk = "Backstab x1.30 · Eye bleed on L3",
		bladeDamageMult = 1.08,
		meshKey = "Dagger_Blade_Rare",
		abilities = { "fan_of_knives_weaponactive", "keen_weaponpassive" },
		desc = "Boss: The Eye · fan of knives + crit",
	},
	{
		id = "b_boss_gale_limbs",
		name = "Gale Limbs",
		handleType = "2H_Bow",
		subFamily = "Bow",
		family = "Bow",
		rarity = "BossExclusive",
		bossId = "eye",
		familyPerk = "Focused Shot L3 ×1.25 · wind volley",
		bladeDamageMult = 1.06,
		meshKey = "Bow_Limbs_Rare",
		abilities = { "gale_volley_weaponactive", "potency_weaponpassive" },
		desc = "Boss: The Eye · triple wind volley + potency",
	},
	{
		id = "b_boss_ocular_bolt",
		name = "Ocular Bolt Head",
		handleType = "2H_Crossbow",
		subFamily = "Crossbow",
		family = "Crossbow",
		rarity = "BossExclusive",
		bossId = "eye",
		familyPerk = "Heavy Bolt L3 ×1.40 + reload",
		bladeDamageMult = 1.10,
		meshKey = "Crossbow_Head_Rare",
		abilities = { "pierce_bolt_weaponactive", "direct_weaponpassive", "keen_weaponpassive" },
		desc = "Boss: The Eye · piercing bolt line + crit/direct",
	},
}

local function normalizeAbilities(abilities: { any }?): { any }
	local out: { any } = {}
	if not abilities then
		return out
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			if PassiveDefs.Get(ab) then
				table.insert(out, PassiveDefs.AbilitySlot(ab))
			else
				table.insert(out, WeaponActiveDefs.AbilitySlot(ab))
			end
		elseif ab.slotType == "Passive" then
			table.insert(out, PassiveDefs.HydrateAbilitySlot(ab))
		elseif ab.slotType == "Active" then
			table.insert(out, WeaponActiveDefs.HydrateAbilitySlot(ab))
		else
			table.insert(out, ab)
		end
	end
	return out
end

function BossContent.BladeIds(): { string }
	local ids = {}
	for _, b in BLADES do
		table.insert(ids, b.id)
	end
	return ids
end

function BossContent.Build(): { [string]: any }
	local out = {}
	for _, b in BLADES do
		out[b.id] = {
			id = b.id,
			name = b.name,
			kind = "WeaponBlade",
			handleType = b.handleType,
			subFamily = b.subFamily,
			family = b.family,
			slotHints = {},
			element = nil,
			scaling = nil,
			familyPerk = b.familyPerk,
			bladeDamageMult = b.bladeDamageMult,
			meshKey = b.meshKey,
			abilities = normalizeAbilities(b.abilities),
			rarity = "BossExclusive",
			bossId = b.bossId,
			desc = b.desc or "Boss-exclusive blade",
		}
	end
	return out
end

return BossContent
