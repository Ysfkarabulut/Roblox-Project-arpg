--[[
	Lobby bootstrap — Remotes + Party/Queue + state sync.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

-- Remotes first: clients must not hang if Party/Queue modules fail to load.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "LobbyRemotes"
remotesFolder.Parent = ReplicatedStorage

local function remote(name: string): RemoteEvent
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

local PartyInvite = remote("PartyInvite")
local PartyInviteByName = remote("PartyInviteByName")
local PartyRespondInvite = remote("PartyRespondInvite")
local PartyInviteReceived = remote("PartyInviteReceived")
local PartyKick = remote("PartyKick")
local PartyPromote = remote("PartyPromote")
local PartyReady = remote("PartyReady")
local PartyLeave = remote("PartyLeave")
local QueueStart = remote("QueueStart")
local QueueCancel = remote("QueueCancel")
local LobbyNotify = remote("LobbyNotify")
local LobbyUpdated = remote("LobbyUpdated")
local GetLobbyState = remoteFunction("GetLobbyState")

local PartyService = require(script.Parent.Lobby.PartyService)
local QueueService = require(script.Parent.Lobby.QueueService)
local LobbyStateService = require(script.Parent.Lobby.LobbyStateService)

local function notify(player: Player, ok: boolean, code: string?)
	LobbyNotify:FireClient(player, { ok = ok, code = code })
end

local function broadcastParty(userId: number)
	local party = PartyService.GetPartyForPlayer(userId)
	if party then
		PartyService.SyncAttributesForParty(party)
		for _, m in party.members do
			local plr = Players:GetPlayerByUserId(m.userId)
			if plr then
				LobbyUpdated:FireClient(plr, LobbyStateService.BuildForPlayer(m.userId))
			end
		end
	else
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			LobbyUpdated:FireClient(plr, LobbyStateService.BuildForPlayer(userId))
		end
	end
end

local function broadcastParties(userIds: { number })
	local seen: { [number]: boolean } = {}
	for _, uid in userIds do
		if not seen[uid] then
			seen[uid] = true
			broadcastParty(uid)
		end
	end
end

local function cancelQueueForUser(userId: number)
	local party = PartyService.GetPartyForPlayer(userId)
	if party then
		QueueService.CancelForParty(party.id)
	end
end

GetLobbyState.OnServerInvoke = function(player: Player)
	return LobbyStateService.BuildForPlayer(player.UserId)
end

local function sendInviteToTarget(leader: Player, target: Player)
	local ok, err = PartyService.SendInvite(leader, target)
	notify(leader, ok, if ok then "InviteSent" else err)
	if ok then
		local payload = PartyService.GetPendingInvite(target.UserId)
		if payload then
			PartyInviteReceived:FireClient(target, payload)
		end
	end
end

PartyInvite.OnServerEvent:Connect(function(leader: Player, targetUserId: number)
	if typeof(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		notify(leader, false, "PlayerNotFound")
		return
	end
	sendInviteToTarget(leader, target)
end)

PartyInviteByName.OnServerEvent:Connect(function(leader: Player, name: string)
	if typeof(name) ~= "string" then
		return
	end
	local target = PartyService.FindPlayerByName(name)
	if not target then
		notify(leader, false, "PlayerNotFound")
		return
	end
	sendInviteToTarget(leader, target)
end)

PartyRespondInvite.OnServerEvent:Connect(function(target: Player, fromUserId: number, accept: boolean)
	if typeof(fromUserId) ~= "number" or typeof(accept) ~= "boolean" then
		return
	end
	local leaderPartyBefore = PartyService.GetPartyForPlayer(fromUserId)
	local targetPartyBefore = PartyService.GetPartyForPlayer(target.UserId)
	local ok, err = PartyService.RespondInvite(target, fromUserId, accept)
	if not ok then
		notify(target, false, err)
		return
	end
	if err == "Declined" then
		notify(target, true, "InviteDeclined")
		local leader = Players:GetPlayerByUserId(fromUserId)
		if leader then
			notify(leader, false, "InviteDeclined")
		end
		return
	end

	if leaderPartyBefore then
		QueueService.CancelForParty(leaderPartyBefore.id)
	end
	if targetPartyBefore then
		QueueService.CancelForParty(targetPartyBefore.id)
	end

	notify(target, true, "JoinedParty")
	local leader = Players:GetPlayerByUserId(fromUserId)
	if leader then
		notify(leader, true, "InviteAccepted")
	end
	local memberIds = {}
	if leaderPartyBefore then
		for _, uid in PartyService.GetMemberUserIds(leaderPartyBefore) do
			table.insert(memberIds, uid)
		end
	end
	table.insert(memberIds, target.UserId)
	broadcastParties(memberIds)
end)

PartyKick.OnServerEvent:Connect(function(leader: Player, targetUserId: number)
	if typeof(targetUserId) ~= "number" then
		return
	end
	local party = PartyService.GetPartyForPlayer(leader.UserId)
	local memberIds = if party then PartyService.GetMemberUserIds(party) else { leader.UserId }
	local ok, err = PartyService.Kick(leader, targetUserId)
	notify(leader, ok, if ok then "Kicked" else err)
	if ok then
		cancelQueueForUser(targetUserId)
		table.insert(memberIds, targetUserId)
		broadcastParties(memberIds)
	end
end)

PartyPromote.OnServerEvent:Connect(function(leader: Player, newLeaderUserId: number)
	if typeof(newLeaderUserId) ~= "number" then
		return
	end
	local party = PartyService.GetPartyForPlayer(leader.UserId)
	local memberIds = if party then PartyService.GetMemberUserIds(party) else { leader.UserId }
	local ok, err = PartyService.PromoteLeader(leader, newLeaderUserId)
	notify(leader, ok, if ok then "Promoted" else err)
	if ok then
		broadcastParties(memberIds)
	end
end)

PartyReady.OnServerEvent:Connect(function(player: Player, ready: boolean)
	if typeof(ready) ~= "boolean" then
		return
	end
	local ok, err = PartyService.SetReady(player, ready)
	notify(player, ok, err)
	if ok then
		broadcastParty(player.UserId)
	end
end)

PartyLeave.OnServerEvent:Connect(function(player: Player)
	local party = PartyService.GetPartyForPlayer(player.UserId)
	local memberIds = if party then PartyService.GetMemberUserIds(party) else { player.UserId }
	if party then
		QueueService.CancelForParty(party.id)
	end
	PartyService.Leave(player)
	PartyService.CreateSoloParty(player)
	notify(player, true, "Left")
	table.insert(memberIds, player.UserId)
	broadcastParties(memberIds)
end)

QueueStart.OnServerEvent:Connect(function(leader: Player, queueId: string)
	if typeof(queueId) ~= "string" then
		return
	end
	if not PartyService.GetPartyForPlayer(leader.UserId) then
		PartyService.CreateSoloParty(leader)
	end
	local ok, err = QueueService.Enqueue(leader, queueId)
	notify(leader, ok, err)
	if ok then
		broadcastParty(leader.UserId)
	end
end)

QueueCancel.OnServerEvent:Connect(function(leader: Player)
	local ok, err = QueueService.Cancel(leader)
	notify(leader, ok, err)
	if ok then
		broadcastParty(leader.UserId)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		if player.Parent then
			LobbyUpdated:FireClient(player, LobbyStateService.BuildForPlayer(player.UserId))
		end
	end)
end)

print("[LobbyBootstrap] Party + Queue + LobbyUI ready")
