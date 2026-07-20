--[[
	InventoryService — UUID instance bag.
	Aynı defId birden fazla olabilir; her kopya ayrı uuid.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)

export type ItemInstance = {
	uuid: string,
	defId: string,
}

local InventoryService = {}

local bags: { [number]: { ItemInstance } } = {}

local function ensureBag(userId: number): { ItemInstance }
	if not bags[userId] then
		bags[userId] = {}
	end
	return bags[userId]
end

function InventoryService.GetItems(userId: number): { ItemInstance }
	local bag = ensureBag(userId)
	local copy = table.create(#bag)
	for i, item in bag do
		copy[i] = { uuid = item.uuid, defId = item.defId }
	end
	return copy
end

function InventoryService.Find(userId: number, uuid: string): ItemInstance?
	for _, item in ensureBag(userId) do
		if item.uuid == uuid then
			return item
		end
	end
	return nil
end

function InventoryService.AddItem(userId: number, defId: string): ItemInstance?
	if not ItemDefs.Get(defId) then
		warn("[Inventory] Unknown defId", defId)
		return nil
	end
	local instance: ItemInstance = {
		uuid = HttpService:GenerateGUID(false),
		defId = defId,
	}
	table.insert(ensureBag(userId), instance)
	return instance
end

function InventoryService.RemoveItem(userId: number, uuid: string): boolean
	local bag = ensureBag(userId)
	for i, item in bag do
		if item.uuid == uuid then
			table.remove(bag, i)
			return true
		end
	end
	return false
end

function InventoryService.GrantStarter(userId: number)
	local bag = ensureBag(userId)
	if #bag > 0 then
		return
	end
	-- Küçük starter; kalanı Dev Tool (F8) ile spawn
	local starter = {
		"w_dagger_fire",
		"w_sword_1h_lightning",
		"w_sword_2h_steel",
		"w_axe_2h_rock",
		"o_kite",
		"o_buckler",
		"o_tower",
		"o_round",
		"o_spiked",
		"o_quiver",
		"o_knot",
		"a_chest_steel",
		"a_hands_stormgrasp",
		"a_head_bedrock",
		"a_feets_tidewalkers",
		"a_chest_thornplate",
	}
	for _, defId in starter do
		InventoryService.AddItem(userId, defId)
	end
end

Players.PlayerRemoving:Connect(function(player)
	bags[player.UserId] = nil
end)

Players.PlayerAdded:Connect(function(player)
	InventoryService.GrantStarter(player.UserId)
end)

-- Late join (script reload)
for _, player in Players:GetPlayers() do
	InventoryService.GrantStarter(player.UserId)
end

return InventoryService
