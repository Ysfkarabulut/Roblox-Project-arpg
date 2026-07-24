--[[
	Career / character stats helpers.
]]

local CareerConfig = {}

function CareerConfig.FormatPlaytime(playtimeSec: number): string
	local total = math.max(0, math.floor(playtimeSec))
	local hours = math.floor(total / 3600)
	local minutes = math.floor((total % 3600) / 60)
	if hours > 0 then
		return `{hours}h {minutes}m`
	end
	return `{minutes}m`
end

function CareerConfig.KdRatio(kills: number, deaths: number): number
	if deaths <= 0 then
		return if kills > 0 then kills else 0
	end
	return math.floor((kills / deaths) * 100 + 0.5) / 100
end

function CareerConfig.FormatClearTime(clearMs: number): string
	local ms = math.max(0, math.floor(clearMs))
	local totalSec = ms / 1000
	local minutes = math.floor(totalSec / 60)
	local sec = totalSec - minutes * 60
	if minutes > 0 then
		return string.format("%d:%05.2f", minutes, sec)
	end
	return string.format("%.2fs", totalSec)
end

return CareerConfig
