--[[
	Player primary stats (server authoritative) + gear-derived secondary bonuses.
]]

local StatConfig = require(game.ReplicatedStorage.Shared.Config.StatConfig)
local XpConfig = require(game.ReplicatedStorage.Shared.Config.XpConfig)
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local PassiveService = require(script.Parent.PassiveService)
local SynergyService = require(game.ReplicatedStorage.Shared.Combat.SynergyService)

local PURE_PERK_LINES = {
	Fire = "Guaranteed Ignite · +15% duration",
	Water = "Guaranteed Wet · 8 stud splash",
	Lightning = "Guaranteed Shock · +0.15s",
	Wind = "Guaranteed Windy · +20% duration · +3% slow",
	Poison = "Guaranteed Poisoned · +1 DPS",
	Rock = "Guaranteed Slow · +15% duration · +5% direct taken",
	Steel = "Guaranteed Bleed · +1s",
}

local function synergyPerkLine(synergy: any): string
	if synergy.band == "Pure" and synergy.pureElement then
		return PURE_PERK_LINES[synergy.pureElement] or "Guaranteed on-hit signature status"
	end
	if synergy.band == "Duality" and synergy.dualityElements then
		return `+5% Defence · +5% Resist ({table.concat(synergy.dualityElements, " + ")})`
	end
	if synergy.band == "Harmony" then
		return "+15 Status Potency"
	end
	if synergy.band == "Unbound" then
		return "+5% direct · +10% Defence · +12% Resist"
	end
	return "No active band"
end

export type PrimaryStats = {
	level: number,
	STR: number,
	DEX: number,
	VIT: number,
	INT: number,
}

local StatService = {}

local byUser: { [number]: PrimaryStats } = {}
local xpByUser: { [number]: number } = {}
local unspentByUser: { [number]: number } = {}

export type GrantXpResult = {
	xpGained: number,
	levelsGained: number,
	level: number,
	totalXp: number,
	xpIntoLevel: number,
	xpToNext: number,
	unspentGained: number,
	unspentTotal: number,
}

local function clampStat(n: number): number
	return math.clamp(math.floor(n), 1, 999)
end

function StatService.Ensure(userId: number): PrimaryStats
	if not byUser[userId] then
		byUser[userId] = StatConfig.DefaultAllocated(StatConfig.DefaultLevel)
		xpByUser[userId] = XpConfig.TotalXpForLevel(byUser[userId].level)
	end
	return byUser[userId]
end

function StatService.GetTotalXp(userId: number): number
	local s = StatService.Ensure(userId)
	return xpByUser[userId] or XpConfig.TotalXpForLevel(s.level)
end

function StatService.GetXpProgress(userId: number): XpConfig.XpProgress
	local s = StatService.Ensure(userId)
	return XpConfig.ProgressFromTotalXp(StatService.GetTotalXp(userId), s.level)
end

function StatService.GetUnspent(userId: number): number
	StatService.Ensure(userId)
	return math.max(0, math.floor(unspentByUser[userId] or 0))
end

function StatService.Get(userId: number): PrimaryStats & { unspent: number }
	local s = StatService.Ensure(userId)
	return {
		level = s.level,
		STR = s.STR,
		DEX = s.DEX,
		VIT = s.VIT,
		INT = s.INT,
		unspent = StatService.GetUnspent(userId),
	}
end

function StatService.Set(userId: number, patch: { [string]: number }): PrimaryStats
	local s = StatService.Ensure(userId)
	if typeof(patch.level) == "number" then
		s.level = math.clamp(math.floor(patch.level), 1, StatConfig.MaxLevel)
	end
	for _, key in { "STR", "DEX", "VIT", "INT" } do
		local v = patch[key]
		if typeof(v) == "number" then
			s[key] = clampStat(v)
		end
	end
	return StatService.Get(userId)
end

function StatService.Reset(userId: number, level: number?): PrimaryStats & { unspent: number }
	local lv = level or StatConfig.DefaultLevel
	byUser[userId] = StatConfig.DefaultAllocated(lv)
	xpByUser[userId] = XpConfig.TotalXpForLevel(byUser[userId].level)
	unspentByUser[userId] = 0
	return StatService.Get(userId)
end

function StatService.Import(
	userId: number,
	stats: { level: number, STR: number, DEX: number, VIT: number, INT: number },
	totalXp: number?,
	unspent: number?
)
	byUser[userId] = {
		level = math.clamp(math.floor(stats.level), 1, StatConfig.MaxLevel),
		STR = clampStat(stats.STR),
		DEX = clampStat(stats.DEX),
		VIT = clampStat(stats.VIT),
		INT = clampStat(stats.INT),
	}
	xpByUser[userId] = if typeof(totalXp) == "number"
		then math.max(0, math.floor(totalXp))
		else XpConfig.TotalXpForLevel(byUser[userId].level)
	unspentByUser[userId] = if typeof(unspent) == "number" then math.max(0, math.floor(unspent)) else 0
end

function StatService.AllocateStat(userId: number, statKey: string): (boolean, string?)
	local s = StatService.Ensure(userId)
	local unspent = StatService.GetUnspent(userId)
	if unspent <= 0 then
		return false, "NoPoints"
	end
	if statKey ~= "STR" and statKey ~= "DEX" and statKey ~= "VIT" and statKey ~= "INT" then
		return false, "BadStat"
	end
	unspentByUser[userId] = unspent - 1
	s[statKey] = clampStat((s :: any)[statKey] + 1)
	return true, nil
end

function StatService.GrantXp(userId: number, amount: number): GrantXpResult
	local s = StatService.Ensure(userId)
	local xpGain = math.max(0, math.floor(amount))
	if xpGain <= 0 then
		local progress = StatService.GetXpProgress(userId)
		return {
			xpGained = 0,
			levelsGained = 0,
			level = s.level,
			totalXp = progress.totalXp,
			xpIntoLevel = progress.xpIntoLevel,
			xpToNext = progress.xpToNext,
			unspentGained = 0,
			unspentTotal = StatService.GetUnspent(userId),
		}
	end

	local totalXp = StatService.GetTotalXp(userId) + xpGain
	local levelsGained = 0
	local unspentGained = 0

	while s.level < StatConfig.MaxLevel do
		local xpAtLevel = XpConfig.TotalXpForLevel(s.level)
		local need = XpConfig.XpRequiredForNextLevel(s.level)
		if totalXp < xpAtLevel + need then
			break
		end
		s.level += 1
		levelsGained += 1
		unspentGained += StatConfig.PointsPerLevel
	end

	if unspentGained > 0 then
		unspentByUser[userId] = StatService.GetUnspent(userId) + unspentGained
	end

	xpByUser[userId] = totalXp
	local progress = StatService.GetXpProgress(userId)
	return {
		xpGained = xpGain,
		levelsGained = levelsGained,
		level = s.level,
		totalXp = progress.totalXp,
		xpIntoLevel = progress.xpIntoLevel,
		xpToNext = progress.xpToNext,
		unspentGained = unspentGained,
		unspentTotal = StatService.GetUnspent(userId),
	}
end

function StatService.GearStats(userId: number): { defence: number, resist: number }
	local totalDef, totalRes = 0, 0
	local loadout = LoadoutService.Get(userId)
	for _, slotId in { "off", "head", "chest", "hands", "feets" } do
		local uuid = (loadout :: any)[slotId]
		if uuid then
			local inst = InventoryService.Find(userId, uuid)
			local def = inst and ItemDefs.Get(inst.defId)
			if def then
				totalDef += def.defence or 0
				totalRes += def.resist or 0
			end
		end
	end
	return { defence = totalDef, resist = totalRes }
end

function StatService.BuffPotency(userId: number): number
	local s = StatService.Ensure(userId)
	local passive = PassiveService.GetBonus(userId)
	return CombatConfig.BaseBuffPotency + s.INT * CombatConfig.KIntBuff + passive.buffPotencyFlat
end

function StatService.ScaleHeal(userId: number, baseHeal: number): number
	return baseHeal * (1 + StatService.BuffPotency(userId) * CombatConfig.KBuffHeal)
end

function StatService.ScaleBuffDuration(userId: number, baseDuration: number): number
	return baseDuration * (1 + StatService.BuffPotency(userId) * CombatConfig.KBuffDuration)
end

function StatService.Derived(userId: number): {
	hp: number,
	stamina: number,
	defenceFromVit: number,
	resistFromVit: number,
	gearDefence: number,
	gearResist: number,
	totalDefence: number,
	totalResist: number,
	passiveStatusPotency: number,
	passiveBuffPotency: number,
	passiveCritChance: number,
	passiveDirectMult: number,
	totalBuffPotency: number,
	synergyBand: string,
	synergyElement: string?,
	synergyElements: { string }?,
	synergyPerk: string,
}
	local s = StatService.Ensure(userId)
	local gear = StatService.GearStats(userId)
	local passive = PassiveService.GetBonus(userId)
	local loadout = LoadoutService.Get(userId)
	local resolved = LoadoutService.GetResolvedMain(userId)
	local synergy = SynergyService.ResolveLoadout(userId, loadout, resolved, function(uuid)
		return InventoryService.Find(userId, uuid)
	end)
	local defVit = s.VIT * CombatConfig.KVitDef
	local resVit = s.VIT * CombatConfig.KVitRes
	local baseDef = defVit + gear.defence
	local baseRes = resVit + gear.resist
	return {
		hp = CombatConfig.BaseHp + s.VIT * CombatConfig.KVitHp,
		stamina = CombatConfig.BaseStam + s.VIT * CombatConfig.KVitStam,
		defenceFromVit = defVit,
		resistFromVit = resVit,
		gearDefence = gear.defence,
		gearResist = gear.resist,
		totalDefence = math.floor(baseDef * (1 + synergy.defenceBonusPct) + 0.5),
		totalResist = math.floor(baseRes * (1 + synergy.resistBonusPct) + 0.5),
		passiveStatusPotency = passive.statusPotencyFlat + synergy.statusPotencyFlat,
		passiveBuffPotency = passive.buffPotencyFlat,
		passiveCritChance = passive.critChanceFlat,
		passiveDirectMult = passive.directMult * synergy.directMult,
		totalBuffPotency = StatService.BuffPotency(userId),
		synergyBand = synergy.band,
		synergyElement = synergy.pureElement,
		synergyElements = synergy.dualityElements,
		synergyPerk = synergyPerkLine(synergy),
	}
end

function StatService.Clear(userId: number)
	byUser[userId] = nil
	xpByUser[userId] = nil
	unspentByUser[userId] = nil
	PassiveService.Clear(userId)
end

return StatService
