--[[
	Lobby training dummy — spawn + HP + damage apply.
]]

local Workspace = game:GetService("Workspace")
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)

local DummyService = {}

local dummyModel: Model? = nil
local currentHp = CombatConfig.DummyMaxHp
local maxHp = CombatConfig.DummyMaxHp
local hpLabel: TextLabel? = nil
local statusLabel: TextLabel? = nil

local function updateBillboard()
	if hpLabel then
		hpLabel.Text = `HP {math.max(0, math.floor(currentHp))} / {maxHp}`
		if currentHp <= 0 then
			hpLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		else
			hpLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
		end
	end
end

function DummyService.RefreshStatusLabel(text: string)
	if statusLabel then
		statusLabel.Text = if text ~= "" then text else "—"
	end
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

	local bb = Instance.new("BillboardGui")
	bb.Name = "HpBillboard"
	bb.Size = UDim2.fromOffset(180, 64)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = head
	bb.Parent = head

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(240, 240, 245)
	title.Text = CombatConfig.DummyName
	title.Parent = bb

	local hp = Instance.new("TextLabel")
	hp.Size = UDim2.new(1, 0, 0, 18)
	hp.Position = UDim2.fromOffset(0, 16)
	hp.BackgroundTransparency = 1
	hp.Font = Enum.Font.Gotham
	hp.TextSize = 12
	hp.TextColor3 = Color3.fromRGB(255, 220, 120)
	hp.Parent = bb
	hpLabel = hp

	local st = Instance.new("TextLabel")
	st.Size = UDim2.new(1, 0, 0, 14)
	st.Position = UDim2.fromOffset(0, 34)
	st.BackgroundTransparency = 1
	st.Font = Enum.Font.Gotham
	st.TextSize = 10
	st.TextColor3 = Color3.fromRGB(160, 200, 255)
	st.Text = "—"
	st.Parent = bb
	statusLabel = st

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, 0, 0, 12)
	hint.Position = UDim2.fromOffset(0, 48)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 9
	hint.TextColor3 = Color3.fromRGB(160, 165, 175)
	hint.Text = "Hotbar actives (Q E R 1 2 3)"
	hint.Parent = bb

	model.Parent = Workspace
	updateBillboard()
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
	updateBillboard()
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
		DummyService.RefreshStatusLabel("")
	end
	updateBillboard()
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
	updateBillboard()
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
