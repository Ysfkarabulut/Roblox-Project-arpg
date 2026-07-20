--[[
	PartyService — lobby parti (max 3).
	Yalnızca lider queue başlatır (QueueService).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local QueueConfig = require(game.ReplicatedStorage.Shared.Config.QueueConfig)

export type PartyMember = {
	userId: number,
	ready: boolean,
}

export type Party = {
	id: string,
	leaderUserId: number,
	members: { PartyMember },
}

local PartyService = {}

local partiesById: { [string]: Party } = {}
local partyIdByUserId: { [number]: string } = {}

local function findMember(party: Party, userId: number): PartyMember?
	for _, m in party.members do
		if m.userId == userId then
			return m
		end
	end
	return nil
end

function PartyService.GetPartyForPlayer(userId: number): Party?
	local id = partyIdByUserId[userId]
	if not id then
		return nil
	end
	return partiesById[id]
end

function PartyService.CreateSoloParty(leader: Player): Party
	local existing = PartyService.GetPartyForPlayer(leader.UserId)
	if existing then
		return existing
	end

	local party: Party = {
		id = HttpService:GenerateGUID(false),
		leaderUserId = leader.UserId,
		members = {
			{ userId = leader.UserId, ready = true },
		},
	}
	partiesById[party.id] = party
	partyIdByUserId[leader.UserId] = party.id
	return party
end

function PartyService.Invite(leader: Player, target: Player): (boolean, string?)
	local party = PartyService.GetPartyForPlayer(leader.UserId)
	if not party then
		party = PartyService.CreateSoloParty(leader)
	end
	if party.leaderUserId ~= leader.UserId then
		return false, "NotLeader"
	end
	if #party.members >= QueueConfig.MaxPartySize then
		return false, "PartyFull"
	end
	if PartyService.GetPartyForPlayer(target.UserId) then
		return false, "AlreadyInParty"
	end

	table.insert(party.members, { userId = target.UserId, ready = false })
	partyIdByUserId[target.UserId] = party.id
	return true, nil
end

function PartyService.SetReady(player: Player, ready: boolean): (boolean, string?)
	local party = PartyService.GetPartyForPlayer(player.UserId)
	if not party then
		return false, "NoParty"
	end
	local member = findMember(party, player.UserId)
	if not member then
		return false, "NoParty"
	end
	member.ready = ready
	return true, nil
end

function PartyService.Leave(player: Player)
	local party = PartyService.GetPartyForPlayer(player.UserId)
	if not party then
		return
	end

	partyIdByUserId[player.UserId] = nil

	for i = #party.members, 1, -1 do
		if party.members[i].userId == player.UserId then
			table.remove(party.members, i)
		end
	end

	if #party.members == 0 then
		partiesById[party.id] = nil
		return
	end

	if party.leaderUserId == player.UserId then
		party.leaderUserId = party.members[1].userId
		party.members[1].ready = true
	end
end

function PartyService.AllReady(party: Party): boolean
	for _, m in party.members do
		if not m.ready then
			return false
		end
	end
	return true
end

function PartyService.GetMemberUserIds(party: Party): { number }
	local ids = {}
	for _, m in party.members do
		table.insert(ids, m.userId)
	end
	return ids
end

Players.PlayerRemoving:Connect(function(player)
	PartyService.Leave(player)
end)

-- Joining player starts as solo party (lobby convenience).
Players.PlayerAdded:Connect(function(player)
	PartyService.CreateSoloParty(player)
end)

return PartyService
