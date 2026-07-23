--[[
	Light attack L1–L3 — family range/shape, combo, pipeline.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local WeaponFamilyConfig = require(game.ReplicatedStorage.Shared.Config.WeaponFamilyConfig)
local DamagePipeline = require(game.ReplicatedStorage.Shared.Combat.DamagePipeline)

local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local WeaponAssemblyService = require(script.Parent.Parent.Inventory.WeaponAssemblyService)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)
local StatService = require(script.Parent.StatService)
local ComboTracker = require(script.Parent.ComboTracker)
local DamageService = require(script.Parent.DamageService)
local PassiveService = require(script.Parent.PassiveService)
local DummyService = require(script.Parent.DummyService)
local BossCombatTargets = require(script.Parent.Parent.Boss.BossCombatTargets)
local PvpMatchService = require(script.Parent.Parent.Pvp.PvpMatchService)
local PvpTeamService = require(script.Parent.Parent.Pvp.PvpTeamService)
local CrossbowReloadService = require(script.Parent.CrossbowReloadService)
local GuardService = require(script.Parent.GuardService)
local ParryService = require(script.Parent.ParryService)
local CombatPressureService = require(script.Parent.CombatPressureService)

local LightAttackService = {}

local function makePressureGroupId(userId: number, t: number): string
	return `{userId}_{math.floor(t * 1000)}`
end

local function getResolvedMain(userId: number)
	local loadout = LoadoutService.Get(userId)
	if not loadout.main then
		return nil
	end
	local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
	if not resolved or not resolved.complete then
		return nil
	end
	return resolved
end

local function scaling(userId: number, def: any): number
	local s = StatService.Get(userId)
	if def and def.scaling == "DEX" then
		return s.DEX
	elseif def and def.scaling == "INT" then
		return s.INT
	end
	return s.STR
end

local function maceShredPct(def: any): number
	if not def or def.family ~= "Mace" then
		return 0
	end
	return if def.kind == "Weapon2H" then CombatConfig.MaceShred2H else CombatConfig.MaceShred1H
end

local function collectTargets(caster: Player, family, look: Vector3, aimPos: Vector3?, comboStep: number?): { Instance }
	local root = caster.Character and caster.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return {}
	end
	local origin = root.Position
	-- Flatten aim for horizontal cone/melee checks (camera pitch otherwise inflates angles → constant whiffs).
	local rawLook = look.Magnitude > 0.1 and look.Unit or root.CFrame.LookVector
	local forward = Vector3.new(rawLook.X, 0, rawLook.Z)
	if forward.Magnitude < 0.1 then
		local flatRoot = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		forward = if flatRoot.Magnitude > 0.1 then flatRoot.Unit else Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end
	local range = family.laRange
	local targets = {}

	local function tryAdd(model: Model)
		if model == caster.Character then
			return
		end
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		local offset = pp.Position - origin
		local dist = offset.Magnitude
		if dist > range + 2 then
			return
		end
		if family.laShape == "Cone" then
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude < 0.2 then
				return
			end
			local coneDeg = family.coneDeg or 45
			if family.key == "Scepter" and comboStep == 3 then
				coneDeg += CombatConfig.ScepterL3ConeBonusDeg
			end
			local ang = math.deg(math.acos(math.clamp(forward:Dot(flat.Unit), -1, 1)))
			if ang > coneDeg / 2 then
				return
			end
		elseif family.laShape == "Melee" then
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude > 0.2 and forward:Dot(flat.Unit) < 0.1 then
				return
			end
		end
		-- Projectile: prefer aim proximity
		table.insert(targets, model)
	end

	if BossCombatTargets.IsActive() then
		local boss = BossCombatTargets.GetBossModel()
		if boss then
			tryAdd(boss)
		end
		for _, add in Workspace:GetDescendants() do
			if add:IsA("Model") and add:GetAttribute("IsBossAdd") and add.Parent and add.Parent.Name == "BossTentacles" then
				tryAdd(add)
			end
		end
	elseif PvpMatchService.IsActive() then
		if PvpTeamService.IsTeamMatch() then
			for _, plr in PvpTeamService.GetEnemyPlayers(caster.UserId) do
				if plr.Character then
					tryAdd(plr.Character)
				end
			end
		else
			local opp = Workspace:FindFirstChild("PvpOpponent")
			if opp and opp:IsA("Model") then
				tryAdd(opp)
			end
		end
	else
		DummyService.Ensure()
		local dummy = Workspace:FindFirstChild("TrainingDummy")
		if dummy and dummy:IsA("Model") then
			tryAdd(dummy)
		end
	end

	if family.laShape ~= "Cone" then
		table.sort(targets, function(a, b)
			local pa = (a :: Model).PrimaryPart or (a :: Model):FindFirstChild("HumanoidRootPart")
			local pb = (b :: Model).PrimaryPart or (b :: Model):FindFirstChild("HumanoidRootPart")
			local ra = if pa and pa:IsA("BasePart") then pa.Position else origin
			local rb = if pb and pb:IsA("BasePart") then pb.Position else origin
			local ref = aimPos or (origin + forward * range)
			return (ra - ref).Magnitude < (rb - ref).Magnitude
		end)
		if #targets > 0 then
			return { targets[1] }
		end
	else
		-- max 3 for scepter
		while #targets > 3 do
			table.remove(targets)
		end
	end
	return targets
end

local function isBackstab(attacker: Player, target: Model): boolean
	local aHrp = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tHrp = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
	if not aHrp or not tHrp or not tHrp:IsA("BasePart") then
		return false
	end
	local toAtk = aHrp.Position - tHrp.Position
	local flat = Vector3.new(toAtk.X, 0, toAtk.Z)
	if flat.Magnitude < 0.1 then
		return false
	end
	return tHrp.CFrame.LookVector:Dot(flat.Unit) < 0
end

local function laConeDeg(family, comboStep: number): number?
	if family.laShape ~= "Cone" then
		return family.coneDeg
	end
	local deg = family.coneDeg or 45
	if family.key == "Scepter" and comboStep == 3 then
		deg += CombatConfig.ScepterL3ConeBonusDeg
	end
	return deg
end

function LightAttackService.Swing(player: Player, lookVector: Vector3?, aimPosition: Vector3?): any
	local userId = player.UserId
	local t = os.clock()
	if CombatPressureService.IsActionLocked(userId) then
		return { ok = false, reason = "Recovery" }
	end
	if CrossbowReloadService.IsReloading(userId) then
		return { ok = false, reason = "Reloading" }
	end
	if PvpTeamService.IsCombatLocked(userId) then
		return { ok = false, reason = "CombatLocked" }
	end
	if typeof(lookVector) == "Vector3" and lookVector.Magnitude > 1.5 then
		lookVector = lookVector.Unit
	end
	if not player.Character then
		return { ok = false, reason = "NoChar" }
	end
	if not CombatPressureService.CanAttackEntity(player.Character) then
		return { ok = false, reason = "Stunned" }
	end
	if GuardService.IsGuarding(userId) or ParryService.IsParrying(userId) then
		return { ok = false, reason = "Defending" }
	end

	local resolved = getResolvedMain(userId)
	if not resolved then
		return { ok = false, reason = "NoWeapon" }
	end
	local def = WeaponResolver.AsItemDef(resolved)
	local family = WeaponFamilyConfig.Resolve(def)
	local stats = StatService.Get(userId)
	local asMult = WeaponFamilyConfig.AttackSpeedMult(def, stats.DEX)

	local step = ComboTracker.PeekStep(userId)
	local recovery = DamagePipeline.HitRecovery(def.asTier, stats.DEX, step, asMult)
	if step == 3 then
		recovery += CombatPressureService.L3EndlagBonus()
		CombatPressureService.ApplyHyperArmor(player.Character, CombatConfig.HyperArmorL3Sec, userId)
	end
	CombatPressureService.LockActions(userId, recovery)

	local pressureGroupId = makePressureGroupId(userId, t)

	local look = if typeof(lookVector) == "Vector3" then lookVector else Vector3.new(0, 0, -1)
	local aim = if typeof(aimPosition) == "Vector3" then aimPosition else nil
	local targets = collectTargets(player, family, look, aim, step)

	if #targets == 0 then
		-- Whiff — no combo advance
		return {
			ok = true,
			whiff = true,
			comboStep = step,
			fx = {
				anim = family.animPrefix .. "_L" .. step,
				vfx = if family.laShape == "Projectile" then "Bolt" elseif family.laShape == "Cone" then "Cone" else "Slash",
				element = resolved.element or "Neutral",
				family = family.animPrefix,
				comboStep = step,
				origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart :: BasePart).Position,
				look = look,
				range = family.laRange,
				coneDeg = laConeDeg(family, step),
				shape = if family.laShape == "Cone" then "Cone" else nil,
				attackSpeedMult = asMult,
				recoverySec = recovery,
				comboMoveMult = CombatConfig.ComboMoveSpeedMult[step] or 1,
			},
		}
	end

	local usedStep = ComboTracker.CommitHit(userId)
	local familyPerk = WeaponFamilyConfig.L3PerkMult(def, usedStep)
	local shredPct = maceShredPct(def)
	local base = resolved.baseDamage
	local scale = scaling(userId, def)
	local el = resolved.element or "Neutral"
	if player.Character then
		el = PassiveService.ResolveLaElement(userId, el, player.Character)
	end

	local hits = {}
	for _, target in targets do
		local backstab = 1
		if def.family == "Dagger" and target:IsA("Model") and isBackstab(player, target) then
			backstab = CombatConfig.KBackstab
		end
		local onHit = PassiveService.RollLaOnHitStatus(userId, usedStep, el)
		local axeMult = if def.family == "Axe" then CombatConfig.AxeGuardStamMult else 1

		local report = DamageService.DealDirect({
			attacker = player,
			target = target,
			weaponBase = base,
			scalingStat = scale,
			atkElement = el,
			comboStep = usedStep,
			familyPerkMult = familyPerk,
			backstabMult = backstab,
			axeGuardMult = axeMult,
			defenceShredPct = shredPct,
			kind = "LA",
			applyOnHitStatus = onHit,
			pressureGroupId = pressureGroupId,
		})
		if report.onHitApplied and onHit and onHit.id == "Wet" and target:IsA("Model") then
			PassiveService.TryPureCascadeSplash(player, target, el)
		end
		table.insert(hits, report)
	end

	-- Dual wield off-hand proc (50% damage, no on-hit status — GDD §7)
	local loadout = LoadoutService.Get(userId)
	if loadout.off and #targets > 0 then
		local offInst = InventoryService.Find(userId, loadout.off)
		local offDef = offInst and ItemDefs.Get(offInst.defId)
		local dualKinds = { Weapon1H = true, Wand = true, Scepter = true }
		if offDef and dualKinds[offDef.kind] then
			local offBase = (offDef.baseDamage or CombatConfig.DefaultWeaponBase) * CombatConfig.OffHandDamageMult
			local offScale = scaling(userId, offDef)
			for _, target in targets do
				local offReport = DamageService.DealDirect({
					attacker = player,
					target = target,
					weaponBase = offBase,
					scalingStat = offScale,
					atkElement = offDef.element or el,
					comboStep = usedStep,
					familyPerkMult = 1,
					backstabMult = 1,
					axeGuardMult = 1,
					kind = "LA",
					pressureGroupId = pressureGroupId,
					-- applyOnHitStatus intentionally nil: off-hand LA never procs status
				})
				table.insert(hits, offReport)
			end
		end
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local reloadSec = nil
	if def.family == "Crossbow" and usedStep == 3 then
		reloadSec = CombatConfig.CrossbowReloadSec
		CrossbowReloadService.Start(userId, reloadSec)
	end
	return {
		ok = true,
		whiff = false,
		comboStep = usedStep,
		hits = hits,
		reloadSec = reloadSec,
		fx = {
			anim = family.animPrefix .. "_L" .. usedStep,
			vfx = if family.laShape == "Projectile" then "Bolt" elseif family.laShape == "Cone" then "Cone" else "Slash",
			element = el,
			family = family.animPrefix,
			comboStep = usedStep,
			reloadSec = reloadSec,
			origin = if root then root.Position else Vector3.zero,
			look = look,
			range = family.laRange,
			coneDeg = laConeDeg(family, usedStep),
			shape = if family.laShape == "Cone" then "Cone" else nil,
			attackSpeedMult = asMult,
			recoverySec = recovery,
			comboMoveMult = CombatConfig.ComboMoveSpeedMult[usedStep] or 1,
		},
	}
end

function LightAttackService.Clear(userId: number)
	CombatPressureService.ClearUser(userId)
	ComboTracker.Clear(userId)
end

return LightAttackService
