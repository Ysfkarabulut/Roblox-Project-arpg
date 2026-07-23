--[[
	Resolve loadout element synergy band + stat bonuses.
]]

local ItemDefs = require(script.Parent.Parent.Config.ItemDefs)
local WeaponResolver = require(script.Parent.WeaponResolver)
local SynergyConfig = require(script.Parent.Parent.Config.SynergyConfig)

local SynergyService = {}

export type WeightedElement = { element: string, weight: number }

local function neutral(el: string?): boolean
	return el == nil or el == "" or el == "Neutral"
end

local function mainWeight(resolved: any): number
	if not resolved or not resolved.complete then
		return 0
	end
	local fam = resolved.family
	if fam == "Bow" or fam == "Crossbow" or fam == "Staff" then
		return SynergyConfig.SlotWeight.main2H
	end
	local kind = resolved.kind
	if kind and string.find(kind, "2H") then
		return SynergyConfig.SlotWeight.main2H
	end
	return SynergyConfig.SlotWeight.main1H
end

local function offWeight(offDef: any): number
	if not offDef then
		return 0
	end
	if neutral(offDef.element) then
		return SynergyConfig.SlotWeight.offUntagged
	end
	return SynergyConfig.SlotWeight.offTagged
end

function SynergyService.ResolveFromElements(mainEl: string?, offEl: string?, chestEl: string?, mainW: number): SynergyConfig.SynergyResult
	local none: SynergyConfig.SynergyResult = {
		band = "None",
		pureElement = nil,
		dualityElements = nil,
		directMult = 1,
		defenceBonusPct = 0,
		resistBonusPct = 0,
		statusPotencyFlat = 0,
		pureOnHitBonus = nil,
	}

	local weights: { WeightedElement } = {}
	if not neutral(mainEl) and mainW > 0 then
		table.insert(weights, { element = mainEl :: string, weight = mainW })
	end
	if not neutral(offEl) then
		table.insert(weights, { element = offEl :: string, weight = SynergyConfig.SlotWeight.offTagged })
	end
	if not neutral(chestEl) then
		table.insert(weights, { element = chestEl :: string, weight = SynergyConfig.SlotWeight.chest })
	end

	if #weights == 0 then
		return none
	end

	if neutral(mainEl) and neutral(offEl) and neutral(chestEl) then
		return none
	end

	local allNeutral = neutral(mainEl) and (neutral(offEl) or offWeight(nil) == 0) and neutral(chestEl)
	if neutral(mainEl) and neutral(chestEl) and (offEl == nil or neutral(offEl)) then
		allNeutral = true
	end

	local taggedCount = 0
	for _, w in weights do
		if not neutral(w.element) then
			taggedCount += 1
		end
	end

	if neutral(mainEl) and neutral(offEl) and neutral(chestEl) then
		return {
			band = "Unbound",
			pureElement = nil,
			dualityElements = nil,
			directMult = SynergyConfig.Unbound.directMult,
			defenceBonusPct = SynergyConfig.Unbound.defencePct,
			resistBonusPct = SynergyConfig.Unbound.resistPct,
			statusPotencyFlat = 0,
			pureOnHitBonus = nil,
		}
	end

	local totalW = 0
	local byElement: { [string]: number } = {}
	for _, w in weights do
		totalW += w.weight
		byElement[w.element] = (byElement[w.element] or 0) + w.weight
	end

	local distinct: { string } = {}
	for el in byElement do
		if not neutral(el) then
			table.insert(distinct, el)
		end
	end
	table.sort(distinct)

	if #distinct == 1 and totalW == 3 then
		local el = distinct[1]
		return {
			band = "Pure",
			pureElement = el,
			dualityElements = nil,
			directMult = 1,
			defenceBonusPct = 0,
			resistBonusPct = 0,
			statusPotencyFlat = 0,
			pureOnHitBonus = {
				durationMult = SynergyConfig.PureDurationMult[el],
				dpsBonus = SynergyConfig.PureDpsBonus[el],
			},
		}
	end

	if #distinct == 2 and totalW == 3 then
		local w1, w2 = byElement[distinct[1]], byElement[distinct[2]]
		if (w1 == 2 and w2 == 1) or (w1 == 1 and w2 == 2) then
			return {
				band = "Duality",
				pureElement = nil,
				dualityElements = distinct,
				directMult = 1,
				defenceBonusPct = SynergyConfig.Duality.defencePct,
				resistBonusPct = SynergyConfig.Duality.resistPct,
				statusPotencyFlat = 0,
				pureOnHitBonus = nil,
			}
		end
	end

	if #distinct == 3 and totalW == 3 and mainW == 1 then
		return {
			band = "Harmony",
			pureElement = nil,
			dualityElements = distinct,
			directMult = 1,
			defenceBonusPct = 0,
			resistBonusPct = 0,
			statusPotencyFlat = SynergyConfig.Harmony.statusPotencyFlat,
			pureOnHitBonus = nil,
		}
	end

	if neutral(mainEl) and neutral(offEl) and neutral(chestEl) then
		return {
			band = "Unbound",
			pureElement = nil,
			dualityElements = nil,
			directMult = SynergyConfig.Unbound.directMult,
			defenceBonusPct = SynergyConfig.Unbound.defencePct,
			resistBonusPct = SynergyConfig.Unbound.resistPct,
			statusPotencyFlat = 0,
			pureOnHitBonus = nil,
		}
	end

	return none
end

function SynergyService.ResolveLoadout(
	userId: number,
	loadout: any,
	resolvedMain: any,
	getItemDef: (uuid: string) -> any
): SynergyConfig.SynergyResult
	local mainEl = if resolvedMain and resolvedMain.complete then resolvedMain.element else nil
	local mainW = mainWeight(resolvedMain)

	local offDef = nil
	if loadout.off then
		local inst = getItemDef(loadout.off)
		offDef = inst and ItemDefs.Get(inst.defId)
	end
	local chestDef = nil
	if loadout.chest then
		local inst = getItemDef(loadout.chest)
		chestDef = inst and ItemDefs.Get(inst.defId)
	end

	local offEl = if offDef and not neutral(offDef.element) then offDef.element else nil
	local chestEl = if chestDef and not neutral(chestDef.element) then chestDef.element else nil

	if neutral(mainEl) and neutral(offEl) and neutral(chestEl) then
		return {
			band = "Unbound",
			pureElement = nil,
			dualityElements = nil,
			directMult = SynergyConfig.Unbound.directMult,
			defenceBonusPct = SynergyConfig.Unbound.defencePct,
			resistBonusPct = SynergyConfig.Unbound.resistPct,
			statusPotencyFlat = 0,
			pureOnHitBonus = nil,
		}
	end

	return SynergyService.ResolveFromElements(mainEl, offEl, chestEl, mainW)
end

return SynergyService
