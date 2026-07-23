--[[
	Profile persistence bootstrap — loads before other server scripts (00_ prefix).
]]

local PlayerProfileService = require(script.Parent.Profile.PlayerProfileService)

PlayerProfileService.Start()
