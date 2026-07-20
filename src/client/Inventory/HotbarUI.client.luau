--[[
	Hotbar UI — Q E R 1 2 3
	Loadout açıkken alt listeden aktif sürükle (basılı tut → slot üzerinde bırak).
	Pasifler listelenmez.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local HotbarConfig = require(ReplicatedStorage.Shared.Config.HotbarConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local GetSnapshot = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local BindAbility = remotes:WaitForChild("BindAbility") :: RemoteEvent
local UnbindHotbar = remotes:WaitForChild("UnbindHotbar") :: RemoteEvent
local InventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent

type ActiveInfo = { abilityId: string, name: string, desc: string, sourceUuid: string, defId: string }

local snapshot = {
	hotbar = {} :: { [number]: string? },
	actives = {} :: { ActiveInfo },
}

local draggingId: string? = nil
local dragGhost: TextLabel? = nil

local gui = Instance.new("ScreenGui")
gui.Name = "HotbarUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Ability pool (loadout ile birlikte; H ile de açılır)
local poolOpen = false
local pool = Instance.new("Frame")
pool.Name = "AbilityPool"
pool.Size = UDim2.fromOffset(320, 220)
pool.Position = UDim2.new(0.5, -160, 1, -280)
pool.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
pool.BorderSizePixel = 0
pool.Visible = false
pool.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = pool
end

local poolTitle = Instance.new("TextLabel")
poolTitle.Size = UDim2.new(1, -12, 0, 24)
poolTitle.Position = UDim2.fromOffset(8, 4)
poolTitle.BackgroundTransparency = 1
poolTitle.Font = Enum.Font.GothamBold
poolTitle.TextSize = 14
poolTitle.TextColor3 = Color3.fromRGB(230, 230, 235)
poolTitle.TextXAlignment = Enum.TextXAlignment.Left
poolTitle.Text = "Actives — hold & drop on hotbar (H)"
poolTitle.Parent = pool

local poolScroll = Instance.new("ScrollingFrame")
poolScroll.Size = UDim2.new(1, -12, 1, -36)
poolScroll.Position = UDim2.fromOffset(6, 30)
poolScroll.BackgroundTransparency = 1
poolScroll.BorderSizePixel = 0
poolScroll.ScrollBarThickness = 4
poolScroll.CanvasSize = UDim2.fromOffset(0, 0)
poolScroll.Parent = pool

local poolList = Instance.new("UIListLayout")
poolList.Padding = UDim.new(0, 4)
poolList.Parent = poolScroll

-- Hotbar bar
local bar = Instance.new("Frame")
bar.Name = "Hotbar"
bar.Size = UDim2.fromOffset(6 * 56 + 20, 64)
bar.Position = UDim2.new(0.5, -(6 * 56 + 20) / 2, 1, -84)
bar.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
bar.BorderSizePixel = 0
bar.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = bar
end

local slotButtons: { [number]: TextButton } = {}
local abilityNameById: { [string]: string } = {}

for i = 1, HotbarConfig.SlotCount do
	local btn = Instance.new("TextButton")
	btn.Name = "Slot" .. i
	btn.Size = UDim2.fromOffset(52, 52)
	btn.Position = UDim2.fromOffset(10 + (i - 1) * 56, 6)
	btn.BackgroundColor3 = Color3.fromRGB(32, 36, 42)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextColor3 = Color3.fromRGB(200, 200, 210)
	btn.Text = HotbarConfig.Labels[i]
	btn.Parent = bar
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	slotButtons[i] = btn

	btn.MouseButton1Click:Connect(function()
		-- Boş bırak / temizle (sürükleme InputEnded ile bind eder)
		if snapshot.hotbar[i] and not draggingId then
			UnbindHotbar:FireServer(i)
		end
	end)
end

local function refreshPool()
	for _, child in poolScroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	abilityNameById = {}
	for i, a in snapshot.actives do
		abilityNameById[a.abilityId] = a.name
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 44)
		btn.BackgroundColor3 = Color3.fromRGB(32, 36, 42)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		btn.TextColor3 = Color3.fromRGB(220, 220, 225)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = i
		btn.Text = string.format("  %s\n  %s", a.name, a.desc)
		btn.Parent = poolScroll
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		btn.MouseButton1Down:Connect(function()
			draggingId = a.abilityId
			if dragGhost then
				dragGhost:Destroy()
			end
			local g = Instance.new("TextLabel")
			g.Size = UDim2.fromOffset(120, 28)
			g.BackgroundColor3 = Color3.fromRGB(48, 72, 96)
			g.BackgroundTransparency = 0.2
			g.Font = Enum.Font.GothamBold
			g.TextSize = 12
			g.TextColor3 = Color3.fromRGB(255, 255, 255)
			g.Text = a.name
			g.ZIndex = 20
			g.Parent = gui
			local gc = Instance.new("UICorner")
			gc.CornerRadius = UDim.new(0, 6)
			gc.Parent = g
			dragGhost = g
		end)
	end
	poolScroll.CanvasSize = UDim2.fromOffset(0, poolList.AbsoluteContentSize.Y + 8)
end

local function refreshHotbar()
	for i = 1, HotbarConfig.SlotCount do
		local id = snapshot.hotbar[i]
		local key = HotbarConfig.Labels[i]
		if id then
			local name = abilityNameById[id] or id
			slotButtons[i].Text = key .. "\n" .. string.sub(name, 1, 8)
			slotButtons[i].BackgroundColor3 = Color3.fromRGB(40, 52, 44)
		else
			slotButtons[i].Text = key
			slotButtons[i].BackgroundColor3 = Color3.fromRGB(32, 36, 42)
		end
	end
end

local function apply(data: any)
	if typeof(data) ~= "table" then
		return
	end
	snapshot.hotbar = data.hotbar or {}
	snapshot.actives = data.actives or {}
	refreshPool()
	refreshHotbar()
end

InventoryUpdated.OnClientEvent:Connect(apply)

task.spawn(function()
	local ok, data = pcall(function()
		return GetSnapshot:InvokeServer()
	end)
	if ok then
		apply(data)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragGhost and input.UserInputType == Enum.UserInputType.MouseMovement then
		local inset = GuiService:GetGuiInset()
		local p = UserInputService:GetMouseLocation() - inset
		dragGhost.Position = UDim2.fromOffset(p.X + 12, p.Y + 12)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if not draggingId then
		return
	end
	local id = draggingId
	draggingId = nil
	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end

	local inset = GuiService:GetGuiInset()
	local mouse = UserInputService:GetMouseLocation() - inset
	for i, btn in slotButtons do
		local pos = btn.AbsolutePosition
		local size = btn.AbsoluteSize
		if mouse.X >= pos.X and mouse.X <= pos.X + size.X and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y then
			BindAbility:FireServer(id, i)
			return
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.H then
		poolOpen = not poolOpen
		pool.Visible = poolOpen
	end
end)

print("[HotbarUI] Q E R 1 2 3 · H = ability pool")
