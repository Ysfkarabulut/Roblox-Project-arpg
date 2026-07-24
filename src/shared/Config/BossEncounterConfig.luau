--[[
	The Eye boss encounter — MODES.md §4.6 playtest defaults.
]]

local BossEncounterConfig = {}

BossEncounterConfig.LobbySpawn = Vector3.new(0, 5, 0)

local DEFAULT_AGGRO = {
	shieldStartThreat = 120,
	shieldThreatMult = 2.75,
	damageThreatMult = 1.0,
	guardThreatPerSec = 42,
	guardRangeStud = 24,
}

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
	-- Threat table + single-target Iris Pulse (tank relevance)
	aggro = DEFAULT_AGGRO,
	irisPulse = {
		-- LA ritmi: telegraphSec windup + kalan süre = interval (hit → hit arası)
		firstDelaySec = 3.65,
		intervalByPhase = { 5, 4, 3 },
		telegraphSec = 1.35,
		damage = 30,
		farRangeStud = 28,
		farDamageMult = 1.3,
	},
}

BossEncounterConfig.Breaker = {
	id = "breaker",
	displayName = "The Breaker",
	baseHp = 14000,
	defence = 140,
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
	aggro = DEFAULT_AGGRO,
	movement = {
		walkSpeed = 14,
		stopRangeStud = 10,
	},
	aggroStrike = {
		firstDelaySec = 3.65,
		intervalByPhase = { 5, 4, 3 },
		telegraphSec = 1.35,
		damage = 32,
		farRangeStud = 28,
		farDamageMult = 1.3,
	},
	rustMark = {
		firstDelaySec = 8,
		intervalSec = 12,
		telegraphSec = 1.2,
		radiusStud = 6,
		damage = 55,
		tankWeight = 0.15,
	},
	shoulderCharge = {
		firstDelaySec = 14,
		intervalSec = 18,
		telegraphSec = 1.5,
		chargeSec = 0.55,
		pathRadiusStud = 5,
		damage = 70,
		stopStudBeforeTarget = 4,
	},
	cataclysmSlam = {
		firstDelaySec = 10,
		intervalSec = 16,
		telegraphSec = 2.75,
		radiusStud = 26,
		damage = 140,
	},
}

function BossEncounterConfig.Get(bossId: string): any?
	if bossId == "eye" then
		return BossEncounterConfig.Eye
	end
	if bossId == "breaker" then
		return BossEncounterConfig.Breaker
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
