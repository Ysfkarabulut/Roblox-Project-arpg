--[[
	Grant loot + open tradeable lootboxes.
]]

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LootTables = require(game.ReplicatedStorage.Shared.Config.LootTables)
local LootBoxDefs = require(game.ReplicatedStorage.Shared.Config.LootBoxDefs)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local LootService = {}

export type GrantedItem = {
	defId: string,
	uuid: string,
	source: string,
}

export type OpenBoxResult = {
	ok: boolean,
	reason: string?,
	reward: GrantedItem?,
	boxDefId: string?,
}

function LootService.GrantDefId(userId: number, defId: string, source: string): GrantedItem?
	local inst = InventoryService.AddItem(userId, defId)
	if not inst then
		return nil
	end
	return {
		defId = defId,
		uuid = inst.uuid,
		source = source,
	}
end

function LootService.OpenLootBox(userId: number, boxUuid: string): OpenBoxResult
	local item = InventoryService.Find(userId, boxUuid)
	if not item then
		return { ok = false, reason = "NoItem" }
	end
	local def = ItemDefs.Get(item.defId)
	if not ItemDefs.IsLootBox(def) then
		return { ok = false, reason = "NotLootBox" }
	end
	local poolId = def.lootBoxPoolId
	if typeof(poolId) ~= "string" or poolId == "" then
		return { ok = false, reason = "BadPool" }
	end
	if InventoryService.IsInstalled(userId, boxUuid) then
		return { ok = false, reason = "Installed" }
	end
	local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
	if LoadoutService.GetSlotOf(userId, boxUuid) then
		return { ok = false, reason = "Equipped" }
	end

	local rewardDefId = LootTables.RollLootBox(poolId)
	if not rewardDefId then
		return { ok = false, reason = "EmptyRoll" }
	end
	if not InventoryService.RemoveItem(userId, boxUuid) then
		return { ok = false, reason = "RemoveFailed" }
	end
	local granted = LootService.GrantDefId(userId, rewardDefId, `LootBox:{item.defId}`)
	if not granted then
		return { ok = false, reason = "GrantFailed", boxDefId = item.defId }
	end
	return {
		ok = true,
		reward = granted,
		boxDefId = item.defId,
	}
end

function LootService.BossLootBoxId(bossId: string): string?
	return LootBoxDefs.ForBoss(bossId)
end

return LootService
