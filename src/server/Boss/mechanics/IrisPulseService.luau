--[[
	Iris Pulse — Eye boss aggro strike (delegates to AggroStrikeService).
]]

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local AggroStrikeService = require(script.Parent.AggroStrikeService)

local IrisPulseService = {}

export type IrisHandle = AggroStrikeService.StrikeHandle

function IrisPulseService.Start(partyUserIds: { number }, getPhase: () -> number): IrisHandle
	return AggroStrikeService.Start(
		partyUserIds,
		getPhase,
		BossEncounterConfig.Eye.irisPulse,
		"IrisPulse"
	)
end

return IrisPulseService
