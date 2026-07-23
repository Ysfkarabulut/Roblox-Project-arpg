--[[
	Rare unique armor — outside Common matrix. Studio grant / boss drop / craft later.
]]

local ArmorAbilityDefs = require(script.Parent.ArmorAbilityDefs)

local RareArmorDefs = {}

local PIECES = {
	{
		id = "a_chest_thornplate",
		name = "Thornplate",
		kind = "Chest",
		slotHints = { "chest" },
		element = "Steel",
		defence = 95,
		resist = 22,
		rarity = "Rare",
		abilities = { "thorn_reflect_armorpassive" },
		desc = "Rare chest · reflects 20% direct HP damage to attacker",
	},
	{
		id = "a_hands_stormgrasp",
		name = "Stormgrasp",
		kind = "Hands",
		slotHints = { "hands" },
		element = "Lightning",
		defence = 6,
		resist = 22,
		rarity = "Rare",
		abilities = { "stormgrasp_armorpassive", "hand_touch_armoractive" },
		desc = "Rare hands · +10 Status Potency · Volt Touch active",
	},
}

function RareArmorDefs.Build(): { [string]: any }
	local out = {}
	for _, p in PIECES do
		out[p.id] = {
			id = p.id,
			name = p.name,
			kind = p.kind,
			slotHints = p.slotHints,
			element = p.element,
			defence = p.defence,
			resist = p.resist,
			rarity = p.rarity,
			abilities = ArmorAbilityDefs.NormalizeAbilities(p.abilities),
			desc = p.desc,
		}
	end
	return out
end

return RareArmorDefs
