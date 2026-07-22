--[[
	Studio Dev Tools + lobby training dummy.
	Grant items, edit primary stats, reset dummy, autofill hotbar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local LegacyWeaponConverter = require(ReplicatedStorage.Shared.Config.LegacyWeaponConverter)
local InventoryService = require(script.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Inventory.LoadoutService)
local HotbarService = require(script.Parent.Hotbar.HotbarService)
local StatService = require(script.Parent.Combat.StatService)
local DummyService = require(script.Parent.Combat.DummyService)
local AbilityService = require(script.Parent.Combat.AbilityService)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "DevRemotes"
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

local GrantItem = remoteEvent("GrantItem")
local SetStats = remoteEvent("SetStats")
local ResetStats = remoteEvent("ResetStats")
local ResetDummy = remoteEvent("ResetDummy")
local SetDummyMaxHp = remoteEvent("SetDummyMaxHp")
local AutoFillHotbar = remoteEvent("AutoFillHotbar")
local DevNotify = remoteEvent("DevNotify")
local GetDevState = remoteFunction("GetDevState")

local function isDev(_player: Player): boolean
	return RunService:IsStudio()
end

local function notify(player: Player, ok: boolean, msg: string, extra: any?)
	local payload = { ok = ok, msg = msg }
	if typeof(extra) == "table" then
		for k, v in extra do
			payload[k] = v
		end
	end
	DevNotify:FireClient(player, payload)
end

local function buildInventorySnapshot(userId: number)
	HotbarService.Prune(userId)
	return {
		items = InventoryService.GetItems(userId),
		loadout = LoadoutService.Get(userId),
		hotbar = HotbarService.GetBinds(userId),
		actives = HotbarService.GetAvailableActives(userId),
		stats = StatService.Get(userId),
		derived = StatService.Derived(userId),
	}
end

local function pushInventory(player: Player)
	local folder = ReplicatedStorage:FindFirstChild("InventoryRemotes")
	if not folder then
		return
	end
	local updated = folder:FindFirstChild("InventoryUpdated")
	if updated and updated:IsA("RemoteEvent") then
		updated:FireClient(player, buildInventorySnapshot(player.UserId))
	end
end

local function buildDevState(userId: number)
	local hp, maxHp = DummyService.GetHp()
	return {
		stats = StatService.Get(userId),
		derived = StatService.Derived(userId),
		dummy = { hp = hp, maxHp = maxHp },
		studio = RunService:IsStudio(),
	}
end

GetDevState.OnServerInvoke = function(player: Player)
	if not isDev(player) then
		return { studio = false }
	end
	return buildDevState(player.UserId)
end

GrantItem.OnServerEvent:Connect(function(player: Player, defId: string, count: number?)
	if not isDev(player) then
		return
	end
	if typeof(defId) ~= "string" then
		return
	end
	if not ItemDefs.Get(defId) and not LegacyWeaponConverter.IsLegacyWeaponId(defId) then
		notify(player, false, `Unknown defId: {defId}`)
		return
	end
	local n = math.clamp(math.floor(if typeof(count) == "number" then count else 1), 1, 20)
	for _ = 1, n do
		if LegacyWeaponConverter.IsLegacyWeaponId(defId) then
			InventoryService.ConvertLegacyWeapon(player.UserId, defId)
		else
			InventoryService.AddItem(player.UserId, defId)
		end
	end
	pushInventory(player)
	local def = ItemDefs.Get(defId)
	notify(player, true, `Granted {n}× {if def then def.name else defId}`)
end)

SetStats.OnServerEvent:Connect(function(player: Player, patch: any)
	if not isDev(player) then
		return
	end
	if typeof(patch) ~= "table" then
		return
	end
	local clean: { [string]: number } = {}
	for _, key in { "level", "STR", "DEX", "VIT", "INT" } do
		local v = patch[key]
		if typeof(v) == "number" then
			clean[key] = v
		end
	end
	StatService.Set(player.UserId, clean)
	pushInventory(player)
	notify(player, true, "Stats applied", { stats = StatService.Get(player.UserId) })
end)

ResetStats.OnServerEvent:Connect(function(player: Player, level: number?)
	if not isDev(player) then
		return
	end
	local lv = if typeof(level) == "number" then level else nil
	StatService.Reset(player.UserId, lv)
	pushInventory(player)
	notify(player, true, "Stats reset", { stats = StatService.Get(player.UserId) })
end)

ResetDummy.OnServerEvent:Connect(function(player: Player)
	if not isDev(player) then
		return
	end
	DummyService.Reset()
	notify(player, true, "Dummy reset")
end)

SetDummyMaxHp.OnServerEvent:Connect(function(player: Player, maxHp: number)
	if not isDev(player) then
		return
	end
	if typeof(maxHp) ~= "number" then
		return
	end
	DummyService.SetMaxHp(maxHp)
	notify(player, true, `Dummy max HP = {math.floor(maxHp)}`)
end)

AutoFillHotbar.OnServerEvent:Connect(function(player: Player)
	if not isDev(player) then
		return
	end
	local n = HotbarService.AutoFill(player.UserId)
	pushInventory(player)
	notify(player, true, `Hotbar auto-filled ({n} new)`)
end)

Players.PlayerRemoving:Connect(function(player)
	StatService.Clear(player.UserId)
	AbilityService.Clear(player.UserId)
end)

DummyService.Ensure()

print("[DevBootstrap] Training dummy + DevTools ready (Studio-only grants)")
