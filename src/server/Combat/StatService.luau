--[[
	Player primary stats (server authoritative) + gear-derived secondary bonuses.
]]

local StatConfig = require(game.ReplicatedStorage.Shared.Config.StatConfig)
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local PassiveService = require(script.Parent.PassiveService)

export type PrimaryStats = {
	level: number,
	STR: number,
	DEX: number,
	VIT: number,
	INT: number,
}

local StatService = {}

local byUser: { [number]: PrimaryStats } = {}

local function clampStat(n: number): number
	return math.clamp(math.floor(n), 1, 999)
end

function StatService.Ensure(userId: number): PrimaryStats
	if not byUser[userId] then
		byUser[userId] = StatConfig.DefaultAllocated(StatConfig.DefaultLevel)
	end
	return byUser[userId]
end

function StatService.Get(userId: number): PrimaryStats
	local s = StatService.Ensure(userId)
	return {
		level = s.level,
		STR = s.STR,
		DEX = s.DEX,
		VIT = s.VIT,
		INT = s.INT,
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

function StatService.Reset(userId: number, level: number?): PrimaryStats
	byUser[userId] = StatConfig.DefaultAllocated(level or StatConfig.DefaultLevel)
	return StatService.Get(userId)
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
}
	local s = StatService.Ensure(userId)
	local gear = StatService.GearStats(userId)
	local passive = PassiveService.GetBonus(userId)
	local defVit = s.VIT * CombatConfig.KVitDef
	local resVit = s.VIT * CombatConfig.KVitRes
	return {
		hp = CombatConfig.BaseHp + s.VIT * CombatConfig.KVitHp,
		stamina = CombatConfig.BaseStam + s.VIT * CombatConfig.KVitStam,
		defenceFromVit = defVit,
		resistFromVit = resVit,
		gearDefence = gear.defence,
		gearResist = gear.resist,
		totalDefence = defVit + gear.defence,
		totalResist = resVit + gear.resist,
		passiveStatusPotency = passive.statusPotencyFlat,
		passiveBuffPotency = passive.buffPotencyFlat,
		passiveCritChance = passive.critChanceFlat,
		passiveDirectMult = passive.directMult,
	}
end

function StatService.Clear(userId: number)
	byUser[userId] = nil
	PassiveService.Clear(userId)
end

return StatService
