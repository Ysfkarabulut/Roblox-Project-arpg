--[[
	3-panel gear UI: Stats | Loadout | Inventory
	I / L toggle · Esc close
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutSlots = require(ReplicatedStorage.Shared.Config.LoadoutSlots)
local HotbarConfig = require(ReplicatedStorage.Shared.Config.HotbarConfig)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)
local ItemIcon = require(script.Parent.ItemIcon)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local GetSnapshot = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local EquipItem = remotes:WaitForChild("EquipItem") :: RemoteEvent
local UnequipSlot = remotes:WaitForChild("UnequipSlot") :: RemoteEvent
local BindAbility = remotes:WaitForChild("BindAbility") :: RemoteEvent
local UnbindHotbar = remotes:WaitForChild("UnbindHotbar") :: RemoteEvent
local DiscardItem = remotes:WaitForChild("DiscardItem") :: RemoteEvent
local InventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent

type ActiveInfo = { abilityId: string, name: string, desc: string, sourceUuid: string, defId: string }

local snapshot = {
	items = {} :: { { uuid: string, defId: string } },
	loadout = {} :: { [string]: string? },
	hotbar = {} :: { [number]: string? },
	actives = {} :: { ActiveInfo },
	stats = { level = 1, STR = 10, DEX = 10, VIT = 10, INT = 10 },
	derived = { hp = 0, stamina = 0, defenceFromVit = 0, resistFromVit = 0 },
}

local selectedUuid: string? = nil
local selectedAbility: string? = nil
local open = false

local COL_BG = Color3.fromRGB(18, 20, 24)
local COL_PANEL = Color3.fromRGB(28, 30, 36)
local COL_SLOT = Color3.fromRGB(42, 44, 52)
local COL_SLOT_EQ = Color3.fromRGB(48, 66, 54)
local COL_SLOT_SEL = Color3.fromRGB(52, 72, 96)
local COL_STROKE = Color3.fromRGB(70, 74, 84)
local COL_TEXT = Color3.fromRGB(235, 236, 240)
local COL_MUTED = Color3.fromRGB(140, 146, 158)

local PRIMARY_COLORS = {
	STR = Color3.fromRGB(230, 90, 90),
	DEX = Color3.fromRGB(90, 200, 120),
	VIT = Color3.fromRGB(90, 170, 255),
	INT = Color3.fromRGB(200, 130, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "GearUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(parent: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3?, t: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or COL_STROKE
	s.Thickness = t or 1
	s.Parent = parent
end

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function shortName(name: string, maxLen: number): string
	if #name <= maxLen then
		return name
	end
	return string.sub(name, 1, maxLen - 1) .. "…"
end

local function isEquipped(uuid: string): boolean
	for _, slot in LoadoutSlots.Order do
		if snapshot.loadout[slot] == uuid then
			return true
		end
	end
	return false
end

local function suggestSlot(defId: string): string?
	local def = ItemDefs.Get(defId)
	if not def then
		return nil
	end
	local hints = (def :: any).slotHints
	if typeof(hints) == "table" and hints[1] then
		return hints[1]
	end
	local kind = def.kind
	if kind == "ArmorHead" then
		return "head"
	elseif kind == "ArmorChest" then
		return "chest"
	elseif kind == "ArmorHands" then
		return "hands"
	elseif kind == "ArmorFeets" or kind == "ArmorFeet" then
		return "feets"
	elseif kind == "Shield" or kind == "Focus" or kind == "Knot" or kind == "Quiver" then
		return "off"
	end
	return "main"
end

local function secondaryFromStats()
	local s = snapshot.stats
	local d = snapshot.derived
	local str, dex, vit, int_ = s.STR or 10, s.DEX or 10, s.VIT or 10, s.INT or 10
	local critChance = math.min(CombatConfig.BaseCrit + dex * CombatConfig.KDexCrit, CombatConfig.CritChanceCap)
	local critDmg = math.min(CombatConfig.BaseCritDmg + str * CombatConfig.KStrCritDmg, CombatConfig.CritDmgCap)
	local asMult = math.min(1 + dex * CombatConfig.KDexAs, CombatConfig.AsCap)
	local defence = d.defenceFromVit or (vit * CombatConfig.KVitDef)
	local resist = d.resistFromVit or (vit * CombatConfig.KVitRes)
	local dr = math.min(defence * CombatConfig.KDr, CombatConfig.DrCapPvp)
	local statusPot = int_ * 0.5 -- display proxy until full gear sum
	local buffPot = int_ * 0.25
	return {
		{ "HP", string.format("%d", math.floor(d.hp or 0)), Color3.fromRGB(100, 220, 130) },
		{ "Stamina", string.format("%d", math.floor(d.stamina or 0)), Color3.fromRGB(240, 210, 80) },
		{ "Defence", string.format("%.0f  (DR %.0f%%)", defence, dr), Color3.fromRGB(120, 190, 255) },
		{ "Resist", string.format("%.0f", resist), Color3.fromRGB(150, 200, 255) },
		{ "Crit Chance", string.format("%.1f%%", critChance), Color3.fromRGB(255, 180, 100) },
		{ "Crit Damage", string.format("%.0f%%", critDmg), Color3.fromRGB(255, 120, 100) },
		{ "Attack Speed", string.format("%.0f%%", asMult * 100), Color3.fromRGB(180, 255, 180) },
		{ "Status Potency", string.format("+%.0f", statusPot), Color3.fromRGB(200, 150, 255) },
		{ "Buff Potency", string.format("+%.0f", buffPot), Color3.fromRGB(180, 160, 255) },
	}
end

-- Overlay
local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
root.BackgroundTransparency = 0.5
root.Visible = false
root.Parent = gui

local shell = Instance.new("Frame")
shell.Name = "Shell"
shell.Size = UDim2.new(0.94, 0, 0.84, 0)
shell.Position = UDim2.new(0.03, 0, 0.07, 0)
shell.BackgroundTransparency = 1
shell.Parent = root

local function makePanel(name: string, size: UDim2, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = COL_PANEL
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	f.Parent = shell
	corner(f, 10)
	stroke(f)
	return f
end

local function makeHeader(parent: Frame, text: string, withClose: boolean?): (TextLabel, TextButton?)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 36)
	bar.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
	bar.BackgroundTransparency = 0.2
	bar.BorderSizePixel = 0
	bar.Parent = parent
	corner(bar, 10)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, if withClose then -44 else -16, 1, 0)
	t.Position = UDim2.fromOffset(12, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = COL_TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.Parent = bar

	local closeBtn: TextButton? = nil
	if withClose then
		local x = Instance.new("TextButton")
		x.Size = UDim2.fromOffset(28, 28)
		x.Position = UDim2.new(1, -32, 0.5, -14)
		x.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
		x.BorderSizePixel = 0
		x.Font = Enum.Font.GothamBold
		x.TextSize = 14
		x.TextColor3 = COL_TEXT
		x.Text = "X"
		x.Parent = bar
		corner(x, 6)
		closeBtn = x
	end
	return t, closeBtn
end

-- ========== LEFT: STATS ==========
local statsPanel = makePanel("Stats", UDim2.new(0.22, -8, 1, 0), UDim2.new(0, 0, 0, 0))
makeHeader(statsPanel, "STATS")

local statsBody = Instance.new("ScrollingFrame")
statsBody.Size = UDim2.new(1, -16, 1, -48)
statsBody.Position = UDim2.fromOffset(8, 42)
statsBody.BackgroundTransparency = 1
statsBody.BorderSizePixel = 0
statsBody.ScrollBarThickness = 3
statsBody.CanvasSize = UDim2.fromOffset(0, 0)
statsBody.Parent = statsPanel

local statsList = Instance.new("UIListLayout")
statsList.Padding = UDim.new(0, 4)
statsList.SortOrder = Enum.SortOrder.LayoutOrder
statsList.Parent = statsBody

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, 0, 0, 22)
levelLabel.BackgroundTransparency = 1
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 13
levelLabel.TextColor3 = COL_MUTED
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.LayoutOrder = 0
levelLabel.Text = "Level —"
levelLabel.Parent = statsBody

local primaryHeader = Instance.new("TextLabel")
primaryHeader.Size = UDim2.new(1, 0, 0, 18)
primaryHeader.BackgroundTransparency = 1
primaryHeader.Font = Enum.Font.GothamBold
primaryHeader.TextSize = 11
primaryHeader.TextColor3 = COL_MUTED
primaryHeader.TextXAlignment = Enum.TextXAlignment.Left
primaryHeader.LayoutOrder = 1
primaryHeader.Text = "PRIMARY"
primaryHeader.Parent = statsBody

local primaryLabels: { [string]: TextLabel } = {}
for i, key in { "STR", "DEX", "VIT", "INT" } do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundColor3 = COL_SLOT
	row.BorderSizePixel = 0
	row.Font = Enum.Font.GothamBold
	row.TextSize = 15
	row.TextColor3 = PRIMARY_COLORS[key]
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.LayoutOrder = 1 + i
	row.Text = `  {key}  —`
	row.Parent = statsBody
	corner(row, 6)
	primaryLabels[key] = row
end

local secHeader = Instance.new("TextLabel")
secHeader.Size = UDim2.new(1, 0, 0, 18)
secHeader.BackgroundTransparency = 1
secHeader.Font = Enum.Font.GothamBold
secHeader.TextSize = 11
secHeader.TextColor3 = COL_MUTED
secHeader.TextXAlignment = Enum.TextXAlignment.Left
secHeader.LayoutOrder = 20
secHeader.Text = "SECONDARY"
secHeader.Parent = statsBody

local secondaryLabels: { TextLabel } = {}
for i = 1, 9 do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.Gotham
	row.TextSize = 12
	row.TextColor3 = COL_TEXT
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.LayoutOrder = 20 + i
	row.Text = ""
	row.Parent = statsBody
	secondaryLabels[i] = row
end

-- ========== MIDDLE: LOADOUT ==========
local loadPanel = makePanel("Loadout", UDim2.new(0.40, -8, 1, 0), UDim2.new(0.22, 4, 0, 0))
local _, loadCloseBtn = makeHeader(loadPanel, "LOADOUT", true)

local dollArea = Instance.new("Frame")
dollArea.Size = UDim2.new(1, -20, 1, -170)
dollArea.Position = UDim2.fromOffset(10, 44)
dollArea.BackgroundTransparency = 1
dollArea.Parent = loadPanel

local SLOT = 58
local gearButtons: { [string]: TextButton } = {}
local gearLabels: { [string]: TextLabel } = {}

local function makeGearSlot(slotId: string, anchor: UDim2, caption: string)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(SLOT + 4, SLOT + 18)
	wrap.Position = anchor
	wrap.AnchorPoint = Vector2.new(0.5, 0.5)
	wrap.BackgroundTransparency = 1
	wrap.Parent = dollArea

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(SLOT, SLOT)
	btn.Position = UDim2.new(0.5, 0, 0, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = COL_SLOT
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.Parent = wrap
	corner(btn, 8)
	stroke(btn, Color3.fromRGB(100, 104, 114))

	local name = Instance.new("TextLabel")
	name.Name = "ItemName"
	name.Size = UDim2.new(1, -4, 0, 14)
	name.Position = UDim2.new(0, 2, 1, -16)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 8
	name.TextColor3 = COL_TEXT
	name.TextWrapped = true
	name.Text = ""
	name.ZIndex = 4
	name.Parent = btn

	local iconHost = Instance.new("Frame")
	iconHost.Name = "IconHost"
	iconHost.Size = UDim2.new(1, -6, 1, -18)
	iconHost.Position = UDim2.fromOffset(3, 3)
	iconHost.BackgroundTransparency = 1
	iconHost.ZIndex = 2
	iconHost.Parent = btn

	local cap = Instance.new("TextLabel")
	cap.Size = UDim2.new(1, 0, 0, 14)
	cap.Position = UDim2.new(0, 0, 1, -14)
	cap.BackgroundTransparency = 1
	cap.Font = Enum.Font.Gotham
	cap.TextSize = 10
	cap.TextColor3 = COL_MUTED
	cap.Text = caption
	cap.Parent = wrap

	gearButtons[slotId] = btn
	gearLabels[slotId] = name

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

makeGearSlot("head", UDim2.new(0.12, 0, 0.18, 0), "Head")
makeGearSlot("chest", UDim2.new(0.12, 0, 0.48, 0), "Chest")
makeGearSlot("feets", UDim2.new(0.12, 0, 0.78, 0), "Boots")
makeGearSlot("main", UDim2.new(0.88, 0, 0.18, 0), "Main")
makeGearSlot("off", UDim2.new(0.88, 0, 0.48, 0), "Off")
makeGearSlot("hands", UDim2.new(0.88, 0, 0.78, 0), "Hands")

local vp = Instance.new("ViewportFrame")
vp.Size = UDim2.new(0.56, 0, 0.92, 0)
vp.Position = UDim2.new(0.5, 0, 0.5, 0)
vp.AnchorPoint = Vector2.new(0.5, 0.5)
vp.BackgroundColor3 = Color3.fromRGB(36, 38, 44)
vp.BorderSizePixel = 0
vp.Parent = dollArea
corner(vp, 8)
stroke(vp, Color3.fromRGB(55, 58, 66))

local worldModel = Instance.new("WorldModel")
worldModel.Parent = vp
local cam = Instance.new("Camera")
cam.Parent = vp
vp.CurrentCamera = cam

local previewChar: Model? = nil
local previewConn: RBXScriptConnection? = nil

local function clearPreview()
	if previewConn then
		previewConn:Disconnect()
		previewConn = nil
	end
	if previewChar then
		previewChar:Destroy()
		previewChar = nil
	end
end

local function refreshPreview()
	clearPreview()
	local char = player.Character
	if not char then
		return
	end
	local clone = char:Clone()
	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	clone.Parent = worldModel
	previewChar = clone
	local hrp = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local pivot = hrp.Position
	cam.CFrame = CFrame.new(pivot + Vector3.new(0, 1.2, -6.2), pivot + Vector3.new(0, 1.0, 0))
	previewConn = RunService.RenderStepped:Connect(function()
		local rootPart = previewChar and previewChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(0.35), 0)
		end
	end)
end

-- Skills
local skillsLabel = Instance.new("TextLabel")
skillsLabel.Size = UDim2.new(1, -20, 0, 16)
skillsLabel.Position = UDim2.new(0, 10, 1, -118)
skillsLabel.BackgroundTransparency = 1
skillsLabel.Font = Enum.Font.GothamBold
skillsLabel.TextSize = 11
skillsLabel.TextColor3 = COL_MUTED
skillsLabel.TextXAlignment = Enum.TextXAlignment.Left
skillsLabel.Text = "SKILLS  Q E R 1 2 3"
skillsLabel.Parent = loadPanel

local skillBar = Instance.new("Frame")
skillBar.Size = UDim2.new(1, -20, 0, 50)
skillBar.Position = UDim2.new(0, 10, 1, -98)
skillBar.BackgroundTransparency = 1
skillBar.Parent = loadPanel

local skillButtons: { [number]: TextButton } = {}
local skillLayout = Instance.new("UIListLayout")
skillLayout.FillDirection = Enum.FillDirection.Horizontal
skillLayout.Padding = UDim.new(0, 5)
skillLayout.Parent = skillBar

for i = 1, HotbarConfig.SlotCount do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(48, 48)
	btn.BackgroundColor3 = COL_SLOT
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.TextColor3 = COL_TEXT
	btn.Text = HotbarConfig.Labels[i]
	btn.LayoutOrder = i
	btn.Parent = skillBar
	corner(btn, 6)
	stroke(btn)
	skillButtons[i] = btn
	btn.MouseButton1Click:Connect(function()
		if selectedAbility then
			BindAbility:FireServer(selectedAbility, i)
			selectedAbility = nil
		elseif snapshot.hotbar[i] then
			UnbindHotbar:FireServer(i)
		end
	end)
end

local abilityStrip = Instance.new("ScrollingFrame")
abilityStrip.Size = UDim2.new(1, -20, 0, 26)
abilityStrip.Position = UDim2.new(0, 10, 1, -42)
abilityStrip.BackgroundTransparency = 1
abilityStrip.BorderSizePixel = 0
abilityStrip.ScrollBarThickness = 2
abilityStrip.ScrollingDirection = Enum.ScrollingDirection.X
abilityStrip.CanvasSize = UDim2.fromOffset(0, 0)
abilityStrip.Parent = loadPanel

local abilityLayout = Instance.new("UIListLayout")
abilityLayout.FillDirection = Enum.FillDirection.Horizontal
abilityLayout.Padding = UDim.new(0, 4)
abilityLayout.Parent = abilityStrip

-- ========== RIGHT: INVENTORY + DETAIL ==========
local invPanel = makePanel("Inventory", UDim2.new(0.38, -4, 1, 0), UDim2.new(0.62, 4, 0, 0))
makeHeader(invPanel, "INVENTORY")

local invGrid = Instance.new("ScrollingFrame")
invGrid.Size = UDim2.new(1, -20, 0.48, -8)
invGrid.Position = UDim2.fromOffset(10, 44)
invGrid.BackgroundColor3 = Color3.fromRGB(24, 26, 30)
invGrid.BorderSizePixel = 0
invGrid.ScrollBarThickness = 3
invGrid.CanvasSize = UDim2.fromOffset(0, 0)
invGrid.Parent = invPanel
corner(invGrid, 8)

local gridPad = Instance.new("UIPadding")
gridPad.PaddingTop = UDim.new(0, 6)
gridPad.PaddingLeft = UDim.new(0, 6)
gridPad.PaddingRight = UDim.new(0, 6)
gridPad.Parent = invGrid

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(64, 64)
gridLayout.CellPadding = UDim2.fromOffset(5, 5)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = invGrid

local detail = Instance.new("Frame")
detail.Name = "Detail"
detail.Size = UDim2.new(1, -20, 0.48, -16)
detail.Position = UDim2.new(0, 10, 0.52, 0)
detail.BackgroundColor3 = Color3.fromRGB(24, 26, 30)
detail.BorderSizePixel = 0
detail.Parent = invPanel
corner(detail, 8)
stroke(detail, Color3.fromRGB(55, 58, 66))

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, -100, 0, 28)
detailTitle.Position = UDim2.fromOffset(10, 8)
detailTitle.BackgroundTransparency = 1
detailTitle.Font = Enum.Font.GothamBold
detailTitle.TextSize = 16
detailTitle.TextColor3 = COL_TEXT
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.Text = "Select an item"
detailTitle.Parent = detail

local detailIconHost = Instance.new("Frame")
detailIconHost.Name = "DetailIconHost"
detailIconHost.Size = UDim2.fromOffset(88, 88)
detailIconHost.Position = UDim2.new(1, -98, 0, 10)
detailIconHost.BackgroundColor3 = COL_SLOT
detailIconHost.BorderSizePixel = 0
detailIconHost.Parent = detail
corner(detailIconHost, 8)
stroke(detailIconHost, Color3.fromRGB(70, 74, 82))

local detailDesc = Instance.new("TextLabel")
detailDesc.Size = UDim2.new(1, -120, 1, -120)
detailDesc.Position = UDim2.fromOffset(10, 40)
detailDesc.BackgroundTransparency = 1
detailDesc.Font = Enum.Font.Gotham
detailDesc.TextSize = 12
detailDesc.TextColor3 = COL_MUTED
detailDesc.TextXAlignment = Enum.TextXAlignment.Left
detailDesc.TextYAlignment = Enum.TextYAlignment.Top
detailDesc.TextWrapped = true
detailDesc.Text = "Click an inventory slot to inspect."
detailDesc.Parent = detail

local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(1, -20, 0, 32)
equipBtn.Position = UDim2.new(0, 10, 1, -78)
equipBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
equipBtn.BorderSizePixel = 0
equipBtn.Font = Enum.Font.GothamBold
equipBtn.TextSize = 14
equipBtn.TextColor3 = COL_TEXT
equipBtn.Text = "Equip"
equipBtn.AutoButtonColor = true
equipBtn.Parent = detail
corner(equipBtn, 6)

local discardBtn = Instance.new("TextButton")
discardBtn.Size = UDim2.new(1, -20, 0, 32)
discardBtn.Position = UDim2.new(0, 10, 1, -40)
discardBtn.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
discardBtn.BorderSizePixel = 0
discardBtn.Font = Enum.Font.GothamBold
discardBtn.TextSize = 14
discardBtn.TextColor3 = COL_TEXT
discardBtn.Text = "Discard"
discardBtn.AutoButtonColor = true
discardBtn.Parent = detail
corner(discardBtn, 6)

equipBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	local defId = nil
	for _, item in snapshot.items do
		if item.uuid == selectedUuid then
			defId = item.defId
			break
		end
	end
	local slot = if defId then suggestSlot(defId) else "main"
	if slot then
		EquipItem:FireServer(selectedUuid, slot)
	end
end)

discardBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	DiscardItem:FireServer(selectedUuid)
	selectedUuid = nil
end)

-- ========== REFRESH ==========
local refreshDetail: () -> ()
local refreshInventory: () -> ()
local refreshGear: () -> ()
local refreshSkills: () -> ()

local function abilityName(id: string?): string
	if not id then
		return ""
	end
	for _, a in snapshot.actives do
		if a.abilityId == id then
			return a.name
		end
	end
	return id
end

local function refreshStats()
	local s = snapshot.stats
	levelLabel.Text = `Level {s.level or 1}`
	for _, key in { "STR", "DEX", "VIT", "INT" } do
		local row = primaryLabels[key]
		if row then
			row.Text = `  {key}   {s[key] or 0}`
		end
	end
	local secs = secondaryFromStats()
	for i, row in secondaryLabels do
		local entry = secs[i]
		if entry then
			row.Text = `{entry[1]}:  {entry[2]}`
			row.TextColor3 = entry[3]
		else
			row.Text = ""
		end
	end
	statsBody.CanvasSize = UDim2.fromOffset(0, statsList.AbsoluteContentSize.Y + 12)
end

refreshGear = function()
	for _, slotId in LoadoutSlots.Order do
		local btn = gearButtons[slotId]
		local label = gearLabels[slotId]
		if btn and label then
			local uuid = snapshot.loadout[slotId]
			local iconHost = btn:FindFirstChild("IconHost")
			if uuid then
				local defId = nil
				for _, item in snapshot.items do
					if item.uuid == uuid then
						defId = item.defId
						break
					end
				end
				local def = defId and ItemDefs.Get(defId)
				label.Text = shortName(def and def.name or "?", 10)
				btn.BackgroundColor3 = COL_SLOT_EQ
				if iconHost and iconHost:IsA("GuiObject") and defId then
					ItemIcon.Mount(iconHost, defId, { zIndex = 2, yawDeg = 40, pitchDeg = -18 })
				end
			else
				label.Text = ""
				btn.BackgroundColor3 = if selectedUuid then COL_SLOT_SEL else COL_SLOT
				if iconHost and iconHost:IsA("GuiObject") then
					ItemIcon.Clear(iconHost)
				end
			end
		end
	end
end

refreshDetail = function()
	if not selectedUuid then
		detailTitle.Text = "Select an item"
		detailDesc.Text = "Click an inventory slot to inspect."
		ItemIcon.Clear(detailIconHost)
		return
	end
	local defId = nil
	for _, item in snapshot.items do
		if item.uuid == selectedUuid then
			defId = item.defId
			break
		end
	end
	local def = defId and ItemDefs.Get(defId)
	detailTitle.Text = def and def.name or (defId or "?")
	local lines = {}
	if def then
		table.insert(lines, def.kind or "")
		if def.element then
			table.insert(lines, "Element: " .. tostring(def.element))
		end
		if def.desc then
			table.insert(lines, "")
			table.insert(lines, def.desc)
		end
		if isEquipped(selectedUuid) then
			table.insert(lines, "")
			table.insert(lines, "[Equipped]")
		end
	end
	detailDesc.Text = table.concat(lines, "\n")
	if defId then
		ItemIcon.Mount(detailIconHost, defId, { zIndex = 2, yawDeg = 38, pitchDeg = -20, distanceMul = 1.7 })
	else
		ItemIcon.Clear(detailIconHost)
	end
end

refreshSkills = function()
	for i = 1, HotbarConfig.SlotCount do
		local btn = skillButtons[i]
		local id = snapshot.hotbar[i]
		local key = HotbarConfig.Labels[i]
		if id then
			btn.Text = key .. "\n" .. shortName(abilityName(id), 7)
			btn.BackgroundColor3 = COL_SLOT_EQ
		else
			btn.Text = key
			btn.BackgroundColor3 = if selectedAbility then COL_SLOT_SEL else COL_SLOT
		end
	end
	for _, child in abilityStrip:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local w = 0
	for i, a in snapshot.actives do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.fromOffset(100, 22)
		chip.BackgroundColor3 = if selectedAbility == a.abilityId then COL_SLOT_SEL else COL_SLOT
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.Gotham
		chip.TextSize = 10
		chip.TextColor3 = COL_TEXT
		chip.Text = shortName(a.name, 12)
		chip.LayoutOrder = i
		chip.Parent = abilityStrip
		corner(chip, 4)
		chip.MouseButton1Click:Connect(function()
			selectedAbility = if selectedAbility == a.abilityId then nil else a.abilityId
			selectedUuid = nil
			refreshSkills()
			refreshInventory()
			refreshGear()
			refreshDetail()
		end)
		w += 104
	end
	abilityStrip.CanvasSize = UDim2.fromOffset(w, 0)
end

refreshInventory = function()
	for _, child in invGrid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local count = math.max(#snapshot.items, 20)
	for i = 1, count do
		local item = snapshot.items[i]
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = COL_SLOT
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = item ~= nil
		btn.LayoutOrder = i
		btn.Parent = invGrid
		corner(btn, 6)
		stroke(btn, Color3.fromRGB(70, 74, 82))
		if item then
			local def = ItemDefs.Get(item.defId)
			local name = def and def.name or item.defId
			local equipped = isEquipped(item.uuid)
			local selected = selectedUuid == item.uuid
			btn.BackgroundColor3 = if selected
				then COL_SLOT_SEL
				elseif equipped then COL_SLOT_EQ
				else COL_SLOT

			local iconHost = Instance.new("Frame")
			iconHost.Name = "IconHost"
			iconHost.Size = UDim2.new(1, -4, 1, -16)
			iconHost.Position = UDim2.fromOffset(2, 2)
			iconHost.BackgroundTransparency = 1
			iconHost.ZIndex = 2
			iconHost.Parent = btn
			ItemIcon.Mount(iconHost, item.defId, { zIndex = 2, yawDeg = 36, pitchDeg = -18 })

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -4, 0, 12)
			label.Position = UDim2.new(0, 2, 1, -13)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextSize = 8
			label.TextColor3 = COL_TEXT
			label.Text = shortName(name, 10)
			label.ZIndex = 4
			label.Parent = btn

			btn.MouseButton1Click:Connect(function()
				selectedUuid = if selectedUuid == item.uuid then nil else item.uuid
				selectedAbility = nil
				refreshInventory()
				refreshGear()
				refreshSkills()
				refreshDetail()
			end)
		end
	end
	local rows = math.ceil(count / 4)
	invGrid.CanvasSize = UDim2.fromOffset(0, rows * 69 + 12)
	refreshDetail()
end

local function applySnapshot(data: any)
	if typeof(data) ~= "table" then
		return
	end
	snapshot.items = data.items or {}
	snapshot.loadout = data.loadout or {}
	snapshot.hotbar = data.hotbar or {}
	snapshot.actives = data.actives or {}
	if typeof(data.stats) == "table" then
		snapshot.stats = data.stats
	end
	if typeof(data.derived) == "table" then
		snapshot.derived = data.derived
	end
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
	refreshStats()
	refreshInventory()
	refreshGear()
	refreshSkills()
	if open then
		refreshPreview()
	end
end

local function setOpen(state: boolean)
	open = state
	root.Visible = open
	if open then
		refreshPreview()
		refreshStats()
		refreshInventory()
		refreshGear()
		refreshSkills()
	else
		clearPreview()
		selectedUuid = nil
		selectedAbility = nil
	end
end

if loadCloseBtn then
	loadCloseBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end)
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

player.CharacterAdded:Connect(function()
	if open then
		task.defer(refreshPreview)
	end
end)

UserInputService.InputBegan:Connect(function(input, _gp)
	if isTyping() then
		return
	end
	if input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.L then
		setOpen(not open)
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and open then
		setOpen(false)
	end
end)

local bar = Instance.new("Frame")
bar.Name = "GearToggleBar"
bar.Size = UDim2.fromOffset(200, 36)
bar.Position = UDim2.new(0.5, -100, 1, -160)
bar.BackgroundColor3 = COL_BG
bar.BorderSizePixel = 0
bar.ZIndex = 5
bar.Parent = gui
corner(bar, 8)
stroke(bar)

local function barBtn(text: string, x: number)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(90, 28)
	b.Position = UDim2.fromOffset(x, 4)
	b.BackgroundColor3 = COL_SLOT
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = COL_TEXT
	b.Text = text
	b.Parent = bar
	corner(b, 6)
	b.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)
end

barBtn("Inventory", 8)
barBtn("Loadout", 102)

print("[GearUI] Stats | Loadout | Inventory — I/L")
