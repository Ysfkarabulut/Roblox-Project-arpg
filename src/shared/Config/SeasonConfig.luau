--[[
	Seasons, leaderboard boards, and rank reward tiers.
	Tweak dates / rewards here before each season.
]]

export type SeasonDef = {
	id: string,
	name: string,
	startUnix: number,
	endUnix: number,
}

export type LeaderboardDef = {
	id: string,
	displayName: string,
	kind: "boss_kills" | "boss_speed" | "mmr",
	bossId: string?,
	bracketKey: string?,
}

export type RewardTier = {
	rankMin: number,
	rankMax: number,
	premium: number?,
	title: string?,
}

local SeasonConfig = {}

-- Unix timestamps (UTC). Season 1 spans mid-2026 for playtest.
SeasonConfig.Seasons = {
	{
		id = "2026-S1",
		name = "Season 1",
		startUnix = 1767225600, -- 2026-01-01 UTC
		endUnix = 1798761600, -- 2027-01-01 UTC
	},
} :: { SeasonDef }

SeasonConfig.Leaderboards = {
	{ id = "boss_eye_kills", displayName = "The Eye — Most Kills", kind = "boss_kills", bossId = "eye" },
	{ id = "boss_eye_speed", displayName = "The Eye — Fastest Clear", kind = "boss_speed", bossId = "eye" },
	{ id = "boss_breaker_kills", displayName = "The Breaker — Most Kills", kind = "boss_kills", bossId = "breaker" },
	{ id = "boss_breaker_speed", displayName = "The Breaker — Fastest Clear", kind = "boss_speed", bossId = "breaker" },
	{ id = "mmr_1v1", displayName = "1v1 Ranked MMR", kind = "mmr", bracketKey = "pvp_1v1" },
	{ id = "mmr_2v2", displayName = "2v2 Ranked MMR", kind = "mmr", bracketKey = "pvp_2v2" },
	{ id = "mmr_3v3", displayName = "3v3 Ranked MMR", kind = "mmr", bracketKey = "pvp_3v3" },
} :: { LeaderboardDef }

SeasonConfig.MergedPveRewardBoards = {
	{ id = "pve_kills", displayName = "PvE — Most Kills", kind = "boss_kills" },
	{ id = "pve_speed", displayName = "PvE — Fastest Clear", kind = "boss_speed" },
} :: { LeaderboardDef }

SeasonConfig.RewardTiers = {
	pve_kills = {
		{ rankMin = 1, rankMax = 1, premium = 75, title = "PvE Slayer" },
		{ rankMin = 2, rankMax = 3, premium = 75 },
		{ rankMin = 4, rankMax = 6, premium = 50 },
		{ rankMin = 7, rankMax = 10, premium = 35 },
	},
	pve_speed = {
		{ rankMin = 1, rankMax = 1, premium = 75, title = "PvE Speedrunner" },
		{ rankMin = 2, rankMax = 3, premium = 75 },
		{ rankMin = 4, rankMax = 6, premium = 50 },
		{ rankMin = 7, rankMax = 10, premium = 35 },
	},
	mmr_1v1 = {
		{ rankMin = 1, rankMax = 1, premium = 100, title = "Duel Champion" },
		{ rankMin = 2, rankMax = 3, premium = 100 },
		{ rankMin = 4, rankMax = 6, premium = 65 },
		{ rankMin = 7, rankMax = 10, premium = 45 },
	},
	mmr_2v2 = {
		{ rankMin = 1, rankMax = 1, premium = 100, title = "Skirmish Champion" },
		{ rankMin = 2, rankMax = 3, premium = 100 },
		{ rankMin = 4, rankMax = 6, premium = 65 },
		{ rankMin = 7, rankMax = 10, premium = 45 },
	},
	mmr_3v3 = {
		{ rankMin = 1, rankMax = 1, premium = 100, title = "Clash Champion" },
		{ rankMin = 2, rankMax = 3, premium = 100 },
		{ rankMin = 4, rankMax = 6, premium = 65 },
		{ rankMin = 7, rankMax = 10, premium = 45 },
	},
} :: { [string]: { RewardTier } }

SeasonConfig.LeaderboardPageSize = 25
SeasonConfig.LeaderboardWallRows = 10
SeasonConfig.LeaderboardUiMax = 100
SeasonConfig.MaxRankScan = 200

function SeasonConfig.Now(): number
	return os.time()
end

function SeasonConfig.GetSeason(seasonId: string): SeasonDef?
	for _, season in SeasonConfig.Seasons do
		if season.id == seasonId then
			return season
		end
	end
	return nil
end

function SeasonConfig.GetCurrentSeason(): SeasonDef
	local now = SeasonConfig.Now()
	for _, season in SeasonConfig.Seasons do
		if now >= season.startUnix and now < season.endUnix then
			return season
		end
	end
	return SeasonConfig.Seasons[#SeasonConfig.Seasons]
end

function SeasonConfig.GetCurrentSeasonId(): string
	return SeasonConfig.GetCurrentSeason().id
end

function SeasonConfig.GetEndedSeasons(): { SeasonDef }
	local now = SeasonConfig.Now()
	local out: { SeasonDef } = {}
	for _, season in SeasonConfig.Seasons do
		if now >= season.endUnix then
			table.insert(out, season)
		end
	end
	return out
end

function SeasonConfig.GetLeaderboard(boardId: string): LeaderboardDef?
	for _, board in SeasonConfig.Leaderboards do
		if board.id == boardId then
			return board
		end
	end
	return nil
end

function SeasonConfig.RewardTierForRank(boardId: string, rank: number): RewardTier?
	local tiers = SeasonConfig.RewardTiers[boardId]
	if not tiers then
		return nil
	end
	for _, tier in tiers do
		if rank >= tier.rankMin and rank <= tier.rankMax then
			return tier
		end
	end
	return nil
end

function SeasonConfig.IsAscendingBoard(boardId: string): boolean
	local board = SeasonConfig.GetLeaderboard(boardId)
	return board ~= nil and board.kind == "boss_speed"
end

function SeasonConfig.BossKillsBoardId(bossId: string): string
	return `boss_{bossId}_kills`
end

function SeasonConfig.BossSpeedBoardId(bossId: string): string
	return `boss_{bossId}_speed`
end

return SeasonConfig
