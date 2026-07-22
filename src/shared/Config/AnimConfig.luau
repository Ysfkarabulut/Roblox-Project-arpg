--[[
	Family LA anim keys + element colors.
	Catalog ids are shared bases; CombatAnim layers procedural swing by family/step.
]]

local AnimConfig = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Jump = "rbxassetid://507765000",
	Fall = "rbxassetid://507767968",

	-- Base action tracks (CombatAnims.DodgeRoll KF overrides Dodge when present)
	Melee = "rbxassetid://522635514", -- tool slash
	Cast = "rbxassetid://507770453", -- point (short; wave was sticking)
	Bow = "rbxassetid://522638767", -- tool lunge
	Buff = "rbxassetid://507770453",
	-- Dodge: CombatAnims.StandToRoll / DodgeRoll KeyframeSequence (+ procedural lean)
	Dodge = "",

	-- Weapon weld swing: pitch/yaw/roll degrees over duration
	SwingProfile = {
		Sword1H = {
			L1 = { yaw = 85, pitch = 8, roll = -5, dur = 0.20 },
			L2 = { yaw = -95, pitch = -18, roll = 25, dur = 0.24 },
			L3 = { yaw = 155, pitch = 28, roll = -35, dur = 0.32 },
		},
		Sword2H = {
			L1 = { yaw = 100, pitch = 18, roll = 0, dur = 0.26 },
			L2 = { yaw = -115, pitch = -22, roll = 30, dur = 0.30 },
			L3 = { yaw = 175, pitch = 40, roll = -45, dur = 0.38 },
		},
		Axe1H = {
			L1 = { yaw = 55, pitch = 55, roll = 15, dur = 0.22 },
			L2 = { yaw = 75, pitch = 65, roll = -20, dur = 0.26 },
			L3 = { yaw = 120, pitch = 85, roll = 25, dur = 0.34 },
		},
		Axe2H = {
			L1 = { yaw = 65, pitch = 60, roll = 12, dur = 0.28 },
			L2 = { yaw = 90, pitch = 70, roll = -25, dur = 0.32 },
			L3 = { yaw = 140, pitch = 95, roll = 30, dur = 0.40 },
		},
		Mace1H = {
			L1 = { yaw = 25, pitch = 75, roll = 0, dur = 0.24 },
			L2 = { yaw = 40, pitch = 90, roll = 12, dur = 0.28 },
			L3 = { yaw = 55, pitch = 115, roll = -18, dur = 0.36 },
		},
		Mace2H = {
			L1 = { yaw = 30, pitch = 85, roll = 0, dur = 0.30 },
			L2 = { yaw = 45, pitch = 100, roll = 12, dur = 0.34 },
			L3 = { yaw = 65, pitch = 125, roll = -22, dur = 0.42 },
		},
		Dagger = {
			L1 = { yaw = 35, pitch = -35, roll = 55, dur = 0.14 },
			L2 = { yaw = -40, pitch = -25, roll = -55, dur = 0.14 },
			L3 = { yaw = 70, pitch = -50, roll = 70, dur = 0.20 },
		},
		Wand = {
			L1 = { yaw = 15, pitch = -40, roll = 10, dur = 0.18 },
			L2 = { yaw = 25, pitch = -50, roll = -10, dur = 0.20 },
			L3 = { yaw = 35, pitch = -70, roll = 15, dur = 0.26 },
		},
		Scepter = {
			L1 = { yaw = 70, pitch = 5, roll = 0, dur = 0.22 },
			L2 = { yaw = -85, pitch = 12, roll = 18, dur = 0.26 },
			L3 = { yaw = 130, pitch = -5, roll = -25, dur = 0.32 },
		},
		Staff = {
			L1 = { yaw = 20, pitch = -35, roll = 0, dur = 0.20 },
			L2 = { yaw = 30, pitch = -45, roll = 8, dur = 0.24 },
			L3 = { yaw = 45, pitch = -65, roll = -12, dur = 0.30 },
		},
		Bow = {
			L1 = { yaw = -12, pitch = 8, roll = 5, dur = 0.18 },
			L2 = { yaw = -18, pitch = 12, roll = 8, dur = 0.22 },
			L3 = { yaw = -28, pitch = 18, roll = 12, dur = 0.28 },
		},
		Crossbow = {
			L1 = { yaw = 0, pitch = -12, roll = 0, dur = 0.22 },
			L2 = { yaw = 5, pitch = -18, roll = 0, dur = 0.26 },
			L3 = { yaw = 8, pitch = -30, roll = 5, dur = 0.40 },
		},
	},

	-- R15 Motor6D offsets (degrees) layered on current C0 — rs/re/ls/waist
	BodyPose = {
		Sword1H = {
			L1 = { rs = { 35, 55, -70 }, re = { 0, 20, -55 }, waist = { 0, 18, 0 }, dur = 0.20 },
			L2 = { rs = { 20, -50, -85 }, re = { 10, -15, -40 }, waist = { 0, -22, 0 }, dur = 0.24 },
			L3 = { rs = { 55, 70, -95 }, re = { -15, 30, -70 }, waist = { 8, 28, 0 }, dur = 0.32 },
		},
		Sword2H = {
			L1 = { rs = { 40, 60, -80 }, re = { 0, 25, -60 }, ls = { 30, -40, 50 }, waist = { 5, 20, 0 }, dur = 0.26 },
			L2 = { rs = { 25, -55, -90 }, re = { 10, -20, -45 }, ls = { 25, 35, 45 }, waist = { 5, -24, 0 }, dur = 0.30 },
			L3 = { rs = { 65, 80, -110 }, re = { -20, 35, -75 }, ls = { 40, -50, 60 }, waist = { 12, 30, 0 }, dur = 0.38 },
		},
		Axe1H = {
			L1 = { rs = { 70, 30, -50 }, re = { 20, 10, -80 }, waist = { 10, 12, 0 }, dur = 0.22 },
			L2 = { rs = { 85, 40, -60 }, re = { 25, 5, -90 }, waist = { 12, -10, 0 }, dur = 0.26 },
			L3 = { rs = { 100, 50, -40 }, re = { 35, 15, -100 }, waist = { 18, 15, 0 }, dur = 0.34 },
		},
		Axe2H = {
			L1 = { rs = { 80, 35, -55 }, re = { 25, 10, -85 }, ls = { 50, -30, 40 }, waist = { 12, 14, 0 }, dur = 0.28 },
			L2 = { rs = { 95, 45, -65 }, re = { 30, 5, -95 }, ls = { 55, 25, 35 }, waist = { 14, -12, 0 }, dur = 0.32 },
			L3 = { rs = { 110, 55, -45 }, re = { 40, 20, -105 }, ls = { 70, -40, 50 }, waist = { 22, 16, 0 }, dur = 0.40 },
		},
		Mace1H = {
			L1 = { rs = { 90, 20, -30 }, re = { 40, 0, -90 }, waist = { 15, 8, 0 }, dur = 0.24 },
			L2 = { rs = { 100, 25, -35 }, re = { 50, 5, -95 }, waist = { 18, -8, 0 }, dur = 0.28 },
			L3 = { rs = { 120, 15, -20 }, re = { 60, 0, -110 }, waist = { 25, 10, 0 }, dur = 0.36 },
		},
		Mace2H = {
			L1 = { rs = { 95, 25, -35 }, re = { 45, 0, -95 }, ls = { 60, -20, 30 }, waist = { 18, 10, 0 }, dur = 0.30 },
			L2 = { rs = { 105, 30, -40 }, re = { 55, 5, -100 }, ls = { 65, 15, 25 }, waist = { 20, -10, 0 }, dur = 0.34 },
			L3 = { rs = { 125, 20, -25 }, re = { 65, 0, -115 }, ls = { 80, -25, 40 }, waist = { 28, 12, 0 }, dur = 0.42 },
		},
		Dagger = {
			L1 = { rs = { 15, 45, -40 }, re = { -10, 40, -30 }, waist = { 0, 20, 0 }, dur = 0.14 },
			L2 = { rs = { 10, -40, -35 }, re = { -5, -35, -25 }, waist = { 0, -20, 0 }, dur = 0.14 },
			L3 = { rs = { 25, 55, -60 }, re = { -20, 50, -45 }, waist = { 5, 25, 0 }, dur = 0.20 },
		},
		Wand = {
			L1 = { rs = { 20, 30, -50 }, re = { -30, 20, -20 }, waist = { 0, 10, 0 }, dur = 0.18 },
			L2 = { rs = { 25, 40, -55 }, re = { -40, 25, -25 }, waist = { 0, -10, 0 }, dur = 0.20 },
			L3 = { rs = { 35, 50, -70 }, re = { -55, 30, -30 }, waist = { 5, 12, 0 }, dur = 0.26 },
		},
		Scepter = {
			L1 = { rs = { 30, 50, -65 }, re = { 5, 15, -50 }, waist = { 0, 16, 0 }, dur = 0.22 },
			L2 = { rs = { 25, -45, -70 }, re = { 10, -10, -40 }, waist = { 0, -18, 0 }, dur = 0.26 },
			L3 = { rs = { 45, 60, -85 }, re = { -10, 20, -60 }, waist = { 8, 22, 0 }, dur = 0.32 },
		},
		Staff = {
			L1 = { rs = { 25, 35, -55 }, re = { -25, 15, -25 }, ls = { 20, -25, 30 }, waist = { 0, 8, 0 }, dur = 0.20 },
			L2 = { rs = { 30, 45, -60 }, re = { -35, 20, -30 }, ls = { 25, 20, 25 }, waist = { 0, -8, 0 }, dur = 0.24 },
			L3 = { rs = { 40, 55, -75 }, re = { -50, 25, -35 }, ls = { 35, -30, 40 }, waist = { 6, 10, 0 }, dur = 0.30 },
		},
		Bow = {
			L1 = { rs = { 10, -25, -20 }, re = { -40, 10, -15 }, ls = { 40, 50, 60 }, waist = { 0, -12, 0 }, dur = 0.18 },
			L2 = { rs = { 12, -30, -25 }, re = { -50, 12, -18 }, ls = { 45, 55, 70 }, waist = { 0, -14, 0 }, dur = 0.22 },
			L3 = { rs = { 15, -40, -30 }, re = { -65, 15, -22 }, ls = { 55, 65, 80 }, waist = { 0, -18, 0 }, dur = 0.28 },
		},
		Crossbow = {
			L1 = { rs = { 25, 20, -45 }, re = { -15, 10, -35 }, ls = { 20, -15, 25 }, waist = { 0, 5, 0 }, dur = 0.22 },
			L2 = { rs = { 30, 25, -50 }, re = { -20, 12, -40 }, ls = { 22, -18, 28 }, waist = { 0, 6, 0 }, dur = 0.26 },
			L3 = { rs = { 40, 30, -60 }, re = { -30, 15, -50 }, ls = { 30, -20, 35 }, waist = { 5, 8, 0 }, dur = 0.40 },
		},
	},

	-- Idle carry via AnimationConstraint.Transform (Stepped). Degrees: { pitch, yaw, roll }
	HoldPose = {
		Bow = {
			ls = { 55, 40, 35 },
			le = { -35, 5, -25 },
		},
	},
}

AnimConfig.ElementColor = {
	Fire = Color3.fromRGB(255, 110, 40),
	Water = Color3.fromRGB(60, 140, 255),
	Lightning = Color3.fromRGB(180, 200, 255),
	Wind = Color3.fromRGB(180, 255, 220),
	Poison = Color3.fromRGB(120, 220, 80),
	Rock = Color3.fromRGB(180, 140, 90),
	Steel = Color3.fromRGB(200, 210, 220),
	Neutral = Color3.fromRGB(200, 200, 210),
}

AnimConfig.ReactionColor = {
	Vaporize = Color3.fromRGB(255, 180, 80),
	ChainShock = Color3.fromRGB(150, 180, 255),
	Chilled = Color3.fromRGB(140, 220, 255),
	Thaw = Color3.fromRGB(255, 220, 160),
	Cauterize = Color3.fromRGB(255, 90, 40),
	Blight = Color3.fromRGB(100, 180, 60),
	Grounded = Color3.fromRGB(160, 120, 70),
	Contamination = Color3.fromRGB(80, 200, 100),
	WildFire = Color3.fromRGB(255, 60, 20),
	CausticBurn = Color3.fromRGB(180, 255, 60),
}

--[[
	7 sprint styles — catalog IDs by default; optional CombatAnims KeyframeSequence
	override via clipName (e.g. Mixamo Great Sword Run → Sprint_TwoHandMelee).
]]
AnimConfig.Sprint = {
	OneHandShield = {
		animId = "rbxassetid://913384386", -- shield-forward run
		speed = 1.05,
		lean = 8,
		label = "1H+Shield",
	},
	OneHandFocus = {
		animId = "rbxassetid://913376220",
		speed = 1.15,
		lean = 12,
		label = "1H+Focus",
	},
	DualWield = {
		animId = "rbxassetid://891621366",
		speed = 1.2,
		lean = 14,
		label = "1H+1H",
	},
	TwoHandMelee = {
		animId = "rbxassetid://913402848",
		-- Prefer local Mixamo clip when present in ReplicatedStorage.CombatAnims
		clipName = "Sprint_TwoHandMelee",
		clipNameAlts = { "GreatSwordRun", "Great Sword Run" },
		speed = 0.92,
		lean = 5,
		label = "2H Melee",
	},
	Crossbow = {
		animId = "rbxassetid://891636393",
		speed = 0.9,
		lean = 4,
		label = "Crossbow",
	},
	Bow = {
		animId = "rbxassetid://913390065",
		speed = 1.1,
		lean = 10,
		label = "Bow",
	},
	Staff = {
		animId = "rbxassetid://507767714", -- classic run (distinct from shield)
		speed = 1.0,
		lean = 7,
		label = "Staff",
	},
}

-- Fallback if a catalog id fails to load
AnimConfig.SprintFallback = "rbxassetid://507767714"

return AnimConfig
