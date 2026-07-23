--[[
	Lobby training dummy — spawn + HP + damage apply.
]]

local Workspace = game:GetService("Workspace")
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)

local DummyService = {}

local dummyModel: Model? = nil
local currentHp = CombatConfig.DummyMaxHp
local maxHp = CombatConfig.DummyMaxHp

local function updateNameplate()
	if not dummyModel then
		return
	end
	local NameplateService = require(script.Parent.NameplateService)
	NameplateService.Sync(dummyModel)
end

function DummyService.RefreshStatusLabel(_text: string)
	updateNameplate()
end

local function buildDummy(): Model
	local model = Instance.new("Model")
	model.Name = "TrainingDummy"
	model:SetAttribute("IsCombatDummy", true)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 2)
	root.Color = Color3.fromRGB(180, 90, 70)
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.Position = CombatConfig.DummySpawn
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = Color3.fromRGB(200, 160, 120)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = CombatConfig.DummySpawn + Vector3.new(0, 3.2, 0)
	head.Parent = model

	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.MaxHealth = maxHp
	hum.Health = maxHp
	hum.Parent = model

	model.PrimaryPart = root
	model.Parent = Workspace

	local NameplateService = require(script.Parent.NameplateService)
	NameplateService.Setup(model, "Training", CombatConfig.DummyName)
	return model
end

function DummyService.Ensure()
	if dummyModel and dummyModel.Parent then
		return dummyModel
	end
	currentHp = maxHp
	dummyModel = buildDummy()
	return dummyModel
end

function DummyService.GetPosition(): Vector3?
	local m = DummyService.Ensure()
	local pp = m.PrimaryPart
	return if pp then pp.Position else nil
end

function DummyService.GetHp(): (number, number)
	return currentHp, maxHp
end

function DummyService.SetMaxHp(newMax: number)
	maxHp = math.max(1, math.floor(newMax))
	currentHp = maxHp
	if dummyModel then
		local hum = dummyModel:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = maxHp
			hum.Health = maxHp
		end
	end
	updateNameplate()
end

function DummyService.Reset()
	currentHp = maxHp
	if dummyModel then
		local hum = dummyModel:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = maxHp
		end
		local root = dummyModel.PrimaryPart
		if root and root:IsA("BasePart") then
			root.Color = Color3.fromRGB(180, 90, 70)
		end
		local StatusService = require(script.Parent.StatusService)
		StatusService.ClearEntity(dummyModel)
	end
	updateNameplate()
end

function DummyService.ApplyDamage(amount: number): (number, boolean)
	DummyService.Ensure()
	if currentHp <= 0 then
		return 0, true
	end
	local dealt = math.max(0, amount)
	currentHp = math.max(0, currentHp - dealt)
	local hum = dummyModel and dummyModel:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = currentHp
	end
	updateNameplate()
	local dead = currentHp <= 0
	if dead and dummyModel and dummyModel.PrimaryPart then
		(dummyModel.PrimaryPart :: BasePart).Color = Color3.fromRGB(80, 80, 90)
		task.delay(2.5, function()
			if currentHp <= 0 then
				DummyService.Reset()
			end
		end)
	end
	return dealt, dead
end

return DummyService
