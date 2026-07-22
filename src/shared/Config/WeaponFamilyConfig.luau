--[[
	Weapon family → LA range, anim key, visual preset, L3 perk.
]]

local CombatConfig = require(script.Parent.CombatConfig)
local DamagePipeline = require(script.Parent.Parent.Combat.DamagePipeline)

local WeaponFamilyConfig = {}

export type FamilyInfo = {
	key: string,
	animPrefix: string, -- Sword1H, Axe2H, Bow, ...
	laRange: number,
	laShape: "Melee" | "Projectile" | "Cone",
	coneDeg: number?,
	hand: "Right" | "Left",
	l3Perk: (kind: string?, is2H: boolean?) -> number,
}

local function measured(is2H: boolean?): number
	return if is2H then CombatConfig.MeasuredStrike2H else CombatConfig.MeasuredStrike1H
end

WeaponFamilyConfig.ByFamily = {
	Sword = {
		key = "Sword",
		animPrefix = "Sword",
		laRange = 7,
		laShape = "Melee",
		hand = "Right",
		l3Perk = function(_k, is2H)
			return measured(is2H)
		end,
	},
	Axe = {
		key = "Axe",
		animPrefix = "Axe",
		laRange = 7,
		laShape = "Melee",
		hand = "Right",
		l3Perk = function()
			return 1
		end,
	},
	Mace = {
		key = "Mace",
		animPrefix = "Mace",
		laRange = 6.5,
		laShape = "Melee",
		hand = "Right",
		l3Perk = function()
			return 1
		end,
	},
	Dagger = {
		key = "Dagger",
		animPrefix = "Dagger",
		laRange = 5.5,
		laShape = "Melee",
		hand = "Right",
		l3Perk = function()
			return 1
		end,
	},
	Wand = {
		key = "Wand",
		animPrefix = "Wand",
		laRange = 22,
		laShape = "Projectile",
		hand = "Right",
		l3Perk = function()
			return CombatConfig.ArcBoltL3
		end,
	},
	Scepter = {
		key = "Scepter",
		animPrefix = "Scepter",
		laRange = 16,
		laShape = "Cone",
		coneDeg = 45,
		hand = "Right",
		l3Perk = function()
			return CombatConfig.RadiantSweepL3
		end,
	},
	Staff = {
		key = "Staff",
		animPrefix = "Staff",
		laRange = 30,
		laShape = "Projectile",
		hand = "Right",
		l3Perk = function()
			return CombatConfig.EmpoweredBoltL3
		end,
	},
	Bow = {
		key = "Bow",
		animPrefix = "Bow",
		laRange = 40,
		laShape = "Projectile",
		hand = "Left",
		l3Perk = function()
			return CombatConfig.FocusedShotL3
		end,
	},
	Crossbow = {
		key = "Crossbow",
		animPrefix = "Crossbow",
		laRange = 35,
		laShape = "Projectile",
		hand = "Right",
		l3Perk = function()
			return CombatConfig.CrossbowL3
		end,
	},
} :: { [string]: FamilyInfo }

function WeaponFamilyConfig.Resolve(def: any): FamilyInfo
	local fam = def and def.family
	if fam and WeaponFamilyConfig.ByFamily[fam] then
		local info = WeaponFamilyConfig.ByFamily[fam]
		-- 2H sword/axe/mace share family name — detect kind
		if fam == "Sword" or fam == "Axe" or fam == "Mace" then
			local is2H = def.kind == "Weapon2H"
			return {
				key = info.key,
				animPrefix = fam .. (if is2H then "2H" else "1H"),
				laRange = if is2H then info.laRange + 1.5 else info.laRange,
				laShape = info.laShape,
				coneDeg = info.coneDeg,
				hand = info.hand,
				l3Perk = info.l3Perk,
			}
		end
		return info
	end
	-- Fallback by kind
	if def and def.kind == "Bow" then
		return WeaponFamilyConfig.ByFamily.Bow
	elseif def and def.kind == "Crossbow" then
		return WeaponFamilyConfig.ByFamily.Crossbow
	elseif def and def.kind == "Staff" then
		return WeaponFamilyConfig.ByFamily.Staff
	elseif def and def.kind == "Wand" then
		return WeaponFamilyConfig.ByFamily.Wand
	elseif def and def.kind == "Scepter" then
		return WeaponFamilyConfig.ByFamily.Scepter
	end
	return WeaponFamilyConfig.ByFamily.Sword
end

function WeaponFamilyConfig.L3PerkMult(def: any, step: number): number
	if step ~= 3 then
		return 1
	end
	local info = WeaponFamilyConfig.Resolve(def)
	local is2H = def and def.kind == "Weapon2H"
	return info.l3Perk(def and def.kind, is2H)
end

--- Effective attack speed mult including pommel (modular weapons)
function WeaponFamilyConfig.AttackSpeedMult(def: any, dex: number): number
	local tier = def and def.asTier or "B"
	local base = DamagePipeline.AttackSpeedMult(tier, dex)
	local pommelMult = def and def.attackSpeedMult or 1
	return base * pommelMult
end

return WeaponFamilyConfig
