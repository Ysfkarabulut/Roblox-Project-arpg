--[[
	The Eye boss encounter — MODES.md §4.6 playtest defaults.
]]

local BossEncounterConfig = {}

BossEncounterConfig.LobbySpawn = Vector3.new(0, 5, 0)

BossEncounterConfig.Eye = {
	id = "eye",
	displayName = "The Eye",
	baseHp = 12000,
	defence = 120,
	partyScale = {
		[1] = 1.0,
		[2] = 1.75,
		[3] = 2.5,
	},
	phase2Pct = 0.70,
	phase3Pct = 0.30,
	introCountdownSec = 3,
	arena = {
		radius = 80,
		center = Vector3.new(0, 5, -120),
		floorY = 5,
	},
	beam = {
		firstDelaySec = 10,
		activeSec = 5,
		cooldownSec = 10,
		tickDps = 45,
		beamHalfThickness = 2.5,
		rotationDegPerSec = 36,
	},
	monolith = {
		cycleSec = 15,
		dropIntervalSec = 3,
		telegraphSec = 1,
		auraRadius = 10,
		auraDps = 12,
		partRadius = 5,
		innerMargin = 18,
	},
	gaze = {
		castSec = 4,
	},
	tentacle = {
		intervalSec = 15,
		hp = 400,
		baseDps = 8,
		stackMult = 1.35,
		maxStacks = 12,
	},
}

function BossEncounterConfig.Get(bossId: string): any?
	if bossId == "eye" then
		return BossEncounterConfig.Eye
	end
	return nil
end

function BossEncounterConfig.ScaledHp(bossId: string, partySize: number): number
	local def = BossEncounterConfig.Get(bossId)
	if not def then
		return 1000
	end
	local scale = def.partyScale[partySize] or def.partyScale[1] or 1
	return math.floor(def.baseHp * scale)
end

return BossEncounterConfig
