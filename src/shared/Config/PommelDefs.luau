--[[
	Pommel (melee/staff) + String (bow/crossbow) — global stat trade-off.
	v1: 3 archetypes each; no per-handle variants. Passives later.
]]

local PommelDefs = {}

local ARCHETYPES = {
	Heavy = { damageMult = 1.12, attackSpeedMult = 0.92, suffix = "Heavy" },
	Balanced = { damageMult = 1.00, attackSpeedMult = 1.00, suffix = "Balanced" },
	Lightweight = { damageMult = 0.90, attackSpeedMult = 1.12, suffix = "Lightweight" },
}

local RANGED_HANDLES = {
	["2H_Bow"] = true,
	["2H_Crossbow"] = true,
}

function PommelDefs.IsRangedHandle(handleType: string?): boolean
	return handleType ~= nil and RANGED_HANDLES[handleType] == true
end

function PommelDefs.Build(): { [string]: any }
	local out = {}

	for archetype, stats in ARCHETYPES do
		local id = `p_{string.lower(archetype)}`
		out[id] = {
			id = id,
			name = `{stats.suffix} Pommel`,
			kind = "WeaponPommel",
			pommelRole = "Pommel",
			handleType = nil,
			archetype = archetype,
			damageMult = stats.damageMult,
			attackSpeedMult = stats.attackSpeedMult,
			slotHints = {},
			element = nil,
			rarity = "Common",
			meshKey = `Pommel_{archetype}`,
			desc = `Universal pommel · DMG ×{stats.damageMult} · AS ×{stats.attackSpeedMult}`,
		}
	end

	for archetype, stats in ARCHETYPES do
		local id = `p_string_{string.lower(archetype)}`
		out[id] = {
			id = id,
			name = `{stats.suffix} String`,
			kind = "WeaponPommel",
			pommelRole = "String",
			handleType = nil,
			archetype = archetype,
			damageMult = stats.damageMult,
			attackSpeedMult = stats.attackSpeedMult,
			slotHints = {},
			element = nil,
			rarity = "Common",
			meshKey = `String_{archetype}`,
			desc = `Bow / Crossbow string · DMG ×{stats.damageMult} · AS ×{stats.attackSpeedMult}`,
		}
	end

	return out
end

function PommelDefs.BalancedFor(handleType: string): string
	if PommelDefs.IsRangedHandle(handleType) then
		return "p_string_balanced"
	end
	return "p_balanced"
end

return PommelDefs
