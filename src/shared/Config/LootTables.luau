--[[
	Gacha Box + boss-exclusive drop tables (GDD §10).
	Weights and rates are playtest defaults — tweak here.
]]

local ItemDefs = require(script.Parent.ItemDefs)
local BossContent = require(script.Parent.BossContent)

local LootTables = {}

export type LootSource = "PvP" | "PvE"

local DropRates = {
	PvP = { gachaChance = 0.40 },
	PvE = { gachaChance = 0.50, bossExclusiveChance = 0.08 },
}

local TierWeights = {
	CommonPart = 55,
	RareBlade = 30,
	RareArmor = 10,
	BonusGem = 5,
}

local RareBoxWeights = {
	RareBlade = 70,
	RareArmor = 25,
	BonusGem = 5,
}

local GachaBoxWeights = {
	Common = 82,
	Rare = 18,
}

local pools: {
	CommonPart: { string },
	RareBlade: { string },
	RareArmor: { string },
	BonusGem: { string },
} = {
	CommonPart = {},
	RareBlade = {},
	RareArmor = {},
	BonusGem = {},
}

local bossPools: { [string]: { string } } = {}

local function isCommonPart(def: any): boolean
	local kind = def.kind
	if kind == "WeaponHandle" or kind == "WeaponPommel" then
		return def.rarity == nil or def.rarity == "Common"
	end
	if kind == "ElementGem" then
		return true
	end
	-- Common blades (48 catalog) excluded — upgrade parts only
	return false
end

local function buildPools()
	for id, def in ItemDefs.All() do
		if not ItemDefs.LootEligible(def) then
			continue
		end
		if isCommonPart(def) then
			table.insert(pools.CommonPart, id)
		elseif def.kind == "WeaponBlade" and def.rarity == "Rare" then
			table.insert(pools.RareBlade, id)
		elseif def.rarity == "Rare" and (def.kind == "Head" or def.kind == "Chest" or def.kind == "Hands" or def.kind == "Feets" or def.kind == "Focus") then
			table.insert(pools.RareArmor, id)
		end
		if def.kind == "ElementGem" then
			table.insert(pools.BonusGem, id)
		end
	end

	for _, bladeId in BossContent.BladeIds() do
		local def = ItemDefs.Get(bladeId)
		if def and def.bossId then
			local bossId = def.bossId
			if not bossPools[bossId] then
				bossPools[bossId] = {}
			end
			table.insert(bossPools[bossId], bladeId)
		end
	end
end

buildPools()

local function pickFrom(list: { string }): string?
	if #list == 0 then
		return nil
	end
	return list[math.random(1, #list)]
end

local function rollTier(): string
	local total = 0
	for _, w in TierWeights do
		total += w
	end
	local roll = math.random() * total
	local acc = 0
	for tier, w in TierWeights do
		acc += w
		if roll <= acc then
			return tier
		end
	end
	return "CommonPart"
end

function LootTables.GetDropRates()
	return DropRates
end

function LootTables.ShouldRollGacha(source: LootSource): boolean
	local rates = DropRates[source]
	if not rates then
		return false
	end
	return math.random() < rates.gachaChance
end

function LootTables.ShouldRollBossExclusive(source: LootSource): boolean
	if source ~= "PvE" then
		return false
	end
	local rates = DropRates.PvE
	return math.random() < rates.bossExclusiveChance
end

function LootTables.RollGacha(_source: LootSource): string?
	local tier = rollTier()
	local list = pools[tier]
	local defId = pickFrom(list)
	if defId then
		return defId
	end
	-- fallback if tier pool empty
	for _, fallbackList in pools do
		defId = pickFrom(fallbackList)
		if defId then
			return defId
		end
	end
	return nil
end

function LootTables.RollBossExclusive(bossId: string): string?
	local list = bossPools[bossId]
	return pickFrom(list)
end

local function rollWeighted(weights: { [string]: number }): string
	local total = 0
	for tier, w in pairs(weights) do
		total += w
	end
	local roll = math.random() * total
	local acc = 0
	for tier, w in pairs(weights) do
		acc += w
		if roll <= acc then
			return tier
		end
	end
	for tier in pairs(weights) do
		return tier
	end
	return "CommonPart"
end

--- Which tradeable lootbox to grant on gacha win (not contents).
function LootTables.RollGachaLootBox(_source: LootSource): string
	local tier = rollWeighted(GachaBoxWeights)
	if tier == "Rare" then
		return "lootbox_rare"
	end
	return "lootbox_common"
end

--- Open a lootbox pool → item defId inside the box.
function LootTables.RollLootBox(poolId: string): string?
	if poolId == "common" then
		return LootTables.RollGacha("PvE")
	elseif poolId == "rare" then
		local tier = rollWeighted(RareBoxWeights)
		return pickFrom(pools[tier]) or LootTables.RollGacha("PvE")
	elseif poolId == "boss_eye" then
		return LootTables.RollBossExclusive("eye")
	end
	if string.sub(poolId, 1, 5) == "boss_" then
		local bossId = string.sub(poolId, 6)
		return LootTables.RollBossExclusive(bossId)
	end
	return LootTables.RollGacha("PvE")
end

function LootTables.XpForResult(source: LootSource, won: boolean): number
	if not won then
		return 0
	end
	if source == "PvE" then
		return 120
	end
	return 80
end

return LootTables
