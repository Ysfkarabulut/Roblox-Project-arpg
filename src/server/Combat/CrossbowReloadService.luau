--[[
	Crossbow L3 finisher → mandatory reload (GDD §7). Blocks LA + weapon actives.
]]

local CrossbowReloadService = {}

local reloadUntil: { [number]: number } = {}

function CrossbowReloadService.IsReloading(userId: number): boolean
	return os.clock() < (reloadUntil[userId] or 0)
end

function CrossbowReloadService.GetRemaining(userId: number): number
	return math.max(0, (reloadUntil[userId] or 0) - os.clock())
end

function CrossbowReloadService.Start(userId: number, duration: number)
	reloadUntil[userId] = os.clock() + duration
end

function CrossbowReloadService.Clear(userId: number)
	reloadUntil[userId] = nil
end

return CrossbowReloadService
