--[[
	OrderedDataStore leaderboards — one store per season + board.
	Boss boards: ascending (lowest clear time wins). MMR: descending.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local SeasonConfig = require(game.ReplicatedStorage.Shared.Config.SeasonConfig)
local CareerConfig = require(game.ReplicatedStorage.Shared.Config.CareerConfig)
local LeaderboardPveMerge = require(game.ReplicatedStorage.Shared.Meta.LeaderboardPveMerge)

local LeaderboardService = {}

local ORDERED_PREFIX = "ARPG_LB_v1"
local META_STORE_NAME = "ARPG_LBMeta_v1"
local storeCache: { [string]: OrderedDataStore } = {}
local lastScoreCache: { [string]: number } = {}
local metaStore = DataStoreService:GetDataStore(META_STORE_NAME)

export type RunMeta = {
	clearMs: number,
	partySize: number,
	memberUserIds: { number },
	memberNames: { string },
}

export type LeaderboardEntry = {
	rank: number,
	userId: number,
	score: number,
	displayName: string,
	clearMs: number?,
	clearTimeText: string?,
	killCount: number?,
	partySize: number?,
	memberNames: { string }?,
	memberUserIds: { number }?,
}

local function storeName(seasonId: string, boardId: string): string
	return `{ORDERED_PREFIX}_{seasonId}_{boardId}`
end

local function metaKey(seasonId: string, boardId: string, userId: number): string
	return `{seasonId}_{boardId}_{userId}`
end

local function getStore(seasonId: string, boardId: string): OrderedDataStore
	local name = storeName(seasonId, boardId)
	local cached = storeCache[name]
	if cached then
		return cached
	end
	local store = DataStoreService:GetOrderedDataStore(name)
	storeCache[name] = store
	return store
end

local function isAscending(boardId: string): boolean
	return SeasonConfig.IsAscendingBoard(boardId)
end

function LeaderboardService.SetRunMeta(seasonId: string, boardId: string, userId: number, meta: RunMeta)
	pcall(function()
		metaStore:SetAsync(metaKey(seasonId, boardId, userId), meta)
	end)
end

function LeaderboardService.GetRunMeta(seasonId: string, boardId: string, userId: number): RunMeta?
	local ok, data = pcall(function()
		return metaStore:GetAsync(metaKey(seasonId, boardId, userId))
	end)
	if ok and typeof(data) == "table" and typeof(data.clearMs) == "number" then
		return data :: RunMeta
	end
	return nil
end

function LeaderboardService.UpdateScore(seasonId: string, boardId: string, userId: number, score: number)
	if typeof(seasonId) ~= "string" or typeof(boardId) ~= "string" then
		return
	end
	score = math.floor(score)
	if score < 0 then
		return
	end
	local cacheKey = `{seasonId}:{boardId}:{userId}`
	if lastScoreCache[cacheKey] == score then
		return
	end
	local store = getStore(seasonId, boardId)
	local ok = pcall(function()
		store:SetAsync(tostring(userId), score)
	end)
	if ok then
		lastScoreCache[cacheKey] = score
	end
end

function LeaderboardService.UpdateBestTime(
	seasonId: string,
	boardId: string,
	userId: number,
	clearMs: number,
	meta: RunMeta
): boolean
	clearMs = math.max(1, math.floor(clearMs))
	local store = getStore(seasonId, boardId)
	local okRead, existing = pcall(function()
		return store:GetAsync(tostring(userId))
	end)
	if okRead and typeof(existing) == "number" and clearMs >= existing then
		return false
	end
	LeaderboardService.UpdateScore(seasonId, boardId, userId, clearMs)
	LeaderboardService.SetRunMeta(seasonId, boardId, userId, meta)
	return true
end

function LeaderboardService.GetTop(seasonId: string, boardId: string, limit: number?): { LeaderboardEntry }
	local pageSize = math.clamp(limit or SeasonConfig.LeaderboardPageSize, 1, SeasonConfig.LeaderboardUiMax)
	local store = getStore(seasonId, boardId)
	local ascending = isAscending(boardId)
	local board = SeasonConfig.GetLeaderboard(boardId)
	local entries: { LeaderboardEntry } = {}
	local ok, pages = pcall(function()
		return store:GetSortedAsync(ascending, pageSize)
	end)
	if not ok or not pages then
		return entries
	end
	local page = pages:GetCurrentPage()
	for rank, item in page do
		local uid = tonumber(item.key)
		if uid then
			local plr = Players:GetPlayerByUserId(uid)
			local meta = if board and board.kind == "boss_speed"
				then LeaderboardService.GetRunMeta(seasonId, boardId, uid)
				else nil
			local clearMs = if board and board.kind == "boss_speed" then item.value else nil
			local killCount = if board and board.kind == "boss_kills" then item.value else nil
			table.insert(entries, {
				rank = rank,
				userId = uid,
				score = item.value,
				displayName = if plr then plr.Name else `Player{uid}`,
				clearMs = clearMs,
				clearTimeText = if clearMs then CareerConfig.FormatClearTime(clearMs) else nil,
				killCount = if killCount then math.floor(killCount) else nil,
				partySize = if meta then meta.partySize else nil,
				memberNames = if meta then meta.memberNames else nil,
				memberUserIds = if meta then meta.memberUserIds else nil,
			})
		end
	end
	return entries
end

function LeaderboardService.GetUserRank(seasonId: string, boardId: string, userId: number): number?
	local store = getStore(seasonId, boardId)
	local ascending = isAscending(boardId)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(ascending, math.min(SeasonConfig.MaxRankScan, 100))
	end)
	if not ok or not pages then
		return nil
	end
	local rank = 0
	while true do
		local page = pages:GetCurrentPage()
		for _, item in page do
			rank += 1
			if tonumber(item.key) == userId then
				return rank
			end
		end
		if rank >= SeasonConfig.MaxRankScan or pages.IsFinished then
			break
		end
		local advanced = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advanced then
			break
		end
	end
	return nil
end

local function entriesToRaw(entries: { LeaderboardEntry }): { LeaderboardPveMerge.RawEntry }
	local out: { LeaderboardPveMerge.RawEntry } = {}
	for _, entry in entries do
		table.insert(out, {
			userId = entry.userId,
			displayName = entry.displayName,
			score = entry.score,
			killCount = entry.killCount,
			clearMs = entry.clearMs,
			clearTimeText = entry.clearTimeText,
			partySize = entry.partySize,
			memberNames = entry.memberNames,
			memberUserIds = entry.memberUserIds,
		})
	end
	return out
end

function LeaderboardService.GetMergedPveTop(seasonId: string, kind: string, limit: number?): { LeaderboardPveMerge.MergedEntry }
	local boards = LeaderboardPveMerge.FilterBoards(LeaderboardPveMerge.BoardsFromSeason(), kind)
	local fetchLimit = SeasonConfig.LeaderboardUiMax
	local byBoard: { [string]: { LeaderboardPveMerge.RawEntry } } = {}
	for _, board in boards do
		byBoard[board.id] = entriesToRaw(LeaderboardService.GetTop(seasonId, board.id, fetchLimit))
	end
	return LeaderboardPveMerge.Merge(boards, byBoard, kind, limit or SeasonConfig.LeaderboardUiMax, nil)
end

function LeaderboardService.GetMergedPveUserRank(seasonId: string, kind: string, userId: number): number?
	local entries = LeaderboardService.GetMergedPveTop(seasonId, kind, SeasonConfig.LeaderboardUiMax)
	for _, entry in entries do
		if entry.userId == userId then
			return entry.rank
		end
	end
	return nil
end

function LeaderboardService.BuildBoardList()
	local season = SeasonConfig.GetCurrentSeason()
	local boards = {}
	for _, def in SeasonConfig.Leaderboards do
		table.insert(boards, {
			id = def.id,
			displayName = def.displayName,
			kind = def.kind,
			bossId = def.bossId,
			bracketKey = def.bracketKey,
			seasonId = season.id,
			seasonName = season.name,
		})
	end
	return boards
end

return LeaderboardService
