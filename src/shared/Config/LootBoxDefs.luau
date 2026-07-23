--[[
	Tradeable loot crates — open for rewards or trade before opening.
	Pool ids map to LootTables.RollLootBox.
]]

local LootBoxDefs = {}

export type LootBoxDef = {
	id: string,
	name: string,
	lootBoxPoolId: string,
	rarity: "Common" | "Rare" | "BossExclusive",
	bossId: string?,
	desc: string,
	tradeable: boolean,
}

local BOXES: { LootBoxDef } = {
	{
		id = "lootbox_common",
		name = "Common Lootbox",
		lootBoxPoolId = "common",
		rarity = "Common",
		desc = "Tradeable · Common parts & gems",
		tradeable = true,
	},
	{
		id = "lootbox_rare",
		name = "Rare Lootbox",
		lootBoxPoolId = "rare",
		rarity = "Rare",
		desc = "Tradeable · Rare blades & armor",
		tradeable = true,
	},
	{
		id = "lootbox_boss_eye",
		name = "The Eye Lootbox",
		lootBoxPoolId = "boss_eye",
		rarity = "BossExclusive",
		bossId = "eye",
		desc = "Tradeable · Boss-exclusive Eye drops",
		tradeable = true,
	},
}

local byBossId: { [string]: string } = {}

function LootBoxDefs.Build(): { [string]: any }
	local out: { [string]: any } = {}
	for _, box in BOXES do
		out[box.id] = {
			id = box.id,
			name = box.name,
			kind = "LootBox",
			slotHints = {},
			element = nil,
			rarity = box.rarity,
			lootBoxPoolId = box.lootBoxPoolId,
			bossId = box.bossId,
			tradeable = box.tradeable ~= false,
			desc = box.desc,
		}
		if box.bossId then
			byBossId[box.bossId] = box.id
		end
	end
	return out
end

function LootBoxDefs.ForBoss(bossId: string): string?
	return byBossId[bossId]
end

function LootBoxDefs.AllIds(): { string }
	local ids = {}
	for _, box in BOXES do
		table.insert(ids, box.id)
	end
	return ids
end

return LootBoxDefs
