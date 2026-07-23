--[[
	PartyService — lobby parti (max 3).
	Invite → accept/decline · lider kick / lider devri.
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

export type PartyInvitePayload = {
	fromUserId: number,
	fromName: string,
}

local PartyService = {}

local INVITE_TTL_SEC = 90

type PendingInvite = {
	fromUserId: number,
	expiresAt: number,
}

local partiesById: { [string]: Party } = {}
local partyIdByUserId: { [number]: string } = {}
local pendingTo: { [number]: PendingInvite } = {}

local function findMember(party: Party, userId: number): PartyMember?
	for _, m in party.members do
		if m.userId == userId then
			return m
		end
	end
	return nil
end

local function normalizeName(name: string): string
	return string.lower((string.gsub(name, "^%s+", "")):gsub("%s+$", ""))
end

local function isSoloParty(party: Party): boolean
	return #party.members <= 1
end

local function clearPendingForTarget(targetUserId: number)
	pendingTo[targetUserId] = nil
end

local function expirePendingInvites()
	local now = os.clock()
	for userId, invite in pendingTo do
		if invite.expiresAt <= now then
			pendingTo[userId] = nil
		end
	end
end

function PartyService.FindPlayerByName(name: string): Player?
	local query = normalizeName(name)
	if query == "" then
		return nil
	end
	for _, plr in Players:GetPlayers() do
		if normalizeName(plr.Name) == query or normalizeName(plr.DisplayName) == query then
			return plr
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

function PartyService.SyncAttributesForParty(party: Party)
	for _, m in party.members do
		local plr = Players:GetPlayerByUserId(m.userId)
		if plr then
			local grouped = #party.members > 1
			local isLeader = party.leaderUserId == m.userId
			plr:SetAttribute("PartyId", party.id)
			plr:SetAttribute("PartyIsLeader", isLeader)
			plr:SetAttribute("PartyGrouped", grouped)
			local char = plr.Character
			if char then
				char:SetAttribute("PartyId", party.id)
				char:SetAttribute("PartyIsLeader", isLeader)
				char:SetAttribute("PartyGrouped", grouped)
			end
		end
	end
end

function PartyService.SyncAttributesForUser(userId: number)
	local party = PartyService.GetPartyForPlayer(userId)
	if party then
		PartyService.SyncAttributesForParty(party)
	end
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
	PartyService.SyncAttributesForParty(party)
	return party
end

function PartyService.GetPendingInvite(userId: number): PartyInvitePayload?
	expirePendingInvites()
	local invite = pendingTo[userId]
	if not invite then
		return nil
	end
	if invite.expiresAt <= os.clock() then
		pendingTo[userId] = nil
		return nil
	end
	local from = Players:GetPlayerByUserId(invite.fromUserId)
	if not from then
		pendingTo[userId] = nil
		return nil
	end
	return {
		fromUserId = invite.fromUserId,
		fromName = from.DisplayName ~= "" and from.DisplayName or from.Name,
	}
end

function PartyService.SendInvite(leader: Player, target: Player): (boolean, string?)
	expirePendingInvites()
	if leader.UserId == target.UserId then
		return false, "Self"
	end

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

	local targetParty = PartyService.GetPartyForPlayer(target.UserId)
	if targetParty and not isSoloParty(targetParty) then
		return false, "AlreadyInParty"
	end
	if pendingTo[target.UserId] then
		return false, "InvitePending"
	end

	pendingTo[target.UserId] = {
		fromUserId = leader.UserId,
		expiresAt = os.clock() + INVITE_TTL_SEC,
	}
	return true, nil
end

function PartyService.RespondInvite(target: Player, fromUserId: number, accept: boolean): (boolean, string?)
	expirePendingInvites()
	local pending = pendingTo[target.UserId]
	if not pending or pending.fromUserId ~= fromUserId then
		return false, "NoInvite"
	end
	clearPendingForTarget(target.UserId)

	if not accept then
		return true, "Declined"
	end

	local leader = Players:GetPlayerByUserId(fromUserId)
	if not leader then
		return false, "TargetOffline"
	end

	local party = PartyService.GetPartyForPlayer(leader.UserId)
	if not party then
		return false, "NoParty"
	end
	if party.leaderUserId ~= leader.UserId then
		return false, "NotLeader"
	end
	if #party.members >= QueueConfig.MaxPartySize then
		return false, "PartyFull"
	end

	local targetParty = PartyService.GetPartyForPlayer(target.UserId)
	if targetParty and not isSoloParty(targetParty) then
		return false, "AlreadyInParty"
	end

	if targetParty then
		PartyService.Leave(target)
	end

	table.insert(party.members, { userId = target.UserId, ready = false })
	partyIdByUserId[target.UserId] = party.id
	PartyService.SyncAttributesForParty(party)
	return true, nil
end

function PartyService.Invite(leader: Player, target: Player): (boolean, string?)
	return PartyService.SendInvite(leader, target)
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

function PartyService.Kick(leader: Player, targetUserId: number): (boolean, string?)
	local party = PartyService.GetPartyForPlayer(leader.UserId)
	if not party then
		return false, "NoParty"
	end
	if party.leaderUserId ~= leader.UserId then
		return false, "NotLeader"
	end
	if targetUserId == leader.UserId then
		return false, "CantKickSelf"
	end
	if not findMember(party, targetUserId) then
		return false, "NotInParty"
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		PartyService.Leave(target)
		PartyService.CreateSoloParty(target)
	else
		partyIdByUserId[targetUserId] = nil
		for i = #party.members, 1, -1 do
			if party.members[i].userId == targetUserId then
				table.remove(party.members, i)
			end
		end
	end
	PartyService.SyncAttributesForParty(party)
	return true, nil
end

function PartyService.PromoteLeader(leader: Player, newLeaderUserId: number): (boolean, string?)
	local party = PartyService.GetPartyForPlayer(leader.UserId)
	if not party then
		return false, "NoParty"
	end
	if party.leaderUserId ~= leader.UserId then
		return false, "NotLeader"
	end
	if newLeaderUserId == leader.UserId then
		return true, nil
	end
	if not findMember(party, newLeaderUserId) then
		return false, "NotInParty"
	end

	party.leaderUserId = newLeaderUserId
	local member = findMember(party, newLeaderUserId)
	if member then
		member.ready = true
	end
	PartyService.SyncAttributesForParty(party)
	return true, nil
end

function PartyService.Leave(player: Player)
	local party = PartyService.GetPartyForPlayer(player.UserId)
	if not party then
		return
	end

	clearPendingForTarget(player.UserId)
	partyIdByUserId[player.UserId] = nil

	for i = #party.members, 1, -1 do
		if party.members[i].userId == player.UserId then
			table.remove(party.members, i)
		end
	end

	if #party.members == 0 then
		partiesById[party.id] = nil
		player:SetAttribute("PartyId", nil)
		player:SetAttribute("PartyIsLeader", nil)
		player:SetAttribute("PartyGrouped", nil)
		if player.Character then
			player.Character:SetAttribute("PartyId", nil)
			player.Character:SetAttribute("PartyIsLeader", nil)
			player.Character:SetAttribute("PartyGrouped", nil)
		end
		return
	end

	if party.leaderUserId == player.UserId then
		party.leaderUserId = party.members[1].userId
		party.members[1].ready = true
	end
	PartyService.SyncAttributesForParty(party)
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
	clearPendingForTarget(player.UserId)
	PartyService.Leave(player)
end)

Players.PlayerAdded:Connect(function(player)
	PartyService.CreateSoloParty(player)
	player.CharacterAdded:Connect(function()
		PartyService.SyncAttributesForUser(player.UserId)
	end)
end)

return PartyService
