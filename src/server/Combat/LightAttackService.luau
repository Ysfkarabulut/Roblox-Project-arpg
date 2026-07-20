--[[
	Light attack L1–L3 — family range/shape, combo, pipeline.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local ElementData = require(game.ReplicatedStorage.Shared.Config.ElementData)
local WeaponFamilyConfig = require(game.ReplicatedStorage.Shared.Config.WeaponFamilyConfig)
local DamagePipeline = require(game.ReplicatedStorage.Shared.Combat.DamagePipeline)

local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local StatService = require(script.Parent.StatService)
local ComboTracker = require(script.Parent.ComboTracker)
local DamageService = require(script.Parent.DamageService)
local DummyService = require(script.Parent.DummyService)
local StatusService = require(script.Parent.StatusService)
local GuardService = require(script.Parent.GuardService)
local ParryService = require(script.Parent.ParryService)

local LightAttackService = {}

local recoveryUntil: { [number]: number } = {}

local function getMainDef(userId: number)
	local loadout = LoadoutService.Get(userId)
	if not loadout.main then
		return nil
	end
	local inst = InventoryService.Find(userId, loadout.main)
	return inst and ItemDefs.Get(inst.defId), loadout.main
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

local function collectTargets(caster: Player, family, look: Vector3, aimPos: Vector3?): { Instance }
	local root = caster.Character and caster.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return {}
	end
	local origin = root.Position
	local forward = look.Magnitude > 0.1 and look.Unit or root.CFrame.LookVector
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
			local ang = math.deg(math.acos(math.clamp(forward:Dot(flat.Unit), -1, 1)))
			if ang > (family.coneDeg or 45) / 2 then
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

	DummyService.Ensure()
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		tryAdd(dummy)
	end
	for _, plr in Players:GetPlayers() do
		if plr ~= caster and plr.Character then
			tryAdd(plr.Character)
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

function LightAttackService.Swing(player: Player, lookVector: Vector3?, aimPosition: Vector3?): any
	local userId = player.UserId
	local t = os.clock()
	if t < (recoveryUntil[userId] or 0) then
		return { ok = false, reason = "Recovery" }
	end
	if not player.Character then
		return { ok = false, reason = "NoChar" }
	end
	if StatusService.Has(player.Character, "Stun") then
		return { ok = false, reason = "Stunned" }
	end
	if GuardService.IsGuarding(userId) or ParryService.IsParrying(userId) then
		return { ok = false, reason = "Defending" }
	end

	local def = getMainDef(userId)
	local family = WeaponFamilyConfig.Resolve(def)
	local stats = StatService.Get(userId)
	local recovery = DamagePipeline.HitRecovery(def and def.asTier, stats.DEX)
	recoveryUntil[userId] = t + recovery

	local step = ComboTracker.PeekStep(userId)
	local look = if typeof(lookVector) == "Vector3" then lookVector else Vector3.new(0, 0, -1)
	local aim = if typeof(aimPosition) == "Vector3" then aimPosition else nil
	local targets = collectTargets(player, family, look, aim)

	if #targets == 0 then
		-- Whiff — no combo advance
		return {
			ok = true,
			whiff = true,
			comboStep = step,
			fx = {
				anim = family.animPrefix .. "_L" .. step,
				vfx = if family.laShape == "Projectile" then "Bolt" else "Slash",
				element = def and def.element or "Neutral",
				family = family.animPrefix,
				comboStep = step,
				origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart :: BasePart).Position,
				look = look,
				range = family.laRange,
			},
		}
	end

	local usedStep = ComboTracker.CommitHit(userId)
	local familyPerk = WeaponFamilyConfig.L3PerkMult(def, usedStep)
	local base = (def and def.baseDamage) or CombatConfig.DefaultWeaponBase
	local scale = scaling(userId, def)
	local el = def and def.element or "Neutral"
	local sig = ElementData.Signature[el]
	local axeMult = if def and def.family == "Axe" then CombatConfig.AxeGuardStamMult else 1

	local hits = {}
	for _, target in targets do
		local backstab = 1
		if def and def.family == "Dagger" and target:IsA("Model") and isBackstab(player, target) then
			backstab = CombatConfig.KBackstab
		end
		local onHit = nil
		-- Pure signature on LA only if we want proto feedback — optional light proc skipped;
		-- use element signature as soft on-hit for readability in lobby (15% later). For proto: always apply short status for chemistry testing on L3 only
		if usedStep == 3 and sig and sig.id then
			local dur = if el == "Lightning" then 0.5 elseif el == "Steel" then 8 elseif el == "Poison" then 5 elseif el == "Water" then 5 elseif el == "Wind" then 3 elseif el == "Rock" then 2 else 3
			local dps = if el == "Steel" then 4 elseif el == "Poison" then 3 elseif el == "Fire" then 7 else nil
			onHit = { id = sig.id, duration = dur, dps = dps }
		end

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
			kind = "LA",
			applyOnHitStatus = onHit,
		})
		table.insert(hits, report)
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return {
		ok = true,
		whiff = false,
		comboStep = usedStep,
		hits = hits,
		fx = {
			anim = family.animPrefix .. "_L" .. usedStep,
			vfx = if family.laShape == "Projectile" then "Bolt" elseif family.laShape == "Cone" then "Cone" else "Slash",
			element = el,
			family = family.animPrefix,
			comboStep = usedStep,
			origin = if root then root.Position else Vector3.zero,
			look = look,
			range = family.laRange,
			coneDeg = family.coneDeg,
		},
	}
end

function LightAttackService.Clear(userId: number)
	recoveryUntil[userId] = nil
	ComboTracker.Clear(userId)
end

return LightAttackService
