-- Party + queue paylaşılan tipler.

export type PartyMember = {
	userId: number,
	ready: boolean,
}

export type Party = {
	id: string,
	leaderUserId: number,
	members: { PartyMember },
}

export type QueueTicket = {
	ticketId: string,
	queueId: string,
	partyId: string,
	memberUserIds: { number },
	enqueuedAt: number,
}

export type MatchPayload = {
	matchId: string,
	queueId: string,
	placeKey: string,
	-- PvP: iki takım; PvE: tek liste
	teams: { { number } },
}

return {}
