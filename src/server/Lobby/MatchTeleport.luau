--[[
	MatchTeleport — maç place'ine TeleportService.
	PlaceId 0 ise Studio stub (log only).
]]

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PlaceConfig = require(game.ReplicatedStorage.Shared.Config.PlaceConfig)

export type MatchPayload = {
	matchId: string,
	queueId: string,
	placeKey: string,
	teams: { { number } },
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
