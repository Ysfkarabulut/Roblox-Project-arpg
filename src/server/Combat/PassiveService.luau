--[[
	PassiveService — loadout passive bonuses + LA on-hit procs.
	Stat / proc definitions → PassiveDefs.luau (global catalog).
]]

local ElementData = require(game.ReplicatedStorage.Shared.Config.ElementData)
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local PassiveDefs = require(game.ReplicatedStorage.Shared.Config.PassiveDefs)
local ExoticPerkDefs = require(game.ReplicatedStorage.Shared.Config.ExoticPerkDefs)
local SynergyConfig = require(game.ReplicatedStorage.Shared.Config.SynergyConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local WeaponAssemblyService = require(script.Parent.Parent.Inventory.WeaponAssemblyService)
local SynergyService = require(game.ReplicatedStorage.Shared.Combat.SynergyService)
local StatusService = require(script.Parent.StatusService)
local CombatPressureService = require(script.Parent.CombatPressureService)
local DummyService = require(script.Parent.DummyService)
local BossCombatTargets = require(script.Parent.Parent.Boss.BossCombatTargets)
local PvpTeamService = require(script.Parent.Parent.Pvp.PvpTeamService)
local HealService = require(script.Parent.HealService)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

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
	params: { [string]: any }?,
}

export type StatusApplyOpts = {
	helmOverride: boolean?,
	gemElement: string?,
}

local bonuses: { [number]: PassiveBonus } = {}
local passiveIds: { [number]: { [string]: boolean } } = {}
local synergyByUser: { [number]: SynergyConfig.SynergyResult } = {}

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
	local params = nil
	if element == "Wind" then
		params = { slowPct = 30 }
	elseif element == "Rock" then
		params = { slowPct = 50 }
	end
	return { id = sig.id, duration = dur, dps = dps, params = params }
end

local function helmBlocksPure(element: string, applyOpts: StatusApplyOpts?): boolean
	if not applyOpts or not applyOpts.helmOverride then
		return false
	end
	local gem = applyOpts.gemElement
	if not gem or gem == "" or gem == "Neutral" then
		return false
	end
	return element ~= gem
end

local function registerPassive(passiveSet: { [string]: boolean }, abilityId: string)
	passiveSet[abilityId] = true
end

local function applyPassiveId(bonus: PassiveBonus, passiveSet: { [string]: boolean }, abilityId: string, scale: number?)
	registerPassive(passiveSet, abilityId)
	local s = scale or 1
	PassiveDefs.ApplyStatBonus(bonus, abilityId, s)
	if s < 1 then
		return
	end
	if abilityId == "stormgrasp_armorpassive" then
		bonus.statusPotencyFlat += 10
	elseif abilityId == "warbound_armorpassive" then
		bonus.directMult *= 1.05
	elseif abilityId == "phantom_step_armorpassive" then
		bonus.critChanceFlat += 6
	elseif abilityId == "arcanist_mind_armorpassive" then
		bonus.statusPotencyFlat += 14
	elseif abilityId == "lifeweaver_grace_armorpassive" then
		bonus.buffPotencyFlat += 12
	elseif abilityId == "spirit_charm_focuspassive" then
		bonus.statusPotencyFlat += 14
	elseif abilityId == "war_sigil_focuspassive" then
		bonus.directMult *= 1.07
	elseif abilityId == "lucky_coin_focuspassive" then
		bonus.critChanceFlat += 8
	elseif abilityId == "iron_heart_focuspassive" then
		bonus.buffPotencyFlat += 18
	elseif string.sub(abilityId, 1, 3) == "mx_" and string.find(abilityId, "_util", 1, true) then
		bonus.critChanceFlat += 3
	end
end

local function collectFromAbilities(
	abilities: { any }?,
	bonus: PassiveBonus,
	passiveSet: { [string]: boolean },
	scale: number?
)
	if not abilities then
		return
	end
	for _, ab in abilities do
		if ab.slotType == "Passive" then
			applyPassiveId(bonus, passiveSet, ab.id, scale)
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
			local stormlash = ExoticPerkDefs.GetBladePerk(resolved.bladeDefId)
			if stormlash and stormlash.potencyBonusFlat then
				bonus.statusPotencyFlat += stormlash.potencyBonusFlat
			end
		end
	end

	for _, slotId in { "off", "head", "chest", "hands", "feets" } do
		local uuid = (loadout :: any)[slotId]
		if uuid then
			local inst = InventoryService.Find(userId, uuid)
			if inst then
				if slotId == "off" and inst.defId == "weapon_frame" then
					local resolved = WeaponAssemblyService.ToResolved(userId, uuid)
					if resolved and resolved.complete then
						collectFromAbilities(
							resolved.abilities,
							bonus,
							passiveSet,
							CombatConfig.OffHandAbilityMult
						)
					end
				else
					local def = ItemDefs.Get(inst.defId)
					collectFromAbilities(def and def.abilities, bonus, passiveSet)
				end
			end
		end
	end

	bonuses[userId] = bonus
	passiveIds[userId] = passiveSet

	local resolved = LoadoutService.GetResolvedMain(userId)
	synergyByUser[userId] = SynergyService.ResolveLoadout(userId, loadout, resolved, function(uuid)
		return InventoryService.Find(userId, uuid)
	end, function(uuid)
		return WeaponAssemblyService.ToResolved(userId, uuid)
	end)
end

function PassiveService.GetSynergy(userId: number): SynergyConfig.SynergyResult
	if not synergyByUser[userId] then
		PassiveService.Refresh(userId)
	end
	return synergyByUser[userId] or {
		band = "None",
		pureElement = nil,
		dualityElements = nil,
		directMult = 1,
		defenceBonusPct = 0,
		resistBonusPct = 0,
		statusPotencyFlat = 0,
		pureOnHitBonus = nil,
	}
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

function PassiveService.GetSlotElement(userId: number, slotId: string): string?
	local loadout = LoadoutService.Get(userId)
	local uuid = (loadout :: any)[slotId]
	if not uuid then
		return nil
	end
	local inst = InventoryService.Find(userId, uuid)
	local def = inst and ItemDefs.Get(inst.defId)
	return def and def.element
end

function PassiveService.GetDirectTakenMult(userId: number): number
	if PassiveService.HasPassive(userId, "unbound_hide_armorpassive") then
		return 0.97
	end
	return 1
end

function PassiveService.TryCarapaceReflect(victimUserId: number, attacker: Player): boolean
	if not PassiveService.HasPassive(victimUserId, "carapace_armorpassive") then
		return false
	end
	if math.random() >= 0.10 then
		return false
	end
	local element = PassiveService.GetSlotElement(victimUserId, "chest")
	if not element or element == "Neutral" then
		return false
	end
	local char = attacker.Character
	if not char then
		return false
	end
	local status = elementStatus(element)
	if not status then
		return false
	end
	local StatusService = require(script.Parent.StatusService)
	StatusService.Apply(char, status.id, status.duration, {
		sourceUserId = victimUserId,
		dps = status.dps,
	})
	return true
end

function PassiveService.TryThornReflect(victimUserId: number, attacker: Player, damageDealt: number): boolean
	if damageDealt <= 0 or not PassiveService.HasPassive(victimUserId, "thorn_reflect_armorpassive") then
		return false
	end
	local char = attacker.Character
	if not char then
		return false
	end
	local reflect = math.floor(damageDealt * 0.20 + 0.5)
	if reflect <= 0 then
		return false
	end
	local DamageService = require(script.Parent.DamageService)
	DamageService.ApplyHp(char, "Player", reflect)
	return true
end

--- Pure x3: guaranteed signature on every main-hand LA hit. L3 / status_weaponpassive otherwise.
function PassiveService.RollLaOnHitStatus(
	userId: number,
	comboStep: number,
	element: string,
	applyOpts: StatusApplyOpts?,
	bladeDefId: string?
): OnHitStatus?
	if element == "Neutral" or element == "" then
		return nil
	end

	local synergy = PassiveService.GetSynergy(userId)
	if synergy.band == "Pure" and synergy.pureElement == element and not helmBlocksPure(element, applyOpts) then
		return elementStatus(element)
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

	local exotic = ExoticPerkDefs.GetBladePerk(bladeDefId)
	if exotic and exotic.laProcChance and comboStep < 3 then
		if math.random() < exotic.laProcChance then
			return elementStatus(element)
		end
	end

	return nil
end

--- Helm Pulse buff: next N light attacks use head armor element instead of gem element.
function PassiveService.ResolveLaElement(userId: number, gemElement: string, character: Model?): (string, boolean)
	local helm = character and StatusService.Get(character, "HelmPulse")
	if helm and helm.params and typeof(helm.params.charges) == "number" and helm.params.charges > 0 then
		local el = helm.params.element
		if typeof(el) == "string" and el ~= "" and el ~= "Neutral" then
			local newCharges = helm.params.charges - 1
			local remain = StatusService.RemainingSeconds(character, "HelmPulse")
			if newCharges <= 0 then
				StatusService.Remove(character, "HelmPulse", userId)
			else
				StatusService.Apply(character, "HelmPulse", if remain > 0 then remain else 6, {
					sourceUserId = userId,
					params = { element = el, charges = newCharges },
					silentBatch = true,
				})
			end
			return el, true
		end
	end
	return gemElement, false
end

function PassiveService.ElementStatus(element: string): OnHitStatus?
	return elementStatus(element)
end

function PassiveService.ScaleOnHitStatus(
	userId: number,
	status: { id: string, duration: number, dps: number?, params: { [string]: any }? }
): OnHitStatus
	local StatService = require(script.Parent.StatService)
	local stats = StatService.Get(userId)
	local derived = PassiveService.GetBonus(userId)
	local synergy = PassiveService.GetSynergy(userId)
	local potency = stats.INT * 0.5 + derived.statusPotencyFlat + synergy.statusPotencyFlat
	local mult = 1 + potency * 0.01
	return {
		id = status.id,
		duration = status.duration * mult,
		dps = if status.dps then status.dps * mult else nil,
		params = status.params,
	}
end

--- Scale + Pure x3 element perks (CHEMISTRY_ENGINE §3.4).
function PassiveService.FinalizeLaOnHitStatus(
	userId: number,
	status: OnHitStatus,
	element: string?,
	applyOpts: StatusApplyOpts?
): OnHitStatus
	local scaled = PassiveService.ScaleOnHitStatus(userId, status)
	if not element or element == "Neutral" then
		return scaled
	end

	if helmBlocksPure(element, applyOpts) then
		return scaled
	end

	local synergy = PassiveService.GetSynergy(userId)
	if synergy.band ~= "Pure" or synergy.pureElement ~= element then
		return scaled
	end

	local bonus = synergy.pureOnHitBonus
	if bonus then
		if typeof(bonus.durationMult) == "number" and bonus.durationMult > 0 then
			scaled.duration *= bonus.durationMult
		end
		if typeof(bonus.dpsBonus) == "number" and scaled.dps then
			scaled.dps += bonus.dpsBonus
		end
	end

	if element == "Lightning" then
		scaled.duration += 0.15
	elseif element == "Steel" then
		scaled.duration += 1
	elseif element == "Rock" and scaled.id == "Slow" then
		scaled.params = { slowPct = 50, damageTakenMult = 1.05 }
	elseif element == "Wind" and scaled.id == "Windy" then
		scaled.params = { slowPct = 33 }
	end

	return scaled
end

--- Pure Water: AoE Wet splash 8 stud around primary target.
function PassiveService.TryPureCascadeSplash(attacker: Player, primaryTarget: Model, element: string)
	if element ~= "Water" then
		return
	end
	local synergy = PassiveService.GetSynergy(attacker.UserId)
	if synergy.band ~= "Pure" or synergy.pureElement ~= "Water" then
		return
	end

	local raw = elementStatus("Water")
	if not raw then
		return
	end
	local wet = PassiveService.FinalizeLaOnHitStatus(attacker.UserId, raw, "Water")

	local root = primaryTarget.PrimaryPart or primaryTarget:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local origin = root.Position
	local radius = 8

	local function trySplash(model: Model)
		if model == primaryTarget or model == attacker.Character then
			return
		end
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		if (pp.Position - origin).Magnitude > radius then
			return
		end
		if model:GetAttribute("IsCombatDummy") or model.Name == "TrainingDummy" then
			CombatPressureService.TryApplyStatus(model, wet.id, wet.duration, {
				sourceUserId = attacker.UserId,
				dps = wet.dps,
				params = wet.params,
			})
			DummyService.RefreshStatusLabel(StatusService.FormatShort(model))
			return
		end
		local victim = Players:GetPlayerFromCharacter(model)
		if victim and PvpTeamService.CanDamage(attacker.UserId, victim.UserId) then
			CombatPressureService.TryApplyStatus(model, wet.id, wet.duration, {
				sourceUserId = attacker.UserId,
				dps = wet.dps,
				params = wet.params,
			})
			return
		end
		if model:GetAttribute("IsBoss") or model:GetAttribute("IsBossAdd") or model:GetAttribute("IsPvpOpponent") then
			CombatPressureService.TryApplyStatus(model, wet.id, wet.duration, {
				sourceUserId = attacker.UserId,
				dps = wet.dps,
				params = wet.params,
			})
		end
	end

	for _, plr in Players:GetPlayers() do
		if plr.Character then
			trySplash(plr.Character)
		end
	end
	for _, child in Workspace:GetChildren() do
		if child:IsA("Model") then
			trySplash(child)
		end
	end
	local boss = BossCombatTargets.GetBossModel()
	if boss then
		trySplash(boss)
	end
end

function PassiveService.ApplyFortifyAura(caster: Player, duration: number, params: { [string]: number }?)
	if not PassiveService.HasPassive(caster.UserId, "fortifyaura_armorpassive") then
		return
	end
	local character = caster.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local mult = params and params.damageTakenMult
	if typeof(mult) ~= "number" then
		mult = 0.9
	end
	local auraMult = 1 - (1 - mult) * 0.5
	local auraDur = duration * 0.5
	local origin = root.Position
	local radius = CombatConfig.FortifyAuraRadius or 8

	local function tryAlly(model: Model)
		if model == character then
			return
		end
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		if (pp.Position - origin).Magnitude > radius then
			return
		end
		StatusService.Apply(model, "Fortify", auraDur, {
			sourceUserId = caster.UserId,
			params = { damageTakenMult = auraMult },
		})
	end

	local Players = game:GetService("Players")
	for _, plr in Players:GetPlayers() do
		if plr ~= caster and plr.Character then
			tryAlly(plr.Character)
		end
	end
end

function PassiveService.TryLifesteal(userId: number, damageDealt: number)
	if damageDealt <= 0 then
		return
	end
	if not passiveIds[userId] then
		PassiveService.Refresh(userId)
	end
	local passiveSet = passiveIds[userId]
	if not passiveSet then
		return
	end
	local totalPct = 0
	for abilityId in passiveSet do
		local pct = PassiveDefs.LifestealPct(abilityId)
		if pct then
			totalPct += pct
		end
	end
	if totalPct <= 0 then
		return
	end
	local heal = math.max(1, math.floor(damageDealt * totalPct + 0.5))
	local plr = Players:GetPlayerByUserId(userId)
	if plr and plr.Character then
		HealService.Apply(plr.Character, heal)
	end
end

function PassiveService.GetSummary(userId: number): { PassiveBonus }
	local b = PassiveService.GetBonus(userId)
	return { b }
end

function PassiveService.Clear(userId: number)
	bonuses[userId] = nil
	passiveIds[userId] = nil
	synergyByUser[userId] = nil
end

return PassiveService
