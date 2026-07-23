--[[
	Boss place bootstrap.
]]

local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
if PlaceRuntime.GetRole() ~= "PveBossEye" then
	return
end

local BossMatchCoordinator = require(script.Parent.Boss.BossMatchCoordinator)
BossMatchCoordinator.Start()
