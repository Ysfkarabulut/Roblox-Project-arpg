--[[
	Match end → loot rolls, profile save, inventory sync, client loot UI.
	Call FinishMatch from DevTools, boss scripts, or future arena handlers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local MatchResultService = require(script.Parent.MatchResultService)
local PlayerProfileService = require(script.Parent.Parent.Profile.PlayerProfileService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local HotbarService = require(script.Parent.Parent.Hotbar.HotbarService)
local StatService = require(script.Parent.Parent.Combat.StatService)
local PassiveService = require(script.Parent.Parent.Combat.PassiveService)
local CurrencyService = require(script.Parent.Parent.Inventory.CurrencyService)
local StanceConfig = require(game.ReplicatedStorage.Shared.Config.StanceConfig)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)

local MatchResultBridge = {}

export type LootEntryClient = {
	defId: string,
	uuid: string,
	name: string,
	kind: string?,
	element: string?,
	source: string,
}

export type LootResultPayload = {
	ok: boolean,
	reason: string?,
	mode: string,
	won: boolean,
	bossId: string?,
	xpGained: number,
	levelsGained: number?,
	level: number?,
	xpIntoLevel: number?,
	xpToNext: number?,
	unspentGained: number?,
	unspentTotal: number?,
	mmrDelta: number?,
	mmr: number?,
	mmrTier: string?,
	gacha: LootEntryClient?,
	bossDrop: LootEntryClient?,
}

local lootResultRemote: RemoteEvent? = nil

function MatchResultBridge.SetLootResultRemote(remote: RemoteEvent)
	lootResultRemote = remote
end

local function formatGrant(granted: { defId: string, uuid: string, source: string }?): LootEntryClient?
	if not granted then
		return nil
	end
	local def = ItemDefs.Get(granted.defId)
	return {
		defId = granted.defId,
		uuid = granted.uuid,
		name = if def and def.name then def.name else granted.defId,
		kind = if def then def.kind else nil,
		element = if def and def.element then tostring(def.element) else nil,
		source = granted.source,
	}
end

local function buildSnapshot(userId: number)
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
		updated:FireClient(player, buildSnapshot(player.UserId))
	end
end

local function fireLootResult(
	player: Player,
	result: MatchResultService.MatchResult,
	out: MatchResultService.ProcessOutput,
	xpResult: StatService.GrantXpResult?
)
	if not lootResultRemote then
		return
	end
	local payload: LootResultPayload = {
		ok = out.ok == true,
		reason = out.reason,
		mode = result.mode,
		won = result.won == true,
		bossId = result.bossId,
		xpGained = out.xpGained or 0,
		levelsGained = if xpResult then xpResult.levelsGained else 0,
		level = if xpResult then xpResult.level else nil,
		xpIntoLevel = if xpResult then xpResult.xpIntoLevel else nil,
		xpToNext = if xpResult then xpResult.xpToNext else nil,
		unspentGained = if xpResult then xpResult.unspentGained else 0,
		unspentTotal = if xpResult then xpResult.unspentTotal else nil,
		mmrDelta = result.mmrDelta,
		mmr = result.mmr,
		mmrTier = result.mmrTier,
		gacha = formatGrant(out.gachaGranted),
		bossDrop = formatGrant(out.bossGranted),
	}
	lootResultRemote:FireClient(player, payload)
end

function MatchResultBridge.FinishMatch(player: Player, result: MatchResultService.MatchResult): MatchResultService.ProcessOutput
	local out = MatchResultService.Process(player.UserId, result)
	local xpResult: StatService.GrantXpResult? = nil
	if out.ok and result.won and out.xpGained and out.xpGained > 0 then
		xpResult = StatService.GrantXp(player.UserId, out.xpGained)
	end

	local shouldSave = out.ok
		and (result.won or result.mmrDelta ~= nil)
		and (
			(out.xpGained and out.xpGained > 0)
			or out.gachaGranted ~= nil
			or out.bossGranted ~= nil
			or (xpResult and xpResult.levelsGained > 0)
			or result.mmrDelta ~= nil
		)
	if shouldSave then
		PlayerProfileService.Save(player.UserId)
	end

	local shouldPush = out.gachaGranted ~= nil
		or out.bossGranted ~= nil
		or (xpResult and (xpResult.levelsGained > 0 or xpResult.xpGained > 0))
	if shouldPush then
		pushInventory(player)
	end

	fireLootResult(player, result, out, xpResult)
	return out
end

function MatchResultBridge.FinishMatchForPlayers(players: { Player }, result: MatchResultService.MatchResult)
	for _, player in players do
		if player.Parent then
			MatchResultBridge.FinishMatch(player, result)
		end
	end
end

return MatchResultBridge
