--[[
	Legacy alias — practice defaults + lobby spawn.
]]

local PvpArenaConfig = require(script.Parent.PvpArenaConfig)

local def = PvpArenaConfig.GetBracket("1v1")

return {
	LobbySpawn = PvpArenaConfig.LobbySpawn,
	arena = {
		center = def.studioOffset,
		radius = math.max(def.floorSize.X, def.floorSize.Y) / 2,
	},
	opponentHp = PvpArenaConfig.practiceOpponentHp,
	opponentDefence = PvpArenaConfig.practiceOpponentDefence,
	introCountdownSec = PvpArenaConfig.introCountdownSec,
}
