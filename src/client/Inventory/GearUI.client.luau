--[[
	Inventory + Loadout UI (lobby).
	I = Inventory · L = Loadout · tıkla: envanterden slot seç / slot'tan çıkar.
	Her item uuid ile listelenir — aynı defId birden fazla satır olabilir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutSlots = require(ReplicatedStorage.Shared.Config.LoadoutSlots)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local GetSnapshot = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local EquipItem = remotes:WaitForChild("EquipItem") :: RemoteEvent
local UnequipSlot = remotes:WaitForChild("UnequipSlot") :: RemoteEvent
local InventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent

local snapshot = {
	items = {} :: { { uuid: string, defId: string } },
	loadout = {} :: { [string]: string? },
}

local selectedUuid: string? = nil
local invOpen = false
local loadOpen = false

local gui = Instance.new("ScreenGui")
gui.Name = "GearUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function stylePanel(frame: Frame)
	frame.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(55, 60, 70)
	stroke.Thickness = 1
	stroke.Parent = frame
end

local function makeTitle(parent: Instance, text: string): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -16, 0, 28)
	t.Position = UDim2.fromOffset(8, 6)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = Color3.fromRGB(230, 230, 235)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.Parent = parent
	return t
end

-- Inventory panel
local invPanel = Instance.new("Frame")
invPanel.Name = "Inventory"
invPanel.Size = UDim2.fromOffset(340, 420)
invPanel.Position = UDim2.new(0, 24, 0.5, -210)
invPanel.Visible = false
invPanel.Parent = gui
stylePanel(invPanel)
makeTitle(invPanel, "Inventory  (I)")

local invHint = Instance.new("TextLabel")
invHint.Size = UDim2.new(1, -16, 0, 18)
invHint.Position = UDim2.fromOffset(8, 32)
invHint.BackgroundTransparency = 1
invHint.Font = Enum.Font.Gotham
invHint.TextSize = 11
invHint.TextColor3 = Color3.fromRGB(140, 145, 155)
invHint.TextXAlignment = Enum.TextXAlignment.Left
invHint.Text = "Select item → click a loadout slot"
invHint.Parent = invPanel

local invScroll = Instance.new("ScrollingFrame")
invScroll.Size = UDim2.new(1, -16, 1, -60)
invScroll.Position = UDim2.fromOffset(8, 52)
invScroll.BackgroundTransparency = 1
invScroll.BorderSizePixel = 0
invScroll.ScrollBarThickness = 4
invScroll.CanvasSize = UDim2.fromOffset(0, 0)
invScroll.Parent = invPanel

local invList = Instance.new("UIListLayout")
invList.Padding = UDim.new(0, 4)
invList.SortOrder = Enum.SortOrder.LayoutOrder
invList.Parent = invScroll

-- Loadout panel
local loadPanel = Instance.new("Frame")
loadPanel.Name = "Loadout"
loadPanel.Size = UDim2.fromOffset(280, 360)
loadPanel.Position = UDim2.new(1, -304, 0.5, -180)
loadPanel.Visible = false
loadPanel.Parent = gui
stylePanel(loadPanel)
makeTitle(loadPanel, "Loadout  (L)")

local loadHint = Instance.new("TextLabel")
loadHint.Size = UDim2.new(1, -16, 0, 18)
loadHint.Position = UDim2.fromOffset(8, 32)
loadHint.BackgroundTransparency = 1
loadHint.Font = Enum.Font.Gotham
loadHint.TextSize = 11
loadHint.TextColor3 = Color3.fromRGB(140, 145, 155)
loadHint.TextXAlignment = Enum.TextXAlignment.Left
loadHint.Text = "Click slot: equip selected / unequip"
loadHint.Parent = loadPanel

local slotButtons: { [string]: TextButton } = {}
local slotY = 56
for i, slotId in LoadoutSlots.Order do
	local btn = Instance.new("TextButton")
	btn.Name = slotId
	btn.Size = UDim2.new(1, -16, 0, 44)
	btn.Position = UDim2.fromOffset(8, slotY)
	btn.BackgroundColor3 = Color3.fromRGB(32, 36, 42)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.TextColor3 = Color3.fromRGB(210, 210, 220)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Text = "  " .. (LoadoutSlots.Labels[slotId] or slotId)
	btn.Parent = loadPanel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	slotButtons[slotId] = btn
	slotY += 48

	btn.MouseButton1Click:Connect(function()
		if selectedUuid then
			EquipItem:FireServer(selectedUuid, slotId)
			selectedUuid = nil
		else
			local uuid = snapshot.loadout[slotId]
			if uuid then
				UnequipSlot:FireServer(slotId)
			end
		end
	end)
end

local function shortUuid(uuid: string): string
	return string.sub(uuid, 1, 8)
end

local function isEquipped(uuid: string): boolean
	for _, slot in LoadoutSlots.Order do
		if snapshot.loadout[slot] == uuid then
			return true
		end
	end
	return false
end

local function refreshLoadout()
	for _, slotId in LoadoutSlots.Order do
		local btn = slotButtons[slotId]
		local uuid = snapshot.loadout[slotId]
		local label = LoadoutSlots.Labels[slotId] or slotId
		if uuid then
			local inst = nil
			for _, item in snapshot.items do
				if item.uuid == uuid then
					inst = item
					break
				end
			end
			local def = inst and ItemDefs.Get(inst.defId)
			local name = def and def.name or "?"
			btn.Text = string.format("  %s\n  %s  #%s", label, name, shortUuid(uuid))
			btn.BackgroundColor3 = Color3.fromRGB(40, 52, 44)
		else
			local hint = if selectedUuid then " ← equip" else " (empty)"
			btn.Text = "  " .. label .. hint
			btn.BackgroundColor3 = if selectedUuid
				then Color3.fromRGB(48, 72, 96)
				else Color3.fromRGB(32, 36, 42)
		end
	end
end

local function refreshInventory()
	for _, child in invScroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i, item in snapshot.items do
		local def = ItemDefs.Get(item.defId)
		local name = def and def.name or item.defId
		local equipped = isEquipped(item.uuid)
		local selected = selectedUuid == item.uuid

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 40)
		btn.BackgroundColor3 = if selected
			then Color3.fromRGB(48, 72, 96)
			elseif equipped then Color3.fromRGB(40, 52, 44)
			else Color3.fromRGB(32, 36, 42)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		btn.TextColor3 = Color3.fromRGB(220, 220, 225)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = i
		local mark = if equipped then " [EQ]" else ""
		btn.Text = string.format("  %s%s\n  #%s", name, mark, shortUuid(item.uuid))
		btn.Parent = invScroll
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		btn.MouseButton1Click:Connect(function()
			if selectedUuid == item.uuid then
				selectedUuid = nil
			else
				selectedUuid = item.uuid
			end
			refreshInventory()
			refreshLoadout()
		end)
	end

	invScroll.CanvasSize = UDim2.fromOffset(0, invList.AbsoluteContentSize.Y + 8)
end

local function applySnapshot(data: any)
	if typeof(data) ~= "table" then
		return
	end
	snapshot.items = data.items or {}
	snapshot.loadout = data.loadout or {}
	-- selected item removed?
	if selectedUuid then
		local found = false
		for _, item in snapshot.items do
			if item.uuid == selectedUuid then
				found = true
				break
			end
		end
		if not found then
			selectedUuid = nil
		end
	end
	refreshInventory()
	refreshLoadout()
end

InventoryUpdated.OnClientEvent:Connect(applySnapshot)

task.spawn(function()
	local ok, data = pcall(function()
		return GetSnapshot:InvokeServer()
	end)
	if ok then
		applySnapshot(data)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		invOpen = not invOpen
		invPanel.Visible = invOpen
	elseif input.KeyCode == Enum.KeyCode.L then
		loadOpen = not loadOpen
		loadPanel.Visible = loadOpen
	elseif input.KeyCode == Enum.KeyCode.Escape then
		invOpen = false
		loadOpen = false
		invPanel.Visible = false
		loadPanel.Visible = false
		selectedUuid = nil
		refreshInventory()
		refreshLoadout()
	end
end)

-- Toggle bar
local bar = Instance.new("Frame")
bar.Size = UDim2.fromOffset(200, 36)
bar.Position = UDim2.new(0.5, -100, 1, -52)
bar.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
bar.BorderSizePixel = 0
bar.Parent = gui
stylePanel(bar)

local function barBtn(text: string, x: number, fn: () -> ())
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(90, 28)
	b.Position = UDim2.fromOffset(x, 4)
	b.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.fromRGB(230, 230, 235)
	b.Text = text
	b.Parent = bar
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	b.MouseButton1Click:Connect(fn)
end

barBtn("Inventory", 8, function()
	invOpen = not invOpen
	invPanel.Visible = invOpen
end)
barBtn("Loadout", 102, function()
	loadOpen = not loadOpen
	loadPanel.Visible = loadOpen
end)

print("[GearUI] I=Inventory L=Loadout — UUID instances")
