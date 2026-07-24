--[[
	MatchTeleport — maç place'ine TeleportService.
	PlaceId 0 ise Studio stub (aynı place, offset arena).
]]

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlaceConfig = require(game.ReplicatedStorage.Shared.Config.PlaceConfig)
local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
local BossEncounterService = require(script.Parent.Parent.Boss.BossEncounterService)

export type MatchPayload = {
	matchId: string,
	queueId: string,
	placeKey: string,
	teams: { { number } },
	bossId: string?,
}

local MatchTeleport = {}

local function collectPlayers(teams: { { number } }): { Player }
	local out: { Player } = {}
	for _, team in teams do
		for _, userId in team do
			local p = Players:GetPlayerByUserId(userId)
			if p then
				table.insert(out, p)
			end
		end
	end
	return out
end

function MatchTeleport.StartMatch(payload: MatchPayload)
	local placeKey = payload.placeKey :: any
	local placeId = PlaceConfig.GetPlaceId(placeKey)
	local players = collectPlayers(payload.teams)

	if #players == 0 then
		warn("[MatchTeleport] No players for match", payload.matchId)
		return
	end

	local teleportData = {
		matchId = payload.matchId,
		queueId = payload.queueId,
		teams = payload.teams,
		bossId = payload.bossId,
	}

	if not PlaceConfig.IsConfigured(placeKey) then
		print(string.format(
			"[MatchTeleport] Studio stub — match=%s queue=%s place=%s players=%d data=%s",
			payload.matchId,
			payload.queueId,
			payload.placeKey,
			#players,
			HttpService:JSONEncode(teleportData)
		))
		if placeKey == "PveBossEye" then
			local userIds = {}
			for _, p in players do
				table.insert(userIds, p.UserId)
			end
			local bossId = if typeof(payload.bossId) == "string" then payload.bossId else "eye"
			BossEncounterService.Start({
				bossId = bossId,
				partyUserIds = userIds,
				partySize = math.clamp(#userIds, 1, 3),
			})
		elseif placeKey == "Pvp1v1" or placeKey == "Pvp2v2" or placeKey == "Pvp3v3" then
			local PvpMatchService = require(script.Parent.Parent.Pvp.PvpMatchService)
			PvpMatchService.Start({
				matchId = payload.matchId,
				queueId = payload.queueId,
				bracket = PlaceRuntime.BracketFromPlaceKey(placeKey),
				teams = payload.teams,
			})
		end
		return
	end

	local options = Instance.new("TeleportOptions")
	options:SetTeleportData(teleportData)

	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, players, options)
	end)

	if not ok then
		warn("[MatchTeleport] Teleport failed:", err)
	end
end

return MatchTeleport
