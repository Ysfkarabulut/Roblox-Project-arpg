--[[
	Primary stat defaults — COMBAT_STAT_SHEET §12.1
]]

local StatConfig = {
	BasePrimary = 10,
	PointsPerLevel = 4,
	MaxLevel = 50,
	-- Studio default: MVP test level
	DefaultLevel = 30,
}

function StatConfig.PointsAtLevel(level: number): number
	local lv = math.clamp(math.floor(level), 1, StatConfig.MaxLevel)
	return (lv - 1) * StatConfig.PointsPerLevel
end

--- Even split leftover for default profile (not required for DevTool free-edit)
function StatConfig.DefaultAllocated(level: number): { STR: number, DEX: number, VIT: number, INT: number, level: number }
	local base = StatConfig.BasePrimary
	local points = StatConfig.PointsAtLevel(level)
	local each = math.floor(points / 4)
	local rem = points - each * 4
	return {
		level = math.clamp(math.floor(level), 1, StatConfig.MaxLevel),
		STR = base + each + (if rem > 0 then 1 else 0),
		DEX = base + each + (if rem > 1 then 1 else 0),
		VIT = base + each + (if rem > 2 then 1 else 0),
		INT = base + each,
	}
end

return StatConfig
