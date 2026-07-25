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
	ComboHitRecoveryBase = 0.15, -- scaled by 1/AS and per-step mult
	ComboRecoveryStepMult = { 0.88, 1.05, 1.55 }, -- L1 / L2 / L3
	ComboMoveSpeedMult = { 0.90, 0.75, 0.50 }, -- during LA windup per step
	ComboHitStopSec = { 0, 0, 0.052 }, -- L1 / L2 / L3 local freeze on connect
	ComboHitStopCritBonus = 0.022,
	ComboHitStopFamilyMult = {
		Dagger = 0.72,
		Sword1H = 0.92,
		Sword2H = 1.05,
		Axe1H = 1.12,
		Axe2H = 1.22,
		Mace1H = 1.28,
		Mace2H = 1.38,
		Wand = 0.85,
		Scepter = 0.95,
		Staff = 1.0,
		Bow = 0.88,
		Crossbow = 1.05,
	},

	-- Pressure / anti-infinite-combo (GPO-style)
	HitstunSec = { 0.085, 0.105, 0.14 }, -- LA L1 / L2 / L3
	AbilityHitstunSec = 0.12,
	HitstunMoveSlowPct = 42, -- victim move during hitstun

	ComboL3EndlagSec = 0.32, -- extra attacker recovery after L3 connect
	AbilityCastRecoverySec = 0.26,

	HyperArmorL3Sec = 0.2,
	HyperArmorAbilitySec = 0.38,

	CcImmunityAfterHardCcSec = 0.55,
	CcImmunityAfterJuggleBreakSec = 0.75,

	JuggleHitLimit = 5, -- swings (not individual multi-hits) per attacker→victim
	JuggleResetGapSec = 1.05,
	ComboL2 = 1.05,
	ComboL3 = 1.10,
	MeasuredStrike1H = 1.35,
	MeasuredStrike2H = 1.40,
	MaceShred1H = 25,
	MaceShred2H = 40,
	ScepterL3ConeBonusDeg = 15,
	CrossbowL3 = 1.40,
	CrossbowReloadSec = 1.2,
	FocusedShotL3 = 1.25,
	EmpoweredBoltL3 = 1.30,
	ArcBoltL3 = 1.20,
	RadiantSweepL3 = 1.25,
	KBackstab = 1.30,

	MatchupStrong = 1.15,
	MatchupWeak = 0.85,

	DodgeCost = 18,
	DodgeIFrameSec = 0.24,
	DodgeRecoverySec = 0.22,
	DodgeDistance = 17,
	DodgeDashSec = 0.50,
	-- Longer roll — less clip compression, matches dash travel
	DodgeAnimTargetSec = 0.58,
	DodgeAnimFadeIn = 0.06,
	DodgeAnimFadeOut = 0.14,
	DodgeAnimWeight = 1,
	DodgeAnimSpeedMin = 1.5,
	DodgeAnimSpeedMax = 3.0,
	DodgeFaceHoldSec = 0.52,
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
	OffHandDamageMult = 0.65, -- dual wield off-hand LA (GDD §7 / §11b)
	OffHandAbilityMult = 0.50, -- off-hand weapon active damage

	-- Buff Potency (COMBAT_STAT_SHEET §7)
	BaseBuffPotency = 8,
	KIntBuff = 0.5,
	KBuffHeal = 0.01,
	KBuffDuration = 0.008,
	FortifyAuraRadius = 8,

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
