--[[
	Loadout lock during queue / match.
]]

local Players = game:GetService("Players")

local LoadoutLockService = {}

local locked: { [number]: boolean } = {}

local function setPlayerAttribute(userId: number, value: boolean?)
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		plr:SetAttribute("LoadoutLocked", value == true)
	end
end

function LoadoutLockService.Lock(userId: number)
	locked[userId] = true
	setPlayerAttribute(userId, true)
end

function LoadoutLockService.Unlock(userId: number)
	locked[userId] = nil
	setPlayerAttribute(userId, nil)
end

function LoadoutLockService.IsLocked(userId: number): boolean
	return locked[userId] == true
end

function LoadoutLockService.UnlockMany(userIds: { number })
	for _, id in userIds do
		LoadoutLockService.Unlock(id)
	end
end

return LoadoutLockService
