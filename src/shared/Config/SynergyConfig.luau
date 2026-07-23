--[[
	Element synergy bands — CHEMISTRY_ENGINE.md §3
]]

export type SynergyBand = "None" | "Pure" | "Duality" | "Harmony" | "Unbound"

export type SynergyResult = {
	band: SynergyBand,
	pureElement: string?,
	dualityElements: { string }?,
	directMult: number,
	defenceBonusPct: number,
	resistBonusPct: number,
	statusPotencyFlat: number,
	pureOnHitBonus: { durationMult: number?, dpsBonus: number? }?,
}

local SynergyConfig = {
	SlotWeight = {
		main1H = 1,
		main2H = 2,
		offTagged = 1,
		offUntagged = 0,
		chest = 1,
	},
	Duality = { defencePct = 0.05, resistPct = 0.05 },
	Harmony = { statusPotencyFlat = 15 },
	Unbound = { directMult = 1.05, defencePct = 0.10, resistPct = 0.12 },
	PureDurationMult = {
		Fire = 1.15,
		Wind = 1.20,
		Rock = 1.15,
		Steel = 1.0,
	},
	PureDpsBonus = {
		Poison = 1,
		Steel = 0,
	},
}

return SynergyConfig
