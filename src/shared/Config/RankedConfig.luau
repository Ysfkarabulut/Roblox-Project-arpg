--[[
	Ranked MMR + tiers — MODES.md §3.6
]]

local RankedConfig = {
	StartingMmr = 1000,
	KFactor = 32,
	Tiers = {
		{ name = "Rookie", min = 0 },
		{ name = "Contender", min = 1100 },
		{ name = "Veteran", min = 1300 },
		{ name = "Champion", min = 1500 },
		{ name = "Gladiator", min = 1700 },
	},
	BracketKeys = {
		pvp_1v1_ranked = "pvp_1v1",
		pvp_2v2_ranked = "pvp_2v2",
		pvp_3v3_ranked = "pvp_3v3",
	},
}

function RankedConfig.BracketKey(queueId: string): string?
	return RankedConfig.BracketKeys[queueId]
end

function RankedConfig.TierForMmr(mmr: number): string
	local tier = RankedConfig.Tiers[1].name
	for _, t in RankedConfig.Tiers do
		if mmr >= t.min then
			tier = t.name
		end
	end
	return tier
end

function RankedConfig.ExpectedScore(playerMmr: number, opponentMmr: number): number
	return 1 / (1 + 10 ^ ((opponentMmr - playerMmr) / 400))
end

function RankedConfig.Delta(playerMmr: number, opponentMmr: number, won: boolean): number
	local expected = RankedConfig.ExpectedScore(playerMmr, opponentMmr)
	local score = if won then 1 else 0
	return math.floor(RankedConfig.KFactor * (score - expected) + 0.5)
end

return RankedConfig
