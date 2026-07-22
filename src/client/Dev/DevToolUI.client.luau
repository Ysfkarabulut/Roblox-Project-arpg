--[[
	Dev Tool UI — F8 toggle (Studio).
	Spawn items by search · edit STR/DEX/VIT/INT/level · dummy controls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DevRemotes")
local GrantItem = remotes:WaitForChild("GrantItem") :: RemoteEvent
local SetStats = remotes:WaitForChild("SetStats") :: RemoteEvent
local ResetStats = remotes:WaitForChild("ResetStats") :: RemoteEvent
local ResetDummy = remotes:WaitForChild("ResetDummy") :: RemoteEvent
local SetDummyMaxHp = remotes:WaitForChild("SetDummyMaxHp") :: RemoteEvent
local DevNotify = remotes:WaitForChild("DevNotify") :: RemoteEvent
local GetDevState = remotes:WaitForChild("GetDevState") :: RemoteFunction

local open = false
local filterText = ""
local statusText = "F8 Dev Tools"

local allDefs: { { id: string, name: string, kind: string, element: string } } = {}
for id, def in ItemDefs.All() do
	table.insert(allDefs, {
		id = id,
		name = def.name or id,
		kind = def.kind or "?",
		element = tostring(def.element or "—"),
	})
end
table.sort(allDefs, function(a, b)
	return a.name:lower() < b.name:lower()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "DevToolUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 50
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(460, 520)
panel.Position = UDim2.new(0.5, -230, 0.5, -260)
panel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 120, 90)
stroke.Thickness = 1.5
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.fromOffset(8, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(120, 220, 160)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Dev Tools  (F8)"
title.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -16, 0, 16)
status.Position = UDim2.fromOffset(8, 34)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(150, 155, 165)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = statusText
status.Parent = panel

local function setStatus(msg: string)
	status.Text = msg
end

-- Stats section
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, -16, 0, 120)
statsFrame.Position = UDim2.fromOffset(8, 56)
statsFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
statsFrame.BorderSizePixel = 0
statsFrame.Parent = panel
local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 6)
sc.Parent = statsFrame

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(1, -12, 0, 20)
statsTitle.Position = UDim2.fromOffset(8, 4)
statsTitle.BackgroundTransparency = 1
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 12
statsTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Text = "Primary stats"
statsTitle.Parent = statsFrame

local derivedLabel = Instance.new("TextLabel")
derivedLabel.Size = UDim2.new(1, -12, 0, 16)
derivedLabel.Position = UDim2.fromOffset(8, 22)
derivedLabel.BackgroundTransparency = 1
derivedLabel.Font = Enum.Font.Gotham
derivedLabel.TextSize = 10
derivedLabel.TextColor3 = Color3.fromRGB(130, 140, 150)
derivedLabel.TextXAlignment = Enum.TextXAlignment.Left
derivedLabel.Text = "HP — · Stam —"
derivedLabel.Parent = statsFrame

local statBoxes: { [string]: TextBox } = {}
local statKeys = { "level", "STR", "DEX", "VIT", "INT" }

for i, key in statKeys do
	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(70, 28)
	box.Position = UDim2.fromOffset(8 + (i - 1) * 78, 44)
	box.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.TextSize = 13
	box.TextColor3 = Color3.fromRGB(235, 235, 240)
	box.PlaceholderText = key
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Parent = statsFrame
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = box
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(70, 12)
	label.Position = UDim2.fromOffset(8 + (i - 1) * 78, 74)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 9
	label.TextColor3 = Color3.fromRGB(120, 130, 140)
	label.Text = key
	label.Parent = statsFrame
	statBoxes[key] = box
end

local applyStats = Instance.new("TextButton")
applyStats.Size = UDim2.fromOffset(90, 26)
applyStats.Position = UDim2.fromOffset(8, 90)
applyStats.BackgroundColor3 = Color3.fromRGB(50, 110, 70)
applyStats.BorderSizePixel = 0
applyStats.Font = Enum.Font.GothamBold
applyStats.TextSize = 12
applyStats.TextColor3 = Color3.fromRGB(240, 250, 240)
applyStats.Text = "Apply"
applyStats.Parent = statsFrame
local ac = Instance.new("UICorner")
ac.CornerRadius = UDim.new(0, 4)
ac.Parent = applyStats

local resetStatsBtn = Instance.new("TextButton")
resetStatsBtn.Size = UDim2.fromOffset(100, 26)
resetStatsBtn.Position = UDim2.fromOffset(106, 90)
resetStatsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
resetStatsBtn.BorderSizePixel = 0
resetStatsBtn.Font = Enum.Font.Gotham
resetStatsBtn.TextSize = 12
resetStatsBtn.TextColor3 = Color3.fromRGB(230, 230, 235)
resetStatsBtn.Text = "Reset Lv30"
resetStatsBtn.Parent = statsFrame
local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(0, 4)
rc.Parent = resetStatsBtn

applyStats.MouseButton1Click:Connect(function()
	local patch = {}
	for _, key in statKeys do
		local n = tonumber(statBoxes[key].Text)
		if n then
			patch[key] = n
		end
	end
	SetStats:FireServer(patch)
end)

resetStatsBtn.MouseButton1Click:Connect(function()
	ResetStats:FireServer(30)
end)

-- Dummy row
local dummyFrame = Instance.new("Frame")
dummyFrame.Size = UDim2.new(1, -16, 0, 40)
dummyFrame.Position = UDim2.fromOffset(8, 184)
dummyFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
dummyFrame.BorderSizePixel = 0
dummyFrame.Parent = panel
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(0, 6)
dc.Parent = dummyFrame

local resetDummyBtn = Instance.new("TextButton")
resetDummyBtn.Size = UDim2.fromOffset(110, 28)
resetDummyBtn.Position = UDim2.fromOffset(8, 6)
resetDummyBtn.BackgroundColor3 = Color3.fromRGB(110, 70, 50)
resetDummyBtn.BorderSizePixel = 0
resetDummyBtn.Font = Enum.Font.GothamBold
resetDummyBtn.TextSize = 12
resetDummyBtn.TextColor3 = Color3.fromRGB(255, 240, 230)
resetDummyBtn.Text = "Reset Dummy"
resetDummyBtn.Parent = dummyFrame
local rdc = Instance.new("UICorner")
rdc.CornerRadius = UDim.new(0, 4)
rdc.Parent = resetDummyBtn

local hpBox = Instance.new("TextBox")
hpBox.Size = UDim2.fromOffset(80, 28)
hpBox.Position = UDim2.fromOffset(128, 6)
hpBox.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
hpBox.BorderSizePixel = 0
hpBox.Font = Enum.Font.Gotham
hpBox.TextSize = 13
hpBox.TextColor3 = Color3.fromRGB(235, 235, 240)
hpBox.PlaceholderText = "MaxHP"
hpBox.Text = "720"
hpBox.ClearTextOnFocus = false
hpBox.Parent = dummyFrame
local hpc = Instance.new("UICorner")
hpc.CornerRadius = UDim.new(0, 4)
hpc.Parent = hpBox

local setHpBtn = Instance.new("TextButton")
setHpBtn.Size = UDim2.fromOffset(90, 28)
setHpBtn.Position = UDim2.fromOffset(216, 6)
setHpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
setHpBtn.BorderSizePixel = 0
setHpBtn.Font = Enum.Font.Gotham
setHpBtn.TextSize = 12
setHpBtn.TextColor3 = Color3.fromRGB(230, 230, 235)
setHpBtn.Text = "Set MaxHP"
setHpBtn.Parent = dummyFrame
local shc = Instance.new("UICorner")
shc.CornerRadius = UDim.new(0, 4)
shc.Parent = setHpBtn

local autoHotbarBtn = Instance.new("TextButton")
autoHotbarBtn.Size = UDim2.fromOffset(90, 28)
autoHotbarBtn.Position = UDim2.fromOffset(314, 6)
autoHotbarBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 110)
autoHotbarBtn.BorderSizePixel = 0
autoHotbarBtn.Font = Enum.Font.GothamBold
autoHotbarBtn.TextSize = 11
autoHotbarBtn.TextColor3 = Color3.fromRGB(230, 240, 255)
autoHotbarBtn.Text = "Fill Hotbar"
autoHotbarBtn.Parent = dummyFrame
local ahc = Instance.new("UICorner")
ahc.CornerRadius = UDim.new(0, 4)
ahc.Parent = autoHotbarBtn

resetDummyBtn.MouseButton1Click:Connect(function()
	ResetDummy:FireServer()
end)
setHpBtn.MouseButton1Click:Connect(function()
	local n = tonumber(hpBox.Text)
	if n then
		SetDummyMaxHp:FireServer(n)
	end
end)

local AutoFillHotbar = remotes:WaitForChild("AutoFillHotbar") :: RemoteEvent
autoHotbarBtn.MouseButton1Click:Connect(function()
	AutoFillHotbar:FireServer()
end)

-- Item spawn
local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -80, 0, 30)
search.Position = UDim2.fromOffset(8, 232)
search.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
search.BorderSizePixel = 0
search.Font = Enum.Font.Gotham
search.TextSize = 13
search.TextColor3 = Color3.fromRGB(235, 235, 240)
search.PlaceholderText = "Search item name / id / element…"
search.Text = ""
search.ClearTextOnFocus = false
search.Parent = panel
local sec = Instance.new("UICorner")
sec.CornerRadius = UDim.new(0, 4)
sec.Parent = search

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.fromOffset(48, 30)
countBox.Position = UDim2.new(1, -64, 0, 232)
countBox.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
countBox.BorderSizePixel = 0
countBox.Font = Enum.Font.Gotham
countBox.TextSize = 13
countBox.TextColor3 = Color3.fromRGB(235, 235, 240)
countBox.PlaceholderText = "×"
countBox.Text = "1"
countBox.ClearTextOnFocus = false
countBox.Parent = panel
local cbc = Instance.new("UICorner")
cbc.CornerRadius = UDim.new(0, 4)
cbc.Parent = countBox

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -278)
scroll.Position = UDim2.fromOffset(8, 270)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 3)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local function clearRows()
	for _, child in scroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function refreshList()
	clearRows()
	local q = filterText:lower()
	local n = 0
	for _, def in allDefs do
		local hay = (`{def.name} {def.id} {def.kind} {def.element}`):lower()
		if q == "" or string.find(hay, q, 1, true) then
			n += 1
			if n > 80 then
				break
			end
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -4, 0, 36)
			btn.BackgroundColor3 = Color3.fromRGB(36, 40, 48)
			btn.BorderSizePixel = 0
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 12
			btn.TextColor3 = Color3.fromRGB(230, 230, 235)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Text = `  {def.name}  ·  {def.element}  ·  {def.kind}`
			btn.Parent = scroll
			local bc2 = Instance.new("UICorner")
			bc2.CornerRadius = UDim.new(0, 4)
			bc2.Parent = btn
			local id = def.id
			btn.MouseButton1Click:Connect(function()
				local count = tonumber(countBox.Text) or 1
				GrantItem:FireServer(id, count)
			end)
		end
	end
	scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 8)
end

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 8)
end)

search:GetPropertyChangedSignal("Text"):Connect(function()
	filterText = search.Text
	refreshList()
end)

local function applyState(state: any)
	if typeof(state) ~= "table" then
		return
	end
	if typeof(state.stats) == "table" then
		for _, key in statKeys do
			local v = state.stats[key]
			if typeof(v) == "number" and statBoxes[key] then
				statBoxes[key].Text = tostring(math.floor(v))
			end
		end
	end
	if typeof(state.derived) == "table" then
		derivedLabel.Text = `HP {math.floor(state.derived.hp or 0)} · Stam {math.floor(state.derived.stamina or 0)} · Def+VIT {string.format("%.1f", state.derived.defenceFromVit or 0)}`
	end
	if typeof(state.dummy) == "table" and typeof(state.dummy.maxHp) == "number" then
		hpBox.Text = tostring(math.floor(state.dummy.maxHp))
	end
end

local function pullState()
	local ok, state = pcall(function()
		return GetDevState:InvokeServer()
	end)
	if ok and state then
		applyState(state)
	end
end

local function toggle()
	open = not open
	panel.Visible = open
	if open then
		pullState()
		refreshList()
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F8 then
		toggle()
	end
end)

DevNotify.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	setStatus(tostring(payload.msg or ""))
	if payload.stats then
		applyState({ stats = payload.stats })
		pullState()
	end
end)

-- Hint chip
local chip = Instance.new("TextLabel")
chip.Size = UDim2.fromOffset(160, 22)
chip.Position = UDim2.new(1, -172, 0, 8)
chip.BackgroundColor3 = Color3.fromRGB(28, 36, 32)
chip.BorderSizePixel = 0
chip.Font = Enum.Font.Gotham
chip.TextSize = 11
chip.TextColor3 = Color3.fromRGB(140, 200, 160)
chip.Text = "F8 Dev · Ctrl sprint · F4 shiftlock"
chip.Parent = gui
local chc = Instance.new("UICorner")
chc.CornerRadius = UDim.new(0, 4)
chc.Parent = chip

refreshList()
task.defer(pullState)

print("[DevToolUI] F8 to open")
