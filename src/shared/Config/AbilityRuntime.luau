--[[
	Data-driven ability combat params (proto).
	ItemDefs desc is flavor; this table drives cast / damage / status / FX.
	Unknown abilityId → safe defaults from source item element.
]]

local ElementData = require(script.Parent.ElementData)

local AbilityRuntime = {}

export type Shape = "Single" | "Cone" | "Sphere" | "Self" | "Dash"

export type AbilitySpec = {
	id: string,
	damagePct: number, -- of WeaponBase; 0 = no damage
	range: number,
	coneDeg: number?,
	radius: number?,
	shape: Shape,
	statusId: string?,
	statusDuration: number?,
	statusDps: number?,
	cooldownSec: number,
	anim: "Melee" | "Cast" | "Bow" | "Buff",
	vfx: "Slash" | "Bolt" | "Burst" | "Aura" | "Cone" | "Dash",
	selfBuff: string?, -- Fortify etc.
	selfBuffDuration: number?,
	selfBuffParams: { [string]: number }?,
}

-- Handcrafted / signature overrides
local SPECS: { [string]: AbilitySpec } = {
	cinder_lunge = {
		id = "cinder_lunge",
		damagePct = 120,
		range = 10,
		shape = "Dash",
		statusId = "Ignite",
		statusDuration = 3,
		cooldownSec = 8,
		anim = "Melee",
		vfx = "Dash",
	},
	arc_thrust = {
		id = "arc_thrust",
		damagePct = 130,
		range = 8,
		shape = "Single",
		statusId = "Shock",
		statusDuration = 0.5,
		cooldownSec = 9,
		anim = "Melee",
		vfx = "Slash",
	},
	rend_wave = {
		id = "rend_wave",
		damagePct = 140,
		range = 8,
		coneDeg = 120,
		shape = "Cone",
		statusId = "Bleed",
		statusDuration = 8,
		statusDps = 4,
		cooldownSec = 11,
		anim = "Melee",
		vfx = "Cone",
	},
	tectonic_cleave = {
		id = "tectonic_cleave",
		damagePct = 160,
		range = 6,
		coneDeg = 90,
		shape = "Cone",
		statusId = "Slow",
		statusDuration = 2,
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Cone",
	},
	fault_crash = {
		id = "fault_crash",
		damagePct = 200,
		range = 6,
		shape = "Dash",
		cooldownSec = 14,
		anim = "Melee",
		vfx = "Dash",
	},
	thunderbolt = {
		id = "thunderbolt",
		damagePct = 150,
		range = 28,
		shape = "Single",
		statusId = "Shock",
		statusDuration = 0.5,
		cooldownSec = 10,
		anim = "Cast",
		vfx = "Bolt",
	},
	stone_armor = {
		id = "stone_armor",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 14,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "Fortify",
		selfBuffDuration = 4,
		selfBuffParams = { damageTakenMult = 0.85 },
	},
	chain_jolt = {
		id = "chain_jolt",
		damagePct = 120,
		range = 28,
		shape = "Single",
		statusId = "Shock",
		statusDuration = 0.5,
		cooldownSec = 12,
		anim = "Cast",
		vfx = "Bolt",
	},
	blazing_arc = {
		id = "blazing_arc",
		damagePct = 140,
		range = 7,
		coneDeg = 100,
		shape = "Cone",
		statusId = "Ignite",
		statusDuration = 3,
		cooldownSec = 9,
		anim = "Melee",
		vfx = "Cone",
	},
	riptide_chop = {
		id = "riptide_chop",
		damagePct = 155,
		range = 8,
		shape = "Dash",
		statusId = "Wet",
		statusDuration = 5,
		cooldownSec = 11,
		anim = "Melee",
		vfx = "Dash",
	},
	fan_of_knives = {
		id = "fan_of_knives",
		damagePct = 75, -- per knife; proto: 3 hits simplified as ×3 once
		range = 10,
		coneDeg = 80,
		shape = "Cone",
		statusId = "Poisoned",
		statusDuration = 5,
		statusDps = 3,
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Cone",
	},
	petrify_bolt = {
		id = "petrify_bolt",
		damagePct = 125,
		range = 22,
		shape = "Single",
		statusId = "Slow",
		statusDuration = 3,
		cooldownSec = 11,
		anim = "Cast",
		vfx = "Bolt",
	},
	ballista_shot = {
		id = "ballista_shot",
		damagePct = 180,
		range = 26,
		shape = "Single",
		statusId = "Bleed",
		statusDuration = 8,
		statusDps = 4,
		cooldownSec = 13,
		anim = "Bow",
		vfx = "Bolt",
	},
	gale_volley = {
		id = "gale_volley",
		damagePct = 70,
		range = 28,
		coneDeg = 40,
		shape = "Cone",
		statusId = "Windy",
		statusDuration = 3,
		cooldownSec = 10,
		anim = "Bow",
		vfx = "Cone",
	},
	grand_slam = {
		id = "grand_slam",
		damagePct = 130,
		range = 10,
		radius = 10,
		shape = "Sphere",
		statusId = "Bleed",
		statusDuration = 8,
		statusDps = 4,
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Burst",
	},
	grand_strike = {
		id = "grand_strike",
		damagePct = 150,
		range = 8,
		shape = "Single",
		statusId = "Knockback",
		statusDuration = 0.35,
		cooldownSec = 15,
		anim = "Melee",
		vfx = "Slash",
	},
}

local function defaultFromElement(abilityId: string, element: string?, cooldownSec: number?): AbilitySpec
	local el = element or "Neutral"
	local sig = ElementData.Signature[el]
	local isRanged = string.find(abilityId, "bolt") ~= nil or string.find(abilityId, "shot") ~= nil
	return {
		id = abilityId,
		damagePct = 125,
		range = if isRanged then 28 else 8,
		shape = if isRanged then "Single" else "Single",
		statusId = sig and sig.id or nil,
		statusDuration = if el == "Lightning" then 0.5 elseif el == "Steel" then 8 elseif el == "Poison" then 5 elseif el == "Water" then 5 elseif el == "Wind" then 3 elseif el == "Rock" then 2 elseif el == "Fire" then 3 else nil,
		statusDps = if el == "Steel" then 4 elseif el == "Poison" then 3 else nil,
		cooldownSec = cooldownSec or 10,
		anim = if isRanged then "Cast" else "Melee",
		vfx = if isRanged then "Bolt" else "Slash",
	}
end

function AbilityRuntime.Get(abilityId: string, fallbackElement: string?, fallbackCd: number?): AbilitySpec
	local spec = SPECS[abilityId]
	if spec then
		return spec
	end
	-- Matrix generics: mx_fire_strike etc.
	if string.sub(abilityId, 1, 3) == "mx_" then
		local parts = string.split(abilityId, "_")
		local elKey = parts[2]
		local elName = nil
		for name, low in ElementData.Lower do
			if low == elKey then
				elName = name
				break
			end
		end
		local base = defaultFromElement(abilityId, elName, fallbackCd)
		if parts[3] == "burst" or abilityId:find("util") then
			base.damagePct = 0
			base.shape = "Self"
			base.anim = "Buff"
			base.vfx = "Aura"
			base.statusId = nil
		end
		return base
	end
	return defaultFromElement(abilityId, fallbackElement, fallbackCd)
end

function AbilityRuntime.Register(spec: AbilitySpec)
	SPECS[spec.id] = spec
end

return AbilityRuntime
