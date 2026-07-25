--[[
	Lobby training dummies — primary dummy + dev-spawned extras + LA attacker.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)

local DummyService = {}

export type DummyRecord = {
	hp: number,
	maxHp: number,
	laAttacker: boolean,
	laComboStep: number,
	spawned: boolean,
}

local records: { [Model]: DummyRecord } = {}
local laThreads: { [Model]: thread? } = {}
local primaryModel: Model? = nil
local defaultMaxHp = CombatConfig.DummyMaxHp

local function syncNameplate(model: Model)
	local NameplateService = require(script.Parent.NameplateService)
	NameplateService.Sync(model)
end

local function getRecord(model: Model?): DummyRecord?
	if not model then
		return nil
	end
	return records[model]
end

local function applyHumHealth(model: Model, hp: number, maxHp: number)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.MaxHealth = maxHp
		hum.Health = hp
	end
end

local function setDeadVisual(model: Model, dead: boolean)
	local root = model.PrimaryPart
	if root and root:IsA("BasePart") then
		root.Color = if dead then Color3.fromRGB(80, 80, 90) else Color3.fromRGB(180, 90, 70)
	end
end

local function stopLaLoop(model: Model)
	local th = laThreads[model]
	if th then
		task.cancel(th)
		laThreads[model] = nil
	end
end

local function fireLaFx(attacker: Model, target: Model, comboStep: number)
	local folder = ReplicatedStorage:FindFirstChild("CombatRemotes")
	local fxRemote = folder and folder:FindFirstChild("CombatFx")
	if not fxRemote or not fxRemote:IsA("RemoteEvent") then
		return
	end
	local aRoot = attacker.PrimaryPart
	local tRoot = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
	if not aRoot or not tRoot then
		return
	end
	local look = tRoot.Position - aRoot.Position
	if look.Magnitude > 0.1 then
		look = look.Unit
	else
		look = aRoot.CFrame.LookVector
	end
	fxRemote:FireAllClients(0, {
		anim = `Sword1H_L{comboStep}`,
		vfx = "Slash",
		element = "Steel",
		family = "Sword1H",
		comboStep = comboStep,
		origin = aRoot.Position,
		look = look,
		range = CombatConfig.DummyLaRange,
		dummyName = attacker.Name,
	}, nil)
end

local function performLaSwing(attacker: Model)
	local rec = getRecord(attacker)
	if not rec or rec.hp <= 0 then
		return
	end
	local root = attacker.PrimaryPart
	if not root or not root:IsA("BasePart") then
		return
	end

	local nearest: Model? = nil
	local nearestDist = CombatConfig.DummyLaRange + 0.5
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if char and hrp and hrp:IsA("BasePart") then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist <= CombatConfig.DummyLaRange and dist < nearestDist then
					nearest = char
					nearestDist = dist
				end
			end
		end
	end
	if not nearest then
		return
	end

	rec.laComboStep = (rec.laComboStep % 3) + 1
	fireLaFx(attacker, nearest, rec.laComboStep)

	local DodgeService = require(script.Parent.DodgeService)
	local GuardService = require(script.Parent.GuardService)
	local ParryService = require(script.Parent.ParryService)
	local DamageService = require(script.Parent.DamageService)

	if DodgeService.IsIFraming(nearest) then
		return
	end

	local damage = CombatConfig.DummyLaDamage
	local attackerPos = root.Position
	local plr = Players:GetPlayerFromCharacter(nearest)
	if plr then
		local userId = plr.UserId
		if ParryService.IsParrying(userId) then
			local handled, perfect, _ = ParryService.TryParry(userId, nearest, nil, attackerPos)
			if handled and perfect then
				return
			end
			if handled and not perfect then
				damage = math.floor(damage * 0.5 + 0.5)
			end
		end
		local blocked, chip = GuardService.TryBlock(userId, nearest, attackerPos, damage, 1)
		if blocked then
			damage = chip
		end
	end

	if damage > 0 then
		DamageService.ApplyHp(nearest, "Player", damage, plr and plr.UserId)
	end
end

local function startLaLoop(model: Model)
	stopLaLoop(model)
	laThreads[model] = task.spawn(function()
		while model.Parent and getRecord(model) do
			performLaSwing(model)
			task.wait(CombatConfig.DummyLaCooldownSec)
		end
	end)
end

function DummyService.RefreshStatusLabel(_text: string)
	for model in records do
		if model.Parent then
			syncNameplate(model)
		end
	end
end

local function buildDummyModel(opts: {
	name: string,
	position: Vector3,
	displayName: string,
	bodyColor: Color3?,
	headColor: Color3?,
	laAttacker: boolean?,
	spawned: boolean?,
}): Model
	local model = Instance.new("Model")
	model.Name = opts.name
	model:SetAttribute("IsCombatDummy", true)
	if opts.laAttacker then
		model:SetAttribute("IsLaAttackerDummy", true)
	end

	local bodyColor = opts.bodyColor or Color3.fromRGB(180, 90, 70)
	local headColor = opts.headColor or Color3.fromRGB(200, 160, 120)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 2)
	root.Color = bodyColor
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.Position = opts.position
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = headColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = opts.position + Vector3.new(0, 3.2, 0)
	head.Parent = model

	local maxHp = defaultMaxHp
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.MaxHealth = maxHp
	hum.Health = maxHp
	hum.Parent = model
	local animator = Instance.new("Animator")
	animator.Parent = hum

	model.PrimaryPart = root
	model.Parent = Workspace

	records[model] = {
		hp = maxHp,
		maxHp = maxHp,
		laAttacker = opts.laAttacker == true,
		laComboStep = 0,
		spawned = opts.spawned == true,
	}

	local NameplateService = require(script.Parent.NameplateService)
	NameplateService.Setup(model, "Training", opts.displayName)
	if opts.laAttacker then
		startLaLoop(model)
	end
	return model
end

function DummyService.Ensure(): Model
	if primaryModel and primaryModel.Parent then
		return primaryModel
	end
	primaryModel = buildDummyModel({
		name = "TrainingDummy",
		position = CombatConfig.DummySpawn,
		displayName = CombatConfig.DummyName,
		spawned = false,
	})
	return primaryModel
end

function DummyService.GetPosition(): Vector3?
	local m = DummyService.Ensure()
	local pp = m.PrimaryPart
	return if pp then pp.Position else nil
end

function DummyService.GetHp(): (number, number)
	local model = DummyService.Ensure()
	local rec = getRecord(model)
	if rec then
		return rec.hp, rec.maxHp
	end
	return defaultMaxHp, defaultMaxHp
end

function DummyService.GetHpFor(model: Model): (number, number)
	local rec = getRecord(model)
	if rec then
		return rec.hp, rec.maxHp
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum.Health, hum.MaxHealth
	end
	return 0, 1
end

function DummyService.GetSpawnedCount(): number
	local n = 0
	for model, rec in records do
		if rec.spawned and model.Parent then
			n += 1
		end
	end
	return n
end

function DummyService.SetMaxHp(newMax: number)
	defaultMaxHp = math.max(1, math.floor(newMax))
	for model, rec in records do
		rec.maxHp = defaultMaxHp
		rec.hp = math.min(rec.hp, rec.maxHp)
		if rec.hp <= 0 then
			rec.hp = rec.maxHp
		end
		applyHumHealth(model, rec.hp, rec.maxHp)
		syncNameplate(model)
	end
end

local function resetRecord(model: Model)
	local rec = getRecord(model)
	if not rec then
		return
	end
	rec.hp = rec.maxHp
	rec.laComboStep = 0
	applyHumHealth(model, rec.hp, rec.maxHp)
	setDeadVisual(model, false)
	local StatusService = require(script.Parent.StatusService)
	StatusService.ClearEntity(model)
	syncNameplate(model)
end

function DummyService.Reset()
	for model in records do
		if model.Parent then
			resetRecord(model)
		end
	end
end

function DummyService.ResetModel(model: Model)
	resetRecord(model)
end

function DummyService.ApplyDamage(amount: number): (number, boolean)
	local model = DummyService.Ensure()
	return DummyService.ApplyDamageTo(model, amount)
end

function DummyService.ApplyDamageTo(model: Model, amount: number): (number, boolean)
	local rec = getRecord(model)
	if not rec then
		return 0, false
	end
	if rec.hp <= 0 then
		return 0, true
	end
	local dealt = math.max(0, amount)
	rec.hp = math.max(0, rec.hp - dealt)
	applyHumHealth(model, rec.hp, rec.maxHp)
	syncNameplate(model)
	local dead = rec.hp <= 0
	if dead then
		setDeadVisual(model, true)
		task.delay(2.5, function()
			if getRecord(model) and rec.hp <= 0 then
				resetRecord(model)
			end
		end)
	end
	return dealt, dead
end

function DummyService.SpawnExtras(count: number): number
	local n = math.clamp(math.floor(count), 1, 8)
	local spread = CombatConfig.DummySpawnSpread
	local base = DummyService.GetSpawnedCount()
	local spawned = 0
	for i = 1, n do
		local idx = base + i
		local angle = (i / n) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * spread, 0, math.sin(angle) * spread)
		local pos = CombatConfig.DummySpawn + offset
		buildDummyModel({
			name = `TrainingDummy_{idx}`,
			position = pos,
			displayName = `Dummy #{idx}`,
			bodyColor = Color3.fromRGB(150, 110, 90),
			spawned = true,
		})
		spawned += 1
	end
	return spawned
end

function DummyService.SpawnLaAttacker(): Model
	local spread = CombatConfig.DummySpawnSpread
	local pos = CombatConfig.DummySpawn + Vector3.new(-spread, 0, spread * 0.6)
	local name = "TrainingDummy_LA"
	local existing = Workspace:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		existing:Destroy()
		records[existing] = nil
		stopLaLoop(existing)
	end
	return buildDummyModel({
		name = name,
		position = pos,
		displayName = CombatConfig.DummyLaName,
		bodyColor = Color3.fromRGB(120, 80, 140),
		headColor = Color3.fromRGB(180, 140, 200),
		laAttacker = true,
		spawned = true,
	})
end

function DummyService.ClearSpawned()
	for model, rec in records do
		if rec.spawned then
			stopLaLoop(model)
			records[model] = nil
			if model.Parent then
				model:Destroy()
			end
		end
	end
end

function DummyService.DestroyAllExtras()
	DummyService.ClearSpawned()
end

return DummyService
