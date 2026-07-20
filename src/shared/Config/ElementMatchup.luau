--[[
	Element matchup — CHEMISTRY §2.4
]]

local ElementMatchup = {}

local STRONG: { [string]: { [string]: boolean } } = {
	Fire = { Steel = true, Poison = true },
	Water = { Fire = true },
	Lightning = { Water = true },
	Wind = { Lightning = true },
	Poison = { Water = true },
	Rock = { Fire = true, Wind = true },
	Steel = { Rock = true },
}

local WEAK: { [string]: { [string]: boolean } } = {
	Fire = { Water = true, Rock = true },
	Water = { Lightning = true },
	Lightning = { Wind = true, Rock = true },
	Wind = { Rock = true },
	Poison = { Fire = true, Steel = true },
	Rock = { Steel = true },
	Steel = { Fire = true, Poison = true },
}

function ElementMatchup.GetMult(atkElement: string?, defChestElement: string?): number
	local a = atkElement or "Neutral"
	local d = defChestElement or "Neutral"
	if a == "Neutral" or d == "Neutral" then
		return 1
	end
	if STRONG[a] and STRONG[a][d] then
		return 1.15
	end
	if WEAK[a] and WEAK[a][d] then
		return 0.85
	end
	return 1
end

return ElementMatchup
