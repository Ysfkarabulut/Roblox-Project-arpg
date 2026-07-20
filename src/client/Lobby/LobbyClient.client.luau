--[[
	Lobby client stub — RemoteEvent köprüsü.
	UI sonra; Studio'da test için _G.Lobby API.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes")
local PartyInvite = remotes:WaitForChild("PartyInvite") :: RemoteEvent
local PartyReady = remotes:WaitForChild("PartyReady") :: RemoteEvent
local PartyLeave = remotes:WaitForChild("PartyLeave") :: RemoteEvent
local QueueStart = remotes:WaitForChild("QueueStart") :: RemoteEvent
local QueueCancel = remotes:WaitForChild("QueueCancel") :: RemoteEvent
local LobbyNotify = remotes:WaitForChild("LobbyNotify") :: RemoteEvent

local Lobby = {}

function Lobby.Invite(targetUserId: number)
	PartyInvite:FireServer(targetUserId)
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

-- Studio Command Bar / hızlı test
_G.Lobby = Lobby

print("[LobbyClient] stub ready — _G.Lobby.Queue(\"pvp_1v1_casual\")")
