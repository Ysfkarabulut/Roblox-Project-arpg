--[[
	Lobby bootstrap — Remotes + Party/Queue wiring.
	Combat henüz yok; yalnızca lobby kabuğu.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PartyService = require(script.Parent.Lobby.PartyService)
local QueueService = require(script.Parent.Lobby.QueueService)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "LobbyRemotes"
remotesFolder.Parent = ReplicatedStorage

local function remote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local PartyInvite = remote("PartyInvite")
local PartyReady = remote("PartyReady")
local PartyLeave = remote("PartyLeave")
local QueueStart = remote("QueueStart")
local QueueCancel = remote("QueueCancel")
local LobbyNotify = remote("LobbyNotify")

local function notify(player: Player, ok: boolean, code: string?)
	LobbyNotify:FireClient(player, { ok = ok, code = code })
end

PartyInvite.OnServerEvent:Connect(function(leader: Player, targetUserId: number)
	if typeof(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		notify(leader, false, "TargetOffline")
		return
	end
	local ok, err = PartyService.Invite(leader, target)
	notify(leader, ok, err)
	if ok then
		notify(target, true, "Invited")
	end
end)

PartyReady.OnServerEvent:Connect(function(player: Player, ready: boolean)
	if typeof(ready) ~= "boolean" then
		return
	end
	local ok, err = PartyService.SetReady(player, ready)
	notify(player, ok, err)
end)

PartyLeave.OnServerEvent:Connect(function(player: Player)
	local party = PartyService.GetPartyForPlayer(player.UserId)
	if party then
		QueueService.CancelForParty(party.id)
	end
	PartyService.Leave(player)
	notify(player, true, "Left")
end)

QueueStart.OnServerEvent:Connect(function(leader: Player, queueId: string)
	if typeof(queueId) ~= "string" then
		return
	end
	local ok, err = QueueService.Enqueue(leader, queueId)
	notify(leader, ok, err)
end)

QueueCancel.OnServerEvent:Connect(function(leader: Player)
	local ok, err = QueueService.Cancel(leader)
	notify(leader, ok, err)
end)

print("[LobbyBootstrap] Party + Queue ready")
