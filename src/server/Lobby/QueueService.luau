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

local QueueConfig = require(game.ReplicatedStorage.Shared.Config.QueueConfig)
local PartyService = require(script.Parent.PartyService)
local MatchTeleport = require(script.Parent.MatchTeleport)

type QueueDef = QueueConfig.QueueDef

export type QueueTicket = {
	ticketId: string,
	queueId: string,
	partyId: string,
	memberUserIds: { number },
	partySize: number,
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

local function startMatch(queueId: string, placeKey: string, teamTickets: { { QueueTicket } })
	local teams = {}
	for _, group in teamTickets do
		table.insert(teams, mergeMembers(group))
	end
	MatchTeleport.StartMatch({
		matchId = HttpService:GenerateGUID(false),
		queueId = queueId,
		placeKey = placeKey,
		teams = teams,
	})
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
		removeTicket(ticket)
	end
end

function QueueService.Enqueue(leader: Player, queueId: string): (boolean, string?)
	local def = QueueConfig.Get(queueId :: any)
	if not def then
		return false, "UnknownQueue"
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
		enqueuedAt = os.clock(),
	}
	table.insert(queues[queueId], ticket)
	ticketByPartyId[party.id] = ticket

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
		while #list >= 1 do
			local a = takeTicket(list, 1)
			startMatch(queueId, def.placeKey, { { a } })
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

return QueueService
