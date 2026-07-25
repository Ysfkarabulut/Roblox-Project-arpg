--[[
	Career + leaderboard remotes — snapshot, boards, season rewards.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeasonConfig = require(ReplicatedStorage.Shared.Config.SeasonConfig)
local CareerService = require(script.Parent.Meta.CareerService)
local LeaderboardService = require(script.Parent.Leaderboard.LeaderboardService)
local SeasonRewardService = require(script.Parent.Meta.SeasonRewardService)

local folder = Instance.new("Folder")
folder.Name = "CareerRemotes"
folder.Parent = ReplicatedStorage

local function remoteFunction(name: string): RemoteFunction
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = folder
	return r
end

local GetCareerSnapshot = remoteFunction("GetCareerSnapshot")
local GetLeaderboard = remoteFunction("GetLeaderboard")
local GetLeaderboardCatalog = remoteFunction("GetLeaderboardCatalog")
local ClaimSeasonRewards = remoteFunction("ClaimSeasonRewards")

GetCareerSnapshot.OnServerInvoke = function(player: Player)
	return CareerService.BuildSnapshot(player.UserId)
end

GetLeaderboardCatalog.OnServerInvoke = function(_player: Player)
	local season = SeasonConfig.GetCurrentSeason()
	return {
		season = {
			id = season.id,
			name = season.name,
			startUnix = season.startUnix,
			endUnix = season.endUnix,
		},
		boards = LeaderboardService.BuildBoardList(),
	}
end

GetLeaderboard.OnServerInvoke = function(player: Player, seasonId: string?, boardId: string?, limit: number?)
	if typeof(seasonId) ~= "string" then
		seasonId = SeasonConfig.GetCurrentSeasonId()
	end
	if typeof(boardId) ~= "string" then
		boardId = SeasonConfig.Leaderboards[1] and SeasonConfig.Leaderboards[1].id or "boss_eye_kills"
	end
	if not SeasonConfig.GetLeaderboard(boardId) then
		return { ok = false, reason = "UnknownBoard", entries = {} }
	end
	local maxLimit = SeasonConfig.LeaderboardUiMax
	local count = math.clamp(limit or SeasonConfig.LeaderboardPageSize, 1, maxLimit)
	local entries = LeaderboardService.GetTop(seasonId, boardId, count)
	local viewerRank = LeaderboardService.GetUserRank(seasonId, boardId, player.UserId)
	return {
		ok = true,
		seasonId = seasonId,
		boardId = boardId,
		entries = entries,
		viewerRank = viewerRank,
	}
end

ClaimSeasonRewards.OnServerInvoke = function(player: Player, seasonId: string?)
	local userId = player.UserId
	if typeof(seasonId) == "string" and seasonId ~= "" then
		return SeasonRewardService.ClaimSeason(userId, seasonId)
	end
	return SeasonRewardService.ClaimAllPending(userId)
end

print("[CareerBootstrap] Career + leaderboard remotes ready")
