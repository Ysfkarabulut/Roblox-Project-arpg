-- PlaceId'leri Roblox Creator Dashboard'dan doldur.
-- Lobby / PvP / Boss ayrı place = TeleportService loading screen.

export type PlaceKey =
	"Lobby"
	| "Pvp1v1"
	| "Pvp2v2"
	| "Pvp3v3"
	| "PveBossEye"

local PlaceConfig = {
	-- Studio test: 0 = aynı place'te kal (teleport yok)
	PlaceIds = {
		Lobby = 0,
		Pvp1v1 = 0,
		Pvp2v2 = 0,
		Pvp3v3 = 0,
		PveBossEye = 0,
	} :: { [PlaceKey]: number },
}

function PlaceConfig.GetPlaceId(key: PlaceKey): number
	return PlaceConfig.PlaceIds[key] or 0
end

function PlaceConfig.IsConfigured(key: PlaceKey): boolean
	local id = PlaceConfig.GetPlaceId(key)
	return id ~= nil and id > 0
end

return PlaceConfig
