--[[
	Studio Dev Tools + lobby training dummy.
	Grant items, edit primary stats, reset dummy, autofill hotbar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local LegacyWeaponConverter = require(ReplicatedStorage.Shared.Config.LegacyWeaponConverter)
local InventoryService = require(script.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Inventory.LoadoutService)
local HotbarService = require(script.Parent.Hotbar.HotbarService)
local StatService = require(script.Parent.Combat.StatService)
local PassiveService = require(script.Parent.Combat.PassiveService)
local DummyService = require(script.Parent.Combat.DummyService)
local AbilityService = require(script.Parent.Combat.AbilityService)
local CurrencyService = require(script.Parent.Inventory.CurrencyService)
local StanceConfig = require(ReplicatedStorage.Shared.Config.StanceConfig)
local WeaponResolver = require(ReplicatedStorage.Shared.Combat.WeaponResolver)
local MatchResultBridge = require(script.Parent.Loot.MatchResultBridge)

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
local GrantMvpLoadout = remoteEvent("GrantMvpLoadout")
local SetStats = remoteEvent("SetStats")
local ResetStats = remoteEvent("ResetStats")
local ResetDummy = remoteEvent("ResetDummy")
local SetDummyMaxHp = remoteEvent("SetDummyMaxHp")
local GrantPremium = remoteEvent("GrantPremium")
local SimulateMatchResult = remoteEvent("SimulateMatchResult")
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
	PassiveService.Refresh(userId)
	local loadout = LoadoutService.Get(userId)
	local resolved = LoadoutService.GetResolvedMain(userId)
	local mainDef = if resolved and resolved.complete then WeaponResolver.AsItemDef(resolved) else nil
	local offDef = nil
	if loadout.off then
		local inst = InventoryService.Find(userId, loadout.off)
		offDef = inst and ItemDefs.Get(inst.defId)
	end
	return {
		items = InventoryService.GetItems(userId),
		loadout = loadout,
		hotbar = HotbarService.GetBinds(userId),
		actives = HotbarService.GetAvailableActives(userId),
		passives = PassiveService.GetSummary(userId),
		stats = StatService.Get(userId),
		xpProgress = StatService.GetXpProgress(userId),
		derived = StatService.Derived(userId),
		stance = StanceConfig.Resolve(mainDef, offDef),
		resolvedMain = if resolved and resolved.complete
			then {
				displayName = resolved.displayName,
				element = resolved.element,
				baseDamage = resolved.baseDamage,
				kind = resolved.kind,
				family = resolved.family,
				scaling = resolved.scaling,
				attackSpeedMult = resolved.attackSpeedMult,
				complete = resolved.complete,
			}
			else nil,
		premiumCurrency = CurrencyService.GetPremium(userId),
		gemPreserveUnsocketCost = CurrencyService.GemPreserveUnsocketCost,
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

GrantMvpLoadout.OnServerEvent:Connect(function(player: Player)
	if not isDev(player) then
		return
	end
	local ids = {
		"h_1h_sword",
		"b_sword_st",
		"p_pommel_balanced",
		"g_fire",
		"a_head_steel",
		"a_chest_steel",
		"a_hands_steel",
		"a_feets_steel",
		"o_shield_t1",
	}
	for _, defId in ids do
		InventoryService.AddItem(player.UserId, defId)
	end
	pushInventory(player)
	notify(player, true, "MVP test loadout granted (steel + sword parts)")
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

GrantPremium.OnServerEvent:Connect(function(player: Player, amount: number?)
	if not isDev(player) then
		return
	end
	local n = math.clamp(math.floor(if typeof(amount) == "number" then amount else 1), 1, 999)
	CurrencyService.GrantPremium(player.UserId, n)
	pushInventory(player)
	notify(player, true, `Granted {n} premium currency`, { premium = CurrencyService.GetPremium(player.UserId) })
end)

SimulateMatchResult.OnServerEvent:Connect(function(player: Player, payload: any)
	if not isDev(player) then
		return
	end
	if typeof(payload) ~= "table" then
		notify(player, false, "SimulateMatchResult: pass a table { mode, won, bossId? }")
		return
	end
	local mode = payload.mode
	local won = payload.won == true
	local bossId = if typeof(payload.bossId) == "string" then payload.bossId else nil
	if mode ~= "PvP" and mode ~= "PvE" then
		notify(player, false, "mode must be PvP or PvE")
		return
	end

	local result = MatchResultBridge.FinishMatch(player, {
		mode = mode,
		won = won,
		bossId = bossId,
	})

	local parts = {}
	if result.xpGained and result.xpGained > 0 then
		table.insert(parts, `XP +{result.xpGained}`)
	end
	if result.gachaGranted then
		local def = ItemDefs.Get(result.gachaGranted.defId)
		table.insert(parts, `Gacha: {if def then def.name else result.gachaGranted.defId}`)
	elseif won then
		table.insert(parts, "Gacha: —")
	end
	if result.bossGranted then
		local def = ItemDefs.Get(result.bossGranted.defId)
		table.insert(parts, `Boss: {if def then def.name else result.bossGranted.defId}`)
	elseif won and mode == "PvE" and bossId then
		table.insert(parts, "Boss: —")
	end
	if not won then
		table.insert(parts, "Loss — no loot")
	end

	notify(player, result.ok == true, table.concat(parts, " · "), {
		matchResult = result,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	AbilityService.Clear(player.UserId)
end)

DummyService.Ensure()

print("[DevBootstrap] Training dummy + DevTools ready (Studio-only grants)")
