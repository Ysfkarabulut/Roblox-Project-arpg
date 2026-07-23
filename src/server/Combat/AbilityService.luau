--[[
	Ability cast — hotbar Active → validate CD → hit targets → damage/status → replicate FX.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local AbilityRuntime = require(game.ReplicatedStorage.Shared.Config.AbilityRuntime)
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)

local HotbarService = require(script.Parent.Parent.Hotbar.HotbarService)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local WeaponAssemblyService = require(script.Parent.Parent.Inventory.WeaponAssemblyService)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)
local StatService = require(script.Parent.StatService)
local PassiveService = require(script.Parent.PassiveService)
local StatusService = require(script.Parent.StatusService)
local DamageService = require(script.Parent.DamageService)
local HealService = require(script.Parent.HealService)
local DummyService = require(script.Parent.DummyService)
local BossCombatTargets = require(script.Parent.Parent.Boss.BossCombatTargets)
local PvpMatchService = require(script.Parent.Parent.Pvp.PvpMatchService)
local PvpTeamService = require(script.Parent.Parent.Pvp.PvpTeamService)
local CrossbowReloadService = require(script.Parent.CrossbowReloadService)
local CombatPressureService = require(script.Parent.CombatPressureService)

local AbilityService = {}

local cooldowns: { [number]: { [string]: number } } = {} -- userId → abilityId → readyAt

export type CastResult = {
	ok: boolean,
	reason: string?,
	abilityId: string?,
	hits: { { targetKind: string, damage: number, statuses: { string } } }?,
	fx: any?,
}

local function readyMap(userId: number)
	if not cooldowns[userId] then
		cooldowns[userId] = {}
	end
	return cooldowns[userId]
end

local function findAbilityOnLoadout(userId: number, abilityId: string): (any?, any?, string?)
	local loadout = LoadoutService.Get(userId)

	if loadout.main then
		local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
		if resolved and resolved.complete and resolved.abilities then
			for _, ab in resolved.abilities do
				if ab.id == abilityId and ab.slotType == "Active" then
					return ab, WeaponResolver.AsItemDef(resolved), resolved.element
				end
			end
		end
	end

	for _, slotId in { "off", "head", "chest", "hands", "feets" } do
		local uuid = loadout[slotId]
		if uuid then
			local inst = InventoryService.Find(userId, uuid)
			local def = inst and ItemDefs.Get(inst.defId)
			if def and def.abilities then
				for _, ab in def.abilities do
					if ab.id == abilityId and ab.slotType == "Active" then
						return ab, def, def.element
					end
				end
			end
		end
	end
	return nil, nil, nil
end

local function isBound(userId: number, abilityId: string): boolean
	local binds = HotbarService.GetBinds(userId)
	for _, id in binds do
		if id == abilityId then
			return true
		end
	end
	return false
end

local function scalingFor(userId: number, def: any): number
	local s = StatService.Get(userId)
	local sc = def and def.scaling
	if sc == "DEX" then
		return s.DEX
	elseif sc == "INT" then
		return s.INT
	end
	return s.STR
end

local function weaponBase(def: any): number
	if def and def.baseDamage then
		return def.baseDamage
	end
	-- Armor actives use main weapon base
	return CombatConfig.DefaultWeaponBase
end

local function getMainWeaponDef(userId: number): any?
	local loadout = LoadoutService.Get(userId)
	if not loadout.main then
		return nil
	end
	local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
	if resolved and resolved.complete then
		return WeaponResolver.AsItemDef(resolved)
	end
	return nil
end

local function characterRoot(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function collectTargets(caster: Player, spec, look: Vector3, aimPos: Vector3?): { Instance }
	local root = characterRoot(caster)
	if not root then
		return {}
	end
	local origin = root.Position
	local forward = look.Magnitude > 0.1 and look.Unit or root.CFrame.LookVector

	if spec.shape == "Self" then
		return { caster.Character :: Instance }
	end

	local targets: { Instance } = {}
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
		if spec.shape ~= "GroundSphere" and dist > spec.range + 2 then
			return
		end
		if spec.shape == "Cone" then
			local deg = spec.coneDeg or 90
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude < 0.2 then
				return
			end
			local ang = math.deg(math.acos(math.clamp(forward:Dot(flat.Unit), -1, 1)))
			if ang > deg / 2 then
				return
			end
		elseif spec.shape == "Sphere" then
			local radius = spec.radius or spec.range
			if dist > radius then
				return
			end
		elseif spec.shape == "GroundSphere" then
			local radius = spec.radius or 8
			local center = aimPos or (origin + forward * math.min(spec.range, spec.range * 0.85))
			local flatCaster = Vector3.new(origin.X, 0, origin.Z)
			local flatCenter = Vector3.new(center.X, 0, center.Z)
			if (flatCenter - flatCaster).Magnitude > spec.range + 2 then
				return
			end
			local flatTarget = Vector3.new(pp.Position.X, 0, pp.Position.Z)
			if (flatTarget - flatCenter).Magnitude > radius then
				return
			end
		elseif spec.shape == "Line" then
			local flatFwd = Vector3.new(forward.X, 0, forward.Z)
			if flatFwd.Magnitude < 0.1 then
				return
			end
			flatFwd = flatFwd.Unit
			local flatOff = Vector3.new(offset.X, 0, offset.Z)
			local along = flatOff:Dot(flatFwd)
			if along < 0 or along > spec.range then
				return
			end
			local perp = flatOff - flatFwd * along
			local halfW = spec.lineWidth or 3
			if perp.Magnitude > halfW then
				return
			end
		elseif spec.shape == "Single" or spec.shape == "Dash" then
			-- Prefer aim / closest in forward hemisphere
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude > 0.2 and forward:Dot(flat.Unit) < 0.15 then
				return
			end
		end
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

	if spec.shape == "Single" or spec.shape == "Dash" then
		-- Keep closest to aimPos or origin
		table.sort(targets, function(a, b)
			local pa = (a :: Model).PrimaryPart or (a :: Model):FindFirstChild("HumanoidRootPart")
			local pb = (b :: Model).PrimaryPart or (b :: Model):FindFirstChild("HumanoidRootPart")
			local ra = if pa and pa:IsA("BasePart") then pa.Position else origin
			local rb = if pb and pb:IsA("BasePart") then pb.Position else origin
			local ref = aimPos or (origin + forward * spec.range)
			return (ra - ref).Magnitude < (rb - ref).Magnitude
		end)
		if #targets > 1 then
			return { targets[1] }
		end
	elseif spec.shape == "Line" then
		table.sort(targets, function(a, b)
			local pa = (a :: Model).PrimaryPart or (a :: Model):FindFirstChild("HumanoidRootPart")
			local pb = (b :: Model).PrimaryPart or (b :: Model):FindFirstChild("HumanoidRootPart")
			local ra = if pa and pa:IsA("BasePart") then pa.Position else origin
			local rb = if pb and pb:IsA("BasePart") then pb.Position else origin
			local flatFwd = Vector3.new(forward.X, 0, forward.Z).Unit
			return (ra - origin):Dot(flatFwd) < (rb - origin):Dot(flatFwd)
		end)
	end

	return targets
end

local function isAllySupportShape(shape: string): boolean
	return shape == "AllySingle" or shape == "AllyCone" or shape == "AllySphere"
end

local function collectAllyTargets(caster: Player, spec, look: Vector3, aimPos: Vector3?): { Model }
	local root = characterRoot(caster)
	if not root then
		return {}
	end
	local origin = root.Position
	local forward = look.Magnitude > 0.1 and look.Unit or root.CFrame.LookVector
	local range = spec.range or 18
	local candidates: { Model } = {}

	for _, ally in PvpTeamService.GetAllyPlayers(caster.UserId) do
		local char = ally.Character
		if not char or char == caster.Character then
			continue
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			continue
		end
		local pp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			continue
		end
		local offset = pp.Position - origin
		local dist = offset.Magnitude

		if spec.shape == "AllySphere" then
			local radius = spec.radius or range
			local center = aimPos or (origin + forward * math.min(range, radius))
			if (pp.Position - center).Magnitude > radius + 2 then
				continue
			end
		elseif spec.shape == "AllyCone" then
			if dist > range + 2 then
				continue
			end
			local deg = spec.coneDeg or 90
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude < 0.2 then
				continue
			end
			local ang = math.deg(math.acos(math.clamp(forward:Dot(flat.Unit), -1, 1)))
			if ang > deg / 2 then
				continue
			end
		else
			if dist > range + 2 then
				continue
			end
		end

		table.insert(candidates, char)
	end

	if #candidates == 0 then
		return {}
	end

	if spec.shape == "AllySingle" then
		table.sort(candidates, function(a, b)
			local pa = a.PrimaryPart or a:FindFirstChild("HumanoidRootPart")
			local pb = b.PrimaryPart or b:FindFirstChild("HumanoidRootPart")
			local ra = if pa and pa:IsA("BasePart") then pa.Position else origin
			local rb = if pb and pb:IsA("BasePart") then pb.Position else origin
			local ref = aimPos or (origin + forward * range)
			return (ra - ref).Magnitude < (rb - ref).Magnitude
		end)
		return { candidates[1] }
	end

	return candidates
end

local function applyAllySupport(casterUserId: number, target: Instance, spec: any): { string }
	local applied: { string } = {}
	if spec.healBase and spec.healBase > 0 then
		local healed = HealService.Apply(target, StatService.ScaleHeal(casterUserId, spec.healBase))
		if healed > 0 then
			table.insert(applied, `Heal+{healed}`)
		end
	end
	if spec.hotHps and spec.hotHps > 0 and spec.hotDuration and spec.hotDuration > 0 then
		local hotDur = StatService.ScaleBuffDuration(casterUserId, spec.hotDuration)
		StatusService.Apply(target, "Regen", hotDur, {
			sourceUserId = casterUserId,
			hps = spec.hotHps,
		})
		table.insert(applied, "Regen")
	end
	return applied
end

local function applyFortify(userId: number, player: Player, baseDuration: number, params: { [string]: number }?)
	local character = player.Character
	if not character then
		return
	end
	local duration = StatService.ScaleBuffDuration(userId, baseDuration)
	if PassiveService.HasPassive(userId, "stone_focus_armorpassive") then
		duration += 0.5
	end
	StatusService.Apply(character, "Fortify", duration, {
		sourceUserId = userId,
		params = params,
	})
	PassiveService.ApplyFortifyAura(player, duration, params)
end

local function applySelfAbility(player: Player, userId: number, element: string, spec: any): { string }
	local applied: { string } = {}
	local character = player.Character
	if not character then
		return applied
	end

	if spec.healBase and spec.healBase > 0 then
		local healed = HealService.Apply(character, StatService.ScaleHeal(userId, spec.healBase))
		if healed > 0 then
			table.insert(applied, `Heal+{healed}`)
		end
	end

	if spec.hotHps and spec.hotHps > 0 and spec.hotDuration and spec.hotDuration > 0 then
		local hotDur = StatService.ScaleBuffDuration(userId, spec.hotDuration)
		StatusService.Apply(character, "Regen", hotDur, {
			sourceUserId = userId,
			hps = spec.hotHps,
		})
		table.insert(applied, "Regen")
	end

	if spec.selfBuff == "Fortify" then
		applyFortify(userId, player, spec.selfBuffDuration or 3, spec.selfBuffParams)
		table.insert(applied, "Fortify")
	elseif spec.selfBuff == "Frenzy" then
		local duration = StatService.ScaleBuffDuration(userId, spec.selfBuffDuration or 3)
		StatusService.Apply(character, "Frenzy", duration, {
			sourceUserId = userId,
			params = spec.selfBuffParams,
		})
		table.insert(applied, "Frenzy")
	elseif spec.selfBuff == "HelmPulse" then
		local params = table.clone(spec.selfBuffParams or {})
		params.element = element
		params.charges = 2
		StatusService.Apply(character, "HelmPulse", spec.selfBuffDuration or 6, {
			sourceUserId = userId,
			params = params,
		})
		table.insert(applied, "HelmPulse")
	elseif spec.selfBuff == "CcImmunity" then
		CombatPressureService.GrantCcImmunity(character, spec.selfBuffDuration or 1.2, "disengage")
		table.insert(applied, "CcImmunity")
	end

	if spec.retreatStuds and spec.retreatStuds > 0 then
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local back = -hrp.CFrame.LookVector
			back = Vector3.new(back.X, 0, back.Z)
			if back.Magnitude > 0.1 then
				back = back.Unit
				hrp.AssemblyLinearVelocity = back * spec.retreatStuds * 14 + Vector3.new(0, 10, 0)
			end
		end
	end

	return applied
end

local function applyCharge(player: Player, look: Vector3, studs: number)
	local hrp = characterRoot(player)
	if not hrp or studs <= 0 then
		return
	end
	local dir = Vector3.new(look.X, 0, look.Z)
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	end
	if dir.Magnitude < 0.1 then
		return
	end
	dir = dir.Unit
	hrp.AssemblyLinearVelocity = dir * studs * 14 + Vector3.new(0, 8, 0)
end

local function applyKnockback(target: Model, fromPos: Vector3, studs: number, sourceUserId: number)
	if studs <= 0 then
		return
	end
	local hrp = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local offset = hrp.Position - fromPos
	local dir = Vector3.new(offset.X, 0, offset.Z)
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(0, 0, 1)
	else
		dir = dir.Unit
	end
	hrp.AssemblyLinearVelocity = dir * studs * 13 + Vector3.new(0, 14, 0)
	CombatPressureService.TryApplyStatus(target, "Hitstun", 0.35, {
		sourceUserId = sourceUserId,
		params = { slowPct = 45 },
		silentBatch = true,
	})
end

local function flatDist(a: Vector3, b: Vector3): number
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

local function resolveHookPosition(origin: Vector3, look: Vector3, aim: Vector3?, maxRange: number): Vector3
	local hook = aim
	if not hook then
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 0.1 then
			flatLook = Vector3.new(0, 0, -1)
		else
			flatLook = flatLook.Unit
		end
		hook = origin + flatLook * maxRange
	end
	if flatDist(origin, hook) > maxRange then
		local dir = hook - origin
		dir = Vector3.new(dir.X, 0, dir.Z)
		if dir.Magnitude < 0.1 then
			dir = Vector3.new(0, 0, -maxRange)
		else
			dir = dir.Unit * maxRange
		end
		hook = origin + dir + Vector3.new(0, hook.Y - origin.Y, 0)
	end
	return hook
end

local function teleportModelRoot(model: Model, pos: Vector3)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local y = pos.Y
	if hum then
		y = pos.Y + hum.HipHeight
	end
	hrp.CFrame = CFrame.new(Vector3.new(pos.X, y, pos.Z))
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end

local function isGrapplePullable(model: Model, caster: Player): boolean
	if model == caster.Character then
		return false
	end
	if model:GetAttribute("IsBoss") or model.Name == "Boss_TheEye" then
		return false
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	local plr = Players:GetPlayerFromCharacter(model)
	if plr and PvpTeamService.IsTeamMatch() then
		for _, ally in PvpTeamService.GetAllyPlayers(caster.UserId) do
			if ally == plr then
				return false
			end
		end
	end
	return true
end

local function collectGrappleTargets(caster: Player, hookPos: Vector3, radius: number): { Model }
	local candidates: { Model } = {}
	local function tryAdd(model: Model)
		if not isGrapplePullable(model, caster) then
			return
		end
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		if flatDist(pp.Position, hookPos) > radius + 1.5 then
			return
		end
		table.insert(candidates, model)
	end

	if BossCombatTargets.IsActive() then
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

	table.sort(candidates, function(a, b)
		local pa = a.PrimaryPart or a:FindFirstChild("HumanoidRootPart")
		local pb = b.PrimaryPart or b:FindFirstChild("HumanoidRootPart")
		local ra = if pa and pa:IsA("BasePart") then pa.Position else hookPos
		local rb = if pb and pb:IsA("BasePart") then pb.Position else hookPos
		return flatDist(ra, hookPos) < flatDist(rb, hookPos)
	end)
	return candidates
end

local function pullTargetBesideCaster(caster: Player, target: Model, look: Vector3, offsetStuds: number)
	local casterHrp = characterRoot(caster)
	if not casterHrp then
		return
	end
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.1 then
		flatLook = Vector3.new(casterHrp.CFrame.LookVector.X, 0, casterHrp.CFrame.LookVector.Z)
	end
	if flatLook.Magnitude < 0.1 then
		flatLook = Vector3.new(0, 0, -1)
	end
	flatLook = flatLook.Unit
	local land = casterHrp.Position + flatLook * offsetStuds
	teleportModelRoot(target, land)
end

local function pullCasterToHook(player: Player, hookPos: Vector3)
	local casterHrp = characterRoot(player)
	local char = player.Character
	if not casterHrp or not char then
		return
	end
	local flat = Vector3.new(hookPos.X - casterHrp.Position.X, 0, hookPos.Z - casterHrp.Position.Z)
	local land = hookPos
	if flat.Magnitude > 1.2 then
		land = hookPos - flat.Unit * 1.5
	end
	teleportModelRoot(char, Vector3.new(land.X, hookPos.Y + 1.5, land.Z))
end

local function isCrossbowMain(userId: number): boolean
	local loadout = LoadoutService.Get(userId)
	if not loadout.main then
		return false
	end
	local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
	return resolved and resolved.complete and resolved.family == "Crossbow"
end

local function isOffHandAbilitySource(userId: number, sourceDefId: string?): boolean
	if not sourceDefId then
		return false
	end
	local loadout = LoadoutService.Get(userId)
	if not loadout.off then
		return false
	end
	local inst = InventoryService.Find(userId, loadout.off)
	if not inst or inst.defId ~= sourceDefId then
		return false
	end
	local offDef = ItemDefs.Get(inst.defId)
	local weaponKinds = { Weapon1H = true, Wand = true, Scepter = true }
	return offDef ~= nil and weaponKinds[offDef.kind] == true
end

function AbilityService.Cast(player: Player, abilityId: string, lookVector: Vector3?, aimPosition: Vector3?): CastResult
	if typeof(abilityId) ~= "string" then
		return { ok = false, reason = "BadId" }
	end
	local userId = player.UserId
	if CombatPressureService.IsActionLocked(userId) then
		return { ok = false, reason = "Recovery" }
	end
	if CrossbowReloadService.IsReloading(userId) and isCrossbowMain(userId) then
		return { ok = false, reason = "Reloading" }
	end
	if PvpTeamService.IsCombatLocked(userId) then
		return { ok = false, reason = "CombatLocked" }
	end
	if not player.Character or not CombatPressureService.CanAttackEntity(player.Character) then
		return { ok = false, reason = "Stunned" }
	end
	if not isBound(userId, abilityId) then
		return { ok = false, reason = "NotBound" }
	end
	local abDef, itemDef, frameElement = findAbilityOnLoadout(userId, abilityId)
	if not abDef then
		return { ok = false, reason = "NotEquipped" }
	end

	local element = frameElement or (itemDef and itemDef.element) or "Neutral"
	local spec = AbilityRuntime.Get(abilityId, element, abDef.cooldownSec)
	local cd = spec.cooldownSec
	local map = readyMap(userId)
	local t = os.clock()
	if (map[abilityId] or 0) > t then
		return { ok = false, reason = "Cooldown" }
	end

	local mainDef = getMainWeaponDef(userId)
	local base = weaponBase(mainDef or itemDef)
	-- If casting from weapon item, use that weapon's base
	if itemDef and itemDef.baseDamage then
		base = itemDef.baseDamage
	end
	local offMult = if isOffHandAbilitySource(userId, itemDef and itemDef.id) then CombatConfig.OffHandAbilityMult else 1
	local scale = scalingFor(userId, mainDef or itemDef)
	local look = if typeof(lookVector) == "Vector3" then lookVector else Vector3.new(0, 0, -1)
	local aim = if typeof(aimPosition) == "Vector3" then aimPosition else nil
	local pressureGroupId = `{userId}_ab_{math.floor(t * 1000)}`

	local function commitCastPressure()
		if player.Character and spec.damagePct and spec.damagePct > 0 then
			CombatPressureService.ApplyHyperArmor(player.Character, CombatConfig.HyperArmorAbilitySec, userId)
		end
		CombatPressureService.LockActions(userId, CombatPressureService.AbilityRecoverySec())
	end

	local hits = {}
	local hookPos: Vector3? = nil
	local grappleMode: string? = nil

	if spec.shape == "Self" then
		map[abilityId] = t + cd
		commitCastPressure()
		local statuses = applySelfAbility(player, userId, element, spec)
		table.insert(hits, { targetKind = "Self", damage = 0, statuses = statuses })
	elseif isAllySupportShape(spec.shape) then
		local allyTargets = collectAllyTargets(player, spec, look, aim)
		if #allyTargets == 0 and abilityId == "healing_idol_focusactive" and player.Character then
			allyTargets = { player.Character }
		end
		if #allyTargets == 0 then
			return { ok = false, reason = "NoAlly" }
		end
		map[abilityId] = t + cd
		commitCastPressure()
		for _, target in allyTargets do
			local statuses = applyAllySupport(userId, target, spec)
			local allyPlr = Players:GetPlayerFromCharacter(target)
			local kind = if allyPlr then "Ally" else "AllyNpc"
			table.insert(hits, { targetKind = kind, damage = 0, statuses = statuses })
		end
	elseif spec.shape == "Grapple" then
		map[abilityId] = t + cd
		if player.Character then
			CombatPressureService.ApplyHyperArmor(player.Character, 0.4, userId)
		end
		CombatPressureService.LockActions(userId, CombatPressureService.AbilityRecoverySec())

		local casterRoot = characterRoot(player)
		if not casterRoot then
			return { ok = false, reason = "NoChar" }
		end
		hookPos = resolveHookPosition(casterRoot.Position, look, aim, spec.range)
		local latchRadius = spec.radius or 4.5
		local pullTargets = collectGrappleTargets(player, hookPos, latchRadius)

		if #pullTargets > 0 then
			local target = pullTargets[1]
			pullTargetBesideCaster(player, target, look, spec.grapplePullDistance or 3.5)
			CombatPressureService.TryApplyStatus(target, "Hitstun", 0.45, {
				sourceUserId = userId,
				params = { slowPct = 55 },
				silentBatch = true,
			})
			if target.Name == "TrainingDummy" then
				DummyService.RefreshStatusLabel(StatusService.FormatShort(target))
			end
			local _, kind = DamageService.ResolveEntity(target)
			table.insert(hits, { targetKind = kind, damage = 0, statuses = { "Grappled" } })
			grappleMode = "Target"
		else
			pullCasterToHook(player, hookPos)
			table.insert(hits, { targetKind = "Self", damage = 0, statuses = { "Grapple" } })
			grappleMode = "Caster"
		end
	else
		map[abilityId] = t + cd
		commitCastPressure()
		if spec.chargeStuds and spec.chargeStuds > 0 then
			applyCharge(player, look, spec.chargeStuds)
		end
		local casterRoot = characterRoot(player)
		local targets = collectTargets(player, spec, look, aim)

		-- multi-hit volley (same target)
		local hitMult = spec.hitCount or 1
		for _, target in targets do
			local statusesApplied = {}
			local totalDmg = 0
			for i = 1, hitMult do
				if spec.damagePct > 0 then
					local onHit = nil
					if i == 1 and spec.statusId then
						onHit = {
							id = spec.statusId,
							duration = spec.statusDuration or 3,
							dps = spec.statusDps,
						}
					end
					local report = DamageService.DealDirect({
						attacker = player,
						target = target,
						weaponBase = base,
						scalingStat = scale,
						atkElement = element,
						abilityPct = spec.damagePct * offMult,
						kind = "Ability",
						applyOnHitStatus = onHit,
						pressureGroupId = pressureGroupId,
					})
					totalDmg += report.dealt
					if onHit and report.onHitApplied then
						table.insert(statusesApplied, spec.statusId)
					end
				elseif spec.statusId then
					local raw = {
						id = spec.statusId,
						duration = spec.statusDuration,
						dps = spec.statusDps,
						params = spec.statusParams,
					}
					local finalized = PassiveService.FinalizeLaOnHitStatus(userId, raw, element)
					CombatPressureService.TryApplyStatus(target, finalized.id, finalized.duration, {
						sourceUserId = userId,
						dps = finalized.dps,
						params = finalized.params,
					})
					table.insert(statusesApplied, spec.statusId)
				end
			end
			if target.Name == "TrainingDummy" then
				DummyService.RefreshStatusLabel(StatusService.FormatShort(target))
			end
			if spec.knockbackStuds and spec.knockbackStuds > 0 and casterRoot and target:IsA("Model") then
				applyKnockback(target, casterRoot.Position, spec.knockbackStuds, userId)
			end
			local _, kind = DamageService.ResolveEntity(target)
			table.insert(hits, { targetKind = kind, damage = totalDmg, statuses = statusesApplied })
		end
	end

	local root = characterRoot(player)
	local fx = {
		abilityId = abilityId,
		anim = spec.anim,
		vfx = spec.vfx,
		element = element,
		origin = if root then root.Position else Vector3.zero,
		look = look,
		aimPos = aim,
		range = spec.range,
		coneDeg = spec.coneDeg,
		radius = spec.radius,
		lineWidth = spec.lineWidth,
		shape = spec.shape,
		cooldownSec = cd,
		recoverySec = CombatPressureService.AbilityRecoverySec(),
		hookPos = hookPos,
		grappleMode = grappleMode,
	}

	return {
		ok = true,
		abilityId = abilityId,
		hits = hits,
		fx = fx,
	}
end

function AbilityService.GetCooldownRemaining(userId: number, abilityId: string): number
	local readyAt = readyMap(userId)[abilityId] or 0
	return math.max(0, readyAt - os.clock())
end

function AbilityService.Clear(userId: number)
	cooldowns[userId] = nil
	CombatPressureService.ClearUser(userId)
end

return AbilityService
