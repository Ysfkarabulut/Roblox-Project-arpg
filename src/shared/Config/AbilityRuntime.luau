--[[
	Data-driven ability combat params (proto).
	ItemDefs desc is flavor; this table drives cast / damage / status / FX.
	Unknown abilityId → safe defaults from source item element.
]]

local ElementData = require(script.Parent.ElementData)
local WeaponActiveDefs = require(script.Parent.WeaponActiveDefs)

local AbilityRuntime = {}

export type Shape = "Single" | "Cone" | "Sphere" | "GroundSphere" | "Grapple" | "Self" | "AllySingle" | "AllyCone" | "AllySphere" | "Dash" | "Line"

export type AbilitySpec = {
	id: string,
	damagePct: number, -- of WeaponBase; 0 = no damage
	range: number,
	coneDeg: number?,
	radius: number?,
	lineWidth: number?, -- Line shape half-width (studs)
	shape: Shape,
	hitCount: number?, -- multi-hit same target or volley ticks
	statusId: string?,
	statusDuration: number?,
	statusDps: number?,
	statusParams: { [string]: number }?,
	cooldownSec: number,
	anim: "Melee" | "Cast" | "Bow" | "Buff",
	vfx: "Slash" | "Bolt" | "Burst" | "Aura" | "Cone" | "Dash",
	selfBuff: string?, -- Fortify, Frenzy, HelmPulse
	selfBuffDuration: number?,
	selfBuffParams: { [string]: number }?,
	healBase: number?, -- instant self heal (Buff Potency scales amount)
	hotHps: number?, -- heal per second
	hotDuration: number?, -- HoT base duration (Buff Potency scales)
	chargeStuds: number?,
	retreatStuds: number?,
	knockbackStuds: number?,
	grapplePullDistance: number?,
}

-- Catalog weapon actives (see WeaponActiveDefs). Signature/boss actives register at runtime.
local SPECS: { [string]: AbilitySpec } = {
	strike_weaponactive = {
		id = "strike_weaponactive",
		damagePct = 130,
		range = 8,
		shape = "Single",
		cooldownSec = 9,
		anim = "Melee",
		vfx = "Slash",
	},
	strike_r_weaponactive = {
		id = "strike_r_weaponactive",
		damagePct = 145,
		range = 9,
		shape = "Single",
		cooldownSec = 8,
		anim = "Melee",
		vfx = "Slash",
	},
	bolt_weaponactive = {
		id = "bolt_weaponactive",
		damagePct = 130,
		range = 28,
		shape = "Single",
		cooldownSec = 9,
		anim = "Cast",
		vfx = "Bolt",
	},
	bolt_r_weaponactive = {
		id = "bolt_r_weaponactive",
		damagePct = 145,
		range = 30,
		shape = "Single",
		cooldownSec = 8,
		anim = "Cast",
		vfx = "Bolt",
	},
	cone_weaponactive = {
		id = "cone_weaponactive",
		damagePct = 115,
		range = 16,
		coneDeg = 45,
		shape = "Cone",
		cooldownSec = 9,
		anim = "Cast",
		vfx = "Cone",
	},
	cone_r_weaponactive = {
		id = "cone_r_weaponactive",
		damagePct = 125,
		range = 18,
		coneDeg = 50,
		shape = "Cone",
		cooldownSec = 9,
		anim = "Melee",
		vfx = "Cone",
	},
	slam_r_weaponactive = {
		id = "slam_r_weaponactive",
		damagePct = 155,
		range = 9,
		radius = 9,
		shape = "Sphere",
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Burst",
	},
	burst_weaponactive = {
		id = "burst_weaponactive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 14,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "Fortify",
		selfBuffDuration = 3,
		selfBuffParams = { damageTakenMult = 0.9 },
	},
	heal_weaponactive = {
		id = "heal_weaponactive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 12,
		anim = "Buff",
		vfx = "Aura",
		healBase = 45,
	},
	mend_weaponactive = {
		id = "mend_weaponactive",
		damagePct = 0,
		range = 18,
		shape = "AllySingle",
		cooldownSec = 11,
		anim = "Cast",
		vfx = "Aura",
		healBase = 50,
	},
	renew_weaponactive = {
		id = "renew_weaponactive",
		damagePct = 0,
		range = 18,
		shape = "AllySingle",
		cooldownSec = 14,
		anim = "Cast",
		vfx = "Aura",
		hotHps = 6,
		hotDuration = 5,
	},
	salve_weaponactive = {
		id = "salve_weaponactive",
		damagePct = 0,
		range = 16,
		coneDeg = 50,
		shape = "AllyCone",
		cooldownSec = 12,
		anim = "Cast",
		vfx = "Cone",
		healBase = 35,
	},
	well_weaponactive = {
		id = "well_weaponactive",
		damagePct = 0,
		range = 14,
		radius = 10,
		shape = "AllySphere",
		cooldownSec = 13,
		anim = "Cast",
		vfx = "Burst",
		healBase = 40,
	},
	hot_weaponactive = {
		id = "hot_weaponactive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 14,
		anim = "Buff",
		vfx = "Aura",
		hotHps = 6,
		hotDuration = 5,
	},
	fortify_weaponactive = {
		id = "fortify_weaponactive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 14,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "Fortify",
		selfBuffDuration = 4,
		selfBuffParams = { damageTakenMult = 0.9 },
	},
	frenzy_weaponactive = {
		id = "frenzy_weaponactive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 12,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "Frenzy",
		selfBuffDuration = 4,
		selfBuffParams = { damageDealtMult = 1.08 },
	},
	dash_weaponactive = {
		id = "dash_weaponactive",
		damagePct = 120,
		range = 10,
		shape = "Dash",
		cooldownSec = 8,
		anim = "Melee",
		vfx = "Dash",
	},
	fan_of_knives_weaponactive = {
		id = "fan_of_knives_weaponactive",
		damagePct = 55,
		range = 14,
		coneDeg = 75,
		shape = "Cone",
		hitCount = 3,
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Cone",
	},
	gale_volley_weaponactive = {
		id = "gale_volley_weaponactive",
		damagePct = 50,
		range = 30,
		coneDeg = 40,
		shape = "Cone",
		hitCount = 3,
		cooldownSec = 11,
		anim = "Bow",
		vfx = "Cone",
	},
	pierce_bolt_weaponactive = {
		id = "pierce_bolt_weaponactive",
		damagePct = 100,
		range = 34,
		lineWidth = 3.5,
		shape = "Line",
		cooldownSec = 12,
		anim = "Bow",
		vfx = "Bolt",
	},
	-- Armor actives (ArmorAbilityDefs)
	helm_pulse_armoractive = {
		id = "helm_pulse_armoractive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 14,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "HelmPulse",
		selfBuffDuration = 6,
		selfBuffParams = { charges = 2 },
	},
	hand_touch_armoractive = {
		id = "hand_touch_armoractive",
		damagePct = 120,
		range = 6,
		shape = "Single",
		cooldownSec = 11,
		anim = "Melee",
		vfx = "Slash",
	},
	charger_armoractive = {
		id = "charger_armoractive",
		damagePct = 115,
		range = 9,
		shape = "Dash",
		cooldownSec = 9,
		anim = "Melee",
		vfx = "Dash",
		chargeStuds = 10,
	},
	disengage_armoractive = {
		id = "disengage_armoractive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Dash",
		retreatStuds = 10,
		selfBuff = "CcImmunity",
		selfBuffDuration = 1.2,
	},
	crushing_palm_armoractive = {
		id = "crushing_palm_armoractive",
		damagePct = 170,
		range = 7,
		shape = "Single",
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Slash",
	},
	nova_burst_armoractive = {
		id = "nova_burst_armoractive",
		damagePct = 100,
		range = 9,
		radius = 9,
		shape = "Sphere",
		cooldownSec = 12,
		anim = "Cast",
		vfx = "Burst",
	},
	shove_palm_armoractive = {
		id = "shove_palm_armoractive",
		damagePct = 85,
		range = 6,
		shape = "Single",
		cooldownSec = 9,
		anim = "Melee",
		vfx = "Slash",
		knockbackStuds = 11,
	},
	fan_volley_armoractive = {
		id = "fan_volley_armoractive",
		damagePct = 55,
		range = 14,
		coneDeg = 70,
		shape = "Cone",
		hitCount = 3,
		cooldownSec = 10,
		anim = "Melee",
		vfx = "Cone",
	},
	arc_bolt_armoractive = {
		id = "arc_bolt_armoractive",
		damagePct = 135,
		range = 26,
		shape = "Single",
		cooldownSec = 9,
		anim = "Cast",
		vfx = "Bolt",
	},
	war_frenzy_armoractive = {
		id = "war_frenzy_armoractive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 14,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "Frenzy",
		selfBuffDuration = 4,
		selfBuffParams = { damageDealtMult = 1.08 },
	},
	lifewave_armoractive = {
		id = "lifewave_armoractive",
		damagePct = 0,
		range = 16,
		coneDeg = 55,
		shape = "AllyCone",
		cooldownSec = 12,
		anim = "Cast",
		vfx = "Cone",
		healBase = 38,
	},
	mend_touch_armoractive = {
		id = "mend_touch_armoractive",
		damagePct = 0,
		range = 18,
		shape = "AllySingle",
		cooldownSec = 10,
		anim = "Cast",
		vfx = "Aura",
		healBase = 55,
	},
	riposte_bash_armoractive = {
		id = "riposte_bash_armoractive",
		damagePct = 125,
		range = 7,
		shape = "Single",
		cooldownSec = 7,
		anim = "Melee",
		vfx = "Slash",
	},
	shield_ram_armoractive = {
		id = "shield_ram_armoractive",
		damagePct = 105,
		range = 9,
		shape = "Dash",
		cooldownSec = 11,
		anim = "Melee",
		vfx = "Dash",
		chargeStuds = 8,
		knockbackStuds = 10,
	},
	bulwark_wall_armoractive = {
		id = "bulwark_wall_armoractive",
		damagePct = 0,
		range = 0,
		shape = "Self",
		cooldownSec = 16,
		anim = "Buff",
		vfx = "Aura",
		selfBuff = "Fortify",
		selfBuffDuration = 5,
		selfBuffParams = { damageTakenMult = 0.85 },
	},
	fish_net_focusactive = {
		id = "fish_net_focusactive",
		damagePct = 0,
		range = 22,
		radius = 8,
		shape = "GroundSphere",
		cooldownSec = 14,
		anim = "Cast",
		vfx = "Burst",
		statusId = "Root",
		statusDuration = 2.5,
	},
	grapple_hook_focusactive = {
		id = "grapple_hook_focusactive",
		damagePct = 0,
		range = 26,
		radius = 4.5,
		shape = "Grapple",
		cooldownSec = 11,
		anim = "Cast",
		vfx = "Dash",
		grapplePullDistance = 3.5,
	},
	smoke_bomb_focusactive = {
		id = "smoke_bomb_focusactive",
		damagePct = 0,
		range = 20,
		radius = 9,
		shape = "GroundSphere",
		cooldownSec = 13,
		anim = "Cast",
		vfx = "Burst",
		statusId = "Slow",
		statusDuration = 4,
		statusParams = { slowPct = 55 },
	},
	healing_idol_focusactive = {
		id = "healing_idol_focusactive",
		damagePct = 0,
		range = 18,
		radius = 10,
		shape = "AllySphere",
		cooldownSec = 16,
		anim = "Cast",
		vfx = "Aura",
		healBase = 32,
		hotHps = 7,
		hotDuration = 4,
	},
}

local ARMOR_ELEMENT_ACTIVES: { [string]: boolean } = {
	hand_touch_armoractive = true,
	charger_armoractive = true,
	crushing_palm_armoractive = true,
	nova_burst_armoractive = true,
	shove_palm_armoractive = true,
	fan_volley_armoractive = true,
	arc_bolt_armoractive = true,
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

local function statusFromElement(el: string): (string?, number?, number?)
	local sig = ElementData.Signature[el]
	local statusId = sig and sig.id or nil
	local statusDuration = if el == "Lightning" then 0.5 elseif el == "Steel" then 8 elseif el == "Poison" then 5 elseif el == "Water" then 5 elseif el == "Wind" then 3 elseif el == "Rock" then 2 elseif el == "Fire" then 3 else nil
	local statusDps = if el == "Steel" then 4 elseif el == "Poison" then 3 elseif el == "Fire" then 7 else nil
	return statusId, statusDuration, statusDps
end

function AbilityRuntime.Get(abilityId: string, fallbackElement: string?, fallbackCd: number?): AbilitySpec
	if WeaponActiveDefs.UsesGemElement(abilityId) then
		local base = SPECS[abilityId]
		if base then
			local el = fallbackElement or "Neutral"
			local out = table.clone(base)
			out.statusId, out.statusDuration, out.statusDps = statusFromElement(el)
			if fallbackCd then
				out.cooldownSec = fallbackCd
			end
			return out
		end
	end

	-- Armor actives inherit element from the equipped armor piece.
	if ARMOR_ELEMENT_ACTIVES[abilityId] then
		local base = SPECS[abilityId]
		if base then
			local out = table.clone(base)
			out.statusId, out.statusDuration, out.statusDps = statusFromElement(fallbackElement or "Neutral")
			if fallbackCd then
				out.cooldownSec = fallbackCd
			end
			return out
		end
	end

	local spec = SPECS[abilityId]
	if spec then
		local out = table.clone(spec)
		if fallbackCd then
			out.cooldownSec = fallbackCd
		end
		return out
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
