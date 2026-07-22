--[[
	8 handle family types — kind, scaling, base damage, AS tier.
]]

local HandleDefs = {}

HandleDefs.List = {
	{
		id = "h_1h_sword",
		name = "1H Sword Handle",
		handleType = "1H_Sword",
		kind = "Weapon1H",
		scaling = "STR",
		baseDamage = 40,
		baseAsTier = "C",
		socketCount = 1,
		meshKey = "Sword1H_Handle",
		desc = "1H Sword / Dagger family handle · 1 gem socket",
	},
	{
		id = "h_1h_axemace",
		name = "1H Axe/Mace Handle",
		handleType = "1H_AxeMace",
		kind = "Weapon1H",
		scaling = "STR",
		baseDamage = 46,
		baseAsTier = "B",
		socketCount = 1,
		meshKey = "Axe1H_Handle",
		desc = "1H Axe / Mace family handle · 1 gem socket",
	},
	{
		id = "h_1h_wandscepter",
		name = "1H Wand/Scepter Handle",
		handleType = "1H_WandScepter",
		kind = "Weapon1H",
		scaling = "INT",
		baseDamage = 30,
		baseAsTier = "D",
		socketCount = 1,
		meshKey = "Wand_Handle",
		desc = "1H Wand / Scepter family handle · 1 gem socket",
	},
	{
		id = "h_2h_sword",
		name = "2H Sword Handle",
		handleType = "2H_Sword",
		kind = "Weapon2H",
		scaling = "STR",
		baseDamage = 50,
		baseAsTier = "B",
		socketCount = 1,
		meshKey = "Sword2H_Handle",
		desc = "2H Sword family handle · 1 gem socket",
	},
	{
		id = "h_2h_axemace",
		name = "2H Axe/Mace Handle",
		handleType = "2H_AxeMace",
		kind = "Weapon2H",
		scaling = "STR",
		baseDamage = 54,
		baseAsTier = "A",
		socketCount = 1,
		meshKey = "Axe2H_Handle",
		desc = "2H Axe / Mace family handle · 1 gem socket",
	},
	{
		id = "h_2h_staff",
		name = "2H Staff Handle",
		handleType = "2H_Staff",
		kind = "Staff",
		scaling = "INT",
		baseDamage = 46,
		baseAsTier = "B",
		socketCount = 1,
		meshKey = "Staff_Handle",
		desc = "2H Staff family handle · 1 gem socket",
	},
	{
		id = "h_2h_bow",
		name = "2H Bow Handle",
		handleType = "2H_Bow",
		kind = "Bow",
		scaling = "DEX",
		baseDamage = 40,
		baseAsTier = "C",
		socketCount = 1,
		meshKey = "Bow_Handle",
		desc = "2H Bow family handle · 1 gem socket",
	},
	{
		id = "h_2h_crossbow",
		name = "2H Crossbow Handle",
		handleType = "2H_Crossbow",
		kind = "Crossbow",
		scaling = "DEX",
		baseDamage = 58,
		baseAsTier = "S",
		socketCount = 1,
		meshKey = "Crossbow_Handle",
		desc = "2H Crossbow family handle · 1 gem socket",
	},
}

function HandleDefs.Build(): { [string]: any }
	local out = {}
	for _, h in HandleDefs.List do
		out[h.id] = {
			id = h.id,
			name = h.name,
			kind = "WeaponHandle",
			handleType = h.handleType,
			family = nil,
			slotHints = {},
			element = nil,
			scaling = h.scaling,
			asTier = h.baseAsTier,
			baseDamage = h.baseDamage,
			socketCount = h.socketCount,
			meshKey = h.meshKey,
			rarity = "Common",
			desc = h.desc,
		}
	end
	return out
end

function HandleDefs.ByType(handleType: string): any?
	for _, h in HandleDefs.List do
		if h.handleType == handleType then
			return h
		end
	end
	return nil
end

return HandleDefs
