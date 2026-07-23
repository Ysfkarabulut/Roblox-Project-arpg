--[[
	Saf Direct damage resolve — Crit → perks → Matchup → DR
	Stance (dodge/guard) applied by DamageService after this.
]]

local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local ElementMatchup = require(script.Parent.Parent.Config.ElementMatchup)

local DamagePipeline = {}

export type DirectCtx = {
	weaponBase: number,
	scalingStat: number,
	abilityPct: number?, -- nil = LA (100%)
	comboStep: number?, -- 1|2|3
	familyPerkMult: number?, -- L3 only
	backstabMult: number?,
	directBonusMult: number?,
	atkElement: string?,
	defChestElement: string?,
	defence: number,
	defenceShredPct: number?, -- 0-100
	critChancePct: number,
	critDamagePct: number, -- e.g. 150
	skipCrit: boolean?,
	skipMatchup: boolean?,
	skipDr: boolean?,
}

export type DirectResult = {
	rawBase: number,
	crit: boolean,
	critMult: number,
	afterPerks: number,
	afterMatchup: number,
	afterDr: number,
	matchupMult: number,
	effectiveDrPct: number,
}

function DamagePipeline.RollCrit(chancePct: number): boolean
	return math.random() * 100 < chancePct
end

function DamagePipeline.ResolveDirect(ctx: DirectCtx): DirectResult
	local pct = ctx.abilityPct or 100
	local rawBase = ctx.weaponBase * (pct / 100) * (1 + ctx.scalingStat * CombatConfig.KDmg)

	local crit = false
	local critMult = 1
	if not ctx.skipCrit then
		crit = DamagePipeline.RollCrit(ctx.critChancePct)
		if crit then
			critMult = ctx.critDamagePct / 100
		end
	end
	rawBase *= critMult

	local combo = 1
	if ctx.comboStep == 2 then
		combo = CombatConfig.ComboL2
	elseif ctx.comboStep == 3 then
		combo = CombatConfig.ComboL3
	end
	local family = ctx.familyPerkMult or 1
	local backstab = ctx.backstabMult or 1
	local bonus = ctx.directBonusMult or 1
	local afterPerks = rawBase * combo * family * backstab * bonus

	local matchup = 1
	if not ctx.skipMatchup then
		matchup = ElementMatchup.GetMult(ctx.atkElement, ctx.defChestElement)
	end
	local afterMatchup = afterPerks * matchup

	local drPct = 0
	if not ctx.skipDr then
		drPct = math.min(ctx.defence * CombatConfig.KDr, CombatConfig.DrCapPvp)
		local shred = (ctx.defenceShredPct or 0) / 100
		drPct = drPct * (1 - shred)
	end
	local afterDr = afterMatchup * (1 - drPct / 100)

	return {
		rawBase = rawBase,
		crit = crit,
		critMult = critMult,
		afterPerks = afterPerks,
		afterMatchup = afterMatchup,
		afterDr = afterDr,
		matchupMult = matchup,
		effectiveDrPct = drPct,
	}
end

function DamagePipeline.CritStats(str: number, dex: number): (number, number)
	local chance = math.min(CombatConfig.BaseCrit + dex * CombatConfig.KDexCrit, CombatConfig.CritChanceCap)
	local dmg = math.min(CombatConfig.BaseCritDmg + str * CombatConfig.KStrCritDmg, CombatConfig.CritDmgCap)
	return chance, dmg
end

function DamagePipeline.AttackSpeedMult(asTier: string?, dex: number): number
	local tier = CombatConfig.AsTierMult[asTier or "B"] or 1
	return math.min(tier * (1 + dex * CombatConfig.KDexAs), CombatConfig.AsCap)
end

function DamagePipeline.HitRecovery(asTier: string?, dex: number, comboStep: number?, attackSpeedMult: number?): number
	local step = math.clamp(comboStep or 1, 1, 3)
	local stepMult = CombatConfig.ComboRecoveryStepMult[step] or 1
	local asMult = math.clamp(attackSpeedMult or DamagePipeline.AttackSpeedMult(asTier, dex), 0.65, CombatConfig.AsCap)
	return (CombatConfig.ComboHitRecoveryBase / asMult) * stepMult
end

return DamagePipeline
