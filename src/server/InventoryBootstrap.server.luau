--[[
	Inventory + Loadout + Hotbar + WeaponAssembly remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create remotes first so client GearUI never hangs if a require below errors.
local existing = ReplicatedStorage:FindFirstChild("InventoryRemotes")
if existing then
	existing:Destroy()
end
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
local InstallWeaponPart = remoteEvent("InstallWeaponPart")
local RemoveWeaponPart = remoteEvent("RemoveWeaponPart")
local SocketGem = remoteEvent("SocketGem")
local UnsocketGem = remoteEvent("UnsocketGem")
local CreateWeaponFrame = remoteEvent("CreateWeaponFrame")
local ForgeWeapon = remoteEvent("ForgeWeapon")
local ForgeResult = remoteEvent("ForgeResult")
local AllocateStat = remoteEvent("AllocateStat")

local PlayerProfileService = require(script.Parent.Profile.PlayerProfileService)

local InventoryService = require(script.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Inventory.LoadoutService)
local WeaponAssemblyService = require(script.Parent.Inventory.WeaponAssemblyService)
local HotbarService = require(script.Parent.Hotbar.HotbarService)
local StatService = require(script.Parent.Combat.StatService)
local PassiveService = require(script.Parent.Combat.PassiveService)
local CurrencyService = require(script.Parent.Inventory.CurrencyService)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local StanceConfig = require(game.ReplicatedStorage.Shared.Config.StanceConfig)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)

local function resolveStance(userId: number): string
	local resolved = LoadoutService.GetResolvedMain(userId)
	local mainDef = if resolved and resolved.complete then WeaponResolver.AsItemDef(resolved) else nil
	local offDef = LoadoutService.GetOffHandDef(userId)
	return StanceConfig.Resolve(mainDef, offDef)
end

local function buildResolvedSummary(userId: number, frameUuid: string?)
	if not frameUuid then
		return nil
	end
	local resolved = WeaponAssemblyService.ToResolved(userId, frameUuid)
	if not resolved or not resolved.complete then
		return nil
	end
	return {
		displayName = resolved.displayName,
		element = resolved.element,
		baseDamage = resolved.baseDamage,
		kind = resolved.kind,
		family = resolved.family,
		scaling = resolved.scaling,
		attackSpeedMult = resolved.attackSpeedMult,
		complete = resolved.complete,
		bladeDefId = resolved.bladeDefId,
		gemDefId = resolved.gemDefId,
	}
end

local function buildSnapshot(userId: number)
	HotbarService.Prune(userId)
	PassiveService.Refresh(userId)
	local loadout = LoadoutService.Get(userId)
	return {
		items = InventoryService.GetItems(userId),
		loadout = LoadoutService.Get(userId),
		hotbar = HotbarService.GetBinds(userId),
		hotbarSource = HotbarService.GetBindSources(userId),
		actives = HotbarService.GetAvailableActives(userId),
		passives = PassiveService.GetSummary(userId),
		stats = StatService.Get(userId),
		xpProgress = StatService.GetXpProgress(userId),
		derived = StatService.Derived(userId),
		stance = resolveStance(userId),
		resolvedMain = buildResolvedSummary(userId, loadout.main),
		resolvedOff = buildResolvedSummary(userId, loadout.off),
		premiumCurrency = CurrencyService.GetPremium(userId),
		gemPreserveUnsocketCost = CurrencyService.GemPreserveUnsocketCost,
	}
end

local function saveProfile(userId: number)
	PlayerProfileService.Save(userId)
end

local function push(player: Player)
	player:SetAttribute("CombatStance", resolveStance(player.UserId))
	InventoryUpdated:FireClient(player, buildSnapshot(player.UserId))
end

GetSnapshot.OnServerInvoke = function(player: Player)
	return buildSnapshot(player.UserId)
end

local function isLoadoutLocked(userId: number): boolean
	local LoadoutLockService = require(script.Parent.Combat.LoadoutLockService)
	return LoadoutLockService.IsLocked(userId)
end

EquipItem.OnServerEvent:Connect(function(player: Player, uuid: string, slotId: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
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
		saveProfile(player.UserId)
	end
	push(player)
end)

UnequipSlot.OnServerEvent:Connect(function(player: Player, slotId: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(slotId) ~= "string" then
		return
	end
	LoadoutService.Unequip(player.UserId, slotId)
	HotbarService.Prune(player.UserId)
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	saveProfile(player.UserId)
	push(player)
end)

BindAbility.OnServerEvent:Connect(function(player: Player, abilityId: string, slotIndex: number, sourceUuid: any)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(abilityId) ~= "string" or typeof(slotIndex) ~= "number" then
		return
	end
	local src = if typeof(sourceUuid) == "string" then sourceUuid else nil
	local ok, err = HotbarService.Bind(player.UserId, abilityId, slotIndex, src)
	if not ok then
		warn("[Hotbar] Bind failed", player.Name, err)
	else
		saveProfile(player.UserId)
	end
	push(player)
end)

UnbindHotbar.OnServerEvent:Connect(function(player: Player, slotIndex: number)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(slotIndex) ~= "number" then
		return
	end
	HotbarService.Unbind(player.UserId, slotIndex)
	push(player)
end)

DiscardItem.OnServerEvent:Connect(function(player: Player, uuid: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(uuid) ~= "string" then
		return
	end
	local userId = player.UserId
	if InventoryService.IsInstalled(userId, uuid) then
		return
	end
	local slot = LoadoutService.GetSlotOf(userId, uuid)
	if slot then
		LoadoutService.Unequip(userId, slot)
	end
	local inst = InventoryService.Find(userId, uuid)
	if inst and inst.defId == "weapon_frame" then
		InventoryService.ReleaseFrameParts(userId, uuid)
	end
	if InventoryService.RemoveItem(userId, uuid) then
		HotbarService.Prune(userId)
		if _G.RefreshWeaponVisuals then
			_G.RefreshWeaponVisuals(player)
		end
		saveProfile(userId)
	end
	push(player)
end)

InstallWeaponPart.OnServerEvent:Connect(function(player: Player, frameUuid: string, partUuid: string, slot: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(frameUuid) ~= "string" or typeof(partUuid) ~= "string" or typeof(slot) ~= "string" then
		return
	end
	local ok, err = WeaponAssemblyService.InstallPart(player.UserId, frameUuid, partUuid, slot)
	if not ok then
		warn("[Assembly] Install failed", player.Name, err)
	end
	if ok then
		saveProfile(player.UserId)
	end
	HotbarService.Prune(player.UserId)
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	push(player)
end)

RemoveWeaponPart.OnServerEvent:Connect(function(player: Player, frameUuid: string, slot: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(frameUuid) ~= "string" or typeof(slot) ~= "string" then
		return
	end
	WeaponAssemblyService.RemovePart(player.UserId, frameUuid, slot)
	saveProfile(player.UserId)
	HotbarService.Prune(player.UserId)
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	push(player)
end)

SocketGem.OnServerEvent:Connect(function(player: Player, frameUuid: string, gemUuid: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(frameUuid) ~= "string" or typeof(gemUuid) ~= "string" then
		return
	end
	WeaponAssemblyService.SocketGem(player.UserId, frameUuid, gemUuid)
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	push(player)
end)

UnsocketGem.OnServerEvent:Connect(function(player: Player, frameUuid: string, preserve: boolean?)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(frameUuid) ~= "string" then
		return
	end
	local ok, err = WeaponAssemblyService.UnsocketGem(player.UserId, frameUuid, preserve == true)
	if not ok and err then
		warn(`[Inventory] UnsocketGem failed for {player.Name}: {err}`)
	end
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	push(player)
end)

CreateWeaponFrame.OnServerEvent:Connect(function(player: Player)
	if isLoadoutLocked(player.UserId) then
		return
	end
	WeaponAssemblyService.CreateFrame(player.UserId)
	push(player)
end)

ForgeWeapon.OnServerEvent:Connect(function(player: Player, handleUuid: any, bladeUuid: any, pommelUuid: any, gemUuid: any)
	if isLoadoutLocked(player.UserId) then
		ForgeResult:FireClient(player, { ok = false, code = "LoadoutLocked" })
		return
	end
	if typeof(handleUuid) ~= "string" or typeof(bladeUuid) ~= "string" or typeof(pommelUuid) ~= "string" then
		ForgeResult:FireClient(player, { ok = false, code = "BadParts" })
		return
	end
	local gem = if typeof(gemUuid) == "string" and gemUuid ~= "" then gemUuid else nil
	local frameUuid, err, gemSkipped = WeaponAssemblyService.ForgeFromParts(player.UserId, handleUuid, bladeUuid, pommelUuid, gem)
	if not frameUuid then
		warn("[Forge] Failed", player.Name, err)
		ForgeResult:FireClient(player, { ok = false, code = err or "ForgeFailed" })
		return
	end
	ForgeResult:FireClient(player, {
		ok = true,
		frameUuid = frameUuid,
		gemSkipped = gemSkipped,
	})
	HotbarService.AutoFill(player.UserId)
	if _G.RefreshWeaponVisuals then
		_G.RefreshWeaponVisuals(player)
	end
	saveProfile(player.UserId)
	push(player)
end)

AllocateStat.OnServerEvent:Connect(function(player: Player, statKey: string)
	if isLoadoutLocked(player.UserId) then
		return
	end
	if typeof(statKey) ~= "string" then
		return
	end
	local ok, err = StatService.AllocateStat(player.UserId, statKey)
	if not ok then
		warn("[Stat] Allocate failed", player.Name, err)
		return
	end
	PlayerProfileService.Save(player.UserId)
	push(player)
end)

local function autoEquipPlaytest(userId: number)
	local lo = LoadoutService.Get(userId)

	if not lo.main then
		for _, item in InventoryService.GetItems(userId) do
			if item.defId == "weapon_frame" and item.parts and item.parts.handle and item.parts.blade and item.parts.pommel then
				LoadoutService.Equip(userId, item.uuid, "main")
				break
			end
		end
	end

	local ArmorMatrix = require(game.ReplicatedStorage.Shared.Config.ArmorMatrix)
	local armorSlots = { "head", "chest", "hands", "feets" }
	for _, slotId in armorSlots do
		local loNow = LoadoutService.Get(userId)
		if not (loNow :: any)[slotId] then
			local wantDef = ArmorMatrix.TestSetIds[slotId]
			for _, item in InventoryService.GetItems(userId) do
				if item.defId == wantDef then
					LoadoutService.Equip(userId, item.uuid, slotId)
					break
				end
			end
		end
	end

	HotbarService.AutoFill(userId)
end

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		if not player.Parent then
			return
		end
		autoEquipPlaytest(player.UserId)
		push(player)
	end)
end)

for _, player in Players:GetPlayers() do
	autoEquipPlaytest(player.UserId)
	push(player)
end

_G.PushInventory = push

print("[InventoryBootstrap] Inventory + Hotbar + Assembly ready")
