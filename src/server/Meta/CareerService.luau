--[[
	Career stats — playtime, PvP K/D, per-season snapshots.
	Persisted via PlayerProfile.career / seasonStats / seasonRewardsClaimed.
]]

local SeasonConfig = require(game.ReplicatedStorage.Shared.Config.SeasonConfig)
local CareerConfig = require(game.ReplicatedStorage.Shared.Config.CareerConfig)
local Players = game:GetService("Players")
local BossProgressService = require(script.Parent.BossProgressService)
local RankedService = require(script.Parent.Parent.Ranked.RankedService)
local RankedConfig = require(game.ReplicatedStorage.Shared.Config.RankedConfig)
local LeaderboardService = require(script.Parent.Parent.Leaderboard.LeaderboardService)

local CareerService = {}

export type CareerData = {
	playtimeSec: number,
	pvpKills: number,
	pvpDeaths: number,
}

export type BossBestRun = {
	clearMs: number,
	partySize: number,
	memberUserIds: { number },
}

export type SeasonSnapshot = {
	bossKills: { [string]: number },
	bossBestClearMs: { [string]: number },
	bossBestRuns: { [string]: BossBestRun },
	pvpKills: number,
	pvpDeaths: number,
	peakMmr: { [string]: number },
}

local careerByUser: { [number]: CareerData } = {}
local seasonByUser: { [number]: { [string]: SeasonSnapshot } } = {}
local rewardsClaimedByUser: { [number]: { [string]: boolean } } = {}
local sessionStartAt: { [number]: number } = {}

local function defaultCareer(): CareerData
	return {
		playtimeSec = 0,
		pvpKills = 0,
		pvpDeaths = 0,
	}
end

local function defaultSeasonSnapshot(): SeasonSnapshot
	return {
		bossKills = {},
		bossBestClearMs = {},
		bossBestRuns = {},
		pvpKills = 0,
		pvpDeaths = 0,
		peakMmr = {},
	}
end

function CareerService.Ensure(userId: number)
	if not careerByUser[userId] then
		careerByUser[userId] = defaultCareer()
	end
	if not seasonByUser[userId] then
		seasonByUser[userId] = {}
	end
	if not rewardsClaimedByUser[userId] then
		rewardsClaimedByUser[userId] = {}
	end
end

function CareerService.StartSession(userId: number)
	CareerService.Ensure(userId)
	sessionStartAt[userId] = os.clock()
end

function CareerService.FlushSession(userId: number)
	local started = sessionStartAt[userId]
	if not started then
		return
	end
	local delta = math.max(0, math.floor(os.clock() - started))
	sessionStartAt[userId] = os.clock()
	if delta <= 0 then
		return
	end
	CareerService.Ensure(userId)
	careerByUser[userId].playtimeSec += delta
end

local function seasonSnapshot(userId: number, seasonId: string): SeasonSnapshot
	CareerService.Ensure(userId)
	local bag = seasonByUser[userId]
	if not bag[seasonId] then
		bag[seasonId] = defaultSeasonSnapshot()
	end
	return bag[seasonId]
end

function CareerService.RecordBossClear(
	userId: number,
	bossId: string,
	clearMs: number,
	partySize: number,
	memberUserIds: { number }
)
	if typeof(bossId) ~= "string" or bossId == "" then
		return
	end
	clearMs = math.max(1, math.floor(clearMs))
	local seasonId = SeasonConfig.GetCurrentSeasonId()
	local snap = seasonSnapshot(userId, seasonId)
	local prev = snap.bossBestClearMs[bossId]
	if prev and clearMs >= prev then
		return
	end

	snap.bossBestClearMs[bossId] = clearMs
	snap.bossBestRuns[bossId] = {
		clearMs = clearMs,
		partySize = math.clamp(partySize, 1, 3),
		memberUserIds = table.clone(memberUserIds),
	}

	local memberNames: { string } = {}
	for _, memberId in memberUserIds do
		local plr = Players:GetPlayerByUserId(memberId)
		table.insert(memberNames, if plr then plr.Name else `Player{memberId}`)
	end

	local boardId = SeasonConfig.BossSpeedBoardId(bossId)
	LeaderboardService.UpdateBestTime(seasonId, boardId, userId, clearMs, {
		clearMs = clearMs,
		partySize = partySize,
		memberUserIds = memberUserIds,
		memberNames = memberNames,
	})
end

function CareerService.RecordBossKill(userId: number, bossId: string)
	if typeof(bossId) ~= "string" or bossId == "" then
		return
	end
	local seasonId = SeasonConfig.GetCurrentSeasonId()
	local snap = seasonSnapshot(userId, seasonId)
	snap.bossKills[bossId] = (snap.bossKills[bossId] or 0) + 1
	LeaderboardService.UpdateScore(seasonId, SeasonConfig.BossKillsBoardId(bossId), userId, snap.bossKills[bossId])
end

function CareerService.RecordPvpResult(userId: number, won: boolean, _ranked: boolean)
	CareerService.Ensure(userId)
	local career = careerByUser[userId]
	local seasonId = SeasonConfig.GetCurrentSeasonId()
	local snap = seasonSnapshot(userId, seasonId)
	if won then
		career.pvpKills += 1
		snap.pvpKills += 1
	else
		career.pvpDeaths += 1
		snap.pvpDeaths += 1
	end
end

function CareerService.UpdatePeakMmr(userId: number, bracketKey: string, mmr: number)
	if typeof(bracketKey) ~= "string" or typeof(mmr) ~= "number" then
		return
	end
	local seasonId = SeasonConfig.GetCurrentSeasonId()
	local snap = seasonSnapshot(userId, seasonId)
	local prev = snap.peakMmr[bracketKey] or 0
	if mmr <= prev then
		return
	end
	snap.peakMmr[bracketKey] = math.floor(mmr)
	local boardId = if bracketKey == "pvp_1v1"
		then "mmr_1v1"
		elseif bracketKey == "pvp_2v2" then "mmr_2v2"
		elseif bracketKey == "pvp_3v3" then "mmr_3v3"
		else nil
	if boardId then
		LeaderboardService.UpdateScore(seasonId, boardId, userId, snap.peakMmr[bracketKey])
	end
end

function CareerService.GetRewardsClaimed(userId: number): { [string]: boolean }
	CareerService.Ensure(userId)
	return rewardsClaimedByUser[userId]
end

function CareerService.MarkSeasonClaimed(userId: number, seasonId: string)
	CareerService.Ensure(userId)
	rewardsClaimedByUser[userId][seasonId] = true
end

function CareerService.IsSeasonClaimed(userId: number, seasonId: string): boolean
	return CareerService.GetRewardsClaimed(userId)[seasonId] == true
end

function CareerService.Export(userId: number): {
	career: CareerData,
	seasonStats: { [string]: SeasonSnapshot },
	seasonRewardsClaimed: { [string]: boolean },
}
	CareerService.FlushSession(userId)
	CareerService.Ensure(userId)
	local seasonStats: { [string]: SeasonSnapshot } = {}
	for seasonId, snap in seasonByUser[userId] do
		local bossBestRuns: { [string]: BossBestRun } = {}
		for bossId, run in snap.bossBestRuns do
			bossBestRuns[bossId] = {
				clearMs = run.clearMs,
				partySize = run.partySize,
				memberUserIds = table.clone(run.memberUserIds),
			}
		end
		seasonStats[seasonId] = {
			bossKills = table.clone(snap.bossKills),
			bossBestClearMs = table.clone(snap.bossBestClearMs),
			bossBestRuns = bossBestRuns,
			pvpKills = snap.pvpKills,
			pvpDeaths = snap.pvpDeaths,
			peakMmr = table.clone(snap.peakMmr),
		}
	end
	return {
		career = table.clone(careerByUser[userId]),
		seasonStats = seasonStats,
		seasonRewardsClaimed = table.clone(rewardsClaimedByUser[userId]),
	}
end

function CareerService.ResyncLeaderboards(userId: number)
	CareerService.Ensure(userId)
	for seasonId, snap in seasonByUser[userId] do
		for bossId, killCount in snap.bossKills do
			LeaderboardService.UpdateScore(seasonId, SeasonConfig.BossKillsBoardId(bossId), userId, killCount)
		end
		for bossId, clearMs in snap.bossBestClearMs do
			local run = snap.bossBestRuns[bossId]
			if run then
				local memberNames: { string } = {}
				for _, memberId in run.memberUserIds do
					local plr = Players:GetPlayerByUserId(memberId)
					table.insert(memberNames, if plr then plr.Name else `Player{memberId}`)
				end
				LeaderboardService.UpdateBestTime(seasonId, SeasonConfig.BossSpeedBoardId(bossId), userId, clearMs, {
					clearMs = clearMs,
					partySize = run.partySize,
					memberUserIds = run.memberUserIds,
					memberNames = memberNames,
				})
			else
				LeaderboardService.UpdateScore(seasonId, SeasonConfig.BossSpeedBoardId(bossId), userId, clearMs)
			end
		end
		for bracketKey, mmr in snap.peakMmr do
			local boardId = if bracketKey == "pvp_1v1"
				then "mmr_1v1"
				elseif bracketKey == "pvp_2v2" then "mmr_2v2"
				elseif bracketKey == "pvp_3v3" then "mmr_3v3"
				else nil
			if boardId then
				LeaderboardService.UpdateScore(seasonId, boardId, userId, mmr)
			end
		end
	end
end

function CareerService.Import(
	userId: number,
	career: CareerData?,
	seasonStats: { [string]: SeasonSnapshot }?,
	seasonRewardsClaimed: { [string]: boolean }?
)
	CareerService.Ensure(userId)
	if typeof(career) == "table" then
		careerByUser[userId] = {
			playtimeSec = math.max(0, math.floor(career.playtimeSec or 0)),
			pvpKills = math.max(0, math.floor(career.pvpKills or 0)),
			pvpDeaths = math.max(0, math.floor(career.pvpDeaths or 0)),
		}
	end
	if typeof(seasonStats) == "table" then
		seasonByUser[userId] = {}
		for seasonId, snap in seasonStats do
			if typeof(seasonId) == "string" and typeof(snap) == "table" then
				local bossKills: { [string]: number } = {}
				if typeof(snap.bossKills) == "table" then
					for bossId, count in snap.bossKills do
						if typeof(bossId) == "string" and typeof(count) == "number" and count > 0 then
							bossKills[bossId] = math.floor(count)
						end
					end
				end
				local bossBestClearMs: { [string]: number } = {}
				local bossBestRuns: { [string]: BossBestRun } = {}
				if typeof(snap.bossBestClearMs) == "table" then
					for bossId, clearMs in snap.bossBestClearMs do
						if typeof(bossId) == "string" and typeof(clearMs) == "number" and clearMs > 0 then
							bossBestClearMs[bossId] = math.floor(clearMs)
						end
					end
				end
				if typeof(snap.bossBestRuns) == "table" then
					for bossId, run in snap.bossBestRuns do
						if typeof(bossId) == "string" and typeof(run) == "table" and typeof(run.clearMs) == "number" then
							local memberUserIds: { number } = {}
							if typeof(run.memberUserIds) == "table" then
								for _, memberId in run.memberUserIds do
									if typeof(memberId) == "number" then
										table.insert(memberUserIds, memberId)
									end
								end
							end
							bossBestRuns[bossId] = {
								clearMs = math.floor(run.clearMs),
								partySize = math.clamp(math.floor(run.partySize or 1), 1, 3),
								memberUserIds = memberUserIds,
							}
						end
					end
				end
				local peakMmr: { [string]: number } = {}
				if typeof(snap.peakMmr) == "table" then
					for key, val in snap.peakMmr do
						if typeof(key) == "string" and typeof(val) == "number" then
							peakMmr[key] = math.floor(val)
						end
					end
				end
				seasonByUser[userId][seasonId] = {
					bossKills = bossKills,
					bossBestClearMs = bossBestClearMs,
					bossBestRuns = bossBestRuns,
					pvpKills = math.max(0, math.floor(snap.pvpKills or 0)),
					pvpDeaths = math.max(0, math.floor(snap.pvpDeaths or 0)),
					peakMmr = peakMmr,
				}
			end
		end
	end
	if typeof(seasonRewardsClaimed) == "table" then
		rewardsClaimedByUser[userId] = {}
		for seasonId, claimed in seasonRewardsClaimed do
			if typeof(seasonId) == "string" and claimed == true then
				rewardsClaimedByUser[userId][seasonId] = true
			end
		end
	end
	sessionStartAt[userId] = os.clock()
	CareerService.ResyncLeaderboards(userId)
end

function CareerService.Clear(userId: number)
	careerByUser[userId] = nil
	seasonByUser[userId] = nil
	rewardsClaimedByUser[userId] = nil
	sessionStartAt[userId] = nil
end

function CareerService.BuildSnapshot(userId: number)
	CareerService.Ensure(userId)
	local career = careerByUser[userId]
	local season = SeasonConfig.GetCurrentSeason()
	local seasonId = season.id
	local snap = seasonSnapshot(userId, seasonId)
	local bossKills = BossProgressService.Export(userId)

	local mmr = {}
	for bracketKey, _ in RankedService.Export(userId) do
		local value = RankedService.GetMmr(userId, bracketKey)
		mmr[bracketKey] = {
			value = value,
			tier = RankedConfig.TierForMmr(value),
		}
	end

	local pendingSeasons = {}
	for _, ended in SeasonConfig.GetEndedSeasons() do
		if not CareerService.IsSeasonClaimed(userId, ended.id) then
			table.insert(pendingSeasons, ended.id)
		end
	end

	local bossBestClears = {}
	for bossId, clearMs in snap.bossBestClearMs do
		local run = snap.bossBestRuns[bossId]
		bossBestClears[bossId] = {
			clearMs = clearMs,
			clearTimeText = CareerConfig.FormatClearTime(clearMs),
			partySize = if run then run.partySize else 1,
			memberUserIds = if run then run.memberUserIds else { userId },
		}
	end

	return {
		playtimeSec = career.playtimeSec,
		playtimeText = CareerConfig.FormatPlaytime(career.playtimeSec),
		pvpKills = career.pvpKills,
		pvpDeaths = career.pvpDeaths,
		kdRatio = CareerConfig.KdRatio(career.pvpKills, career.pvpDeaths),
		bossKills = bossKills,
		mmr = mmr,
		season = {
			id = seasonId,
			name = season.name,
			endsAt = season.endUnix,
			bossBestClears = bossBestClears,
			bossKills = table.clone(snap.bossKills),
			pvpKills = snap.pvpKills,
			pvpDeaths = snap.pvpDeaths,
			peakMmr = table.clone(snap.peakMmr),
		},
		pendingRewardSeasons = pendingSeasons,
	}
end

return CareerService
