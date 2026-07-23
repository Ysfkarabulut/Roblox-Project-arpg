--[[
	Player-to-player trade — invite by username, then bilateral lootbox exchange.
]]

local Players = game:GetService("Players")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local InventoryService = require(script.Parent.Inventory.InventoryService)
local LoadoutService = require(script.Parent.Inventory.LoadoutService)

local TradeService = {}

export type OfferLine = {
	uuid: string,
	name: string,
}

export type TradeSnapshot = {
	ok: boolean,
	reason: string?,
	partnerUserId: number?,
	myOffers: { string }?,
	partnerOffers: { string }?,
	myOfferLines: { OfferLine }?,
	partnerOfferLines: { OfferLine }?,
	myReady: boolean?,
	partnerReady: boolean?,
}

export type TradeInvitePayload = {
	fromUserId: number,
	fromName: string,
	starterOfferUuid: string?,
}

local MAX_OFFERS = 6
local MAX_DISTANCE = 48
local INVITE_TTL_SEC = 90

type Session = {
	a: number,
	b: number,
	offersA: { string },
	offersB: { string },
	readyA: boolean,
	readyB: boolean,
}

type PendingInvite = {
	fromUserId: number,
	starterOfferUuid: string?,
	expiresAt: number,
}

local sessions: { [string]: Session } = {}
local partnerOf: { [number]: number } = {}
local pendingTo: { [number]: PendingInvite } = {} -- targetUserId -> invite

local function sessionKey(a: number, b: number): string
	if a < b then
		return `{a}_{b}`
	end
	return `{b}_{a}`
end

local function getPartner(userId: number): number?
	return partnerOf[userId]
end

local function getSession(userId: number): Session?
	local partner = getPartner(userId)
	if not partner then
		return nil
	end
	return sessions[sessionKey(userId, partner)]
end

local function normalizeName(name: string): string
	return string.lower((string.gsub(name, "^%s+", "")):gsub("%s+$", ""))
end

function TradeService.FindPlayerByName(name: string): Player?
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

local function playerDistance(a: Player, b: Player): number
	local ca, cb = a.Character, b.Character
	local pa = ca and ca:FindFirstChild("HumanoidRootPart") :: BasePart?
	local pb = cb and cb:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not pa or not pb then
		return math.huge
	end
	return (pa.Position - pb.Position).Magnitude
end

local function validateOffer(userId: number, uuid: string): (boolean, string?)
	local item = InventoryService.Find(userId, uuid)
	if not item then
		return false, "NoItem"
	end
	local def = ItemDefs.Get(item.defId)
	if not ItemDefs.IsTradeable(def) then
		return false, "NotTradeable"
	end
	if InventoryService.IsInstalled(userId, uuid) then
		return false, "Installed"
	end
	if LoadoutService.GetSlotOf(userId, uuid) then
		return false, "Equipped"
	end
	return true
end

local function clearSession(key: string)
	local session = sessions[key]
	if not session then
		return
	end
	partnerOf[session.a] = nil
	partnerOf[session.b] = nil
	sessions[key] = nil
end

local function clearInviteFor(userId: number)
	pendingTo[userId] = nil
end

local function offersFor(session: Session, userId: number): { string }
	if session.a == userId then
		return session.offersA
	end
	return session.offersB
end

local function setReady(session: Session, userId: number, ready: boolean)
	if session.a == userId then
		session.readyA = ready
	else
		session.readyB = ready
	end
end

local function isReady(session: Session, userId: number): boolean
	if session.a == userId then
		return session.readyA
	end
	return session.readyB
end

local function createSession(fromPlayer: Player, toPlayer: Player): (boolean, string?)
	if fromPlayer.UserId == toPlayer.UserId then
		return false, "Self"
	end
	if getPartner(fromPlayer.UserId) or getPartner(toPlayer.UserId) then
		return false, "Busy"
	end
	local key = sessionKey(fromPlayer.UserId, toPlayer.UserId)
	sessions[key] = {
		a = fromPlayer.UserId,
		b = toPlayer.UserId,
		offersA = {},
		offersB = {},
		readyA = false,
		readyB = false,
	}
	partnerOf[fromPlayer.UserId] = toPlayer.UserId
	partnerOf[toPlayer.UserId] = fromPlayer.UserId
	return true, nil
end

local function offerLines(userId: number, uuids: { string }): { OfferLine }
	local lines: { OfferLine } = {}
	for _, uuid in uuids do
		local item = InventoryService.Find(userId, uuid)
		local name = "Unknown item"
		if item then
			local def = ItemDefs.Get(item.defId)
			name = if def and def.name then def.name else item.defId
		end
		table.insert(lines, { uuid = uuid, name = name })
	end
	return lines
end

function TradeService.SnapshotFor(userId: number): TradeSnapshot
	local partnerId = getPartner(userId)
	local session = getSession(userId)
	if not partnerId or not session then
		return { ok = false, reason = "NoSession" }
	end
	local myOffers = offersFor(session, userId)
	local partnerOffers = offersFor(session, partnerId)
	return {
		ok = true,
		partnerUserId = partnerId,
		myOffers = myOffers,
		partnerOffers = partnerOffers,
		myOfferLines = offerLines(userId, myOffers),
		partnerOfferLines = offerLines(partnerId, partnerOffers),
		myReady = isReady(session, userId),
		partnerReady = isReady(session, partnerId),
	}
end

function TradeService.GetPendingInvite(userId: number): TradeInvitePayload?
	local invite = pendingTo[userId]
	if not invite then
		return nil
	end
	if os.clock() > invite.expiresAt then
		clearInviteFor(userId)
		return nil
	end
	local fromPlr = Players:GetPlayerByUserId(invite.fromUserId)
	if not fromPlr then
		clearInviteFor(userId)
		return nil
	end
	return {
		fromUserId = invite.fromUserId,
		fromName = fromPlr.DisplayName,
		starterOfferUuid = invite.starterOfferUuid,
	}
end

function TradeService.SendInvite(fromPlayer: Player, toPlayer: Player, starterOfferUuid: string?): (boolean, string?)
	if fromPlayer.UserId == toPlayer.UserId then
		return false, "Self"
	end
	if getPartner(fromPlayer.UserId) or getPartner(toPlayer.UserId) then
		return false, "Busy"
	end
	if pendingTo[toPlayer.UserId] then
		return false, "InvitePending"
	end
	if typeof(starterOfferUuid) == "string" then
		local ok, err = validateOffer(fromPlayer.UserId, starterOfferUuid)
		if not ok then
			return false, err
		end
	end
	pendingTo[toPlayer.UserId] = {
		fromUserId = fromPlayer.UserId,
		starterOfferUuid = starterOfferUuid,
		expiresAt = os.clock() + INVITE_TTL_SEC,
	}
	return true, nil
end

function TradeService.DeclineInvite(targetUserId: number, fromUserId: number): boolean
	local invite = pendingTo[targetUserId]
	if not invite or invite.fromUserId ~= fromUserId then
		return false
	end
	clearInviteFor(targetUserId)
	return true
end

function TradeService.AcceptInvite(targetUserId: number, fromUserId: number): (boolean, string?)
	local invite = pendingTo[targetUserId]
	if not invite or invite.fromUserId ~= fromUserId then
		return false, "NoInvite"
	end
	if os.clock() > invite.expiresAt then
		clearInviteFor(targetUserId)
		return false, "InviteExpired"
	end

	local fromPlr = Players:GetPlayerByUserId(fromUserId)
	local toPlr = Players:GetPlayerByUserId(targetUserId)
	if not fromPlr or not toPlr then
		clearInviteFor(targetUserId)
		return false, "Offline"
	end

	clearInviteFor(targetUserId)
	local ok, err = createSession(fromPlr, toPlr)
	if not ok then
		return false, err
	end

	if invite.starterOfferUuid then
		TradeService.AddOffer(fromUserId, invite.starterOfferUuid)
	end
	return true, nil
end

function TradeService.Cancel(userId: number)
	local partner = getPartner(userId)
	if partner then
		clearSession(sessionKey(userId, partner))
	end
	clearInviteFor(userId)
	for targetId, invite in pendingTo do
		if invite.fromUserId == userId then
			pendingTo[targetId] = nil
		end
	end
end

function TradeService.AddOffer(userId: number, uuid: string): (boolean, string?)
	local session = getSession(userId)
	if not session then
		return false, "NoSession"
	end
	setReady(session, userId, false)
	setReady(session, getPartner(userId) :: number, false)

	local ok, err = validateOffer(userId, uuid)
	if not ok then
		return false, err
	end
	local offers = offersFor(session, userId)
	for _, existing in offers do
		if existing == uuid then
			return true, nil
		end
	end
	if #offers >= MAX_OFFERS then
		return false, "Full"
	end
	table.insert(offers, uuid)
	return true, nil
end

function TradeService.RemoveOffer(userId: number, uuid: string): boolean
	local session = getSession(userId)
	if not session then
		return false
	end
	setReady(session, userId, false)
	setReady(session, getPartner(userId) :: number, false)
	local offers = offersFor(session, userId)
	for i, id in offers do
		if id == uuid then
			table.remove(offers, i)
			return true
		end
	end
	return false
end

function TradeService.SetReady(userId: number, ready: boolean): (boolean, string?)
	local session = getSession(userId)
	if not session then
		return false, "NoSession"
	end
	setReady(session, userId, ready)
	return true, nil
end

function TradeService.TryExecute(userId: number): (boolean, string?)
	local partnerId = getPartner(userId)
	local session = getSession(userId)
	if not session or not partnerId then
		return false, "NoSession"
	end
	if not (session.readyA and session.readyB) then
		return false, "NotReady"
	end

	local playerA = Players:GetPlayerByUserId(session.a)
	local playerB = Players:GetPlayerByUserId(session.b)
	if not playerA or not playerB then
		clearSession(sessionKey(session.a, session.b))
		return false, "Offline"
	end
	if playerDistance(playerA, playerB) > MAX_DISTANCE then
		return false, "TooFar"
	end

	for _, uuid in session.offersA do
		local ok, err = validateOffer(session.a, uuid)
		if not ok then
			return false, err or "InvalidOffer"
		end
	end
	for _, uuid in session.offersB do
		local ok, err = validateOffer(session.b, uuid)
		if not ok then
			return false, err or "InvalidOffer"
		end
	end

	local key = sessionKey(session.a, session.b)
	for _, uuid in session.offersA do
		if not InventoryService.TransferItem(session.a, session.b, uuid) then
			clearSession(key)
			return false, "TransferFailed"
		end
	end
	for _, uuid in session.offersB do
		if not InventoryService.TransferItem(session.b, session.a, uuid) then
			clearSession(key)
			return false, "TransferFailed"
		end
	end

	clearSession(key)
	return true, nil
end

function TradeService.ClearUser(userId: number)
	TradeService.Cancel(userId)
end

Players.PlayerRemoving:Connect(function(player)
	TradeService.ClearUser(player.UserId)
end)

return TradeService
