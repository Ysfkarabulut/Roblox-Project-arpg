--[[
	Trade remotes — invite by player name, bilateral lootbox trade.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TradeService = require(script.Parent.Trade.TradeService)
local LootService = require(script.Parent.Loot.LootService)

local existing = ReplicatedStorage:FindFirstChild("TradeRemotes")
if existing then
	existing:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "TradeRemotes"
folder.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = folder
	return r
end

local TradeInviteByName = remoteEvent("TradeInviteByName")
local TradeRespondInvite = remoteEvent("TradeRespondInvite")
local TradeAddOffer = remoteEvent("TradeAddOffer")
local TradeRemoveOffer = remoteEvent("TradeRemoveOffer")
local TradeSetReady = remoteEvent("TradeSetReady")
local TradeCancel = remoteEvent("TradeCancel")
local TradeExecute = remoteEvent("TradeExecute")
local TradeUpdated = remoteEvent("TradeUpdated")
local TradeInviteReceived = remoteEvent("TradeInviteReceived")
local OpenLootBox = remoteEvent("OpenLootBox")
local LootBoxResult = remoteEvent("LootBoxResult")

local invFolder = ReplicatedStorage:WaitForChild("InventoryRemotes")
local InventoryUpdated = invFolder:WaitForChild("InventoryUpdated") :: RemoteEvent

local function pushInventory(player: Player)
	if _G.PushInventory then
		_G.PushInventory(player)
	else
		InventoryUpdated:FireClient(player, {})
	end
end

local function pushBoth(a: Player?, b: Player?)
	if a and a.Parent then
		pushInventory(a)
		TradeUpdated:FireClient(a, TradeService.SnapshotFor(a.UserId))
	end
	if b and b.Parent then
		pushInventory(b)
		TradeUpdated:FireClient(b, TradeService.SnapshotFor(b.UserId))
	end
end

local function partnerPlayer(player: Player): Player?
	local snap = TradeService.SnapshotFor(player.UserId)
	if snap.ok and snap.partnerUserId then
		return Players:GetPlayerByUserId(snap.partnerUserId)
	end
	return nil
end

TradeInviteByName.OnServerEvent:Connect(function(player: Player, targetName: string, starterUuid: string?)
	if typeof(targetName) ~= "string" then
		return
	end
	if typeof(starterUuid) ~= "string" then
		starterUuid = nil
	end
	local target = TradeService.FindPlayerByName(targetName)
	if not target then
		TradeUpdated:FireClient(player, { ok = false, reason = "PlayerNotFound" })
		return
	end
	local ok, err = TradeService.SendInvite(player, target, starterUuid)
	if not ok then
		TradeUpdated:FireClient(player, { ok = false, reason = err })
		return
	end
	TradeUpdated:FireClient(player, { ok = false, reason = "InviteSent", partnerUserId = target.UserId })
	local payload = TradeService.GetPendingInvite(target.UserId)
	if payload then
		TradeInviteReceived:FireClient(target, payload)
	end
end)

TradeRespondInvite.OnServerEvent:Connect(function(player: Player, fromUserId: number, accept: boolean)
	if typeof(fromUserId) ~= "number" or typeof(accept) ~= "boolean" then
		return
	end
	if not accept then
		TradeService.DeclineInvite(player.UserId, fromUserId)
		local fromPlr = Players:GetPlayerByUserId(fromUserId)
		if fromPlr then
			TradeUpdated:FireClient(fromPlr, { ok = false, reason = "InviteDeclined" })
		end
		TradeUpdated:FireClient(player, { ok = false, reason = "InviteDeclined" })
		return
	end

	local ok, err = TradeService.AcceptInvite(player.UserId, fromUserId)
	local fromPlr = Players:GetPlayerByUserId(fromUserId)
	if not ok then
		TradeUpdated:FireClient(player, { ok = false, reason = err })
		if fromPlr then
			TradeUpdated:FireClient(fromPlr, { ok = false, reason = err })
		end
		return
	end
	pushBoth(fromPlr, player)
end)

TradeAddOffer.OnServerEvent:Connect(function(player: Player, uuid: string)
	if typeof(uuid) ~= "string" then
		return
	end
	local ok, err = TradeService.AddOffer(player.UserId, uuid)
	if not ok then
		TradeUpdated:FireClient(player, { ok = false, reason = err })
		return
	end
	pushBoth(player, partnerPlayer(player))
end)

TradeRemoveOffer.OnServerEvent:Connect(function(player: Player, uuid: string)
	if typeof(uuid) ~= "string" then
		return
	end
	TradeService.RemoveOffer(player.UserId, uuid)
	pushBoth(player, partnerPlayer(player))
end)

TradeSetReady.OnServerEvent:Connect(function(player: Player, ready: boolean)
	if typeof(ready) ~= "boolean" then
		return
	end
	TradeService.SetReady(player.UserId, ready)
	pushBoth(player, partnerPlayer(player))
end)

TradeCancel.OnServerEvent:Connect(function(player: Player)
	local partner = partnerPlayer(player)
	TradeService.Cancel(player.UserId)
	TradeUpdated:FireClient(player, { ok = false, reason = "Cancelled" })
	if partner then
		TradeUpdated:FireClient(partner, { ok = false, reason = "Cancelled" })
	end
end)

TradeExecute.OnServerEvent:Connect(function(player: Player)
	local partner = partnerPlayer(player)
	local ok, err = TradeService.TryExecute(player.UserId)
	if not ok then
		TradeUpdated:FireClient(player, { ok = false, reason = err })
		return
	end
	pushInventory(player)
	if partner then
		pushInventory(partner)
	end
	TradeUpdated:FireClient(player, { ok = false, reason = "Completed" })
	if partner then
		TradeUpdated:FireClient(partner, { ok = false, reason = "Completed" })
	end
end)

OpenLootBox.OnServerEvent:Connect(function(player: Player, boxUuid: string)
	if typeof(boxUuid) ~= "string" then
		return
	end
	local result = LootService.OpenLootBox(player.UserId, boxUuid)
	if not result.ok then
		warn(`[LootBox] Open failed for {player.Name}: {result.reason}`)
		LootBoxResult:FireClient(player, result)
		return
	end
	pushInventory(player)
	LootBoxResult:FireClient(player, result)
end)

print("[TradeBootstrap] Trade invite-by-name + lootbox open ready")
