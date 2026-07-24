--[[
	QueueService — PvP matchmaking:
	1) Öncelik: full premade vs full premade (hemen)
	2) FillerTimeout sonrası:
	   - 2v2: solo+solo takım vs solo+solo (premade 2 asla iki soloya düşmez)
	   - 3v3: (parti2 + solo) vs (parti2 + solo); premade 3 asla 3 soloya düşmez
	3) Premade 3 / Premade 2 yalnızca kendi seviyesinde veya kurallı filler ile
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local QueueConfig = require(game.ReplicatedStorage.Shared.Config.QueueConfig)
local BossQueueConfig = require(game.ReplicatedStorage.Shared.Config.BossQueueConfig)
local PartyService = require(script.Parent.PartyService)
local MatchTeleport = require(script.Parent.MatchTeleport)
local LoadoutLockService = require(script.Parent.Parent.Combat.LoadoutLockService)

type QueueDef = QueueConfig.QueueDef

export type QueueTicket = {
	ticketId: string,
	queueId: string,
	partyId: string,
	memberUserIds: { number },
	partySize: number,
	bossPref: BossQueueConfig.BossQueuePref?,
	enqueuedAt: number,
}

local QueueService = {}

local queues: { [string]: { QueueTicket } } = {}
local ticketByPartyId: { [string]: QueueTicket } = {}

local function ensureQueue(queueId: string)
	if not queues[queueId] then
		queues[queueId] = {}
	end
end

local function removeTicket(ticket: QueueTicket)
	ticketByPartyId[ticket.partyId] = nil
	local list = queues[ticket.queueId]
	if not list then
		return
	end
	for i, t in list do
		if t.ticketId == ticket.ticketId then
			table.remove(list, i)
			return
		end
	end
end

local function takeTicket(list: { QueueTicket }, index: number): QueueTicket
	local t = table.remove(list, index) :: QueueTicket
	ticketByPartyId[t.partyId] = nil
	return t
end

local function mergeMembers(tickets: { QueueTicket }): { number }
	local ids = {}
	for _, t in tickets do
		for _, id in t.memberUserIds do
			table.insert(ids, id)
		end
	end
	return ids
end

local function flattenTickets(teamTickets: { { QueueTicket } }): { QueueTicket }
	local out: { QueueTicket } = {}
	for _, group in teamTickets do
		for _, ticket in group do
			table.insert(out, ticket)
		end
	end
	return out
end

local function startMatch(queueId: string, placeKey: string, teamTickets: { { QueueTicket } })
	local teams = {}
	for _, group in teamTickets do
		table.insert(teams, mergeMembers(group))
	end
	local def = QueueConfig.Get(queueId :: any)
	local resolvedBoss: string? = nil
	if def and def.mode == "PvE" then
		local prefs: { BossQueueConfig.BossQueuePref } = {}
		for _, ticket in flattenTickets(teamTickets) do
			local norm = BossQueueConfig.Normalize(ticket.bossPref)
			if norm then
				table.insert(prefs, norm)
			end
		end
		resolvedBoss = BossQueueConfig.ResolveMatch(prefs)
	end
	MatchTeleport.StartMatch({
		matchId = HttpService:GenerateGUID(false),
		queueId = queueId,
		placeKey = placeKey,
		teams = teams,
		bossId = resolvedBoss,
	})
end

local function findCompatibleTicket(
	list: { QueueTicket },
	anchor: QueueTicket,
	roomLeft: number
): number?
	for i, ticket in list do
		if ticket.partySize <= roomLeft and BossQueueConfig.CanMatch(anchor.bossPref, ticket.bossPref) then
			return i
		end
	end
	return nil
end

local function putTicketsBack(list: { QueueTicket }, group: { QueueTicket })
	for _, ticket in group do
		table.insert(list, ticket)
		ticketByPartyId[ticket.partyId] = ticket
	end
end

local function oldestWait(tickets: { QueueTicket }): number
	local now = os.clock()
	local best = 0
	for _, t in tickets do
		best = math.max(best, now - t.enqueuedAt)
	end
	return best
end

local function filterBySize(list: { QueueTicket }, size: number): { number }
	local indices = {}
	for i, t in list do
		if t.partySize == size then
			table.insert(indices, i)
		end
	end
	return indices
end

function QueueService.CancelForParty(partyId: string)
	local ticket = ticketByPartyId[partyId]
	if ticket then
		for _, id in ticket.memberUserIds do
			LoadoutLockService.Unlock(id)
		end
		removeTicket(ticket)
	end
end

function QueueService.CancelForUser(userId: number)
	for _, list in queues do
		for i = #list, 1, -1 do
			local t = list[i]
			for _, uid in t.memberUserIds do
				if uid == userId then
					QueueService.CancelForParty(t.partyId)
					break
				end
			end
		end
	end
end

function QueueService.Enqueue(
	leader: Player,
	queueId: string,
	bossPref: BossQueueConfig.BossQueuePref?
): (boolean, string?)
	local def = QueueConfig.Get(queueId :: any)
	if not def then
		return false, "UnknownQueue"
	end

	if def.mode == "PvE" then
		local norm = BossQueueConfig.Normalize(bossPref)
		if not norm then
			return false, "InvalidBoss"
		end
		bossPref = norm
	else
		bossPref = nil
	end

	local party = PartyService.GetPartyForPlayer(leader.UserId)
	if not party then
		return false, "NoParty"
	end
	if party.leaderUserId ~= leader.UserId then
		return false, "NotLeader"
	end

	local partySize = #party.members
	if not QueueConfig.CanEnqueuePartySize(def, partySize) then
		return false, "WrongPartySize"
	end
	if not PartyService.AllReady(party) then
		return false, "MembersNotReady"
	end
	if ticketByPartyId[party.id] then
		return false, "AlreadyQueued"
	end

	ensureQueue(queueId)
	local ticket: QueueTicket = {
		ticketId = HttpService:GenerateGUID(false),
		queueId = queueId,
		partyId = party.id,
		memberUserIds = PartyService.GetMemberUserIds(party),
		partySize = partySize,
		bossPref = bossPref,
		enqueuedAt = os.clock(),
	}
	table.insert(queues[queueId], ticket)
	ticketByPartyId[party.id] = ticket
	for _, id in ticket.memberUserIds do
		LoadoutLockService.Lock(id)
	end

	QueueService.TryMatch(queueId)
	return true, nil
end

function QueueService.Cancel(leader: Player): (boolean, string?)
	local party = PartyService.GetPartyForPlayer(leader.UserId)
	if not party then
		return false, "NoParty"
	end
	if party.leaderUserId ~= leader.UserId then
		return false, "NotLeader"
	end
	QueueService.CancelForParty(party.id)
	return true, nil
end

local function matchPremades(list: { QueueTicket }, teamSize: number, queueId: string, placeKey: string)
	-- Aynı boyutta full premade vs full premade
	while true do
		local idx = filterBySize(list, teamSize)
		if #idx < 2 then
			break
		end
		-- İki en eski full premade (list sırası FIFO ≈ yaş)
		local a = takeTicket(list, idx[1])
		-- idx[2] kaydı idx[1] silindikten sonra kaymış olabilir — yeniden bul
		idx = filterBySize(list, teamSize)
		if #idx < 1 then
			-- a'yı geri koy
			table.insert(list, 1, a)
			ticketByPartyId[a.partyId] = a
			break
		end
		local b = takeTicket(list, idx[1])
		startMatch(queueId, placeKey, { { a }, { b } })
	end
end

local function match2v2Fillers(list: { QueueTicket }, queueId: string, placeKey: string, allowFiller: boolean)
	matchPremades(list, 2, queueId, placeKey)
	if not allowFiller then
		return
	end
	-- Solo+solo vs solo+solo (premade 2 asla sola düşmez)
	while true do
		local solos = filterBySize(list, 1)
		if #solos < 4 then
			break
		end
		local t1 = takeTicket(list, solos[1])
		solos = filterBySize(list, 1)
		local t2 = takeTicket(list, solos[1])
		solos = filterBySize(list, 1)
		local t3 = takeTicket(list, solos[1])
		solos = filterBySize(list, 1)
		local t4 = takeTicket(list, solos[1])
		startMatch(queueId, placeKey, { { t1, t2 }, { t3, t4 } })
	end
end

local function match3v3Fillers(list: { QueueTicket }, queueId: string, placeKey: string, allowFiller: boolean)
	matchPremades(list, 3, queueId, placeKey)
	if not allowFiller then
		return
	end
	-- (P2 + solo) vs (P2 + solo) — premade 3 asla 3 soloya düşmez; S+S+S takım yok
	while true do
		local duos = filterBySize(list, 2)
		local solos = filterBySize(list, 1)
		if #duos < 2 or #solos < 2 then
			break
		end
		local d1 = takeTicket(list, duos[1])
		duos = filterBySize(list, 2)
		local d2 = takeTicket(list, duos[1])
		solos = filterBySize(list, 1)
		local s1 = takeTicket(list, solos[1])
		solos = filterBySize(list, 1)
		local s2 = takeTicket(list, solos[1])
		startMatch(queueId, placeKey, { { d1, s1 }, { d2, s2 } })
	end
end

function QueueService.TryMatch(queueId: string)
	local def = QueueConfig.Get(queueId :: any)
	if not def then
		return
	end
	ensureQueue(queueId)
	local list = queues[queueId]

	if def.mode == "PvE" then
		local i = 1
		while i <= #list do
			local t = list[i]
			if t.partySize == def.teamSize then
				takeTicket(list, i)
				startMatch(queueId, def.placeKey, { { t } })
			else
				i += 1
			end
		end
		if #list > 0 and oldestWait(list) >= QueueConfig.FillerTimeoutSec then
			while #list > 0 do
				local anchor = takeTicket(list, 1)
				local group: { QueueTicket } = { anchor }
				local seats = anchor.partySize
				while seats < def.teamSize do
					local foundIdx = findCompatibleTicket(list, anchor, def.teamSize - seats)
					if not foundIdx then
						break
					end
					local nextTicket = takeTicket(list, foundIdx)
					table.insert(group, nextTicket)
					seats += nextTicket.partySize
				end
				if seats == def.teamSize then
					startMatch(queueId, def.placeKey, { group })
				else
					putTicketsBack(list, group)
					break
				end
			end
		end
		return
	end

	if def.teamSize == 1 then
		while #list >= 2 do
			local a = takeTicket(list, 1)
			local b = takeTicket(list, 1)
			startMatch(queueId, def.placeKey, { { a }, { b } })
		end
		return
	end

	local allowFiller = oldestWait(list) >= QueueConfig.FillerTimeoutSec

	if def.teamSize == 2 then
		match2v2Fillers(list, queueId, def.placeKey, allowFiller)
	elseif def.teamSize == 3 then
		match3v3Fillers(list, queueId, def.placeKey, allowFiller)
	end
end

-- Timeout dolunca filler için periyodik dene
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 2 then
		return
	end
	acc = 0
	for queueId in queues do
		QueueService.TryMatch(queueId)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	QueueService.CancelForUser(player.UserId)
end)

return QueueService
