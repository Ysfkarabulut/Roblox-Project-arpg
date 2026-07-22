--[[
	Blade / Limbs / Head — ability-bearing weapon part (48 entries).
	6×1H + 6×2H families · each: ST/AOE × Common/Rare.
	Passives: *_weaponpassive. Actives: *_weaponactive.
]]

local PassiveDefs = require(script.Parent.PassiveDefs)
local WeaponActiveDefs = require(script.Parent.WeaponActiveDefs)

local BladeDefs = {}

local BLADES = {
	-- ═══════════════════════════════════════════════════════════════════════
	-- 1H — Dagger (1H_Sword handle, subFamily Dagger)
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_dagger_st",
		name = "Piercing Shiv",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Backstab x1.30 (rear 180 deg)",
		bladeDamageMult = 1.0,
		meshKey = "Dagger_Blade",
		abilities = { "dash_weaponactive" },
		desc = "1H Dagger · single-target · dash strike",
	},
	{
		id = "b_dagger_aoe",
		name = "Fan Blade",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Backstab x1.30 (rear 180 deg)",
		bladeDamageMult = 0.98,
		meshKey = "Dagger_Blade",
		abilities = { "cone_weaponactive" },
		desc = "1H Dagger · AoE cone sweep",
	},
	{
		id = "b_dagger_st_r",
		name = "Assassin's Needle",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Backstab x1.30 (rear 180 deg)",
		bladeDamageMult = 1.05,
		meshKey = "Dagger_Blade_Rare",
		abilities = { "strike_r_weaponactive", "keen_weaponpassive" },
		desc = "1H Dagger · rare single-target thrust + crit",
	},
	{
		id = "b_dagger_aoe_r",
		name = "Whirling Edge",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Backstab x1.30 (rear 180 deg)",
		bladeDamageMult = 1.03,
		meshKey = "Dagger_Blade_Rare",
		abilities = { "cone_r_weaponactive", "status_weaponpassive" },
		desc = "1H Dagger · rare AoE cone + LA status proc",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 1H — Sword
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_sword_st",
		name = "Longblade",
		handleType = "1H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Measured Strike L3 x1.35",
		bladeDamageMult = 1.0,
		meshKey = "Sword1H_Blade",
		abilities = { "strike_weaponactive" },
		desc = "1H Sword · single-target thrust",
	},
	{
		id = "b_sword_aoe",
		name = "Wide Cleaver",
		handleType = "1H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Measured Strike L3 x1.35",
		bladeDamageMult = 0.98,
		meshKey = "Sword1H_Blade",
		abilities = { "cone_weaponactive" },
		desc = "1H Sword · AoE cone sweep",
	},
	{
		id = "b_sword_st_r",
		name = "Court Rapier",
		handleType = "1H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Measured Strike L3 x1.40",
		bladeDamageMult = 1.05,
		meshKey = "Sword1H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "keen_weaponpassive" },
		desc = "1H Sword · rare precise thrust + crit",
	},
	{
		id = "b_sword_aoe_r",
		name = "Rendblade",
		handleType = "1H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Measured Strike L3 x1.40",
		bladeDamageMult = 1.03,
		meshKey = "Sword1H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "direct_weaponpassive" },
		desc = "1H Sword · rare AoE cone + direct damage",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 1H — Axe
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_axe_st",
		name = "Hatchet Head",
		handleType = "1H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Anti-guard stamina x1.25",
		bladeDamageMult = 1.0,
		meshKey = "Axe1H_Blade",
		abilities = { "strike_weaponactive" },
		desc = "1H Axe · single-target chop",
	},
	{
		id = "b_axe_aoe",
		name = "Timber Axe",
		handleType = "1H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Anti-guard stamina x1.25",
		bladeDamageMult = 0.98,
		meshKey = "Axe1H_Blade",
		abilities = { "cone_weaponactive" },
		desc = "1H Axe · AoE cleave",
	},
	{
		id = "b_axe_st_r",
		name = "Warbreaker Head",
		handleType = "1H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Anti-guard stamina x1.30",
		bladeDamageMult = 1.05,
		meshKey = "Axe1H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "direct_weaponpassive" },
		desc = "1H Axe · rare heavy strike + direct",
	},
	{
		id = "b_axe_aoe_r",
		name = "Splinter Axe",
		handleType = "1H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Anti-guard stamina x1.30",
		bladeDamageMult = 1.03,
		meshKey = "Axe1H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "status_weaponpassive" },
		desc = "1H Axe · rare AoE + LA status proc",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 1H — Mace
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_mace_st",
		name = "Flanged Head",
		handleType = "1H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Defence Shred on hit (light)",
		bladeDamageMult = 1.0,
		meshKey = "Mace1H_Blade",
		abilities = { "strike_weaponactive" },
		desc = "1H Mace · single-target crush",
	},
	{
		id = "b_mace_aoe",
		name = "Sweep Mace",
		handleType = "1H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon1H",
		rarity = "Common",
		familyPerk = "Defence Shred on hit (light)",
		bladeDamageMult = 0.98,
		meshKey = "Mace1H_Blade",
		abilities = { "cone_weaponactive" },
		desc = "1H Mace · AoE swing",
	},
	{
		id = "b_mace_st_r",
		name = "Skullcrusher Head",
		handleType = "1H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Defence Shred on hit (medium)",
		bladeDamageMult = 1.05,
		meshKey = "Mace1H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "direct_weaponpassive" },
		desc = "1H Mace · rare crush + direct",
	},
	{
		id = "b_mace_aoe_r",
		name = "Shock Maul",
		handleType = "1H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon1H",
		rarity = "Rare",
		familyPerk = "Defence Shred on hit (medium)",
		bladeDamageMult = 1.03,
		meshKey = "Mace1H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "status_weaponpassive" },
		desc = "1H Mace · rare AoE + LA status proc",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 1H — Wand
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_wand_st",
		name = "Crystal Wand",
		handleType = "1H_WandScepter",
		subFamily = "Wand",
		family = "Wand",
		kind = "Wand",
		rarity = "Common",
		familyPerk = "+Status Potency",
		bladeDamageMult = 1.0,
		meshKey = "Wand_Blade",
		abilities = { "bolt_weaponactive" },
		desc = "1H Wand · single-target bolt",
	},
	{
		id = "b_wand_aoe",
		name = "Arc Wand",
		handleType = "1H_WandScepter",
		subFamily = "Wand",
		family = "Wand",
		kind = "Wand",
		rarity = "Common",
		familyPerk = "+Status Potency",
		bladeDamageMult = 0.98,
		meshKey = "Wand_Blade",
		abilities = { "cone_weaponactive" },
		desc = "1H Wand · AoE arc burst",
	},
	{
		id = "b_wand_st_r",
		name = "Archon Spindle",
		handleType = "1H_WandScepter",
		subFamily = "Wand",
		family = "Wand",
		kind = "Wand",
		rarity = "Rare",
		familyPerk = "+Status Potency",
		bladeDamageMult = 1.05,
		meshKey = "Wand_Blade_Rare",
		abilities = { "bolt_r_weaponactive", "potency_weaponpassive" },
		desc = "1H Wand · rare bolt + status potency",
	},
	{
		id = "b_wand_aoe_r",
		name = "Nova Wand",
		handleType = "1H_WandScepter",
		subFamily = "Wand",
		family = "Wand",
		kind = "Wand",
		rarity = "Rare",
		familyPerk = "+Status Potency",
		bladeDamageMult = 1.03,
		meshKey = "Wand_Blade_Rare",
		abilities = { "cone_r_weaponactive", "potency_weaponpassive" },
		desc = "1H Wand · rare AoE arc + potency",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 1H — Scepter
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_scepter_st",
		name = "Focus Scepter",
		handleType = "1H_WandScepter",
		subFamily = "Scepter",
		family = "Scepter",
		kind = "Scepter",
		rarity = "Common",
		familyPerk = "+Buff Potency · cone LA",
		bladeDamageMult = 1.0,
		meshKey = "Scepter_Blade",
		abilities = { "bolt_weaponactive" },
		desc = "1H Scepter · single-target ray",
	},
	{
		id = "b_scepter_aoe",
		name = "Radiant Crook",
		handleType = "1H_WandScepter",
		subFamily = "Scepter",
		family = "Scepter",
		kind = "Scepter",
		rarity = "Common",
		familyPerk = "+Buff Potency · cone LA",
		bladeDamageMult = 0.98,
		meshKey = "Scepter_Blade",
		abilities = { "cone_weaponactive" },
		desc = "1H Scepter · AoE radiant sweep",
	},
	{
		id = "b_scepter_st_r",
		name = "High Scepter",
		handleType = "1H_WandScepter",
		subFamily = "Scepter",
		family = "Scepter",
		kind = "Scepter",
		rarity = "Rare",
		familyPerk = "+Buff Potency · cone LA",
		bladeDamageMult = 1.05,
		meshKey = "Scepter_Blade_Rare",
		abilities = { "bolt_r_weaponactive", "potency_weaponpassive" },
		desc = "1H Scepter · rare ray + potency",
	},
	{
		id = "b_scepter_aoe_r",
		name = "Haze Scepter",
		handleType = "1H_WandScepter",
		subFamily = "Scepter",
		family = "Scepter",
		kind = "Scepter",
		rarity = "Rare",
		familyPerk = "+Buff Potency · cone LA",
		bladeDamageMult = 1.03,
		meshKey = "Scepter_Blade_Rare",
		abilities = { "cone_r_weaponactive", "status_weaponpassive" },
		desc = "1H Scepter · rare AoE + LA status proc",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 2H — Greatblade (2H_Sword)
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_greatblade_st",
		name = "Iron Greatblade",
		handleType = "2H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon2H",
		rarity = "Common",
		familyPerk = "Measured Strike L3 x1.40",
		bladeDamageMult = 1.0,
		meshKey = "Sword2H_Blade",
		abilities = { "strike_weaponactive", "keen_weaponpassive" },
		desc = "2H Sword · single-target thrust + crit",
	},
	{
		id = "b_greatblade_aoe",
		name = "Tempest Blade",
		handleType = "2H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon2H",
		rarity = "Common",
		familyPerk = "Measured Strike L3 x1.40",
		bladeDamageMult = 0.98,
		meshKey = "Sword2H_Blade",
		abilities = { "cone_weaponactive", "status_weaponpassive" },
		desc = "2H Sword · AoE sweep + LA status proc",
	},
	{
		id = "b_greatblade_st_r",
		name = "Tyrant Blade",
		handleType = "2H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon2H",
		rarity = "Rare",
		familyPerk = "Measured Strike L3 x1.45",
		bladeDamageMult = 1.05,
		meshKey = "Sword2H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "dash_weaponactive", "keen_weaponpassive" },
		desc = "2H Sword · rare ST combo: thrust + dash + crit",
	},
	{
		id = "b_greatblade_aoe_r",
		name = "Earthshaker Blade",
		handleType = "2H_Sword",
		subFamily = "Sword",
		family = "Sword",
		kind = "Weapon2H",
		rarity = "Rare",
		familyPerk = "Measured Strike L3 x1.45",
		bladeDamageMult = 1.03,
		meshKey = "Sword2H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "slam_r_weaponactive", "direct_weaponpassive" },
		desc = "2H Sword · rare AoE: cone + ground slam + direct",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 2H — Greataxe
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_greataxe_st",
		name = "Greataxe Head",
		handleType = "2H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon2H",
		rarity = "Common",
		familyPerk = "Anti-guard stamina x1.50",
		bladeDamageMult = 1.0,
		meshKey = "Axe2H_Blade",
		abilities = { "strike_weaponactive", "direct_weaponpassive" },
		desc = "2H Axe · single-target cleave + direct",
	},
	{
		id = "b_greataxe_aoe",
		name = "Cleaving Axe",
		handleType = "2H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon2H",
		rarity = "Common",
		familyPerk = "Anti-guard stamina x1.50",
		bladeDamageMult = 0.98,
		meshKey = "Axe2H_Blade",
		abilities = { "cone_weaponactive", "status_weaponpassive" },
		desc = "2H Axe · AoE sweep + LA status proc",
	},
	{
		id = "b_greataxe_st_r",
		name = "Soulreaver Head",
		handleType = "2H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon2H",
		rarity = "Rare",
		familyPerk = "Anti-guard stamina x1.55",
		bladeDamageMult = 1.05,
		meshKey = "Axe2H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "dash_weaponactive", "direct_weaponpassive" },
		desc = "2H Axe · rare ST: heavy chop + dash + direct",
	},
	{
		id = "b_greataxe_aoe_r",
		name = "Faultline Axe",
		handleType = "2H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		kind = "Weapon2H",
		rarity = "Rare",
		familyPerk = "Anti-guard stamina x1.55",
		bladeDamageMult = 1.03,
		meshKey = "Axe2H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "slam_r_weaponactive", "status_weaponpassive" },
		desc = "2H Axe · rare AoE: cone + slam + status proc",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 2H — Greathammer (Mace)
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_greathammer_st",
		name = "War Hammer Head",
		handleType = "2H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon2H",
		rarity = "Common",
		familyPerk = "Defence Shred on hit (high, 2H)",
		bladeDamageMult = 1.0,
		meshKey = "Mace2H_Blade",
		abilities = { "strike_weaponactive", "direct_weaponpassive" },
		desc = "2H Mace · single-target smash + direct",
	},
	{
		id = "b_greathammer_aoe",
		name = "Quake Hammer",
		handleType = "2H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon2H",
		rarity = "Common",
		familyPerk = "Defence Shred on hit (high, 2H)",
		bladeDamageMult = 0.98,
		meshKey = "Mace2H_Blade",
		abilities = { "cone_weaponactive", "status_weaponpassive" },
		desc = "2H Mace · AoE quake swing + status proc",
	},
	{
		id = "b_greathammer_st_r",
		name = "Thronebreaker Head",
		handleType = "2H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon2H",
		rarity = "Rare",
		familyPerk = "Defence Shred on hit (high, 2H)",
		bladeDamageMult = 1.05,
		meshKey = "Mace2H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "dash_weaponactive", "direct_weaponpassive" },
		desc = "2H Mace · rare ST: crush + dash + direct",
	},
	{
		id = "b_greathammer_aoe_r",
		name = "Cataclysm Maul",
		handleType = "2H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		kind = "Weapon2H",
		rarity = "Rare",
		familyPerk = "Defence Shred on hit (high, 2H)",
		bladeDamageMult = 1.03,
		meshKey = "Mace2H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "slam_r_weaponactive", "direct_weaponpassive" },
		desc = "2H Mace · rare AoE: cone + slam + direct",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 2H — Staff Head
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_staff_st",
		name = "Crystal Head",
		handleType = "2H_Staff",
		subFamily = "Staff",
		family = "Staff",
		kind = "Staff",
		rarity = "Common",
		familyPerk = "+Status Potency++ · Empowered Bolt L3 x1.30",
		bladeDamageMult = 1.0,
		meshKey = "Staff_Head",
		abilities = { "bolt_weaponactive", "potency_weaponpassive" },
		desc = "Staff head · single-target bolt + potency",
	},
	{
		id = "b_staff_aoe",
		name = "Storm Head",
		handleType = "2H_Staff",
		subFamily = "Staff",
		family = "Staff",
		kind = "Staff",
		rarity = "Common",
		familyPerk = "+Status Potency++ · Empowered Bolt L3 x1.30",
		bladeDamageMult = 0.98,
		meshKey = "Staff_Head",
		abilities = { "cone_weaponactive", "status_weaponpassive" },
		desc = "Staff head · AoE storm burst + status proc",
	},
	{
		id = "b_staff_st_r",
		name = "Voidheart Head",
		handleType = "2H_Staff",
		subFamily = "Staff",
		family = "Staff",
		kind = "Staff",
		rarity = "Rare",
		familyPerk = "+Status Potency++ · Empowered Bolt L3 x1.35",
		bladeDamageMult = 1.05,
		meshKey = "Staff_Head_Rare",
		abilities = { "bolt_r_weaponactive", "potency_weaponpassive", "direct_weaponpassive" },
		desc = "Staff head · rare bolt + potency + direct (1A+2P)",
	},
	{
		id = "b_staff_aoe_r",
		name = "Cataclysm Head",
		handleType = "2H_Staff",
		subFamily = "Staff",
		family = "Staff",
		kind = "Staff",
		rarity = "Rare",
		familyPerk = "+Status Potency++ · Empowered Bolt L3 x1.35",
		bladeDamageMult = 1.03,
		meshKey = "Staff_Head_Rare",
		abilities = { "cone_r_weaponactive", "slam_r_weaponactive", "potency_weaponpassive" },
		desc = "Staff head · rare AoE: cone + slam + potency",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 2H — Bow Limbs
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_bow_st",
		name = "Hunter Limbs",
		handleType = "2H_Bow",
		subFamily = "Bow",
		family = "Bow",
		kind = "Bow",
		rarity = "Common",
		familyPerk = "+Crit Chance · Focused Shot L3 x1.25",
		bladeDamageMult = 1.0,
		meshKey = "Bow_Limbs",
		abilities = { "bolt_weaponactive", "keen_weaponpassive" },
		desc = "Bow limbs · single-target shot + crit",
	},
	{
		id = "b_bow_aoe",
		name = "Scatter Limbs",
		handleType = "2H_Bow",
		subFamily = "Bow",
		family = "Bow",
		kind = "Bow",
		rarity = "Common",
		familyPerk = "+Crit Chance · Focused Shot L3 x1.25",
		bladeDamageMult = 0.98,
		meshKey = "Bow_Limbs",
		abilities = { "cone_weaponactive", "status_weaponpassive" },
		desc = "Bow limbs · AoE fan volley + status proc",
	},
	{
		id = "b_bow_st_r",
		name = "Windcaller Limbs",
		handleType = "2H_Bow",
		subFamily = "Bow",
		family = "Bow",
		kind = "Bow",
		rarity = "Rare",
		familyPerk = "+Crit Chance · Focused Shot L3 x1.30",
		bladeDamageMult = 1.05,
		meshKey = "Bow_Limbs_Rare",
		abilities = { "bolt_r_weaponactive", "keen_weaponpassive", "direct_weaponpassive" },
		desc = "Bow limbs · rare shot + crit + direct (1A+2P)",
	},
	{
		id = "b_bow_aoe_r",
		name = "Gale Limbs",
		handleType = "2H_Bow",
		subFamily = "Bow",
		family = "Bow",
		kind = "Bow",
		rarity = "Rare",
		familyPerk = "+Crit Chance · Focused Shot L3 x1.30",
		bladeDamageMult = 1.03,
		meshKey = "Bow_Limbs_Rare",
		abilities = { "cone_r_weaponactive", "slam_r_weaponactive", "status_weaponpassive" },
		desc = "Bow limbs · rare AoE: fan + ground burst + status",
	},

	-- ═══════════════════════════════════════════════════════════════════════
	-- 2H — Crossbow Head
	-- ═══════════════════════════════════════════════════════════════════════
	{
		id = "b_crossbow_st",
		name = "Arbalest Head",
		handleType = "2H_Crossbow",
		subFamily = "Crossbow",
		family = "Crossbow",
		kind = "Crossbow",
		rarity = "Common",
		familyPerk = "+Crit Damage · Heavy Bolt L3 x1.40",
		bladeDamageMult = 1.0,
		meshKey = "Crossbow_Head",
		abilities = { "bolt_weaponactive", "keen_weaponpassive" },
		desc = "Crossbow head · single-target bolt + crit",
	},
	{
		id = "b_crossbow_aoe",
		name = "Shard Head",
		handleType = "2H_Crossbow",
		subFamily = "Crossbow",
		family = "Crossbow",
		kind = "Crossbow",
		rarity = "Common",
		familyPerk = "+Crit Damage · Heavy Bolt L3 x1.40",
		bladeDamageMult = 0.98,
		meshKey = "Crossbow_Head",
		abilities = { "cone_weaponactive", "status_weaponpassive" },
		desc = "Crossbow head · AoE shard burst + status proc",
	},
	{
		id = "b_crossbow_st_r",
		name = "Siege Head",
		handleType = "2H_Crossbow",
		subFamily = "Crossbow",
		family = "Crossbow",
		kind = "Crossbow",
		rarity = "Rare",
		familyPerk = "+Crit Damage · Heavy Bolt L3 x1.45",
		bladeDamageMult = 1.05,
		meshKey = "Crossbow_Head_Rare",
		abilities = { "bolt_r_weaponactive", "keen_weaponpassive", "direct_weaponpassive" },
		desc = "Crossbow head · rare pierce + crit + direct (1A+2P)",
	},
	{
		id = "b_crossbow_aoe_r",
		name = "Bombard Head",
		handleType = "2H_Crossbow",
		subFamily = "Crossbow",
		family = "Crossbow",
		kind = "Crossbow",
		rarity = "Rare",
		familyPerk = "+Crit Damage · Heavy Bolt L3 x1.45",
		bladeDamageMult = 1.03,
		meshKey = "Crossbow_Head_Rare",
		abilities = { "cone_r_weaponactive", "slam_r_weaponactive", "status_weaponpassive" },
		desc = "Crossbow head · rare AoE: shards + blast + status",
	},
}

local LEGACY_BLADE: { [string]: string } = {
	dagger = "b_dagger_st",
	sword_1h = "b_sword_st",
	axe_1h = "b_axe_st",
	mace_1h = "b_mace_st",
	wand = "b_wand_st",
	scepter = "b_scepter_st",
	sword_2h = "b_greatblade_st",
	axe_2h = "b_greataxe_st",
	mace_2h = "b_greathammer_st",
	staff = "b_staff_st",
	bow = "b_bow_st",
	crossbow = "b_crossbow_st",
}

local TWO_HAND_HANDLES: { [string]: boolean } = {
	["2H_Sword"] = true,
	["2H_AxeMace"] = true,
	["2H_Staff"] = true,
	["2H_Bow"] = true,
	["2H_Crossbow"] = true,
}

local function normalizeAbilities(abilities: { any }?): { any }
	local out: { any } = {}
	if not abilities then
		return out
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			if PassiveDefs.Get(ab) then
				table.insert(out, PassiveDefs.AbilitySlot(ab))
			else
				table.insert(out, WeaponActiveDefs.AbilitySlot(ab))
			end
		elseif ab.slotType == "Passive" then
			table.insert(out, PassiveDefs.HydrateAbilitySlot(ab))
		elseif ab.slotType == "Active" then
			table.insert(out, WeaponActiveDefs.HydrateAbilitySlot(ab))
		else
			table.insert(out, ab)
		end
	end
	return out
end

local function countAbilities(abilities: { any }?): (number, number)
	local active, passive = 0, 0
	if not abilities then
		return active, passive
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			if PassiveDefs.Get(ab) then
				passive += 1
			else
				active += 1
			end
		elseif ab.slotType == "Active" then
			active += 1
		elseif ab.slotType == "Passive" then
			passive += 1
		end
	end
	return active, passive
end

function BladeDefs.IsTwoHandHandle(handleType: string?): boolean
	return handleType ~= nil and TWO_HAND_HANDLES[handleType] == true
end

function BladeDefs.ValidateBlade(blade: any): (boolean, string?)
	local rarity = blade.rarity or "Common"
	local active, passive = countAbilities(blade.abilities)
	local total = active + passive
	local is2H = BladeDefs.IsTwoHandHandle(blade.handleType)

	if is2H then
		if active > 2 or passive > 2 then
			return false, "AbilityCapExceeded2H"
		end
		if rarity == "Common" and total ~= 2 then
			return false, "Common2HMustHaveExactly2Abilities"
		end
		if rarity == "Rare" then
			if passive < 1 or total < 3 then
				return false, "Rare2HNeedsExtraPassive"
			end
		end
	else
		if active > 1 or passive > 1 then
			return false, "AbilityCapExceeded1H"
		end
		if rarity == "Common" and total ~= 1 then
			return false, "Common1HMustHaveExactly1Ability"
		end
		if rarity == "Rare" and (active ~= 1 or passive ~= 1) then
			return false, "Rare1HMustBe1Active1Passive"
		end
	end
	return true, nil
end

function BladeDefs.Build(): { [string]: any }
	local out = {}
	for _, b in BLADES do
		local ok, err = BladeDefs.ValidateBlade(b)
		if not ok then
			warn(`[BladeDefs] {b.id}: {err}`)
		end
		out[b.id] = {
			id = b.id,
			name = b.name,
			kind = "WeaponBlade",
			handleType = b.handleType,
			subFamily = b.subFamily,
			family = b.family,
			slotHints = {},
			element = nil,
			scaling = nil,
			familyPerk = b.familyPerk,
			bladeDamageMult = b.bladeDamageMult,
			meshKey = b.meshKey,
			abilities = normalizeAbilities(b.abilities),
			rarity = b.rarity or "Common",
			desc = b.desc or "Weapon blade",
		}
	end
	return out
end

function BladeDefs.ForLegacyFamily(familyKey: string): string?
	return LEGACY_BLADE[familyKey]
end

return BladeDefs
