--[[
	Item catalog = modular weapon parts + ArmorMatrix + handcrafted overrides.
	Legacy w_* weapons are converted to WeaponFrame at runtime (see LegacyWeaponConverter).
]]

local ArmorMatrix = require(script.Parent.ArmorMatrix)
local HandleDefs = require(script.Parent.HandleDefs)
local BladeDefs = require(script.Parent.BladeDefs)
local PommelDefs = require(script.Parent.PommelDefs)
local GemDefs = require(script.Parent.GemDefs)

local ItemDefs = {}

local catalog: { [string]: any } = {}

for id, def in HandleDefs.Build() do
	catalog[id] = def
end
for id, def in BladeDefs.Build() do
	catalog[id] = def
end
for id, def in PommelDefs.Build() do
	catalog[id] = def
end
for id, def in GemDefs.Build() do
	catalog[id] = def
end
for id, def in ArmorMatrix.Build() do
	catalog[id] = def
end

catalog.weapon_frame = {
	id = "weapon_frame",
	name = "Weapon Frame",
	kind = "WeaponFrame",
	slotHints = { "main" },
	element = nil,
	desc = "Modular weapon â€” install Handle, Blade, Pommel; socket a Gem",
}

-- â”€â”€ Handcrafted overrides & exclusive pieces â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

local handcrafted = {
	-- Legacy placeholders (UI / eski starter)
	w_sword_1h = {
		id = "w_sword_1h",
		name = "Iron Longsword",
		kind = "Weapon1H",
		family = "Sword",
		slotHints = { "main", "off" },
		element = "Steel",
		baseDamage = 40,
		desc = "1H Sword Â· Measured Strike (legacy stub)",
	},
	w_axe_1h = {
		id = "w_axe_1h",
		name = "Hand Axe",
		kind = "Weapon1H",
		family = "Axe",
		slotHints = { "main", "off" },
		element = "Fire",
		baseDamage = 46,
		desc = "1H Axe Â· anti-guard (legacy stub)",
	},
	w_sword_2h = {
		id = "w_sword_2h",
		name = "Greatblade",
		kind = "Weapon2H",
		family = "Sword",
		slotHints = { "main" },
		element = "Steel",
		baseDamage = 50,
		desc = "2H Sword Â· off = Knot (legacy stub)",
	},
	w_bow = {
		id = "w_bow",
		name = "Hunter Bow",
		kind = "Bow",
		family = "Bow",
		slotHints = { "main" },
		element = "Wind",
		baseDamage = 40,
		desc = "Bow Â· Quiver off (legacy stub)",
	},
	w_crossbow = {
		id = "w_crossbow",
		name = "Siege Crossbow",
		kind = "Crossbow",
		family = "Crossbow",
		slotHints = { "main" },
		element = "Steel",
		baseDamage = 58,
		desc = "Crossbow Â· L3 reload (legacy stub)",
	},
	w_staff = {
		id = "w_staff",
		name = "Ember Staff",
		kind = "Staff",
		family = "Staff",
		slotHints = { "main" },
		element = "Fire",
		baseDamage = 46,
		desc = "2H Staff Â· Knot off (legacy stub)",
	},
	w_wand = {
		id = "w_wand",
		name = "Spark Wand",
		kind = "Wand",
		family = "Wand",
		slotHints = { "main", "off" },
		element = "Lightning",
		baseDamage = 30,
		desc = "1H Wand Â· kÄ±sa menzil (legacy stub)",
	},
	w_scepter = {
		id = "w_scepter",
		name = "Radiant Scepter",
		kind = "Scepter",
		family = "Scepter",
		slotHints = { "main", "off" },
		element = "Water",
		baseDamage = 28,
		desc = "1H Scepter Â· cone (legacy stub)",
	},

	-- Off-hand
	o_kite = {
		id = "o_kite",
		name = "Kite Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Rock",
		defence = 120,
		desc = "Guard Â· chip 40% Â· drain 1.0/s",
	},
	o_buckler = {
		id = "o_buckler",
		name = "Buckler",
		kind = "Shield",
		slotHints = { "off" },
		element = "Steel",
		defence = 60,
		desc = "Guard Â· chip 60% Â· drain 0.5/s Â· low slow",
	},
	o_tower = {
		id = "o_tower",
		name = "Tower Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Rock",
		defence = 160,
		desc = "Guard Â· chip 30% Â· drain 1.5/s Â· high slow",
	},
	o_round = {
		id = "o_round",
		name = "Round Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Water",
		defence = 90,
		desc = "Guard Â· chip 45% Â· drain 0.8/s Â· balanced",
	},
	o_spiked = {
		id = "o_spiked",
		name = "Spiked Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Steel",
		defence = 100,
		desc = "Guard Â· chip 50% Â· drain 1.1/s",
	},
	o_quiver = {
		id = "o_quiver",
		name = "Hunter Quiver",
		kind = "Quiver",
		slotHints = { "off" },
		element = nil,
		desc = "Bow/Crossbow off Â· tagsiz",
	},
	o_knot = {
		id = "o_knot",
		name = "Weapon Knot",
		kind = "Knot",
		slotHints = { "off" },
		element = nil,
		desc = "2H / Staff off Â· tagsiz",
	},
	o_focus = {
		id = "o_focus",
		name = "Root Totem",
		kind = "Focus",
		slotHints = { "off" },
		element = "Poison",
		desc = "Focus utility",
	},
}
for id, def in handcrafted do
	catalog[id] = def
end

function ItemDefs.Get(defId: string)
	return catalog[defId]
end

function ItemDefs.All()
	return catalog
end

function ItemDefs.CanEquipInSlot(defId: string, slotId: string): boolean
	local def = catalog[defId]
	if not def then
		return false
	end
	if def.kind == "WeaponFrame" then
		return slotId == "main"
	end
	if def.kind == "WeaponHandle" or def.kind == "WeaponBlade" or def.kind == "WeaponPommel" or def.kind == "ElementGem" then
		return false
	end
	for _, s in def.slotHints do
		if s == slotId then
			return true
		end
	end
	return false
end

function ItemDefs.IsPartKind(kind: string?): boolean
	return kind == "WeaponHandle" or kind == "WeaponBlade" or kind == "WeaponPommel" or kind == "ElementGem"
end

--- Common + Rare (Studio starter); BossExclusive dÄ±ÅŸarÄ±da
function ItemDefs.StarterDefIds(): { string }
	local ids = {}
	for id, def in catalog do
		local r = def.rarity
		if r ~= "BossExclusive" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

return ItemDefs
