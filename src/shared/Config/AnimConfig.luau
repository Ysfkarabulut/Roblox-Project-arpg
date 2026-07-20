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

	-- Base action tracks (procedural overlay differentiates families)
	Melee = "rbxassetid://522635514",
	Cast = "rbxassetid://507770239",
	Bow = "rbxassetid://522638767",
	Buff = "rbxassetid://507770677",
	Dodge = "rbxassetid://507770677",

	-- Procedural swing profiles: pitch/yaw/roll degrees over duration
	SwingProfile = {
		Sword1H = {
			L1 = { yaw = 70, pitch = 10, roll = 0, dur = 0.22 },
			L2 = { yaw = 100, pitch = -15, roll = 20, dur = 0.26 },
			L3 = { yaw = 140, pitch = 25, roll = -30, dur = 0.34 },
		},
		Sword2H = {
			L1 = { yaw = 90, pitch = 15, roll = 0, dur = 0.28 },
			L2 = { yaw = 120, pitch = -20, roll = 25, dur = 0.32 },
			L3 = { yaw = 160, pitch = 35, roll = -40, dur = 0.40 },
		},
		Axe1H = {
			L1 = { yaw = 60, pitch = 40, roll = 10, dur = 0.24 },
			L2 = { yaw = 80, pitch = 50, roll = -15, dur = 0.28 },
			L3 = { yaw = 110, pitch = 70, roll = 20, dur = 0.36 },
		},
		Axe2H = {
			L1 = { yaw = 70, pitch = 50, roll = 10, dur = 0.30 },
			L2 = { yaw = 95, pitch = 60, roll = -20, dur = 0.34 },
			L3 = { yaw = 130, pitch = 80, roll = 25, dur = 0.42 },
		},
		Mace1H = {
			L1 = { yaw = 40, pitch = 60, roll = 0, dur = 0.26 },
			L2 = { yaw = 50, pitch = 75, roll = 10, dur = 0.30 },
			L3 = { yaw = 70, pitch = 95, roll = -15, dur = 0.38 },
		},
		Mace2H = {
			L1 = { yaw = 45, pitch = 70, roll = 0, dur = 0.32 },
			L2 = { yaw = 55, pitch = 85, roll = 10, dur = 0.36 },
			L3 = { yaw = 80, pitch = 110, roll = -20, dur = 0.44 },
		},
		Dagger = {
			L1 = { yaw = 50, pitch = -20, roll = 40, dur = 0.16 },
			L2 = { yaw = -55, pitch = 10, roll = -40, dur = 0.16 },
			L3 = { yaw = 90, pitch = -30, roll = 50, dur = 0.22 },
		},
		Wand = {
			L1 = { yaw = 20, pitch = -30, roll = 0, dur = 0.20 },
			L2 = { yaw = 30, pitch = -40, roll = 10, dur = 0.22 },
			L3 = { yaw = 40, pitch = -55, roll = 0, dur = 0.28 },
		},
		Scepter = {
			L1 = { yaw = 80, pitch = 0, roll = 0, dur = 0.24 },
			L2 = { yaw = 100, pitch = 10, roll = 15, dur = 0.28 },
			L3 = { yaw = 130, pitch = 0, roll = -20, dur = 0.34 },
		},
		Staff = {
			L1 = { yaw = 15, pitch = -25, roll = 0, dur = 0.22 },
			L2 = { yaw = 25, pitch = -35, roll = 0, dur = 0.26 },
			L3 = { yaw = 35, pitch = -50, roll = 10, dur = 0.32 },
		},
		Bow = {
			L1 = { yaw = -15, pitch = 5, roll = 0, dur = 0.20 },
			L2 = { yaw = -20, pitch = 8, roll = 0, dur = 0.24 },
			L3 = { yaw = -30, pitch = 12, roll = 0, dur = 0.30 },
		},
		Crossbow = {
			L1 = { yaw = 0, pitch = -10, roll = 0, dur = 0.24 },
			L2 = { yaw = 0, pitch = -15, roll = 0, dur = 0.28 },
			L3 = { yaw = 5, pitch = -25, roll = 0, dur = 0.45 },
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
	7 sprint styles — distinct catalog run/locomotion IDs (R15).
	Custom packs later: swap IDs only. Speed/lean differ per stance in SprintController.
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
		speed = 0.95,
		lean = 6,
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
