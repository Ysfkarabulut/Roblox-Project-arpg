--[[
	Lobby client — RemoteEvent köprüsü + Studio test API (_G.Lobby).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes")
local PartyInvite = remotes:WaitForChild("PartyInvite") :: RemoteEvent
local PartyInviteByName = remotes:WaitForChild("PartyInviteByName") :: RemoteEvent
local PartyRespondInvite = remotes:WaitForChild("PartyRespondInvite") :: RemoteEvent
local PartyKick = remotes:WaitForChild("PartyKick") :: RemoteEvent
local PartyPromote = remotes:WaitForChild("PartyPromote") :: RemoteEvent
local PartyReady = remotes:WaitForChild("PartyReady") :: RemoteEvent
local PartyLeave = remotes:WaitForChild("PartyLeave") :: RemoteEvent
local QueueStart = remotes:WaitForChild("QueueStart") :: RemoteEvent
local QueueCancel = remotes:WaitForChild("QueueCancel") :: RemoteEvent
local LobbyNotify = remotes:WaitForChild("LobbyNotify") :: RemoteEvent

local Lobby = {}

function Lobby.Invite(targetUserId: number)
	PartyInvite:FireServer(targetUserId)
end

function Lobby.InviteByName(name: string)
	PartyInviteByName:FireServer(name)
end

function Lobby.RespondInvite(fromUserId: number, accept: boolean)
	PartyRespondInvite:FireServer(fromUserId, accept)
end

function Lobby.Kick(targetUserId: number)
	PartyKick:FireServer(targetUserId)
end

function Lobby.Promote(targetUserId: number)
	PartyPromote:FireServer(targetUserId)
end

function Lobby.SetReady(ready: boolean)
	PartyReady:FireServer(ready)
end

function Lobby.LeaveParty()
	PartyLeave:FireServer()
end

function Lobby.Queue(queueId: string)
	QueueStart:FireServer(queueId)
end

function Lobby.CancelQueue()
	QueueCancel:FireServer()
end

LobbyNotify.OnClientEvent:Connect(function(payload)
	print("[Lobby]", player.Name, payload)
end)

_G.Lobby = Lobby

print("[LobbyClient] ready — _G.Lobby.InviteByName(\"PlayerName\")")
