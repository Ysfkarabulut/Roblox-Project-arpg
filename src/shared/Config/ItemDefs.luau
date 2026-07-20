--[[
	Item catalog = WeaponMatrix + ArmorMatrix + handcrafted overrides.
	Matrix: her silah ailesi × 8 element + her zırh slotu × 8 element (Common).
	Aynı id'li handcrafted / Rare / BossExclusive kayıtlar matrisi ezer.
]]

local WeaponMatrix = require(script.Parent.WeaponMatrix)
local ArmorMatrix = require(script.Parent.ArmorMatrix)

local ItemDefs = {}

local catalog: { [string]: any } = {}

for id, def in WeaponMatrix.Build() do
	catalog[id] = def
end
for id, def in ArmorMatrix.Build() do
	catalog[id] = def
end

-- ── Handcrafted overrides & exclusive pieces ───────────────────────────────

local handcrafted = {
	-- Legacy placeholders (UI / eski starter)
	w_sword_1h = {
		id = "w_sword_1h",
		name = "Iron Longsword",
		kind = "Weapon1H",
		family = "Sword",
		slotHints = { "main", "off" },
		element = "Steel",
		baseDamage = 40,
		desc = "1H Sword · Measured Strike (legacy stub)",
	},
	w_axe_1h = {
		id = "w_axe_1h",
		name = "Hand Axe",
		kind = "Weapon1H",
		family = "Axe",
		slotHints = { "main", "off" },
		element = "Fire",
		baseDamage = 46,
		desc = "1H Axe · anti-guard (legacy stub)",
	},
	w_sword_2h = {
		id = "w_sword_2h",
		name = "Greatblade",
		kind = "Weapon2H",
		family = "Sword",
		slotHints = { "main" },
		element = "Steel",
		baseDamage = 50,
		desc = "2H Sword · off = Knot (legacy stub)",
	},
	w_bow = {
		id = "w_bow",
		name = "Hunter Bow",
		kind = "Bow",
		family = "Bow",
		slotHints = { "main" },
		element = "Wind",
		baseDamage = 40,
		desc = "Bow · Quiver off (legacy stub)",
	},
	w_crossbow = {
		id = "w_crossbow",
		name = "Siege Crossbow",
		kind = "Crossbow",
		family = "Crossbow",
		slotHints = { "main" },
		element = "Steel",
		baseDamage = 58,
		desc = "Crossbow · L3 reload (legacy stub)",
	},
	w_staff = {
		id = "w_staff",
		name = "Ember Staff",
		kind = "Staff",
		family = "Staff",
		slotHints = { "main" },
		element = "Fire",
		baseDamage = 46,
		desc = "2H Staff · Knot off (legacy stub)",
	},
	w_wand = {
		id = "w_wand",
		name = "Spark Wand",
		kind = "Wand",
		family = "Wand",
		slotHints = { "main", "off" },
		element = "Lightning",
		baseDamage = 30,
		desc = "1H Wand · kısa menzil (legacy stub)",
	},
	w_scepter = {
		id = "w_scepter",
		name = "Radiant Scepter",
		kind = "Scepter",
		family = "Scepter",
		slotHints = { "main", "off" },
		element = "Water",
		baseDamage = 28,
		desc = "1H Scepter · cone (legacy stub)",
	},

	-- Signature Common designs (override matrix same id)
	w_dagger_fire = {
		id = "w_dagger_fire",
		name = "Ember Shiv",
		kind = "Weapon1H",
		family = "Dagger",
		slotHints = { "main", "off" },
		element = "Fire",
		scaling = "DEX",
		asTier = "D",
		baseDamage = 30,
		requires = { DEX = 28 },
		familyPerk = "Backstab ×1.30 (arka 180°)",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "cinder_lunge",
				name = "Cinder Lunge",
				slotType = "Active",
				cooldownSec = 8,
				desc = "Dash ~8 stud · 120% weapon base · isabette Ignite 3s · stam 0",
			},
		},
		desc = "Fire · 1H Dagger · yalnız 1 Active",
	},
	w_wand_water = {
		id = "w_wand_water",
		name = "Tide Spindle",
		kind = "Wand",
		family = "Wand",
		slotHints = { "main", "off" },
		element = "Water",
		scaling = "INT",
		asTier = "D",
		baseDamage = 30,
		requires = { INT = 28 },
		familyPerk = "+Status Potency",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "deep_current",
				name = "Deep Current",
				slotType = "Passive",
				desc = "Uyguladığın Wet süresi +25% (Potency sonrası)",
			},
		},
		desc = "Water · 1H Wand · yalnız 1 Passive · ~22 stud LA",
	},
	w_sword_1h_lightning = {
		id = "w_sword_1h_lightning",
		name = "Stormbrand",
		kind = "Weapon1H",
		family = "Sword",
		slotHints = { "main", "off" },
		element = "Lightning",
		scaling = "STR",
		asTier = "C",
		baseDamage = 40,
		requires = { STR = 28 },
		familyPerk = "Measured Strike L3 ×1.35",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "arc_thrust",
				name = "Arc Thrust",
				slotType = "Active",
				cooldownSec = 9,
				desc = "İleri thrust 7 stud · 130% weapon base · isabette Shock 0.5s · stam 0",
			},
		},
		desc = "Lightning · 1H Sword · yalnız 1 Active",
	},
	w_bow_wind = {
		id = "w_bow_wind",
		name = "Gale Longbow",
		kind = "Bow",
		family = "Bow",
		slotHints = { "main" },
		element = "Wind",
		scaling = "DEX",
		asTier = "C",
		baseDamage = 40,
		requires = { DEX = 32 },
		familyPerk = "+Crit Chance · Focused Shot L3 ×1.25",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "tailwind",
				name = "Tailwind",
				slotType = "Passive",
				desc = "Sprint drain −20%",
			},
			{
				id = "keen_eye",
				name = "Keen Eye",
				slotType = "Passive",
				desc = "Crit Chance +4% (flat, cap öncesi)",
			},
		},
		desc = "Wind · Bow · 2 Passive · Quiver off",
	},
	w_scepter_poison = {
		id = "w_scepter_poison",
		name = "Blight Crook",
		kind = "Scepter",
		family = "Scepter",
		slotHints = { "main", "off" },
		element = "Poison",
		scaling = "INT",
		asTier = "E",
		baseDamage = 28,
		requires = { INT = 30 },
		familyPerk = "+Buff Potency · cone LA",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "venom_haze",
				name = "Venom Haze",
				slotType = "Passive",
				desc = "Cone LA isabetinde %20 şans Poisoned 5s (3 DPS) — LA affix değil, pasif proc",
			},
		},
		desc = "Poison · 1H Scepter · yalnız 1 Passive · ~16 stud cone",
	},
	w_sword_2h_steel = {
		id = "w_sword_2h_steel",
		name = "Ironhowl",
		kind = "Weapon2H",
		family = "Sword",
		slotHints = { "main" },
		element = "Steel",
		scaling = "STR",
		asTier = "B",
		baseDamage = 50,
		requires = { STR = 38 },
		familyPerk = "Measured Strike L3 ×1.40",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "rend_wave",
				name = "Rend Wave",
				slotType = "Active",
				cooldownSec = 11,
				desc = "Yatay sweep · 8 stud arc · 140% weapon base · isabette Bleed 8s (4 DPS) · stam 0",
			},
			{
				id = "tempered_edge",
				name = "Tempered Edge",
				slotType = "Passive",
				desc = "L3 combo isabetinde +8% direct (Measured üstüne çarpılmaz; raw'a ek flat% playtest)",
			},
		},
		desc = "Steel · 2H Sword · 1 Active + 1 Passive · Knot off",
	},
	w_axe_2h_rock = {
		id = "w_axe_2h_rock",
		name = "Faultline Greataxe",
		kind = "Weapon2H",
		family = "Axe",
		slotHints = { "main" },
		element = "Rock",
		scaling = "STR",
		asTier = "A",
		baseDamage = 54,
		requires = { STR = 40 },
		familyPerk = "Anti-guard stamina ×1.50 (2H)",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "tectonic_cleave",
				name = "Tectonic Cleave",
				slotType = "Active",
				cooldownSec = 10,
				desc = "Ön ~90° cone · 6 stud · 160% weapon base · isabette Slow 50% 2s · stam 0",
			},
			{
				id = "fault_crash",
				name = "Fault Crash",
				slotType = "Active",
				cooldownSec = 14,
				desc = "Kısa ileri step ~4 stud · tek hedef 200% weapon base · Guard'a vurursa stamina hasarı ×2 · stam 0",
			},
		},
		desc = "Rock · 2H Axe · 2 Active · Knot off",
	},
	w_crossbow_neutral = {
		id = "w_crossbow_neutral",
		name = "Hollow Arbalest",
		kind = "Crossbow",
		family = "Crossbow",
		slotHints = { "main" },
		element = "Neutral",
		scaling = "DEX",
		asTier = "S",
		baseDamage = 58,
		requires = { DEX = 36 },
		familyPerk = "+Crit Damage · Heavy Bolt L3 ×1.40 + reload 1.2s",
		onHitAffix = nil,
		rarity = "Common",
		abilities = {
			{
				id = "steady_frame",
				name = "Steady Frame",
				slotType = "Passive",
				desc = "L3 reload süresi −0.2s (1.2 → 1.0)",
			},
			{
				id = "unbound_bolt",
				name = "Unbound Bolt",
				slotType = "Passive",
				desc = "Direct hasar +3% (Unbound sinerji ile stack — playtest)",
			},
		},
		desc = "Neutral · Crossbow · 2 Passive · Quiver off",
	},

	-- Boss / exclusive
	w_dagger_poison_boss = {
		id = "w_dagger_poison_boss",
		name = "Serpent Fang",
		kind = "Weapon1H",
		family = "Dagger",
		slotHints = { "main", "off" },
		element = "Poison",
		scaling = "DEX",
		asTier = "D",
		baseDamage = 32,
		requires = { DEX = 40 },
		familyPerk = "Backstab ×1.30 (arka 180°)",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "fan_of_knives",
				name = "Fan of Knives",
				slotType = "Active",
				cooldownSec = 10,
				desc = "80° cone · 10 stud · 4 knives · each knife 75% weapon base + Poisoned 5s (3 DPS) · same target can be hit by multiple knives (4 hits = 300%, 2 = 150%) · crit: first knife only · stam 0",
			},
			{
				id = "toxic_edge",
				name = "Toxic Edge",
				slotType = "Passive",
				desc = "15% chance on light-attack hit to ApplyStatus Poisoned 5s (3 DPS) · not an item on-hit affix",
			},
		},
		desc = "Poison · 1H Dagger · BossExclusive · 1 Active + 1 Passive",
	},
	w_mace_2h_steel_boss = {
		id = "w_mace_2h_steel_boss",
		name = "Thronebreaker",
		kind = "Weapon2H",
		family = "Mace",
		slotHints = { "main" },
		element = "Steel",
		scaling = "STR",
		asTier = "S",
		baseDamage = 58,
		requires = { STR = 48 },
		familyPerk = "Defence Shred (yüksek) 2H %40",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "grand_slam",
				name = "Grand Slam",
				slotType = "Active",
				cooldownSec = 10,
				desc = "Ground slam · 10 stud radius AoE · 130% weapon base · Bleed 8s (4 DPS) to all hit · stam 0",
			},
			{
				id = "grand_strike",
				name = "Grand Strike",
				slotType = "Active",
				cooldownSec = 15,
				desc = "Single-target 150% weapon base · ApplyStatus Knockback ~8 stud · stam 0",
			},
			{
				id = "oppressor",
				name = "Oppressor",
				slotType = "Passive",
				desc = "+15% direct vs Shock / Stun / Chilled / Root (Knockback does not count)",
			},
		},
		desc = "Steel · 2H Mace · BossExclusive · 2 Active + 1 Passive · Knot off",
	},
	w_sword_1h_fire_boss = {
		id = "w_sword_1h_fire_boss",
		name = "Cinderbrand",
		kind = "Weapon1H",
		family = "Sword",
		slotHints = { "main", "off" },
		element = "Fire",
		scaling = "STR",
		asTier = "C",
		baseDamage = 42,
		requires = { STR = 40 },
		familyPerk = "Measured Strike L3 ×1.35",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "blazing_arc",
				name = "Blazing Arc",
				slotType = "Active",
				cooldownSec = 9,
				desc = "Wide slash · 7 stud arc · 140% weapon base · Ignite 3s on hit · stam 0",
			},
			{
				id = "ember_rhythm",
				name = "Ember Rhythm",
				slotType = "Passive",
				desc = "Measured Strike (L3) also applies Ignite 3s",
			},
		},
		desc = "Fire · 1H Sword · BossExclusive · 1 Active + 1 Passive",
	},
	w_axe_1h_water_boss = {
		id = "w_axe_1h_water_boss",
		name = "Tide Cleaver",
		kind = "Weapon1H",
		family = "Axe",
		slotHints = { "main", "off" },
		element = "Water",
		scaling = "STR",
		asTier = "B",
		baseDamage = 46,
		requires = { STR = 42 },
		familyPerk = "Anti-guard stamina ×1.25",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "riptide_chop",
				name = "Riptide Chop",
				slotType = "Active",
				cooldownSec = 11,
				desc = "Leap strike · 6 stud · 155% weapon base · Wet 5s · if target already Wet: extra 40% burst · stam 0",
			},
			{
				id = "floodgate",
				name = "Floodgate",
				slotType = "Passive",
				desc = "Hits vs guarding enemies also apply Wet 3s (chip still applies; on-hit affix rules: no status through full guard block — this passive only on successful stamina chip)",
			},
		},
		desc = "Water · 1H Axe · BossExclusive · 1 Active + 1 Passive",
	},
	w_staff_lightning_boss = {
		id = "w_staff_lightning_boss",
		name = "Skyfract Staff",
		kind = "Staff",
		family = "Staff",
		slotHints = { "main" },
		element = "Lightning",
		scaling = "INT",
		asTier = "B",
		baseDamage = 48,
		requires = { INT = 46 },
		familyPerk = "+Status Potency++ · Empowered Bolt L3 ×1.30",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "chain_jolt",
				name = "Chain Jolt",
				slotType = "Active",
				cooldownSec = 12,
				desc = "Bolt · 28 stud · 120% weapon base · Shock 0.5s · jumps to 2 nearby enemies within 10 stud (80% then 60%) · stam 0",
			},
			{
				id = "thunder_cage",
				name = "Thunder Cage",
				slotType = "Active",
				cooldownSec = 16,
				desc = "Ground zone · 8 stud radius · 4s · enemies entering take Shock 0.5s once · stam 0",
			},
			{
				id = "storm_focus",
				name = "Storm Focus",
				slotType = "Passive",
				desc = "Shock duration you apply +0.15s (before Resist)",
			},
		},
		desc = "Lightning · Staff · BossExclusive · 2 Active + 1 Passive · Knot off",
	},
	w_bow_wind_boss = {
		id = "w_bow_wind_boss",
		name = "Skycutter",
		kind = "Bow",
		family = "Bow",
		slotHints = { "main" },
		element = "Wind",
		scaling = "DEX",
		asTier = "C",
		baseDamage = 42,
		requires = { DEX = 44 },
		familyPerk = "+Crit Chance · Focused Shot L3 ×1.25 pierce",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "gale_volley",
				name = "Gale Volley",
				slotType = "Active",
				cooldownSec = 10,
				desc = "3 arrows in a tight fan · each 70% weapon base · Windy 3s on hit · stam 0",
			},
			{
				id = "updraft",
				name = "Updraft",
				slotType = "Active",
				cooldownSec = 14,
				desc = "Self: Move Speed +25% for 3s · next light attack within window deals +30% · stam 0",
			},
			{
				id = "eye_of_the_storm",
				name = "Eye of the Storm",
				slotType = "Passive",
				desc = "Crits apply Windy 2s",
			},
		},
		desc = "Wind · Bow · BossExclusive · 2 Active + 1 Passive · Quiver off",
	},
	w_wand_rock_boss = {
		id = "w_wand_rock_boss",
		name = "Stonewhisper",
		kind = "Wand",
		family = "Wand",
		slotHints = { "main", "off" },
		element = "Rock",
		scaling = "INT",
		asTier = "D",
		baseDamage = 32,
		requires = { INT = 40 },
		familyPerk = "+Status Potency",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "petrify_bolt",
				name = "Petrify Bolt",
				slotType = "Active",
				cooldownSec = 11,
				desc = "Projectile · 22 stud · 125% weapon base · Slow 50% 3s · stam 0",
			},
			{
				id = "bedrock",
				name = "Bedrock",
				slotType = "Passive",
				desc = "While you have a shield equipped (off): incoming direct −5% (not DR stack; flat after DR playtest)",
			},
		},
		desc = "Rock · Wand · BossExclusive · 1 Active + 1 Passive",
	},
	w_crossbow_steel_boss = {
		id = "w_crossbow_steel_boss",
		name = "Siege Piercer",
		kind = "Crossbow",
		family = "Crossbow",
		slotHints = { "main" },
		element = "Steel",
		scaling = "DEX",
		asTier = "S",
		baseDamage = 62,
		requires = { DEX = 46 },
		familyPerk = "+Crit Damage · Heavy Bolt L3 ×1.40 + reload 1.2s",
		onHitAffix = nil,
		rarity = "BossExclusive",
		abilities = {
			{
				id = "ballista_shot",
				name = "Ballista Shot",
				slotType = "Active",
				cooldownSec = 13,
				desc = "Charged bolt · 26 stud · 180% weapon base · Bleed 8s · pierces 1 extra target at 60% · forces reload after cast · stam 0",
			},
			{
				id = "armor_spike",
				name = "Armor Spike",
				slotType = "Active",
				cooldownSec = 15,
				desc = "Next L3 Heavy Bolt within 5s gains +Defence Shred 20% for that hit · stam 0",
			},
			{
				id = "barbed_quarrels",
				name = "Barbed Quarrels",
				slotType = "Passive",
				desc = "Bleed you apply +1 DPS",
			},
		},
		desc = "Steel · Crossbow · BossExclusive · 2 Active + 1 Passive · Quiver off",
	},

	-- Off-hand
	o_kite = {
		id = "o_kite",
		name = "Kite Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Rock",
		defence = 120,
		desc = "Guard · chip 40% · drain 1.0/s",
	},
	o_buckler = {
		id = "o_buckler",
		name = "Buckler",
		kind = "Shield",
		slotHints = { "off" },
		element = "Steel",
		defence = 60,
		desc = "Guard · chip 60% · drain 0.5/s · low slow",
	},
	o_tower = {
		id = "o_tower",
		name = "Tower Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Rock",
		defence = 160,
		desc = "Guard · chip 30% · drain 1.5/s · high slow",
	},
	o_round = {
		id = "o_round",
		name = "Round Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Water",
		defence = 90,
		desc = "Guard · chip 45% · drain 0.8/s · balanced",
	},
	o_spiked = {
		id = "o_spiked",
		name = "Spiked Shield",
		kind = "Shield",
		slotHints = { "off" },
		element = "Steel",
		defence = 100,
		desc = "Guard · chip 50% · drain 1.1/s",
	},
	o_quiver = {
		id = "o_quiver",
		name = "Hunter Quiver",
		kind = "Quiver",
		slotHints = { "off" },
		element = nil,
		desc = "Bow/Crossbow off · tagsiz",
	},
	o_knot = {
		id = "o_knot",
		name = "Weapon Knot",
		kind = "Knot",
		slotHints = { "off" },
		element = nil,
		desc = "2H / Staff off · tagsiz",
	},
	o_focus = {
		id = "o_focus",
		name = "Root Totem",
		kind = "Focus",
		slotHints = { "off" },
		element = "Poison",
		desc = "Focus utility",
	},

	-- Legacy armor stubs (keep for old refs)
	a_helm = {
		id = "a_helm",
		name = "Iron Helm",
		kind = "Head",
		slotHints = { "head" },
		element = "Steel",
		defence = 16,
		resist = 5,
		desc = "Head (legacy stub)",
	},
	a_chest = {
		id = "a_chest",
		name = "Steel Cuirass",
		kind = "Chest",
		slotHints = { "chest" },
		element = "Steel",
		defence = 80,
		resist = 20,
		desc = "Chest · sinerji tag (legacy stub)",
	},
	a_hands = {
		id = "a_hands",
		name = "Cloth Wraps",
		kind = "Hands",
		slotHints = { "hands" },
		element = "Water",
		defence = 3,
		resist = 16,
		desc = "Hands (legacy stub)",
	},
	a_feets = {
		id = "a_feets",
		name = "Traveler Boots",
		kind = "Feets",
		slotHints = { "feets" },
		element = "Neutral",
		defence = 14,
		resist = 10,
		desc = "Feets (legacy stub)",
	},

	-- Rare signature armor (unique ids — matrix commons remain)
	a_chest_thornplate = {
		id = "a_chest_thornplate",
		name = "Thornplate",
		kind = "Chest",
		slotHints = { "chest" },
		element = "Neutral",
		defence = 80,
		resist = 20,
		rarity = "Rare",
		abilities = {
			{
				id = "thorn",
				name = "Thorn",
				slotType = "Passive",
				desc = "While equipped: permanent status Thorn · reflect 15% of Direct after_dr (no chip reflect, no chains, no crit/on-hit)",
			},
		},
		desc = "Neutral Chest · tank · permanent Thorn status",
	},
	a_feets_tidewalkers = {
		id = "a_feets_tidewalkers",
		name = "Tidewalkers",
		kind = "Feets",
		slotHints = { "feets" },
		element = "Water",
		defence = 14,
		resist = 10,
		rarity = "Rare",
		abilities = {
			{
				id = "splash_step",
				name = "Splash Step",
				slotType = "Passive",
				desc = "On Dodge start: Wet 5s to enemies in 5 stud radius at dodge origin",
			},
		},
		desc = "Water Feets · Splash Step",
	},
	a_hands_stormgrasp = {
		id = "a_hands_stormgrasp",
		name = "Stormgrasp",
		kind = "Hands",
		slotHints = { "hands" },
		element = "Lightning",
		defence = 5,
		resist = 8,
		rarity = "Rare",
		abilities = {
			{
				id = "thunderbolt",
				name = "Thunderbolt",
				slotType = "Active",
				cooldownSec = 10,
				desc = "Lightning strike on target · 150% main WeaponBase · Shock 0.5s · ~28 stud · stam 0",
			},
		},
		desc = "Lightning Hands · Thunderbolt",
	},
	a_head_bedrock = {
		id = "a_head_bedrock",
		name = "Bedrock Crown",
		kind = "Head",
		slotHints = { "head" },
		element = "Rock",
		defence = 16,
		resist = 5,
		rarity = "Rare",
		abilities = {
			{
				id = "stone_armor",
				name = "Stone Armor",
				slotType = "Active",
				cooldownSec = 14,
				desc = "Self ApplyStatus Fortify 4s · damageTakenMult 0.85 (−15% Direct after DR) · stam 0",
			},
		},
		desc = "Rock Head · Stone Armor → Fortify",
	},
}

for id, def in handcrafted do
	catalog[id] = def
end

function ItemDefs.Get(defId: string)
	return catalog[defId]
end

function ItemDefs.All()
	return catalog
end

function ItemDefs.CanEquipInSlot(defId: string, slotId: string): boolean
	local def = catalog[defId]
	if not def then
		return false
	end
	for _, s in def.slotHints do
		if s == slotId then
			return true
		end
	end
	return false
end

--- Common + Rare (Studio starter); BossExclusive dışarıda
function ItemDefs.StarterDefIds(): { string }
	local ids = {}
	for id, def in catalog do
		local r = def.rarity
		if r ~= "BossExclusive" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

return ItemDefs
