--[[
	Merge per-boss PvE leaderboard rows into unified kill / speed lists.
	Speed: rank by party run (same clear); every member shares that run's placement.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossEncounterConfig = require(ReplicatedStorage.Shared.Config.BossEncounterConfig)

local LeaderboardPveMerge = {}

export type BoardDef = {
	id: string,
	displayName: string,
	kind: string,
	bossId: string?,
}

export type RawEntry = {
	userId: number?,
	displayName: string,
	score: number,
	killCount: number?,
	clearMs: number?,
	clearTimeText: string?,
	partySize: number?,
	memberNames: { string }?,
	memberUserIds: { number }?,
}

export type MergedEntry = {
	rank: number,
	userId: number?,
	displayName: string,
	bossName: string,
	bossId: string?,
	score: number,
	killCount: number?,
	clearMs: number?,
	clearTimeText: string?,
	boardId: string,
}

type RunMember = {
	userId: number?,
	displayName: string,
}

type SpeedRun = {
	bossName: string,
	bossId: string?,
	boardId: string,
	clearMs: number,
	clearTimeText: string?,
	score: number,
	members: { RunMember },
}

function LeaderboardPveMerge.BossName(board: BoardDef): string
	if board.bossId then
		local def = BossEncounterConfig.Get(board.bossId)
		if def and def.displayName then
			return def.displayName
		end
	end
	local parts = string.split(board.displayName, " — ")
	return parts[1] or board.displayName
end

function LeaderboardPveMerge.FormatRow(entry: MergedEntry, kind: string): string
	if kind == "boss_kills" then
		local kills = math.floor(entry.killCount or entry.score)
		return `{entry.displayName} > {entry.bossName} > {kills}`
	end
	local timeText = entry.clearTimeText or "—"
	return `{entry.displayName} > {entry.bossName} > {timeText}`
end

local function sortedIdKey(ids: { number }): string
	local copy = table.clone(ids)
	table.sort(copy)
	local parts: { string } = {}
	for _, id in copy do
		table.insert(parts, tostring(id))
	end
	return table.concat(parts, ",")
end

local function runKey(bossKey: string, clearMs: number, memberUserIds: { number }): string
	return `{bossKey}:{clearMs}:{sortedIdKey(memberUserIds)}`
end

local function membersFromEntry(entry: RawEntry): { RunMember }
	local partySize = entry.partySize or 1
	local userIds = entry.memberUserIds
	local names = entry.memberNames

	if typeof(userIds) == "table" and #userIds > 0 and partySize > 1 then
		local members: { RunMember } = {}
		for i, uid in userIds do
			local name = if typeof(names) == "table" and names[i] then names[i] else `Player{uid}`
			table.insert(members, { userId = uid, displayName = name })
		end
		return members
	end

	return {
		{
			userId = entry.userId,
			displayName = entry.displayName,
		},
	}
end

local function memberUserIdsForRun(members: { RunMember }): { number }
	local ids: { number } = {}
	for _, member in members do
		if member.userId then
			table.insert(ids, member.userId)
		end
	end
	if #ids == 0 then
		table.insert(ids, 0)
	end
	return ids
end

local function collectSpeedRuns(
	boards: { BoardDef },
	entriesByBoardId: { [string]: { RawEntry } }
): { SpeedRun }
	local runsByKey: { [string]: SpeedRun } = {}

	for _, board in boards do
		if board.kind ~= "boss_speed" then
			continue
		end
		local bossName = LeaderboardPveMerge.BossName(board)
		local bossKey = board.bossId or board.id

		for _, entry in entriesByBoardId[board.id] or {} do
			local clearMs = entry.clearMs or entry.score
			local members = membersFromEntry(entry)
			local key = runKey(bossKey, clearMs, memberUserIdsForRun(members))
			if runsByKey[key] then
				continue
			end
			runsByKey[key] = {
				bossName = bossName,
				bossId = board.bossId,
				boardId = board.id,
				clearMs = clearMs,
				clearTimeText = entry.clearTimeText,
				score = entry.score,
				members = members,
			}
		end
	end

	local runs: { SpeedRun } = {}
	for _, run in runsByKey do
		table.insert(runs, run)
	end
	table.sort(runs, function(a, b)
		return a.clearMs < b.clearMs
	end)
	return runs
end

local function mergeSpeed(
	boards: { BoardDef },
	entriesByBoardId: { [string]: { RawEntry } },
	partyRankLimit: number,
	rowLimit: number?
): { MergedEntry }
	local runs = collectSpeedRuns(boards, entriesByBoardId)
	local out: { MergedEntry } = {}

	for partyRank, run in runs do
		if partyRank > partyRankLimit then
			break
		end
		for _, member in run.members do
			if rowLimit and #out >= rowLimit then
				return out
			end
			table.insert(out, {
				rank = partyRank,
				userId = member.userId,
				displayName = member.displayName,
				bossName = run.bossName,
				bossId = run.bossId,
				score = run.score,
				clearMs = run.clearMs,
				clearTimeText = run.clearTimeText,
				boardId = run.boardId,
			})
		end
	end

	return out
end

local function mergeKills(
	boards: { BoardDef },
	entriesByBoardId: { [string]: { RawEntry } },
	limit: number
): { MergedEntry }
	local merged: { MergedEntry } = {}
	local seen: { [string]: boolean } = {}

	for _, board in boards do
		if board.kind ~= "boss_kills" then
			continue
		end
		local bossName = LeaderboardPveMerge.BossName(board)
		local bossKey = board.bossId or board.id

		for _, entry in entriesByBoardId[board.id] or {} do
			local key = `{bossKey}:{entry.userId or entry.displayName}:{entry.killCount or entry.score}`
			if seen[key] then
				continue
			end
			seen[key] = true
			table.insert(merged, {
				rank = 0,
				userId = entry.userId,
				displayName = entry.displayName,
				bossName = bossName,
				bossId = board.bossId,
				score = entry.score,
				killCount = entry.killCount,
				clearMs = entry.clearMs,
				clearTimeText = entry.clearTimeText,
				boardId = board.id,
			})
		end
	end

	table.sort(merged, function(a, b)
		return (a.killCount or a.score) > (b.killCount or b.score)
	end)

	local out: { MergedEntry } = {}
	for i = 1, math.min(limit, #merged) do
		local row = merged[i]
		row.rank = i
		table.insert(out, row)
	end
	return out
end

-- limit: kills = row count; speed = max party placement (rewards use top 100).
-- rowLimit: speed only — cap rows shown on wall/UI.
function LeaderboardPveMerge.Merge(
	boards: { BoardDef },
	entriesByBoardId: { [string]: { RawEntry } },
	kind: string,
	limit: number,
	rowLimit: number?
): { MergedEntry }
	if kind == "boss_speed" then
		return mergeSpeed(boards, entriesByBoardId, limit, rowLimit)
	end
	return mergeKills(boards, entriesByBoardId, limit)
end

function LeaderboardPveMerge.FilterBoards(boards: { BoardDef }, kind: string): { BoardDef }
	local out: { BoardDef } = {}
	for _, board in boards do
		if board.kind == kind then
			table.insert(out, board)
		end
	end
	return out
end

function LeaderboardPveMerge.BoardsFromSeason(): { BoardDef }
	local SeasonConfig = require(ReplicatedStorage.Shared.Config.SeasonConfig)
	local out: { BoardDef } = {}
	for _, def in SeasonConfig.Leaderboards do
		if def.kind == "boss_kills" or def.kind == "boss_speed" then
			table.insert(out, {
				id = def.id,
				displayName = def.displayName,
				kind = def.kind,
				bossId = def.bossId,
			})
		end
	end
	return out
end

export type PartyGroup = {
	rank: number,
	bossName: string,
	bossId: string?,
	clearTimeText: string?,
	killCount: number?,
	members: { { userId: number?, displayName: string } },
}

function LeaderboardPveMerge.GroupByPartyRank(entries: { MergedEntry }): { PartyGroup }
	local byRank: { [number]: PartyGroup } = {}
	local order: { number } = {}

	for _, entry in entries do
		local partyRank = entry.rank
		local group = byRank[partyRank]
		if not group then
			group = {
				rank = partyRank,
				bossName = entry.bossName,
				bossId = entry.bossId,
				clearTimeText = entry.clearTimeText,
				killCount = entry.killCount,
				members = {},
			}
			byRank[partyRank] = group
			table.insert(order, partyRank)
		end
		table.insert(group.members, {
			userId = entry.userId,
			displayName = entry.displayName,
		})
	end

	table.sort(order)
	local out: { PartyGroup } = {}
	for _, partyRank in order do
		table.insert(out, byRank[partyRank])
	end
	return out
end

return LeaderboardPveMerge
