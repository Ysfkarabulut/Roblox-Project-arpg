--[[
	Hotbar UI — Q E R 1 2 3
	Loadout açıkken alt listeden aktif sürükle (basılı tut → slot üzerinde bırak).
	Pasifler listelenmez.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HotbarConfig = require(ReplicatedStorage.Shared.Config.HotbarConfig)
local AbilityTooltip = require(ReplicatedStorage.Shared.UI.AbilityTooltip)
local HoverTooltip = require(script.Parent.Parent.UI.HoverTooltip)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 30)
if not remotes then
	warn("[HotbarUI] InventoryRemotes missing — Rojo sync / InventoryBootstrap failed")
	return
end
local GetSnapshot = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local BindAbility = remotes:WaitForChild("BindAbility") :: RemoteEvent
local UnbindHotbar = remotes:WaitForChild("UnbindHotbar") :: RemoteEvent
local InventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent

local combatRemotes = ReplicatedStorage:WaitForChild("CombatRemotes", 30)
if not combatRemotes then
	warn("[HotbarUI] CombatRemotes missing")
	return
end
local CombatNotify = combatRemotes:WaitForChild("CombatNotify") :: RemoteEvent

type ActiveInfo = { abilityId: string, name: string, desc: string, sourceUuid: string, defId: string }

local snapshot = {
	hotbar = {} :: { [number]: string? },
	actives = {} :: { ActiveInfo },
}

local cdUntil: { [string]: number } = {}
local cdDuration: { [string]: number } = {}
local draggingId: string? = nil
local dragGhost: TextLabel? = nil

local gui = UiTheme.ScreenGui({
	name = "HotbarUI",
	displayOrder = UiTheme.DisplayOrder.Hud,
	zIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
gui.Parent = playerGui

local pool = UiTheme.Panel({
	parent = gui,
	name = "AbilityPool",
	size = UDim2.fromOffset(320, 220),
	position = UDim2.new(0.5, -160, 1, -400),
	visible = false,
	bg = C.BgElevated,
	radius = UiTheme.Radius.Md,
})

local poolOpen = false

local poolTitle = UiTheme.Label({
	parent = pool,
	text = "Actives (H) — or bind in Equipment (I)",
	size = UDim2.new(1, -12, 0, 24),
	position = UDim2.fromOffset(8, 4),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Title,
	color = C.Text,
})

local poolScroll = UiTheme.ScrollFrame({
	parent = pool,
	size = UDim2.new(1, -12, 1, -36),
	position = UDim2.fromOffset(6, 30),
})

local poolList = Instance.new("UIListLayout")
poolList.Padding = UDim.new(0, 4)
poolList.Parent = poolScroll

-- Hotbar bar
local bar = UiTheme.Panel({
	parent = gui,
	name = "Hotbar",
	size = UDim2.fromOffset(6 * 56 + 20, 64),
	position = UDim2.new(0.5, -(6 * 56 + 20) / 2, 1, -84),
	bg = C.BgElevated,
	radius = UiTheme.Radius.Md,
})

local slotButtons: { [number]: TextButton } = {}
local slotCdFill: { [number]: Frame } = {}
local slotCdLabel: { [number]: TextLabel } = {}
local abilityNameById: { [string]: string } = {}
local abilityInfoById: { [string]: ActiveInfo } = {}

for i = 1, HotbarConfig.SlotCount do
	local btn = Instance.new("TextButton")
	btn.Name = "Slot" .. i
	btn.Size = UDim2.fromOffset(52, 52)
	btn.Position = UDim2.fromOffset(10 + (i - 1) * 56, 6)
	btn.BackgroundColor3 = C.SlotHover
	btn.BorderSizePixel = 0
	btn.Font = UiTheme.Font.Title
	btn.TextSize = UiTheme.TextSize.Caption
	btn.TextColor3 = C.TextDim
	btn.Text = HotbarConfig.Labels[i]
	btn.ClipsDescendants = true
	btn.Parent = bar
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	slotButtons[i] = btn

	local cdFill = Instance.new("Frame")
	cdFill.Name = "CdFill"
	cdFill.Size = UDim2.fromScale(1, 0)
	cdFill.Position = UDim2.fromScale(0, 1)
	cdFill.AnchorPoint = Vector2.new(0, 1)
	cdFill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cdFill.BackgroundTransparency = 0.45
	cdFill.BorderSizePixel = 0
	cdFill.ZIndex = 2
	cdFill.Visible = false
	cdFill.Parent = btn
	slotCdFill[i] = cdFill

	local cdLabel = Instance.new("TextLabel")
	cdLabel.Name = "CdLabel"
	cdLabel.Size = UDim2.fromScale(1, 1)
	cdLabel.BackgroundTransparency = 1
	cdLabel.Font = Enum.Font.GothamBold
	cdLabel.TextSize = 16
	cdLabel.TextColor3 = Color3.fromRGB(255, 230, 160)
	cdLabel.TextStrokeTransparency = 0.4
	cdLabel.Text = ""
	cdLabel.ZIndex = 3
	cdLabel.Visible = false
	cdLabel.Parent = btn
	slotCdLabel[i] = cdLabel

	btn.MouseButton2Click:Connect(function()
		if snapshot.hotbar[i] and not draggingId then
			UnbindHotbar:FireServer(i)
		end
	end)

	btn.MouseEnter:Connect(function()
		local slotId = snapshot.hotbar[i]
		if not slotId then
			return
		end
		local info = abilityInfoById[slotId]
		local title, body = AbilityTooltip.Build(slotId, info and { name = info.name, desc = info.desc } or nil)
		HoverTooltip.show(title, body, btn)
	end)
	btn.MouseLeave:Connect(function()
		HoverTooltip.hide()
	end)
end

local function refreshPool()
	for _, child in poolScroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	abilityNameById = {}
	abilityInfoById = {}
	for i, a in snapshot.actives do
		abilityNameById[a.abilityId] = a.name
		abilityInfoById[a.abilityId] = a
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 44)
		btn.BackgroundColor3 = C.SlotHover
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Font = UiTheme.Font.Body
		btn.TextSize = UiTheme.TextSize.Body
		btn.TextColor3 = C.Text
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = i
		btn.Text = string.format("  %s\n  %s", a.name, a.desc)
		btn.Parent = poolScroll
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		btn.MouseEnter:Connect(function()
			local title, body = AbilityTooltip.Build(a.abilityId, { name = a.name, desc = a.desc })
			HoverTooltip.show(title, body, btn)
		end)
		btn.MouseLeave:Connect(function()
			HoverTooltip.hide()
		end)

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

local function updateCooldowns()
	local now = os.clock()
	for i = 1, HotbarConfig.SlotCount do
		local id = snapshot.hotbar[i]
		local fill = slotCdFill[i]
		local label = slotCdLabel[i]
		if not id then
			fill.Visible = false
			label.Visible = false
		else
			local untilT = cdUntil[id] or 0
			local remain = untilT - now
			if remain <= 0 then
				fill.Visible = false
				label.Visible = false
			else
				local dur = math.max(cdDuration[id] or remain, 0.05)
				local frac = math.clamp(remain / dur, 0, 1)
				fill.Size = UDim2.fromScale(1, frac)
				fill.Visible = true
				label.Text = if remain >= 1 then string.format("%.0f", remain) else string.format("%.1f", remain)
				label.Visible = true
			end
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

CombatNotify.OnClientEvent:Connect(function(result: any)
	if typeof(result) ~= "table" or not result.ok then
		return
	end
	local abilityId = result.abilityId
	local cd = result.fx and result.fx.cooldownSec
	if typeof(abilityId) == "string" and typeof(cd) == "number" and cd > 0 then
		cdUntil[abilityId] = os.clock() + cd
		cdDuration[abilityId] = cd
	end
end)

RunService.RenderStepped:Connect(updateCooldowns)

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
