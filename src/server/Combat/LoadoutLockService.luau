--[[
	Loadout lock during queue / match.
]]

local LoadoutLockService = {}

local locked: { [number]: boolean } = {}

function LoadoutLockService.Lock(userId: number)
	locked[userId] = true
end

function LoadoutLockService.Unlock(userId: number)
	locked[userId] = nil
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
