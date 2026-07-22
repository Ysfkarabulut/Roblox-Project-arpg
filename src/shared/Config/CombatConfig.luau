--[[
	COMBAT_STAT_SHEET + CHEMISTRY — playtest constants.
]]

local CombatConfig = {
	KDmg = 0.012,
	BaseHp = 120,
	KVitHp = 10,
	BaseStam = 100,
	KVitStam = 2,
	KVitDef = 0.25,
	KVitRes = 0.25,
	KDr = 0.1,
	DrCapPvp = 70,

	KDexAs = 0.0035,
	AsCap = 1.45,
	BaseCrit = 5,
	KDexCrit = 0.12,
	CritChanceCap = 60,
	BaseCritDmg = 150, -- %
	KStrCritDmg = 0.4,
	CritDmgCap = 250,

	ComboWindowSec = 0.6,
	ComboL2 = 1.05,
	ComboL3 = 1.10,
	MeasuredStrike1H = 1.35,
	MeasuredStrike2H = 1.40,
	CrossbowL3 = 1.40,
	FocusedShotL3 = 1.25,
	EmpoweredBoltL3 = 1.30,
	ArcBoltL3 = 1.20,
	RadiantSweepL3 = 1.25,
	KBackstab = 1.30,

	MatchupStrong = 1.15,
	MatchupWeak = 0.85,

	DodgeCost = 18,
	DodgeIFrameSec = 0.22,
	DodgeRecoverySec = 0.28,
	DodgeDistance = 11,
	DodgeDashSec = 0.32,
	SprintDrainPerSec = 12,
	WalkSpeed = 16,
	SprintWalkSpeed = 24, -- Ctrl sprint (1.5×)

	GuardHitStamFactor = 0.12,
	GuardHitStamMin = 8,
	AxeGuardStamMult = 1.25,
	GuardBreakStunSec = 0.75,

	-- Parry (no shield) — COMBAT_STAT_SHEET §10
	ParryPerfectWindowSec = 0.28,
	ParryStunSec = 1.0,
	ParryFailCost1H = 0.50, -- fraction of max stam (1H band / dual / focus)
	ParryFailCost2H = 0.75, -- 2H / Staff / Bow / Crossbow
	ParryStanceSlowPct = 20,
	ParryEmptyStamStunSec = 1.0,

	DummyMaxHp = 720,
	DummyDefence = 80, -- mid chest-ish for matchup/DR feel
	DummyName = "Training Dummy",
	DummySpawn = Vector3.new(8, 3, -12),
	MeleeRange = 10,
	DefaultWeaponBase = 40,

	-- Classic over-the-shoulder offset while F4 shift lock is on.
	-- Soft target aimlock deferred — do not drive camera look-at here.
	ShiftLockCameraOffset = Vector3.new(1.75, 0, 0),
}

CombatConfig.AsTierMult = {
	S = 0.70,
	A = 0.85,
	B = 1.00,
	C = 1.15,
	D = 1.30,
	E = 1.45,
}

return CombatConfig
