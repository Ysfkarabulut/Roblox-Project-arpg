--[[
	DamageService — Crit → Matchup → DR → stance → HP; on-hit + reactions via StatusService.
]]

local Players = game:GetService("Players")
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local DamagePipeline = require(game.ReplicatedStorage.Shared.Combat.DamagePipeline)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local StatusService = require(script.Parent.StatusService)
local DummyService = require(script.Parent.DummyService)
local DodgeService = require(script.Parent.DodgeService)
local GuardService = require(script.Parent.GuardService)
local ParryService = require(script.Parent.ParryService)
local StatService = require(script.Parent.StatService)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local DamageService = {}

export type HitReport = {
	dealt: number,
	chip: number,
	crit: boolean,
	blocked: boolean,
	dodged: boolean,
	parried: boolean,
	perfectParry: boolean,
	dead: boolean,
	targetKind: string,
	matchupMult: number,
	drPct: number,
	comboStep: number?,
	onHitApplied: boolean,
}

local function fortifyMult(entity: Instance): number
	local f = StatusService.Get(entity, "Fortify")
	if f and f.params and typeof(f.params.damageTakenMult) == "number" then
		return f.params.damageTakenMult
	end
	return 1
end

function DamageService.ResolveEntity(target: Instance?): (Instance?, string)
	if not target then
		return nil, "None"
	end
	if target:GetAttribute("IsCombatDummy") or (target:IsA("Model") and target.Name == "TrainingDummy") then
		return target, "Dummy"
	end
	if target:IsA("Model") and Players:GetPlayerFromCharacter(target) then
		return target, "Player"
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if model then
		if model:GetAttribute("IsCombatDummy") or model.Name == "TrainingDummy" then
			return model, "Dummy"
		end
		if Players:GetPlayerFromCharacter(model) then
			return model, "Player"
		end
	end
	return nil, "None"
end

function DamageService.GetChestElement(entity: Instance): string?
	local plr = Players:GetPlayerFromCharacter(entity)
	if not plr then
		-- Dummy: Steel chest default for matchup tests
		return "Steel"
	end
	local loadout = LoadoutService.Get(plr.UserId)
	if not loadout.chest then
		return nil
	end
	local inst = InventoryService.Find(plr.UserId, loadout.chest)
	local def = inst and ItemDefs.Get(inst.defId)
	return def and def.element
end

function DamageService.GetDefence(entity: Instance): number
	local plr = Players:GetPlayerFromCharacter(entity)
	if not plr then
		return CombatConfig.DummyDefence
	end
	return StatService.Derived(plr.UserId).totalDefence
end

function DamageService.ApplyHp(entity: Instance, kind: string, amount: number): (number, boolean)
	amount = math.max(0, math.floor(amount * fortifyMult(entity) + 0.5))
	if kind == "Dummy" then
		local dealt, dead = DummyService.ApplyDamage(amount)
		DummyService.RefreshStatusLabel(StatusService.FormatShort(entity))
		return dealt, dead
	end
	local hum = entity:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return 0, true
	end
	hum:TakeDamage(amount)
	return amount, hum.Health <= 0
end

export type DirectAttackCtx = {
	attacker: Player,
	target: Instance,
	weaponBase: number,
	scalingStat: number,
	atkElement: string?,
	abilityPct: number?,
	comboStep: number?,
	familyPerkMult: number?,
	backstabMult: number?,
	axeGuardMult: number?,
	skipCrit: boolean?,
	kind: string?, -- "LA" | "Ability" | "Burst" | "DoT"
	applyOnHitStatus: { id: string, duration: number, dps: number? }?,
}

function DamageService.DealDirect(ctx: DirectAttackCtx): HitReport
	local entity, kind = DamageService.ResolveEntity(ctx.target)
	local empty: HitReport = {
		dealt = 0,
		chip = 0,
		crit = false,
		blocked = false,
		dodged = false,
		parried = false,
		perfectParry = false,
		dead = false,
		targetKind = kind,
		matchupMult = 1,
		drPct = 0,
		comboStep = ctx.comboStep,
		onHitApplied = false,
	}
	if not entity or kind == "None" then
		return empty
	end

	-- Dodge i-frame
	if DodgeService.IsIFraming(entity) then
		empty.dodged = true
		return empty
	end

	local stats = StatService.Get(ctx.attacker.UserId)
	local derived = StatService.Derived(ctx.attacker.UserId)
	local critChance, critDmg = DamagePipeline.CritStats(stats.STR, stats.DEX)
	critChance = math.min(critChance + derived.passiveCritChance, CombatConfig.CritChanceCap)
	local isDotOrBurst = ctx.kind == "DoT" or ctx.kind == "Burst"

	local pipe = DamagePipeline.ResolveDirect({
		weaponBase = ctx.weaponBase,
		scalingStat = ctx.scalingStat,
		abilityPct = ctx.abilityPct,
		comboStep = if isDotOrBurst then nil else ctx.comboStep,
		familyPerkMult = if isDotOrBurst then 1 else ctx.familyPerkMult,
		backstabMult = ctx.backstabMult or 1,
		directBonusMult = derived.passiveDirectMult,
		atkElement = ctx.atkElement,
		defChestElement = DamageService.GetChestElement(entity),
		defence = DamageService.GetDefence(entity),
		defenceShredPct = 0,
		critChancePct = critChance,
		critDamagePct = critDmg,
		skipCrit = ctx.skipCrit or isDotOrBurst,
		skipMatchup = isDotOrBurst,
		skipDr = isDotOrBurst,
	})

	local afterDr = pipe.afterDr
	local attackerPos = Vector3.zero
	local hrp = ctx.attacker.Character and ctx.attacker.Character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		attackerPos = hrp.Position
	end

	-- Parry before Guard (Dodge → Parry → Guard)
	local parryFail = false
	if kind == "Player" and not isDotOrBurst then
		local defPlr = Players:GetPlayerFromCharacter(entity)
		if defPlr then
			local handled, perfect, _failCost = ParryService.TryParry(defPlr.UserId, entity, ctx.attacker, attackerPos)
			if handled then
				if perfect then
					empty.parried = true
					empty.perfectParry = true
					empty.crit = pipe.crit
					empty.matchupMult = pipe.matchupMult
					empty.drPct = pipe.effectiveDrPct
					return empty -- 0 damage, no on-hit
				end
				-- Fail: stam drained + parry closed; full damage continues
				parryFail = true
			end
		end
	end

	local blocked, chip, _, _broke = false, 0, 0, false
	if kind == "Player" and not isDotOrBurst then
		local defPlr = Players:GetPlayerFromCharacter(entity)
		if defPlr then
			blocked, chip = GuardService.TryBlock(defPlr.UserId, entity, attackerPos, afterDr, ctx.axeGuardMult)
		end
	end

	local dealt, dead = 0, false
	local onHit = false
	if blocked then
		dealt, dead = DamageService.ApplyHp(entity, kind, chip)
	else
		dealt, dead = DamageService.ApplyHp(entity, kind, afterDr)
		if ctx.applyOnHitStatus and dealt > 0 then
			StatusService.Apply(entity, ctx.applyOnHitStatus.id, ctx.applyOnHitStatus.duration, {
				sourceUserId = ctx.attacker.UserId,
				dps = ctx.applyOnHitStatus.dps,
			})
			onHit = true
			if kind == "Dummy" then
				DummyService.RefreshStatusLabel(StatusService.FormatShort(entity))
			end
		end
	end

	return {
		dealt = dealt,
		chip = if blocked then dealt else 0,
		crit = pipe.crit,
		blocked = blocked,
		dodged = false,
		parried = parryFail,
		perfectParry = false,
		dead = dead,
		targetKind = kind,
		matchupMult = pipe.matchupMult,
		drPct = pipe.effectiveDrPct,
		comboStep = ctx.comboStep,
		onHitApplied = onHit,
	}
end

function DamageService.DealBurst(entity: Instance, amount: number, _reactionId: string, sourceUserId: number?)
	local _, kind = DamageService.ResolveEntity(entity)
	if kind == "None" then
		return
	end
	DamageService.ApplyHp(entity, kind, amount)
end

function DamageService.TickDoTs()
	StatusService.TickDoTs(function(entity, dps, statusId, sourceUserId)
		local _, kind = DamageService.ResolveEntity(entity)
		if kind ~= "None" then
			DamageService.ApplyHp(entity, kind, dps)
		end
	end)
end

-- Legacy helper for ability raw (pre-pipeline callers)
function DamageService.ComputeAbilityDamage(userId: number, weaponBase: number, scalingStat: number, damagePct: number): number
	return weaponBase * (damagePct / 100) * (1 + scalingStat * CombatConfig.KDmg)
end

function DamageService.DealDamage(attacker: Player?, targetEntity: Instance, rawDamage: number, kind: string?): any
	-- Simplified path for DoT/legacy
	local entity, tkind = DamageService.ResolveEntity(targetEntity)
	if not entity then
		return { dealt = 0, dead = false, targetKind = "None" }
	end
	local dealt, dead = DamageService.ApplyHp(entity, tkind, rawDamage)
	return { dealt = dealt, dead = dead, targetKind = tkind }
end

return DamageService
