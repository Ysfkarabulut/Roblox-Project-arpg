--[[
	Data-driven ability combat params (proto).
	ItemDefs desc is flavor; this table drives cast / damage / status / FX.
	Unknown abilityId → safe defaults from source item element.
]]

local ElementData = require(script.Parent.ElementData)
local WeaponActiveDefs = require(script.Parent.WeaponActiveDefs)

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
	dash_weaponactive = {
		id = "dash_weaponactive",
		damagePct = 120,
		range = 10,
		shape = "Dash",
		cooldownSec = 8,
		anim = "Melee",
		vfx = "Dash",
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
		selfBuff = "Fortify",
		selfBuffDuration = 4,
		selfBuffParams = { damageDealtMult = 1.08 },
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

	-- Armor touch inherits element from the armor piece
	if abilityId == "hand_touch_armoractive" then
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
