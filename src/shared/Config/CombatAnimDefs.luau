--[[
	Universal animation catalog — stable clip ids (like FocusAbilityDefs / WeaponActiveDefs).

	Evening import workflow:
	1. Drop Animation instances under ReplicatedStorage.CombatAnims using clipName
	   (e.g. Sword1H_L1, Sprint_TwoHandMelee, Dodge, Walk).
	2. Or set animId on the entry here — one id change updates every consumer.

	Ids:
	  locomotion_idle | walk | run | jump | fall
	  combat_dodge | combat_melee | combat_cast | combat_bow | combat_buff
	  sprint_<stance>  (7 stances, keys match StanceConfig)
	  la_<family>_l1|l2|l3  (family = Sword1H, Bow, …)
]]

local CombatAnimDefs = {}

export type AnimCategory = "Locomotion" | "Combat" | "Sprint"

export type AnimClipDef = {
	id: string,
	category: AnimCategory,
	label: string?,
	animId: string?,
	clipName: string?,
	clipNameAlts: { string }?,
	fallbackId: string?,
	speed: number?,
	weight: number?,
	fadeIn: number?,
	fadeOut: number?,
	sanitizeTranslation: boolean?,
	lean: number?,
	stanceId: string?,
}

local CATALOG: { [string]: AnimClipDef } = {}

local LEGACY_TO_ID: { [string]: string } = {
	Idle = "locomotion_idle",
	Walk = "locomotion_walk",
	Run = "locomotion_run",
	Jump = "locomotion_jump",
	Fall = "locomotion_fall",
	Melee = "combat_melee",
	Cast = "combat_cast",
	Bow = "combat_bow",
	Buff = "combat_buff",
	Dodge = "combat_dodge",
}

local ID_TO_LEGACY: { [string]: string } = {}
for legacy, id in LEGACY_TO_ID do
	ID_TO_LEGACY[id] = legacy
end

local LA_FAMILIES = {
	"Sword1H",
	"Sword2H",
	"Axe1H",
	"Axe2H",
	"Mace1H",
	"Mace2H",
	"Dagger",
	"Wand",
	"Scepter",
	"Staff",
	"Bow",
	"Crossbow",
}

local function laFallbackId(family: string): string
	if family == "Bow" or family == "Crossbow" then
		return "combat_bow"
	end
	if family == "Wand" or family == "Staff" or family == "Scepter" then
		return "combat_cast"
	end
	return "combat_melee"
end

local function register(def: AnimClipDef)
	CATALOG[def.id] = def
end

-- Locomotion
register({
	id = "locomotion_idle",
	category = "Locomotion",
	label = "Idle",
	animId = "rbxassetid://507766666",
	clipName = "Idle",
})
register({
	id = "locomotion_walk",
	category = "Locomotion",
	label = "Walk",
	animId = "rbxassetid://507777826",
	clipName = "Walk",
})
register({
	id = "locomotion_run",
	category = "Locomotion",
	label = "Run",
	animId = "rbxassetid://507767714",
	clipName = "Run",
})
register({
	id = "locomotion_jump",
	category = "Locomotion",
	label = "Jump",
	animId = "rbxassetid://507765000",
	clipName = "Jump",
})
register({
	id = "locomotion_fall",
	category = "Locomotion",
	label = "Fall",
	animId = "rbxassetid://507767968",
	clipName = "Fall",
})

-- Combat bases
register({
	id = "combat_melee",
	category = "Combat",
	label = "Melee base",
	animId = "rbxassetid://522635514",
	clipName = "Melee",
})
register({
	id = "combat_cast",
	category = "Combat",
	label = "Cast base",
	animId = "rbxassetid://507770453",
	clipName = "Cast",
	clipNameAlts = { "CastPoint" },
})
register({
	id = "combat_bow",
	category = "Combat",
	label = "Bow base",
	animId = "rbxassetid://522638767",
	clipName = "Bow",
})
register({
	id = "combat_buff",
	category = "Combat",
	label = "Buff base",
	animId = "rbxassetid://507770453",
	clipName = "Buff",
	fallbackId = "combat_cast",
})
register({
	id = "combat_dodge",
	category = "Combat",
	label = "Dodge roll",
	animId = "rbxassetid://136179211599391",
	clipName = "Dodge",
	sanitizeTranslation = true,
})

-- Sprint (stance keys align with StanceConfig)
local SPRINT_ENTRIES: { { stanceId: string, id: string, animId: string, speed: number, lean: number, label: string, clipName: string?, clipNameAlts: { string }? } } =
	{
		{
			stanceId = "OneHandShield",
			id = "sprint_onehand_shield",
			animId = "rbxassetid://913384386",
			speed = 1.05,
			lean = 8,
			label = "1H+Shield",
			clipName = "Sprint_OneHandShield",
		},
		{
			stanceId = "OneHandFocus",
			id = "sprint_onehand_focus",
			animId = "rbxassetid://913376220",
			speed = 1.15,
			lean = 12,
			label = "1H+Focus",
			clipName = "Sprint_OneHandFocus",
		},
		{
			stanceId = "DualWield",
			id = "sprint_dual_wield",
			animId = "rbxassetid://891621366",
			speed = 1.2,
			lean = 14,
			label = "1H+1H",
			clipName = "Sprint_DualWield",
		},
		{
			stanceId = "TwoHandMelee",
			id = "sprint_twohand_melee",
			animId = "rbxassetid://913402848",
			speed = 0.92,
			lean = 5,
			label = "2H Melee",
			clipName = "Sprint_TwoHandMelee",
			clipNameAlts = { "GreatSwordRun", "Great Sword Run" },
		},
		{
			stanceId = "Crossbow",
			id = "sprint_crossbow",
			animId = "rbxassetid://891636393",
			speed = 0.9,
			lean = 4,
			label = "Crossbow",
			clipName = "Sprint_Crossbow",
		},
		{
			stanceId = "Bow",
			id = "sprint_bow",
			animId = "rbxassetid://913390065",
			speed = 1.1,
			lean = 10,
			label = "Bow",
			clipName = "Sprint_Bow",
		},
		{
			stanceId = "Staff",
			id = "sprint_staff",
			animId = "rbxassetid://507767714",
			speed = 1.0,
			lean = 7,
			label = "Staff",
			clipName = "Sprint_Staff",
		},
	}

CombatAnimDefs.SprintByStance = {} :: { [string]: string }
CombatAnimDefs.StanceBySprintId = {} :: { [string]: string }

for _, row in SPRINT_ENTRIES do
	register({
		id = row.id,
		category = "Sprint",
		label = row.label,
		stanceId = row.stanceId,
		animId = row.animId,
		clipName = row.clipName,
		clipNameAlts = row.clipNameAlts,
		speed = row.speed,
		lean = row.lean,
		fallbackId = "locomotion_run",
	})
	CombatAnimDefs.SprintByStance[row.stanceId] = row.id
	CombatAnimDefs.StanceBySprintId[row.id] = row.stanceId
end

-- LA per family × step (clipName matches server fx key: Sword1H_L1, …)
for _, family in LA_FAMILIES do
	local famKey = string.lower(family)
	for step = 1, 3 do
		register({
			id = `la_{famKey}_l{step}`,
			category = "Combat",
			label = `{family} L{step}`,
			clipName = `{family}_L{step}`,
			fallbackId = laFallbackId(family),
		})
	end
end

function CombatAnimDefs.Get(clipId: string): AnimClipDef?
	return CATALOG[clipId]
end

function CombatAnimDefs.IdFromLegacyName(legacyName: string): string?
	return LEGACY_TO_ID[legacyName]
end

function CombatAnimDefs.LegacyNameFromId(clipId: string): string?
	return ID_TO_LEGACY[clipId]
end

function CombatAnimDefs.LaClipId(familyAnimPrefix: string, step: number): string
	return `la_{string.lower(familyAnimPrefix)}_l{step}`
end

function CombatAnimDefs.SprintClipId(stanceId: string): string?
	return CombatAnimDefs.SprintByStance[stanceId]
end

function CombatAnimDefs.All(): { [string]: AnimClipDef }
	return CATALOG
end

function CombatAnimDefs.SprintFallbackId(): string
	return "locomotion_run"
end

return CombatAnimDefs
