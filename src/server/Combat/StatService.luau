--[[
	Player primary stats (server authoritative).
	DevTool can set freely (budget ignored in Studio).
]]

local StatConfig = require(game.ReplicatedStorage.Shared.Config.StatConfig)
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)

export type PrimaryStats = {
	level: number,
	STR: number,
	DEX: number,
	VIT: number,
	INT: number,
}

local StatService = {}

local byUser: { [number]: PrimaryStats } = {}

local function clampStat(n: number): number
	return math.clamp(math.floor(n), 1, 999)
end

function StatService.Ensure(userId: number): PrimaryStats
	if not byUser[userId] then
		byUser[userId] = StatConfig.DefaultAllocated(StatConfig.DefaultLevel)
	end
	return byUser[userId]
end

function StatService.Get(userId: number): PrimaryStats
	local s = StatService.Ensure(userId)
	return {
		level = s.level,
		STR = s.STR,
		DEX = s.DEX,
		VIT = s.VIT,
		INT = s.INT,
	}
end

function StatService.Set(userId: number, patch: { [string]: number }): PrimaryStats
	local s = StatService.Ensure(userId)
	if typeof(patch.level) == "number" then
		s.level = math.clamp(math.floor(patch.level), 1, StatConfig.MaxLevel)
	end
	for _, key in { "STR", "DEX", "VIT", "INT" } do
		local v = patch[key]
		if typeof(v) == "number" then
			s[key] = clampStat(v)
		end
	end
	return StatService.Get(userId)
end

function StatService.Reset(userId: number, level: number?): PrimaryStats
	byUser[userId] = StatConfig.DefaultAllocated(level or StatConfig.DefaultLevel)
	return StatService.Get(userId)
end

function StatService.Derived(userId: number): { hp: number, stamina: number, defenceFromVit: number, resistFromVit: number }
	local s = StatService.Ensure(userId)
	return {
		hp = CombatConfig.BaseHp + s.VIT * CombatConfig.KVitHp,
		stamina = CombatConfig.BaseStam + s.VIT * CombatConfig.KVitStam,
		defenceFromVit = s.VIT * CombatConfig.KVitDef,
		resistFromVit = s.VIT * CombatConfig.KVitRes,
	}
end

function StatService.Clear(userId: number)
	byUser[userId] = nil
end

return StatService
