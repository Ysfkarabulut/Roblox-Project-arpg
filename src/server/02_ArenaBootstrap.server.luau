--[[
	Arena place bootstrap — dedicated PvP arena servers only.
]]

local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsPvpArena() then
	return
end

local ArenaMatchCoordinator = require(script.Parent.Pvp.ArenaMatchCoordinator)
ArenaMatchCoordinator.Start()

print("[ArenaBootstrap] Arena match coordinator ready")
