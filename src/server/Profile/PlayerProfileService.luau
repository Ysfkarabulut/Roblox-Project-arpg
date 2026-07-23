--[[
	Player profile persistence — DataStore v1.
	Saves: inventory, loadout, hotbar, stats, premium currency.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local StatConfig = require(game.ReplicatedStorage.Shared.Config.StatConfig)
local XpConfig = require(game.ReplicatedStorage.Shared.Config.XpConfig)
local HotbarConfig = require(game.ReplicatedStorage.Shared.Config.HotbarConfig)
local LoadoutSlots = require(game.ReplicatedStorage.Shared.Config.LoadoutSlots)

local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local HotbarService = require(script.Parent.Parent.Hotbar.HotbarService)
local StatService = require(script.Parent.Parent.Combat.StatService)
local CurrencyService = require(script.Parent.Parent.Inventory.CurrencyService)
local RankedService = require(script.Parent.Parent.Ranked.RankedService)
local TutorialService = require(script.Parent.Parent.Meta.TutorialService)

local PlayerProfileService = {}

local DATASTORE_NAME = "ARPG_PlayerProfile_v1"
local SCHEMA_VERSION = 4
local AUTOSAVE_SEC = 120

export type SavedItem = {
	uuid: string,
	defId: string,
	parts: { handle: string?, blade: string?, pommel: string? }?,
	gemUuid: string?,
	installedIn: string?,
	upgradeLevel: number?,
}

export type PlayerProfile = {
	schemaVersion: number,
	items: { SavedItem },
	loadout: { [string]: string? },
	hotbar: { [string]: string? },
	stats: { level: number, STR: number, DEX: number, VIT: number, INT: number },
	xp: number,
	unspentStatPoints: number,
	premium: number,
	pvpMmr: { [string]: number }?,
	tutorialFlags: { [string]: boolean }?,
}

local store = DataStoreService:GetDataStore(DATASTORE_NAME)
local loaded: { [number]: boolean } = {}
local lastSaveAt: { [number]: number } = {}

local function keyFor(userId: number): string
	return `u_{userId}`
end

local function defaultProfile(): PlayerProfile
	local stats = StatConfig.DefaultAllocated(StatConfig.DefaultLevel)
	return {
		schemaVersion = SCHEMA_VERSION,
		items = {},
		loadout = {
			main = nil,
			off = nil,
			head = nil,
			chest = nil,
			hands = nil,
			feets = nil,
		},
		hotbar = {},
		stats = {
			level = stats.level,
			STR = stats.STR,
			DEX = stats.DEX,
			VIT = stats.VIT,
			INT = stats.INT,
		},
		premium = 0,
		xp = XpConfig.TotalXpForLevel(stats.level),
		unspentStatPoints = 0,
		pvpMmr = {
			pvp_1v1 = 1000,
			pvp_2v2 = 1000,
			pvp_3v3 = 1000,
		},
		tutorialFlags = {},
	}
end

function PlayerProfileService.Export(userId: number): PlayerProfile
	local items: { SavedItem } = {}
	for _, item in InventoryService.GetItems(userId) do
		local saved: SavedItem = {
			uuid = item.uuid,
			defId = item.defId,
		}
		if item.parts then
			saved.parts = {
				handle = item.parts.handle,
				blade = item.parts.blade,
				pommel = item.parts.pommel,
			}
		end
		if item.gemUuid then
			saved.gemUuid = item.gemUuid
		end
		if item.installedIn then
			saved.installedIn = item.installedIn
		end
		if typeof((item :: any).upgradeLevel) == "number" then
			saved.upgradeLevel = (item :: any).upgradeLevel
		end
		table.insert(items, saved)
	end

	local lo = LoadoutService.Get(userId)
	local hb = HotbarService.GetBinds(userId)
	local hotbar: { [string]: string? } = {}
	for i = 1, HotbarConfig.SlotCount do
		if hb[i] then
			hotbar[tostring(i)] = hb[i]
		end
	end

	local stats = StatService.Get(userId)
	return {
		schemaVersion = SCHEMA_VERSION,
		items = items,
		loadout = {
			main = lo.main,
			off = lo.off,
			head = lo.head,
			chest = lo.chest,
			hands = lo.hands,
			feets = lo.feets,
		},
		hotbar = hotbar,
		stats = {
			level = stats.level,
			STR = stats.STR,
			DEX = stats.DEX,
			VIT = stats.VIT,
			INT = stats.INT,
		},
		xp = StatService.GetTotalXp(userId),
		unspentStatPoints = StatService.GetUnspent(userId),
		premium = CurrencyService.GetPremium(userId),
		pvpMmr = RankedService.Export(userId),
		tutorialFlags = TutorialService.Export(userId),
	}
end

local function sanitizeProfile(raw: any): PlayerProfile?
	if typeof(raw) ~= "table" then
		return nil
	end
	if typeof(raw.schemaVersion) ~= "number" or raw.schemaVersion > SCHEMA_VERSION then
		return nil
	end

	local profile = defaultProfile()
	profile.schemaVersion = raw.schemaVersion

	local uuidSet: { [string]: boolean } = {}

	if typeof(raw.items) == "table" then
		for _, item in raw.items do
			if typeof(item) ~= "table" then
				continue
			end
			if typeof(item.uuid) ~= "string" or typeof(item.defId) ~= "string" then
				continue
			end
			if not ItemDefs.Get(item.defId) then
				continue
			end
			if uuidSet[item.uuid] then
				continue
			end
			uuidSet[item.uuid] = true
			local saved: SavedItem = {
				uuid = item.uuid,
				defId = item.defId,
			}
			if typeof(item.parts) == "table" then
				saved.parts = {
					handle = if typeof(item.parts.handle) == "string" then item.parts.handle else nil,
					blade = if typeof(item.parts.blade) == "string" then item.parts.blade else nil,
					pommel = if typeof(item.parts.pommel) == "string" then item.parts.pommel else nil,
				}
			end
			if typeof(item.gemUuid) == "string" then
				saved.gemUuid = item.gemUuid
			end
			if typeof(item.installedIn) == "string" then
				saved.installedIn = item.installedIn
			end
			if typeof(item.upgradeLevel) == "number" then
				saved.upgradeLevel = math.clamp(math.floor(item.upgradeLevel), 0, 99)
			end
			table.insert(profile.items, saved)
		end
	end

	-- rebuild uuid set and fix gem references
	uuidSet = {}
	for _, item in profile.items do
		uuidSet[item.uuid] = true
	end
	for _, item in profile.items do
		if item.gemUuid and not uuidSet[item.gemUuid] then
			item.gemUuid = nil
		end
		if item.installedIn and not uuidSet[item.installedIn] then
			item.installedIn = nil
		end
		if item.parts then
			for _, partUuid in { item.parts.handle, item.parts.blade, item.parts.pommel } do
				if partUuid and not uuidSet[partUuid] then
					item.parts = nil
					break
				end
			end
		end
	end

	if typeof(raw.loadout) == "table" then
		for _, slotId in LoadoutSlots.Order do
			local uuid = raw.loadout[slotId]
			if typeof(uuid) == "string" and uuidSet[uuid] then
				profile.loadout[slotId] = uuid
			end
		end
	end

	if typeof(raw.hotbar) == "table" then
		for i = 1, HotbarConfig.SlotCount do
			local id = raw.hotbar[tostring(i)]
			if typeof(id) == "string" then
				profile.hotbar[tostring(i)] = id
			end
		end
	end

	if typeof(raw.stats) == "table" then
		local s = raw.stats
		if typeof(s.level) == "number" then
			profile.stats.level = math.clamp(math.floor(s.level), 1, StatConfig.MaxLevel)
		end
		for _, k in { "STR", "DEX", "VIT", "INT" } do
			if typeof(s[k]) == "number" then
				profile.stats[k] = math.clamp(math.floor(s[k]), 1, 999)
			end
		end
	end

	if typeof(raw.premium) == "number" and raw.premium >= 0 then
		profile.premium = math.floor(raw.premium)
	end

	if typeof(raw.xp) == "number" and raw.xp >= 0 then
		profile.xp = math.floor(raw.xp)
	else
		profile.xp = XpConfig.TotalXpForLevel(profile.stats.level)
	end

	if typeof(raw.unspentStatPoints) == "number" and raw.unspentStatPoints >= 0 then
		profile.unspentStatPoints = math.floor(raw.unspentStatPoints)
	else
		profile.unspentStatPoints = 0
	end

	if typeof(raw.pvpMmr) == "table" then
		profile.pvpMmr = {}
		for key, val in raw.pvpMmr do
			if typeof(val) == "number" then
				profile.pvpMmr[key] = math.floor(val)
			end
		end
	end

	if typeof(raw.tutorialFlags) == "table" then
		profile.tutorialFlags = {}
		for key, val in raw.tutorialFlags do
			if typeof(key) == "string" and val == true then
				profile.tutorialFlags[key] = true
			end
		end
	end

	return profile
end

function PlayerProfileService.Import(userId: number, profile: PlayerProfile)
	local items = {}
	for _, saved in profile.items do
		table.insert(items, {
			uuid = saved.uuid,
			defId = saved.defId,
			parts = saved.parts,
			gemUuid = saved.gemUuid,
			installedIn = saved.installedIn,
			upgradeLevel = saved.upgradeLevel,
		})
	end
	InventoryService.ReplaceBag(userId, items)
	LoadoutService.Import(userId, profile.loadout)

	local binds = {}
	for i = 1, HotbarConfig.SlotCount do
		binds[i] = profile.hotbar[tostring(i)]
	end
	HotbarService.ImportBinds(userId, binds)

	StatService.Import(userId, profile.stats, profile.xp, profile.unspentStatPoints)
	CurrencyService.SetPremium(userId, profile.premium)
	RankedService.Import(userId, profile.pvpMmr)
	TutorialService.Import(userId, profile.tutorialFlags)
end

function PlayerProfileService.Load(userId: number): boolean
	local ok, data = pcall(function()
		return store:GetAsync(keyFor(userId))
	end)
	if not ok then
		warn("[PlayerProfile] Load failed", userId, data)
		return false
	end
	if data == nil then
		return false
	end
	local profile = sanitizeProfile(data)
	if not profile then
		warn("[PlayerProfile] Invalid profile data", userId)
		return false
	end
	PlayerProfileService.Import(userId, profile)
	return true
end

function PlayerProfileService.Save(userId: number): boolean
	local profile = PlayerProfileService.Export(userId)
	local ok, err = pcall(function()
		store:SetAsync(keyFor(userId), profile)
	end)
	if not ok then
		warn("[PlayerProfile] Save failed", userId, err)
		return false
	end
	lastSaveAt[userId] = os.clock()
	return true
end

function PlayerProfileService.Release(userId: number)
	loaded[userId] = nil
	lastSaveAt[userId] = nil
	InventoryService.Clear(userId)
	LoadoutService.Clear(userId)
	HotbarService.Clear(userId)
	StatService.Clear(userId)
	CurrencyService.Clear(userId)
	RankedService.Clear(userId)
	TutorialService.Clear(userId)
end

function PlayerProfileService.InitializePlayer(player: Player)
	local userId = player.UserId
	if loaded[userId] then
		return
	end

	local hadSave = PlayerProfileService.Load(userId)
	if not hadSave then
		InventoryService.GrantStarter(userId)
		StatService.Reset(userId, StatConfig.DefaultLevel)
		CurrencyService.SetPremium(userId, 0)
	end

	loaded[userId] = true
	lastSaveAt[userId] = os.clock()
end

function PlayerProfileService.SavePlayer(player: Player)
	if not loaded[player.UserId] then
		return
	end
	PlayerProfileService.Save(player.UserId)
end

local function onPlayerRemoving(player: Player)
	PlayerProfileService.SavePlayer(player)
	PlayerProfileService.Release(player.UserId)
end

function PlayerProfileService.Start()
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerProfileService.SavePlayer(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SEC)
			for _, player in Players:GetPlayers() do
				local userId = player.UserId
				if loaded[userId] then
					local since = os.clock() - (lastSaveAt[userId] or 0)
					if since >= AUTOSAVE_SEC - 1 then
						PlayerProfileService.Save(userId)
					end
				end
			end
		end
	end)

	for _, player in Players:GetPlayers() do
		PlayerProfileService.InitializePlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		PlayerProfileService.InitializePlayer(player)
	end)

	local env = if RunService:IsStudio() then "Studio" else "Live"
	print(`[PlayerProfile] Persistence ready ({env}) — {DATASTORE_NAME}`)
end

return PlayerProfileService
