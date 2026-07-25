--[[
	Process match win/loss → Gacha + boss-exclusive rolls.
]]

local LootTables = require(game.ReplicatedStorage.Shared.Config.LootTables)
local LootService = require(script.Parent.LootService)
local BossProgressService = require(script.Parent.Parent.Meta.BossProgressService)
local CareerService = require(script.Parent.Parent.Meta.CareerService)

local MatchResultService = {}

export type MatchResult = {
	mode: "PvP" | "PvE",
	won: boolean,
	bossId: string?,
	queueId: string?,
	mmrDelta: number?,
	mmr: number?,
	mmrTier: string?,
	clearMs: number?,
	clearTimeText: string?,
}

export type ProcessOutput = {
	ok: boolean,
	reason: string?,
	xpGained: number,
	gachaGranted: LootService.GrantedItem?,
	bossGranted: LootService.GrantedItem?,
	bossKillCount: number?,
	firstBossClear: boolean?,
}

function MatchResultService.Process(userId: number, result: MatchResult): ProcessOutput
	if typeof(result) ~= "table" or typeof(result.mode) ~= "string" then
		return { ok = false, reason = "BadPayload", xpGained = 0 }
	end
	if result.mode ~= "PvP" and result.mode ~= "PvE" then
		return { ok = false, reason = "BadMode", xpGained = 0 }
	end
	if not result.won then
		return { ok = true, xpGained = 0 }
	end

	local source = result.mode :: LootTables.LootSource
	local out: ProcessOutput = {
		ok = true,
		xpGained = LootTables.XpForResult(source, true),
	}

	if LootTables.ShouldRollGacha(source) then
		local boxId = LootTables.RollGachaLootBox(source)
		if boxId then
			out.gachaGranted = LootService.GrantDefId(userId, boxId, "GachaBox")
		end
	end

	if source == "PvE" and result.bossId then
		local bossId = result.bossId
		local firstClear = BossProgressService.GetKills(userId, bossId) == 0
		local rollBoss = firstClear or LootTables.ShouldRollBossExclusive(source)
		if rollBoss then
			local boxId = LootService.BossLootBoxId(bossId)
			if boxId then
				out.bossGranted = LootService.GrantDefId(userId, boxId, "BossLootBox")
			end
		end
		local killCount = BossProgressService.RecordKill(userId, bossId)
		CareerService.RecordBossKill(userId, bossId)
		out.bossKillCount = killCount
		out.firstBossClear = firstClear
	end

	return out
end

return MatchResultService
