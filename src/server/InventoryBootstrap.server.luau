--[[
	Inventory + Loadout + Hotbar remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InventoryService = require(script.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Inventory.LoadoutService)
local HotbarService = require(script.Parent.Hotbar.HotbarService)
local StatService = require(script.Parent.Combat.StatService)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local StanceConfig = require(game.ReplicatedStorage.Shared.Config.StanceConfig)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "InventoryRemotes"
remotesFolder.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local function remoteFunction(name: string): RemoteFunction
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local GetSnapshot = remoteFunction("GetSnapshot")
local EquipItem = remoteEvent("EquipItem")
local UnequipSlot = remoteEvent("UnequipSlot")
local BindAbility = remoteEvent("BindAbility")
local UnbindHotbar = remoteEvent("UnbindHotbar")
local DiscardItem = remoteEvent("DiscardItem")
local InventoryUpdated = remoteEvent("InventoryUpdated")

local function resolveStance(userId: number): string
	local loadout = LoadoutService.Get(userId)
	local mainDef, offDef = nil, nil
	if loadout.main then
		local inst = InventoryService.Find(userId, loadout.main)
		mainDef = inst and ItemDefs.Get(inst.defId)
	end
	if loadout.off then
		local inst = InventoryService.Find(userId, loadout.off)
		offDef = inst and ItemDefs.Get(inst.defId)
	end
	return StanceConfig.Resolve(mainDef, offDef)
end

local function syncStance(player: Player)
	local stance = resolveStance(player.UserId)
	player:SetAttribute("CombatStance", stance)
end

local function buildSnapshot(userId: number)
	HotbarService.Prune(userId)
	return {
		items = InventoryService.GetItems(userId),
		loadout = LoadoutService.Get(userId),
		hotbar = HotbarService.GetBinds(userId),
		actives = HotbarService.GetAvailableActives(userId),
		stats = StatService.Get(userId),
		derived = StatService.Derived(userId),
		stance = resolveStance(userId),
	}
end

local function push(player: Player)
	syncStance(player)
	InventoryUpdated:FireClient(player, buildSnapshot(player.UserId))
end

GetSnapshot.OnServerInvoke = function(player: Player)
	return buildSnapshot(player.UserId)
end

EquipItem.OnServerEvent:Connect(function(player: Player, uuid: string, slotId: string)
	if typeof(uuid) ~= "string" or typeof(slotId) ~= "string" then
		return
	end
	local ok, err = LoadoutService.Equip(player.UserId, uuid, slotId)
	if not ok then
		warn("[Loadout] Equip failed", player.Name, err)
	else
		HotbarService.AutoFill(player.UserId)
		if _G.RefreshWeaponVisuals then
			_G.RefreshWeaponVisuals(player)
		end
	end
	push(player)
end)

UnequipSlot.OnServerEvent:Connect(function(player: Player, slotId: string)
	if typeof(slotId) ~= "string" then
		return
	end
	LoadoutService.Unequip(player.UserId, slotId)
	HotbarService.Prune(player.UserId)
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	push(player)
end)

BindAbility.OnServerEvent:Connect(function(player: Player, abilityId: string, slotIndex: number)
	if typeof(abilityId) ~= "string" or typeof(slotIndex) ~= "number" then
		return
	end
	local ok, err = HotbarService.Bind(player.UserId, abilityId, slotIndex)
	if not ok then
		warn("[Hotbar] Bind failed", player.Name, err)
	end
	push(player)
end)

UnbindHotbar.OnServerEvent:Connect(function(player: Player, slotIndex: number)
	if typeof(slotIndex) ~= "number" then
		return
	end
	HotbarService.Unbind(player.UserId, slotIndex)
	push(player)
end)

DiscardItem.OnServerEvent:Connect(function(player: Player, uuid: string)
	if typeof(uuid) ~= "string" then
		return
	end
	local userId = player.UserId
	local slot = LoadoutService.GetSlotOf(userId, uuid)
	if slot then
		LoadoutService.Unequip(userId, slot)
	end
	if InventoryService.RemoveItem(userId, uuid) then
		HotbarService.Prune(userId)
		if _G.RefreshWeaponVisuals then
			_G.RefreshWeaponVisuals(player)
		end
	end
	push(player)
end)

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		if player.Parent then
			push(player)
		end
	end)
end)

for _, player in Players:GetPlayers() do
	push(player)
end

print("[InventoryBootstrap] Inventory + Hotbar ready")
