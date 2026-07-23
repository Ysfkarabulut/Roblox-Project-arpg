--[[
	Shared pressure / CC category helpers.
]]

local PressureTypes = {}

PressureTypes.HARD_CC = {
	Shock = true,
	Stun = true,
	Chilled = true,
	Knockback = true,
}

PressureTypes.PRESSURE_CC = {
	Hitstun = true,
}

function PressureTypes.IsHardCc(statusId: string): boolean
	return PressureTypes.HARD_CC[statusId] == true
end

function PressureTypes.IsInterruptCc(statusId: string): boolean
	return PressureTypes.HARD_CC[statusId] == true or PressureTypes.PRESSURE_CC[statusId] == true
end

return PressureTypes
