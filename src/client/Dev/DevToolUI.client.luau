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

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("DevRemotes", 10)
if not remotes then
	warn("[DevToolUI] DevRemotes missing (lobby only)")
	return
end
local GrantItem = remotes:WaitForChild("GrantItem") :: RemoteEvent
local SetStats = remotes:WaitForChild("SetStats") :: RemoteEvent
local ResetStats = remotes:WaitForChild("ResetStats") :: RemoteEvent
local ResetDummy = remotes:WaitForChild("ResetDummy") :: RemoteEvent
local SetDummyMaxHp = remotes:WaitForChild("SetDummyMaxHp") :: RemoteEvent
local SpawnDummies = remotes:WaitForChild("SpawnDummies") :: RemoteEvent
local SpawnLaDummy = remotes:WaitForChild("SpawnLaDummy") :: RemoteEvent
local ClearSpawnedDummies = remotes:WaitForChild("ClearSpawnedDummies") :: RemoteEvent
local DevNotify = remotes:WaitForChild("DevNotify") :: RemoteEvent
local SimulateMatchResult = remotes:WaitForChild("SimulateMatchResult") :: RemoteEvent
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

local gui = UiTheme.ScreenGui({
	name = "DevToolUI",
	displayOrder = UiTheme.DisplayOrder.Dev,
	zIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
gui.Parent = playerGui

local panel = UiTheme.Panel({
	parent = gui,
	name = "Panel",
	size = UDim2.fromOffset(460, 628),
	position = UDim2.new(0.5, -230, 0.5, -314),
	visible = false,
})
UiTheme.Stroke(panel, { color = C.Dev, thickness = 1.5 })

local title = UiTheme.Label({
	parent = panel,
	text = "Dev Tools  (F8)",
	size = UDim2.new(1, -16, 0, 28),
	position = UDim2.fromOffset(8, 8),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Heading,
	color = C.Dev,
})

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
dummyFrame.Size = UDim2.new(1, -16, 0, 76)
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

local spawn3Btn = Instance.new("TextButton")
spawn3Btn.Size = UDim2.fromOffset(88, 28)
spawn3Btn.Position = UDim2.fromOffset(8, 40)
spawn3Btn.BackgroundColor3 = Color3.fromRGB(60, 100, 70)
spawn3Btn.BorderSizePixel = 0
spawn3Btn.Font = Enum.Font.GothamBold
spawn3Btn.TextSize = 11
spawn3Btn.TextColor3 = Color3.fromRGB(230, 245, 235)
spawn3Btn.Text = "Spawn +3"
spawn3Btn.Parent = dummyFrame
local s3c = Instance.new("UICorner")
s3c.CornerRadius = UDim.new(0, 4)
s3c.Parent = spawn3Btn

local spawnLaBtn = Instance.new("TextButton")
spawnLaBtn.Size = UDim2.fromOffset(88, 28)
spawnLaBtn.Position = UDim2.fromOffset(104, 40)
spawnLaBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 120)
spawnLaBtn.BorderSizePixel = 0
spawnLaBtn.Font = Enum.Font.GothamBold
spawnLaBtn.TextSize = 11
spawnLaBtn.TextColor3 = Color3.fromRGB(240, 220, 255)
spawnLaBtn.Text = "LA Dummy"
spawnLaBtn.Parent = dummyFrame
local slc = Instance.new("UICorner")
slc.CornerRadius = UDim.new(0, 4)
slc.Parent = spawnLaBtn

local clearSpawnBtn = Instance.new("TextButton")
clearSpawnBtn.Size = UDim2.fromOffset(88, 28)
clearSpawnBtn.Position = UDim2.fromOffset(200, 40)
clearSpawnBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
clearSpawnBtn.BorderSizePixel = 0
clearSpawnBtn.Font = Enum.Font.GothamBold
clearSpawnBtn.TextSize = 11
clearSpawnBtn.TextColor3 = Color3.fromRGB(220, 220, 228)
clearSpawnBtn.Text = "Clear extras"
clearSpawnBtn.Parent = dummyFrame
local csc = Instance.new("UICorner")
csc.CornerRadius = UDim.new(0, 4)
csc.Parent = clearSpawnBtn

local autoHotbarBtn = Instance.new("TextButton")
autoHotbarBtn.Size = UDim2.fromOffset(90, 28)
autoHotbarBtn.Position = UDim2.fromOffset(296, 40)
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
spawn3Btn.MouseButton1Click:Connect(function()
	SpawnDummies:FireServer(3)
end)
spawnLaBtn.MouseButton1Click:Connect(function()
	SpawnLaDummy:FireServer()
end)
clearSpawnBtn.MouseButton1Click:Connect(function()
	ClearSpawnedDummies:FireServer()
end)

local AutoFillHotbar = remotes:WaitForChild("AutoFillHotbar") :: RemoteEvent
autoHotbarBtn.MouseButton1Click:Connect(function()
	AutoFillHotbar:FireServer()
end)

-- Match loot sim (Faz 3)
local matchFrame = Instance.new("Frame")
matchFrame.Size = UDim2.new(1, -16, 0, 76)
matchFrame.Position = UDim2.fromOffset(8, 268)
matchFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
matchFrame.BorderSizePixel = 0
matchFrame.Parent = panel
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 6)
mc.Parent = matchFrame

local matchTitle = Instance.new("TextLabel")
matchTitle.Size = UDim2.fromOffset(80, 16)
matchTitle.Position = UDim2.fromOffset(8, 4)
matchTitle.BackgroundTransparency = 1
matchTitle.Font = Enum.Font.GothamBold
matchTitle.TextSize = 10
matchTitle.TextColor3 = Color3.fromRGB(150, 160, 175)
matchTitle.TextXAlignment = Enum.TextXAlignment.Left
matchTitle.Text = "Match sim"
matchTitle.Parent = matchFrame

local function matchBtn(text: string, x: number, color: Color3, y: number?)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(128, 28)
	btn.Position = UDim2.fromOffset(x, y or 12)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextColor3 = Color3.fromRGB(240, 245, 250)
	btn.Text = text
	btn.Parent = matchFrame
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = btn
	return btn
end

matchBtn("Eye Win", 8, Color3.fromRGB(50, 110, 70)).MouseButton1Click:Connect(function()
	SimulateMatchResult:FireServer({ mode = "PvE", won = true, bossId = "eye" })
end)
matchBtn("Breaker Win", 108, Color3.fromRGB(90, 80, 55)).MouseButton1Click:Connect(function()
	SimulateMatchResult:FireServer({ mode = "PvE", won = true, bossId = "breaker" })
end)
matchBtn("PvP Win", 208, Color3.fromRGB(50, 90, 130)).MouseButton1Click:Connect(function()
	SimulateMatchResult:FireServer({ mode = "PvP", won = true })
end)
matchBtn("Loss", 8, Color3.fromRGB(90, 55, 55), 44).MouseButton1Click:Connect(function()
	SimulateMatchResult:FireServer({ mode = "PvE", won = false, bossId = "eye" })
end)

local bossRemotes = ReplicatedStorage:WaitForChild("BossRemotes")
local StartBossDev = bossRemotes:WaitForChild("StartBossDev") :: RemoteEvent
matchBtn("Start Eye Boss", 8, Color3.fromRGB(120, 60, 140), 44).MouseButton1Click:Connect(function()
	StartBossDev:FireServer({ bossId = "eye" })
end)
matchBtn("Start Breaker", 58, Color3.fromRGB(100, 70, 50), 44).MouseButton1Click:Connect(function()
	StartBossDev:FireServer({ bossId = "breaker" })
end)

local pvpRemotes = ReplicatedStorage:WaitForChild("PvpRemotes")
local StartPvpDev = pvpRemotes:WaitForChild("StartPvpDev") :: RemoteEvent
matchBtn("PvP Practice", 142, Color3.fromRGB(70, 90, 140), 44).MouseButton1Click:Connect(function()
	StartPvpDev:FireServer()
end)

-- Item spawn
local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -80, 0, 30)
search.Position = UDim2.fromOffset(8, 352)
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
countBox.Position = UDim2.new(1, -64, 0, 316)
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
scroll.Size = UDim2.new(1, -16, 1, -398)
scroll.Position = UDim2.fromOffset(8, 390)
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
