--[[
	XP curve — GDD §10 playtest defaults (level cap 50).
]]

local StatConfig = require(script.Parent.StatConfig)

local XpConfig = {}

--- XP required to advance from `level` to `level + 1`.
function XpConfig.XpRequiredForNextLevel(level: number): number
	local lv = math.clamp(math.floor(level), 1, StatConfig.MaxLevel)
	if lv >= StatConfig.MaxLevel then
		return 0
	end
	return 100 + (lv - 1) * 40
end

--- Total XP at the start of `level` (level 1 = 0).
function XpConfig.TotalXpForLevel(level: number): number
	local lv = math.clamp(math.floor(level), 1, StatConfig.MaxLevel)
	local total = 0
	for i = 1, lv - 1 do
		total += XpConfig.XpRequiredForNextLevel(i)
	end
	return total
end

export type XpProgress = {
	totalXp: number,
	level: number,
	xpIntoLevel: number,
	xpToNext: number,
}

function XpConfig.ProgressFromTotalXp(totalXp: number, level: number): XpProgress
	local xp = math.max(0, math.floor(totalXp))
	local lv = math.clamp(math.floor(level), 1, StatConfig.MaxLevel)
	local xpAtLevel = XpConfig.TotalXpForLevel(lv)
	local xpIntoLevel = xp - xpAtLevel
	local xpToNext = XpConfig.XpRequiredForNextLevel(lv)
	if lv >= StatConfig.MaxLevel then
		xpIntoLevel = 0
		xpToNext = 0
	else
		xpIntoLevel = math.clamp(xpIntoLevel, 0, math.max(xpToNext, 1))
	end
	return {
		totalXp = xp,
		level = lv,
		xpIntoLevel = xpIntoLevel,
		xpToNext = xpToNext,
	}
end

return XpConfig
