-- PlaceId'leri Roblox Creator Dashboard'dan doldur.
-- Lobby + her PvP bracket ayrı place (TeleportService).
-- Studio: PlaceIds = 0 → aynı place, offset greybox arena (PlaceRole ile arena test).

export type PlaceKey =
	"Lobby"
	| "Pvp1v1"
	| "Pvp2v2"
	| "Pvp3v3"
	| "PveBoss"
	| "PveBossEye"

local PlaceConfig = {
	-- Creator Dashboard → Experience → Places → copy PlaceId here.
	-- Studio: 0 = same place stub (offset greybox arena via PlaceRole).
	PlaceIds = {
		Lobby = 0,
		Pvp1v1 = 0,
		Pvp2v2 = 0,
		Pvp3v3 = 0,
		PveBoss = 0, -- shared PvE boss instance (Eye + Breaker)
		PveBossEye = 0, -- legacy alias — same PlaceId as PveBoss
	} :: { [PlaceKey]: number },
}

local function resolveBossPlaceId(): number
	local boss = PlaceConfig.PlaceIds.PveBoss
	local legacy = PlaceConfig.PlaceIds.PveBossEye
	if typeof(boss) == "number" and boss > 0 then
		return boss
	end
	if typeof(legacy) == "number" and legacy > 0 then
		return legacy
	end
	return 0
end

function PlaceConfig.GetPlaceId(key: PlaceKey): number
	if key == "PveBoss" or key == "PveBossEye" then
		return resolveBossPlaceId()
	end
	return PlaceConfig.PlaceIds[key] or 0
end

function PlaceConfig.IsConfigured(key: PlaceKey): boolean
	return PlaceConfig.GetPlaceId(key) > 0
end

function PlaceConfig.IsPveBossKey(placeKey: string): boolean
	return placeKey == "PveBoss" or placeKey == "PveBossEye"
end

return PlaceConfig
