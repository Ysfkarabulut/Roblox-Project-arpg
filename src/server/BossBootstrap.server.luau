--[[
	Boss remotes + dev start hook.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)

local BossEncounterService = require(script.Parent.Boss.BossEncounterService)
local BossSync = require(script.Parent.Boss.BossSync)
local PartyService = require(script.Parent.Lobby.PartyService)

local existing = ReplicatedStorage:FindFirstChild("BossRemotes")
if existing then
	existing:Destroy()
end

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BossRemotes"
remotesFolder.Parent = ReplicatedStorage

local BossState = Instance.new("RemoteEvent")
BossState.Name = "BossState"
BossState.Parent = remotesFolder

local BossTelegraph = Instance.new("RemoteEvent")
BossTelegraph.Name = "BossTelegraph"
BossTelegraph.Parent = remotesFolder

local StartBossDev = Instance.new("RemoteEvent")
StartBossDev.Name = "StartBossDev"
StartBossDev.Parent = remotesFolder

BossSync.SetRemotes(BossState, BossTelegraph)

local function startForPlayer(player: Player, bossId: string, partySize: number?)
	local party = PartyService.GetPartyForPlayer(player.UserId)
	local userIds: { number }
	local size: number
	if party then
		userIds = {}
		for _, m in party.members do
			table.insert(userIds, m.userId)
		end
		size = #party.members
	else
		userIds = { player.UserId }
		size = 1
	end
	if typeof(partySize) == "number" then
		size = math.clamp(math.floor(partySize), 1, 3)
	end
	return BossEncounterService.Start({
		bossId = bossId,
		partyUserIds = userIds,
		partySize = size,
	})
end

if PlaceRuntime.IsLobby() then
	StartBossDev.OnServerEvent:Connect(function(player: Player, payload: any)
		if not RunService:IsStudio() then
			return
		end
		local bossId = if typeof(payload) == "table" and typeof(payload.bossId) == "string" then payload.bossId else "eye"
		local partySize = if typeof(payload) == "table" then payload.partySize else nil
		startForPlayer(player, bossId, partySize)
	end)
end

-- Expose for MatchTeleport / other server modules
_G.StartBossEncounter = function(bossId: string, partyUserIds: { number }, partySize: number)
	return BossEncounterService.Start({
		bossId = bossId,
		partyUserIds = partyUserIds,
		partySize = partySize,
	})
end

print("[BossBootstrap] Boss remotes ready")
