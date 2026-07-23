--[[
	Lobby state snapshot for client UI.
]]

local Players = game:GetService("Players")

local QueueConfig = require(game.ReplicatedStorage.Shared.Config.QueueConfig)
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

	local queues = {}
	for id, def in QueueConfig.Queues do
		table.insert(queues, {
			id = id,
			mode = def.mode,
			teamSize = def.teamSize,
			ranked = def.ranked == true,
			label = if def.mode == "PvE"
				then `PvE Boss · {def.teamSize}p`
				else `PvP {def.teamSize}v{def.teamSize}{if def.ranked then " Ranked" else ""}`,
		})
	end
	table.sort(queues, function(a, b)
		return a.id < b.id
	end)

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
		queues = queues,
	}
end

return LobbyStateService
