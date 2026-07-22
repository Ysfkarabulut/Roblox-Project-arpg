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
	-- Her aileden 1 silah (matris = aile × 8 element ≈ 96; lobby'de hepsi yok)
	-- Eksik starter parçalarını sonradan da tamamla (eski bag boş sayılmaz)
	local starter = {
		"w_dagger_fire",
		"w_sword_1h_lightning",
		"w_axe_1h_rock",
		"w_mace_1h_water",
		"w_wand_fire",
		"w_scepter_lightning",
		"w_sword_2h_steel",
		"w_axe_2h_rock",
		"w_mace_2h_poison",
		"w_staff_wind",
		"w_bow_wind",
		"w_crossbow_lightning",
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
	local have: { [string]: boolean } = {}
	for _, inst in bag do
		if typeof(inst) == "table" and typeof(inst.defId) == "string" then
			have[inst.defId] = true
		end
	end
	for _, defId in starter do
		if not have[defId] then
			InventoryService.AddItem(userId, defId)
			have[defId] = true
		end
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
