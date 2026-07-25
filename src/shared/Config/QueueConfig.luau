-- MODES.md §3 / §5b — queue kimlikleri + filler kuralları.

export type QueueId =
	"pvp_1v1_casual"
	| "pvp_1v1_ranked"
	| "pvp_2v2_casual"
	| "pvp_2v2_ranked"
	| "pvp_3v3_casual"
	| "pvp_3v3_ranked"
	| "pve_boss_solo"
	| "pve_boss_duo"
	| "pve_boss_trio"

export type QueueDef = {
	id: QueueId,
	mode: "PvP" | "PvE",
	-- PvP: takım / maç başına oyuncu sayısı. PvE: gerekli parti boyutu (tam).
	teamSize: number,
	placeKey: string,
	ranked: boolean?,
}

local QueueConfig = {
	MaxPartySize = 3,

	-- Premade eşleşme bulunamazsa filler aranmadan önce bekleme (sn)
	FillerTimeoutSec = 45,

	Queues = {
		pvp_1v1_casual = { id = "pvp_1v1_casual", mode = "PvP", teamSize = 1, placeKey = "Pvp1v1", ranked = false },
		pvp_1v1_ranked = { id = "pvp_1v1_ranked", mode = "PvP", teamSize = 1, placeKey = "Pvp1v1", ranked = true },
		pvp_2v2_casual = { id = "pvp_2v2_casual", mode = "PvP", teamSize = 2, placeKey = "Pvp2v2", ranked = false },
		pvp_2v2_ranked = { id = "pvp_2v2_ranked", mode = "PvP", teamSize = 2, placeKey = "Pvp2v2", ranked = true },
		pvp_3v3_casual = { id = "pvp_3v3_casual", mode = "PvP", teamSize = 3, placeKey = "Pvp3v3", ranked = false },
		pvp_3v3_ranked = { id = "pvp_3v3_ranked", mode = "PvP", teamSize = 3, placeKey = "Pvp3v3", ranked = true },
		pve_boss_solo = { id = "pve_boss_solo", mode = "PvE", teamSize = 1, placeKey = "PveBoss" },
		pve_boss_duo = { id = "pve_boss_duo", mode = "PvE", teamSize = 2, placeKey = "PveBoss" },
		pve_boss_trio = { id = "pve_boss_trio", mode = "PvE", teamSize = 3, placeKey = "PveBoss" },
	} :: { [QueueId]: QueueDef },
}

function QueueConfig.Get(id: QueueId): QueueDef?
	return QueueConfig.Queues[id]
end

-- Solo 2v2/3v3 queue'a girebilir; parti boyutu 1..teamSize.
function QueueConfig.CanEnqueuePartySize(def: QueueDef, partySize: number): boolean
	if def.mode == "PvE" then
		return partySize >= 1 and partySize <= def.teamSize
	end
	-- PvP: 1v1 yalnızca solo; 2v2/3v3 = 1..teamSize
	if def.teamSize == 1 then
		return partySize == 1
	end
	return partySize >= 1 and partySize <= def.teamSize
end

return QueueConfig
