--[[
	WoW-style PvP arena layout — MODES.md §3.2 greybox specs.
	Placeholder geometry only; swap meshes later via ArenaBuilder asset hooks.
]]

local BossEncounterConfig = require(script.Parent.BossEncounterConfig)

export type Bracket = "1v1" | "2v2" | "3v3"

export type BracketDef = {
	bracket: Bracket,
	placeKey: string,
	displayName: string,
	floorSize: Vector2,
	wallHeight: number,
	pillarCount: number,
	pillarRadius: number,
	pillarHeight: number,
	teamSpawnSpread: number,
	spawnBackOffset: number,
	studioOffset: Vector3,
}

local PvpArenaConfig = {
	LobbySpawn = BossEncounterConfig.LobbySpawn,
	introCountdownSec = 3,
	gateHoldSec = 3,
	matchJoinTimeoutSec = 45,
	postMatchLobbyDelaySec = 4,

	practiceOpponentHp = 600,
	practiceOpponentDefence = 60,

	-- Casual gas phase (MODES.md §3.5) — v1 linear shrink
	casualCombatSec = 120,
	casualShrinkSec = 20,
	casualGasDpsSec = 10,
	casualGasDps = 12,

	rankedCombatSec = 180,
	rankedShrinkSec = 20,
	rankedGasDpsSec = 30,
	rankedGasDps = 14,

	Brackets = {
		["1v1"] = {
			bracket = "1v1",
			placeKey = "Pvp1v1",
			displayName = "Duel Pit",
			floorSize = Vector2.new(40, 40),
			wallHeight = 14,
			pillarCount = 4,
			pillarRadius = 3.5,
			pillarHeight = 12,
			teamSpawnSpread = 0,
			spawnBackOffset = 16,
			studioOffset = Vector3.new(200, 5, 0),
		},
		["2v2"] = {
			bracket = "2v2",
			placeKey = "Pvp2v2",
			displayName = "Skirmish Yard",
			floorSize = Vector2.new(55, 45),
			wallHeight = 14,
			pillarCount = 4,
			pillarRadius = 4,
			pillarHeight = 12,
			teamSpawnSpread = 8,
			spawnBackOffset = 18,
			studioOffset = Vector3.new(400, 5, 0),
		},
		["3v3"] = {
			bracket = "3v3",
			placeKey = "Pvp3v3",
			displayName = "Clash Ring",
			floorSize = Vector2.new(65, 55),
			wallHeight = 16,
			pillarCount = 4,
			pillarRadius = 4.5,
			pillarHeight = 14,
			teamSpawnSpread = 10,
			spawnBackOffset = 20,
			studioOffset = Vector3.new(600, 5, 0),
		},
	} :: { [Bracket]: BracketDef },
}

function PvpArenaConfig.GetBracket(bracket: Bracket): BracketDef
	return PvpArenaConfig.Brackets[bracket]
end

function PvpArenaConfig.GetBracketForPlaceKey(placeKey: string): BracketDef
	if placeKey == "Pvp2v2" then
		return PvpArenaConfig.Brackets["2v2"]
	end
	if placeKey == "Pvp3v3" then
		return PvpArenaConfig.Brackets["3v3"]
	end
	return PvpArenaConfig.Brackets["1v1"]
end

function PvpArenaConfig.ArenaCenter(bracket: Bracket, useStudioOffset: boolean): Vector3
	local def = PvpArenaConfig.GetBracket(bracket)
	if useStudioOffset then
		return def.studioOffset
	end
	return Vector3.new(0, 5, 0)
end

function PvpArenaConfig.GasTiming(ranked: boolean)
	if ranked then
		return {
			combatSec = PvpArenaConfig.rankedCombatSec,
			shrinkSec = PvpArenaConfig.rankedShrinkSec,
			gasDpsSec = PvpArenaConfig.rankedGasDpsSec,
			gasDps = PvpArenaConfig.rankedGasDps,
		}
	end
	return {
		combatSec = PvpArenaConfig.casualCombatSec,
		shrinkSec = PvpArenaConfig.casualShrinkSec,
		gasDpsSec = PvpArenaConfig.casualGasDpsSec,
		gasDps = PvpArenaConfig.casualGasDps,
	}
end

return PvpArenaConfig
