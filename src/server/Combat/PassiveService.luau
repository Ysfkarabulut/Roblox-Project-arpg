--[[
	PassiveService — loadout passive bonuses + LA on-hit procs.
	Stat / proc definitions → PassiveDefs.luau (global catalog).
]]

local ElementData = require(game.ReplicatedStorage.Shared.Config.ElementData)
local PassiveDefs = require(game.ReplicatedStorage.Shared.Config.PassiveDefs)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local WeaponAssemblyService = require(script.Parent.Parent.Inventory.WeaponAssemblyService)

local PassiveService = {}

export type PassiveBonus = {
	statusPotencyFlat: number,
	buffPotencyFlat: number,
	critChanceFlat: number,
	directMult: number,
}

export type OnHitStatus = {
	id: string,
	duration: number,
	dps: number?,
}

local bonuses: { [number]: PassiveBonus } = {}
local passiveIds: { [number]: { [string]: boolean } } = {}

local function emptyBonus(): PassiveBonus
	return {
		statusPotencyFlat = 0,
		buffPotencyFlat = 0,
		critChanceFlat = 0,
		directMult = 1,
	}
end

local function elementStatus(element: string): OnHitStatus?
	local sig = ElementData.Signature[element]
	if not sig or not sig.id then
		return nil
	end
	local dur = if element == "Lightning"
		then 0.5
		elseif element == "Steel" then 8
		elseif element == "Poison" then 5
		elseif element == "Water" then 5
		elseif element == "Wind" then 3
		elseif element == "Rock" then 2
		else 3
	local dps = if element == "Steel" then 4 elseif element == "Poison" then 3 elseif element == "Fire" then 7 else nil
	return { id = sig.id, duration = dur, dps = dps }
end

local function registerPassive(passiveSet: { [string]: boolean }, abilityId: string)
	passiveSet[abilityId] = true
end

local function applyPassiveId(bonus: PassiveBonus, passiveSet: { [string]: boolean }, abilityId: string)
	registerPassive(passiveSet, abilityId)
	PassiveDefs.ApplyStatBonus(bonus, abilityId)
end

local function collectFromAbilities(abilities: { any }?, bonus: PassiveBonus, passiveSet: { [string]: boolean })
	if not abilities then
		return
	end
	for _, ab in abilities do
		if ab.slotType == "Passive" then
			applyPassiveId(bonus, passiveSet, ab.id)
		end
	end
end

function PassiveService.Refresh(userId: number)
	local bonus = emptyBonus()
	local passiveSet: { [string]: boolean } = {}
	local loadout = LoadoutService.Get(userId)

	if loadout.main then
		local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
		if resolved and resolved.complete then
			collectFromAbilities(resolved.abilities, bonus, passiveSet)
		end
	end

	for _, slotId in { "off", "head", "chest", "hands", "feets" } do
		local uuid = (loadout :: any)[slotId]
		if uuid then
			local inst = InventoryService.Find(userId, uuid)
			local def = inst and ItemDefs.Get(inst.defId)
			collectFromAbilities(def and def.abilities, bonus, passiveSet)
		end
	end

	bonuses[userId] = bonus
	passiveIds[userId] = passiveSet
end

function PassiveService.GetBonus(userId: number): PassiveBonus
	if not bonuses[userId] then
		PassiveService.Refresh(userId)
	end
	return bonuses[userId] or emptyBonus()
end

function PassiveService.HasPassive(userId: number, abilityId: string): boolean
	if not passiveIds[userId] then
		PassiveService.Refresh(userId)
	end
	local set = passiveIds[userId]
	return set ~= nil and set[abilityId] == true
end

--- L3 finisher: guaranteed gem status. L1/L2: status_weaponpassive proc from PassiveDefs.
function PassiveService.RollLaOnHitStatus(userId: number, comboStep: number, element: string): OnHitStatus?
	if element == "Neutral" or element == "" then
		return nil
	end

	if comboStep == 3 then
		return elementStatus(element)
	end

	if PassiveService.HasPassive(userId, "status_weaponpassive") then
		local chance = PassiveDefs.LaProcChance("status_weaponpassive") or 0.15
		if math.random() < chance then
			return elementStatus(element)
		end
	end

	return nil
end

function PassiveService.GetSummary(userId: number): { PassiveBonus }
	local b = PassiveService.GetBonus(userId)
	return { b }
end

function PassiveService.Clear(userId: number)
	bonuses[userId] = nil
	passiveIds[userId] = nil
end

return PassiveService
