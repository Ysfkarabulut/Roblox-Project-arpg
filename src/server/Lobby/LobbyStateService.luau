--[[
	Lobby state snapshot for client UI.
]]

local Players = game:GetService("Players")

local BossQueueConfig = require(game.ReplicatedStorage.Shared.Config.BossQueueConfig)
local PartyService = require(script.Parent.PartyService)

local LobbyStateService = {}

local listeners: { (userId: number) -> () } = {}

function LobbyStateService.OnChanged(fn: (userId: number) -> ())
	table.insert(listeners, fn)
end

function LobbyStateService.NotifyParty(userId: number)
	for _, fn in listeners do
		task.spawn(fn, userId)
	end
end

function LobbyStateService.BuildForPlayer(userId: number)
	local party = PartyService.GetPartyForPlayer(userId)
	local members = {}
	if party then
		for _, m in party.members do
			local plr = Players:GetPlayerByUserId(m.userId)
			table.insert(members, {
				userId = m.userId,
				name = if plr then plr.Name else `User{m.userId}`,
				ready = m.ready,
				isLeader = party.leaderUserId == m.userId,
				isYou = m.userId == userId,
			})
		end
	end

	return {
		party = if party
			then {
				id = party.id,
				leaderUserId = party.leaderUserId,
				members = members,
				allReady = PartyService.AllReady(party),
				isLeader = party.leaderUserId == userId,
			}
			else nil,
		pvpSections = {
			{
				title = "Casual",
				queues = {
					{ label = "1v1", queueId = "pvp_1v1_casual" },
					{ label = "2v2", queueId = "pvp_2v2_casual" },
					{ label = "3v3", queueId = "pvp_3v3_casual" },
				},
			},
			{
				title = "Ranked",
				queues = {
					{ label = "1v1", queueId = "pvp_1v1_ranked" },
					{ label = "2v2", queueId = "pvp_2v2_ranked" },
					{ label = "3v3", queueId = "pvp_3v3_ranked" },
				},
			},
		},
		pveWildcard = BossQueueConfig.GetWildcardOption(),
		pveBosses = BossQueueConfig.GetBossList(),
		pveQueues = {
			[1] = "pve_boss_solo",
			[2] = "pve_boss_duo",
			[3] = "pve_boss_trio",
		},
	}
end

return LobbyStateService
