--[[
	PvP remotes + dev start (lobby only).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
local PvpMatchService = require(script.Parent.Pvp.PvpMatchService)
local PartyService = require(script.Parent.Lobby.PartyService)

local folder = Instance.new("Folder")
folder.Name = "PvpRemotes"
folder.Parent = ReplicatedStorage

local ArenaState = Instance.new("RemoteEvent")
ArenaState.Name = "ArenaState"
ArenaState.Parent = folder

if PlaceRuntime.IsLobby() then
	local StartPvpDev = Instance.new("RemoteEvent")
	StartPvpDev.Name = "StartPvpDev"
	StartPvpDev.Parent = folder

	StartPvpDev.OnServerEvent:Connect(function(player: Player)
		if not RunService:IsStudio() then
			return
		end
		local party = PartyService.GetPartyForPlayer(player.UserId)
		local userIds: { number }
		if party then
			userIds = {}
			for _, m in party.members do
				table.insert(userIds, m.userId)
			end
		else
			userIds = { player.UserId }
		end
		PvpMatchService.Start({
			bracket = "1v1",
			teams = { userIds },
		})
	end)
end

print("[PvpBootstrap] PvP remotes ready role=", PlaceRuntime.GetRole())
