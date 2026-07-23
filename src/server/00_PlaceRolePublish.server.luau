--[[
	Publish place role to ReplicatedStorage for client scripts (runs first).
]]

local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
PlaceRuntime.PublishRoleForClients()
