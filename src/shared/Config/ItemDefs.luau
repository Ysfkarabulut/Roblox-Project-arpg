--[[
	Item catalog = modular weapon parts + ArmorMatrix + handcrafted overrides.
	Legacy w_* weapons are converted to WeaponFrame at runtime (see LegacyWeaponConverter).
]]

local ArmorMatrix = require(script.Parent.ArmorMatrix)
local BossContent = require(script.Parent.BossContent)
local RareArmorDefs = require(script.Parent.RareArmorDefs)
local RoleArmorDefs = require(script.Parent.RoleArmorDefs)
local ExoticContent = require(script.Parent.ExoticContent)
local ArmorAbilityDefs = require(script.Parent.ArmorAbilityDefs)
local FocusDefs = require(script.Parent.FocusDefs)
local HandleDefs = require(script.Parent.HandleDefs)
local BladeDefs = require(script.Parent.BladeDefs)
local PommelDefs = require(script.Parent.PommelDefs)
local GemDefs = require(script.Parent.GemDefs)
local LootBoxDefs = require(script.Parent.LootBoxDefs)

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
for id, def in BossContent.Build() do
	catalog[id] = def
end
for id, def in RareArmorDefs.Build() do
	catalog[id] = def
end
for id, def in RoleArmorDefs.Build() do
	catalog[id] = def
end
for id, def in ExoticContent.Build() do
	catalog[id] = def
end
for id, def in FocusDefs.Build() do
	catalog[id] = def
end
for id, def in LootBoxDefs.Build() do
	catalog[id] = def
end

catalog.weapon_frame = {
	id = "weapon_frame",
	name = "Weapon Frame",
	kind = "WeaponFrame",
	slotHints = { "main" },
	element = nil,
	desc = "Modular weapon — install Handle, Blade, Pommel; socket Gem. Complete 1H frames may equip Off for dual wield.",
}

-- Handcrafted off-hand / utility (weapons are modular via Handle/Blade/Pommel)

local handcrafted = {
	-- Off-hand
	o_buckler = {
		id = "o_buckler",
		name = "Buckler",
		kind = "Shield",
		slotHints = { "off" },
		element = "Steel",
		defence = 60,
		abilities = ArmorAbilityDefs.NormalizeAbilities({ "riposte_bash_armoractive" }),
		desc = "Light shield · Riposte Bash · chip 60% · drain 0.5/s",
	},
	o_kite = {
		id = "o_kite",
		name = "Kite Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Rock",
		defence = 120,
		abilities = ArmorAbilityDefs.NormalizeAbilities({ "shield_ram_armoractive" }),
		desc = "Balanced shield · Shield Ram · chip 40% · drain 1.0/s",
	},
	o_tower = {
		id = "o_tower",
		name = "Tower Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Rock",
		defence = 160,
		abilities = ArmorAbilityDefs.NormalizeAbilities({ "bulwark_wall_armoractive" }),
		desc = "Heavy shield · Bulwark Fortify · chip 30% · drain 1.5/s",
	},
	o_round = {
		id = "o_round",
		name = "Round Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Water",
		defence = 90,
		desc = "Guard · chip 45% · drain 0.8/s · balanced",
	},
	o_spiked = {
		id = "o_spiked",
		name = "Spiked Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Steel",
		defence = 100,
		desc = "Guard · chip 50% · drain 1.1/s",
	},
	o_quiver = {
		id = "o_quiver",
		name = "Hunter Quiver",
		kind = "Quiver",
		slotHints = { "off" },
		element = nil,
		desc = "Bow/Crossbow off · untagged",
	},
	o_knot = {
		id = "o_knot",
		name = "Weapon Knot",
		kind = "Knot",
		slotHints = { "off" },
		element = nil,
		desc = "2H / Staff off · untagged",
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
	if def.kind == "LootBox" then
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

--- Items that may appear in Gacha Box (never BossExclusive / frames / off-hand utility).
function ItemDefs.LootEligible(def: any): boolean
	if not def or typeof(def) ~= "table" then
		return false
	end
	if def.rarity == "BossExclusive" then
		return false
	end
	if def.id == "weapon_frame" then
		return false
	end
	local kind = def.kind
	if kind == "WeaponHandle" or kind == "WeaponPommel" or kind == "ElementGem" then
		return true
	end
	if kind == "WeaponBlade" then
		return def.rarity == "Rare" or def.rarity == "Exotic"
	end
	if kind == "Head" or kind == "Chest" or kind == "Hands" or kind == "Feets" then
		return def.rarity == "Rare" or def.rarity == "Exotic"
	end
	if kind == "Focus" then
		return def.rarity == "Rare" or def.rarity == "Exotic"
	end
	return false
end

function ItemDefs.IsLootBox(def: any): boolean
	return def ~= nil and def.kind == "LootBox"
end

function ItemDefs.IsTradeable(def: any): boolean
	if not def or typeof(def) ~= "table" then
		return false
	end
	if def.kind == "LootBox" then
		return def.tradeable ~= false
	end
	return def.tradeable == true
end

--- Common + Rare (Studio starter); BossExclusive dışarıda
function ItemDefs.StarterDefIds(): { string }
	local ids = {}
	for id, def in catalog do
		local r = def.rarity
		if r ~= "BossExclusive" and r ~= "Exotic" and def.kind ~= "LootBox" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

--- Studio / balance snapshot — total catalog counts by category.
function ItemDefs.ContentSummary(): { [string]: number }
	local counts = {
		total = 0,
		blades = 0,
		bossBlades = 0,
		rareArmor = 0,
		commonArmor = 0,
		focus = 0,
		offHand = 0,
		parts = 0,
		lootEligible = 0,
	}
	for _, def in catalog do
		counts.total += 1
		local kind = def.kind
		if kind == "WeaponBlade" then
			if def.bossId then
				counts.bossBlades += 1
			else
				counts.blades += 1
			end
		elseif kind == "Head" or kind == "Chest" or kind == "Hands" or kind == "Feets" then
			if def.rarity == "Rare" then
				counts.rareArmor += 1
			else
				counts.commonArmor += 1
			end
		elseif kind == "Focus" then
			counts.focus += 1
		elseif kind == "Shield" or kind == "Quiver" or kind == "Knot" or kind == "Weapon1H" or kind == "Wand" or kind == "Scepter" then
			counts.offHand += 1
		elseif ItemDefs.IsPartKind(kind) then
			counts.parts += 1
		end
		if ItemDefs.LootEligible(def) then
			counts.lootEligible += 1
		end
	end
	return counts
end

return ItemDefs
