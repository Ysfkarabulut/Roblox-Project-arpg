--[[
	Season-end leaderboard rewards — claim after season ends.
]]

local SeasonConfig = require(game.ReplicatedStorage.Shared.Config.SeasonConfig)
local CareerService = require(script.Parent.CareerService)
local LeaderboardService = require(script.Parent.Parent.Leaderboard.LeaderboardService)
local CurrencyService = require(script.Parent.Parent.Inventory.CurrencyService)
local ShopService = require(script.Parent.ShopService)
local PlayerProfileService = require(script.Parent.Parent.Profile.PlayerProfileService)

local SeasonRewardService = {}

export type GrantedReward = {
	seasonId: string,
	boardId: string,
	rank: number,
	premium: number?,
	title: string?,
}

function SeasonRewardService.ClaimSeason(userId: number, seasonId: string): { ok: boolean, rewards: { GrantedReward }, reason: string? }
	local season = SeasonConfig.GetSeason(seasonId)
	if not season then
		return { ok = false, rewards = {}, reason = "UnknownSeason" }
	end
	if SeasonConfig.Now() < season.endUnix then
		return { ok = false, rewards = {}, reason = "SeasonActive" }
	end
	if CareerService.IsSeasonClaimed(userId, seasonId) then
		return { ok = false, rewards = {}, reason = "AlreadyClaimed" }
	end

	local granted: { GrantedReward } = {}
	local totalPremium = 0

	local function grantBoard(boardId: string, rank: number)
		local tier = SeasonConfig.RewardTierForRank(boardId, rank)
		if not tier then
			return
		end
		local premium = tier.premium or 0
		if premium > 0 then
			totalPremium += premium
		end
		if typeof(tier.title) == "string" and tier.title ~= "" then
			ShopService.GrantTitle(userId, tier.title)
		end
		table.insert(granted, {
			seasonId = seasonId,
			boardId = boardId,
			rank = rank,
			premium = tier.premium,
			title = tier.title,
		})
	end

	for _, board in SeasonConfig.Leaderboards do
		if board.kind == "boss_kills" or board.kind == "boss_speed" then
			continue
		end
		local rank = LeaderboardService.GetUserRank(seasonId, board.id, userId)
		if rank then
			grantBoard(board.id, rank)
		end
	end

	for _, board in SeasonConfig.MergedPveRewardBoards do
		local rank = LeaderboardService.GetMergedPveUserRank(seasonId, board.kind, userId)
		if rank then
			grantBoard(board.id, rank)
		end
	end

	if totalPremium > 0 then
		CurrencyService.AddPremium(userId, totalPremium)
	end

	CareerService.MarkSeasonClaimed(userId, seasonId)
	PlayerProfileService.Save(userId)

	return { ok = true, rewards = granted, reason = nil }
end

function SeasonRewardService.ClaimAllPending(userId: number): { ok: boolean, seasons: { string }, rewards: { GrantedReward } }
	local allRewards: { GrantedReward } = {}
	local claimedSeasons: { string } = {}
	for _, season in SeasonConfig.GetEndedSeasons() do
		if CareerService.IsSeasonClaimed(userId, season.id) then
			continue
		end
		local result = SeasonRewardService.ClaimSeason(userId, season.id)
		if result.ok then
			table.insert(claimedSeasons, season.id)
			for _, reward in result.rewards do
				table.insert(allRewards, reward)
			end
		end
	end
	return {
		ok = #claimedSeasons > 0 or #SeasonConfig.GetEndedSeasons() == 0,
		seasons = claimedSeasons,
		rewards = allRewards,
	}
end

function SeasonRewardService.TryAutoClaimOnJoin(userId: number)
	task.defer(function()
		SeasonRewardService.ClaimAllPending(userId)
	end)
end

return SeasonRewardService
