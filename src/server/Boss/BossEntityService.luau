--[[
	Boss entity — placeholder Eye model, HP, phase sync.
]]

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local NameplateService = require(script.Parent.Parent.Combat.NameplateService)

local BossEntityService = {}

local bossModel: Model? = nil
local maxHp = 0
local currentHp = 0
local phase = 1
local bossId: string? = nil
local onHpChanged: ((number, number, number) -> ())? = nil
local onDeath: (() -> ())? = nil

function BossEntityService.SetOnHpChanged(cb: ((number, number, number) -> ())?)
	onHpChanged = cb
end

function BossEntityService.SetOnDeath(cb: (() -> ())?)
	onDeath = cb
end

local function refreshBillboard()
	if bossModel then
		NameplateService.Sync(bossModel)
	end
end

local function buildEyeModel(center: Vector3, hp: number, id: string): Model
	local model = Instance.new("Model")
	model.Name = "Boss_TheEye"
	model:SetAttribute("IsBoss", true)
	model:SetAttribute("BossId", id)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(8, 8, 8)
	root.Anchored = true
	root.CanCollide = false
	root.Transparency = 1
	root.CFrame = CFrame.new(center + Vector3.new(0, 8, 0))
	root.Parent = model
	model.PrimaryPart = root

	local body = Instance.new("Part")
	body.Name = "EyeBody"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(24, 24, 24)
	body.Anchored = true
	body.CanCollide = true
	body.Color = Color3.fromRGB(220, 220, 230)
	body.Material = Enum.Material.SmoothPlastic
	body.CFrame = root.CFrame
	body.Parent = model

	local iris = Instance.new("Part")
	iris.Name = "Iris"
	iris.Shape = Enum.PartType.Ball
	iris.Size = Vector3.new(10, 10, 3)
	iris.Anchored = true
	iris.CanCollide = false
	iris.Color = Color3.fromRGB(180, 40, 60)
	iris.Material = Enum.Material.Neon
	iris.CFrame = root.CFrame * CFrame.new(0, 0, -10)
	iris.Parent = model

	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.MaxHealth = hp
	hum.Health = hp
	hum.Parent = model

	model.Parent = workspace
	return model
end

function BossEntityService.Spawn(id: string, center: Vector3, hp: number)
	BossEntityService.Destroy()
	bossId = id
	maxHp = hp
	currentHp = hp
	phase = 1
	bossModel = buildEyeModel(center, hp, id)
	local def = BossEncounterConfig.Get(id)
	local displayName = if def then def.displayName else "Boss"
	NameplateService.Setup(bossModel, "Boss", displayName, { phase = 1 })
	refreshBillboard()
end

function BossEntityService.Destroy()
	if bossModel and bossModel.Parent then
		bossModel:Destroy()
	end
	bossModel = nil
	maxHp = 0
	currentHp = 0
	phase = 1
	bossId = nil
end

function BossEntityService.GetModel(): Model?
	return bossModel
end

function BossEntityService.GetCenter(): Vector3?
	if bossModel and bossModel.PrimaryPart then
		return bossModel.PrimaryPart.Position
	end
	return nil
end

function BossEntityService.GetHp(): (number, number)
	return currentHp, maxHp
end

function BossEntityService.GetHpPct(): number
	if maxHp <= 0 then
		return 1
	end
	return currentHp / maxHp
end

function BossEntityService.GetPhase(): number
	return phase
end

function BossEntityService.SetPhase(p: number)
	phase = math.clamp(math.floor(p), 1, 3)
	refreshBillboard()
end

function BossEntityService.SetCallbacks(hpCb: ((number, number, number) -> ())?, deathCb: (() -> ())?)
	BossEntityService.SetOnHpChanged(hpCb)
	BossEntityService.SetOnDeath(deathCb)
end

function BossEntityService.ApplyDamage(amount: number): (number, boolean)
	if not bossModel or currentHp <= 0 then
		return 0, true
	end
	local dealt = math.max(0, math.floor(amount))
	currentHp = math.max(0, currentHp - dealt)
	local hum = bossModel:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = currentHp
	end
	refreshBillboard()
	if onHpChanged then
		onHpChanged(currentHp, maxHp, phase)
	end
	local dead = currentHp <= 0
	if dead and onDeath then
		onDeath()
	end
	return dealt, dead
end

function BossEntityService.GetDefence(): number
	local def = bossId and BossEncounterConfig.Get(bossId)
	return if def and typeof(def.defence) == "number" then def.defence else 100
end

return BossEntityService
