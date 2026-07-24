--[[
	PvE boss kill counts — persisted in PlayerProfile.bossKills.
]]

local BossProgressService = {}

local killsByUser: { [number]: { [string]: number } } = {}

function BossProgressService.Ensure(userId: number)
	if not killsByUser[userId] then
		killsByUser[userId] = {}
	end
end

function BossProgressService.GetKills(userId: number, bossId: string): number
	BossProgressService.Ensure(userId)
	return killsByUser[userId][bossId] or 0
end

function BossProgressService.RecordKill(userId: number, bossId: string): number
	if typeof(bossId) ~= "string" or bossId == "" then
		return 0
	end
	BossProgressService.Ensure(userId)
	local nextCount = (killsByUser[userId][bossId] or 0) + 1
	killsByUser[userId][bossId] = nextCount
	return nextCount
end

function BossProgressService.Export(userId: number): { [string]: number }
	BossProgressService.Ensure(userId)
	return table.clone(killsByUser[userId])
end

function BossProgressService.Import(userId: number, data: { [string]: number }?)
	BossProgressService.Ensure(userId)
	killsByUser[userId] = {}
	if typeof(data) ~= "table" then
		return
	end
	for bossId, count in data do
		if typeof(bossId) == "string" and typeof(count) == "number" and count > 0 then
			killsByUser[userId][bossId] = math.floor(count)
		end
	end
end

function BossProgressService.Clear(userId: number)
	killsByUser[userId] = nil
end

return BossProgressService
