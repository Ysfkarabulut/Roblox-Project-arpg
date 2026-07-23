--[[
	Per-bracket MMR persistence + match updates.
]]

local RankedConfig = require(game.ReplicatedStorage.Shared.Config.RankedConfig)

local RankedService = {}

local mmrByUser: { [number]: { [string]: number } } = {}

function RankedService.Ensure(userId: number)
	if not mmrByUser[userId] then
		mmrByUser[userId] = {
			pvp_1v1 = RankedConfig.StartingMmr,
			pvp_2v2 = RankedConfig.StartingMmr,
			pvp_3v3 = RankedConfig.StartingMmr,
		}
	end
end

function RankedService.Import(userId: number, data: { [string]: number }?)
	RankedService.Ensure(userId)
	if typeof(data) ~= "table" then
		return
	end
	for key, val in data do
		if typeof(val) == "number" and val >= 0 then
			mmrByUser[userId][key] = math.floor(val)
		end
	end
end

function RankedService.Export(userId: number): { [string]: number }
	RankedService.Ensure(userId)
	return table.clone(mmrByUser[userId])
end

function RankedService.GetMmr(userId: number, bracketKey: string): number
	RankedService.Ensure(userId)
	return mmrByUser[userId][bracketKey] or RankedConfig.StartingMmr
end

function RankedService.GetTier(userId: number, bracketKey: string): string
	return RankedConfig.TierForMmr(RankedService.GetMmr(userId, bracketKey))
end

function RankedService.ApplyMatchResult(
	queueId: string,
	winnerUserIds: { number },
	loserUserIds: { number }
): { [number]: { delta: number, mmr: number, tier: string } }
	local bracketKey = RankedConfig.BracketKey(queueId)
	if not bracketKey then
		return {}
	end

	local avg = function(ids: { number }): number
		if #ids == 0 then
			return RankedConfig.StartingMmr
		end
		local sum = 0
		for _, id in ids do
			sum += RankedService.GetMmr(id, bracketKey)
		end
		return sum / #ids
	end

	local winnerAvg = avg(winnerUserIds)
	local loserAvg = avg(loserUserIds)
	local out: { [number]: { delta: number, mmr: number, tier: string } } = {}

	for _, id in winnerUserIds do
		local mmr = RankedService.GetMmr(id, bracketKey)
		local delta = RankedConfig.Delta(mmr, loserAvg, true)
		mmrByUser[id][bracketKey] = math.max(0, mmr + delta)
		out[id] = {
			delta = delta,
			mmr = mmrByUser[id][bracketKey],
			tier = RankedService.GetTier(id, bracketKey),
		}
	end
	for _, id in loserUserIds do
		local mmr = RankedService.GetMmr(id, bracketKey)
		local delta = RankedConfig.Delta(mmr, winnerAvg, false)
		mmrByUser[id][bracketKey] = math.max(0, mmr + delta)
		out[id] = {
			delta = delta,
			mmr = mmrByUser[id][bracketKey],
			tier = RankedService.GetTier(id, bracketKey),
		}
	end
	return out
end

function RankedService.Clear(userId: number)
	mmrByUser[userId] = nil
end

return RankedService
