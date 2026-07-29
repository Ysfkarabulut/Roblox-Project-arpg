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
	{
		id = "a_chest_emberward",
		name = "Emberward Plate",
		kind = "Chest",
		slotHints = { "chest" },
		element = "Fire",
		defence = 48,
		resist = 42,
		rarity = "Rare",
		abilities = { "fortifyaura_armorpassive" },
		desc = "Rare chest · Fortify cast shares weakened aura to nearby allies",
	},
	{
		id = "a_head_blightmask",
		name = "Blight Mask",
		kind = "Head",
		slotHints = { "head" },
		element = "Poison",
		defence = 10,
		resist = 18,
		rarity = "Rare",
		abilities = { "hand_touch_armoractive" },
		desc = "Rare head · Poison Element Touch strike",
	},
	{
		id = "a_feets_quakehold",
		name = "Quakehold Sabatons",
		kind = "Feets",
		slotHints = { "feets" },
		element = "Rock",
		defence = 18,
		resist = 10,
		rarity = "Rare",
		abilities = { "charger_armoractive" },
		desc = "Rare boots · forward charge strike · Rock element",
	},
	{
		id = "a_hands_tidecaller",
		name = "Tidecaller Mitts",
		kind = "Hands",
		slotHints = { "hands" },
		element = "Water",
		defence = 4,
		resist = 18,
		rarity = "Rare",
		abilities = { "mend_touch_armoractive" },
		desc = "Rare hands · Mend Touch ally heal",
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
