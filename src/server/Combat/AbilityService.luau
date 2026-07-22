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
local StatusService = require(script.Parent.StatusService)
local DamageService = require(script.Parent.DamageService)
local DummyService = require(script.Parent.DummyService)

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
		if dist > spec.range + 2 then
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
		elseif spec.shape == "Single" or spec.shape == "Dash" then
			-- Prefer aim / closest in forward hemisphere
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude > 0.2 and forward:Dot(flat.Unit) < 0.15 then
				return
			end
		end
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
	end

	return targets
end

function AbilityService.Cast(player: Player, abilityId: string, lookVector: Vector3?, aimPosition: Vector3?): CastResult
	if typeof(abilityId) ~= "string" then
		return { ok = false, reason = "BadId" }
	end
	local userId = player.UserId
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
	local scale = scalingFor(userId, mainDef or itemDef)
	local look = if typeof(lookVector) == "Vector3" then lookVector else Vector3.new(0, 0, -1)
	local aim = if typeof(aimPosition) == "Vector3" then aimPosition else nil

	map[abilityId] = t + cd

	local hits = {}
	local targets = collectTargets(player, spec, look, aim)

	if spec.shape == "Self" then
		if player.Character then
			if spec.selfBuff then
				StatusService.Apply(player.Character, spec.selfBuff, spec.selfBuffDuration, {
					sourceUserId = userId,
					params = spec.selfBuffParams,
				})
			end
			table.insert(hits, { targetKind = "Self", damage = 0, statuses = { spec.selfBuff or "" } })
		end
	else
		-- fan_of_knives proto: apply damage 3 times as simplified volley
		local hitMult = if abilityId == "fan_of_knives" then 3 elseif abilityId == "gale_volley" then 3 else 1
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
						abilityPct = spec.damagePct,
						kind = "Ability",
						applyOnHitStatus = onHit,
					})
					totalDmg += report.dealt
					if onHit and report.onHitApplied then
						table.insert(statusesApplied, spec.statusId)
					end
				elseif spec.statusId then
					StatusService.Apply(target, spec.statusId, spec.statusDuration, {
						sourceUserId = userId,
						dps = spec.statusDps,
					})
					table.insert(statusesApplied, spec.statusId)
				end
			end
			if target.Name == "TrainingDummy" then
				DummyService.RefreshStatusLabel(StatusService.FormatShort(target))
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
		range = spec.range,
		coneDeg = spec.coneDeg,
		radius = spec.radius,
		shape = spec.shape,
		cooldownSec = cd,
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
end

return AbilityService
