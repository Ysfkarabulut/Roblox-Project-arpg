--[[
	Loadout → combat stance (7 sprint / locomotion styles).
]]

local StanceConfig = {}

export type StanceId =
	"OneHandShield"
	| "OneHandFocus"
	| "DualWield"
	| "TwoHandMelee"
	| "Crossbow"
	| "Bow"
	| "Staff"

StanceConfig.List = {
	"OneHandShield",
	"OneHandFocus",
	"DualWield",
	"TwoHandMelee",
	"Crossbow",
	"Bow",
	"Staff",
} :: { StanceId }

local ONE_H_KINDS = {
	Weapon1H = true,
	Wand = true,
	Scepter = true,
}

function StanceConfig.Resolve(mainDef: any?, offDef: any?): StanceId
	if not mainDef then
		return "OneHandFocus"
	end
	local kind = mainDef.kind
	if kind == "Bow" then
		return "Bow"
	end
	if kind == "Crossbow" then
		return "Crossbow"
	end
	if kind == "Staff" then
		return "Staff"
	end
	if kind == "Weapon2H" then
		return "TwoHandMelee"
	end
	-- 1H family
	if ONE_H_KINDS[kind] then
		if offDef then
			if offDef.kind == "Shield" then
				return "OneHandShield"
			end
			if offDef.kind == "Focus" then
				return "OneHandFocus"
			end
			if ONE_H_KINDS[offDef.kind] then
				return "DualWield"
			end
		end
		return "OneHandFocus"
	end
	return "OneHandFocus"
end

return StanceConfig
