--[[
	Post-match loot result modal (Gacha / boss drop / XP).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local ItemIcon = require(script.Parent.Parent.Inventory.ItemIcon)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COL_BG = C.Bg
local COL_PANEL = C.Panel
local COL_SLOT = C.Slot
local COL_STROKE = C.Stroke
local COL_TEXT = C.Text
local COL_MUTED = C.TextMuted
local COL_WIN = C.SuccessBright
local COL_LOSS = C.DangerBright
local COL_ACCENT = C.Accent
local COL_BOSS = C.Boss

local remotes = ReplicatedStorage:WaitForChild("LootRemotes", 15)
if not remotes then
	warn("[LootResultUI] LootRemotes missing")
	return
end
local LootResult = remotes:WaitForChild("LootResult") :: RemoteEvent

local gui = UiTheme.ScreenGui({
	name = "LootResultUI",
	displayOrder = UiTheme.DisplayOrder.Modal,
	zIndexBehavior = Enum.ZIndexBehavior.Sibling,
	enabled = false,
})
gui.Parent = playerGui

local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = C.BgOverlay
overlay.BackgroundTransparency = UiTheme.OverlayTransparency
overlay.BorderSizePixel = 0
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(420, 380)
panel.Position = UDim2.new(0.5, -210, 0.5, -190)
panel.BackgroundColor3 = COL_BG
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COL_STROKE
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 36)
title.Position = UDim2.fromOffset(12, 12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = COL_WIN
title.Text = "VICTORY"
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -24, 0, 18)
subtitle.Position = UDim2.fromOffset(12, 48)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextColor3 = COL_MUTED
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "PvE · The Eye"
subtitle.Parent = panel

local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "Xp"
xpLabel.Size = UDim2.new(1, -24, 0, 22)
xpLabel.Position = UDim2.fromOffset(12, 72)
xpLabel.BackgroundTransparency = 1
xpLabel.Font = Enum.Font.GothamBold
xpLabel.TextSize = 15
xpLabel.TextColor3 = COL_ACCENT
xpLabel.TextXAlignment = Enum.TextXAlignment.Left
xpLabel.Text = "+120 XP"
xpLabel.Parent = panel

local dropsFrame = Instance.new("Frame")
dropsFrame.Name = "Drops"
dropsFrame.Size = UDim2.new(1, -24, 0, 200)
dropsFrame.Position = UDim2.fromOffset(12, 104)
dropsFrame.BackgroundColor3 = COL_PANEL
dropsFrame.BorderSizePixel = 0
dropsFrame.Parent = panel

local dropsCorner = Instance.new("UICorner")
dropsCorner.CornerRadius = UDim.new(0, 8)
dropsCorner.Parent = dropsFrame

local dropsTitle = Instance.new("TextLabel")
dropsTitle.Size = UDim2.new(1, -16, 0, 20)
dropsTitle.Position = UDim2.fromOffset(8, 8)
dropsTitle.BackgroundTransparency = 1
dropsTitle.Font = Enum.Font.GothamBold
dropsTitle.TextSize = 12
dropsTitle.TextColor3 = COL_TEXT
dropsTitle.TextXAlignment = Enum.TextXAlignment.Left
dropsTitle.Text = "Rewards"
dropsTitle.Parent = dropsFrame

local dropsList = Instance.new("Frame")
dropsList.Name = "List"
dropsList.Size = UDim2.new(1, -16, 1, -36)
dropsList.Position = UDim2.fromOffset(8, 28)
dropsList.BackgroundTransparency = 1
dropsList.Parent = dropsFrame

local dropsLayout = Instance.new("UIListLayout")
dropsLayout.Padding = UDim.new(0, 8)
dropsLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropsLayout.Parent = dropsList

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Name = "Empty"
emptyLabel.Size = UDim2.new(1, 0, 0, 40)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 13
emptyLabel.TextColor3 = COL_MUTED
emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
emptyLabel.Text = "No bonus drops this time."
emptyLabel.Visible = false
emptyLabel.Parent = dropsList

local continueBtn = Instance.new("TextButton")
continueBtn.Name = "Continue"
continueBtn.Size = UDim2.new(0.5, -18, 0, 40)
continueBtn.Position = UDim2.new(0, 12, 1, -52)
continueBtn.BackgroundColor3 = C.SuccessDark
continueBtn.BorderSizePixel = 0
continueBtn.Font = UiTheme.Font.Title
continueBtn.TextSize = UiTheme.TextSize.Subtitle
continueBtn.TextColor3 = C.TextBright
continueBtn.Text = "Continue"
continueBtn.Parent = panel

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 8)
continueCorner.Parent = continueBtn

local retryBtn = Instance.new("TextButton")
retryBtn.Name = "Retry"
retryBtn.Size = UDim2.new(0.5, -18, 0, 40)
retryBtn.Position = UDim2.new(0.5, 6, 1, -52)
retryBtn.BackgroundColor3 = C.AccentMuted
retryBtn.BorderSizePixel = 0
retryBtn.Font = UiTheme.Font.Title
retryBtn.TextSize = UiTheme.TextSize.Subtitle
retryBtn.TextColor3 = C.TextBright
retryBtn.Text = "Retry"
retryBtn.Visible = false
retryBtn.Parent = panel
local retryCorner = Instance.new("UICorner")
retryCorner.CornerRadius = UDim.new(0, 8)
retryCorner.Parent = retryBtn

local bossRemotes = ReplicatedStorage:FindFirstChild("BossRemotes")
local pvpRemotes = ReplicatedStorage:FindFirstChild("PvpRemotes")
local StartBossDev = bossRemotes and bossRemotes:FindFirstChild("StartBossDev")
local StartPvpDev = pvpRemotes and pvpRemotes:FindFirstChild("StartPvpDev")
local lastPayload: any = nil

local function sourceLabel(source: string?): string
	if source == "BossExclusive" then
		return "Boss Drop"
	end
	if source == "Gacha" then
		return "Gacha Box"
	end
	return source or "Reward"
end

local function sourceColor(source: string?): Color3
	if source == "BossExclusive" then
		return COL_BOSS
	end
	if source == "Gacha" then
		return COL_ACCENT
	end
	return COL_MUTED
end

local function clearDrops()
	for _, child in dropsList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	emptyLabel.Visible = false
end

local function addDropRow(entry: any, order: number)
	local row = Instance.new("Frame")
	row.Name = "DropRow"
	row.Size = UDim2.new(1, 0, 0, 64)
	row.BackgroundColor3 = COL_SLOT
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = dropsList

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row

	local iconHost = Instance.new("Frame")
	iconHost.Size = UDim2.fromOffset(52, 52)
	iconHost.Position = UDim2.fromOffset(6, 6)
	iconHost.BackgroundTransparency = 1
	iconHost.ClipsDescendants = true
	iconHost.Parent = row
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = iconHost

	ItemIcon.Mount(iconHost, entry.defId, { zIndex = 2 })

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(90, 16)
	badge.Position = UDim2.fromOffset(66, 10)
	badge.BackgroundTransparency = 1
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 11
	badge.TextColor3 = sourceColor(entry.source)
	badge.TextXAlignment = Enum.TextXAlignment.Left
	badge.Text = sourceLabel(entry.source)
	badge.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -74, 0, 20)
	nameLabel.Position = UDim2.fromOffset(66, 28)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = COL_TEXT
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = entry.name or entry.defId or "Item"
	nameLabel.Parent = row

	local meta = Instance.new("TextLabel")
	meta.Size = UDim2.new(1, -74, 0, 14)
	meta.Position = UDim2.fromOffset(66, 46)
	meta.BackgroundTransparency = 1
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 11
	meta.TextColor3 = COL_MUTED
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.Text = `{entry.kind or "?"} · {entry.element or "—"}`
	meta.Parent = row
end

local function closeModal()
	gui.Enabled = false
end

local function show(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	local won = payload.won == true
	local mode = if typeof(payload.mode) == "string" then payload.mode else "Match"
	local bossId = if typeof(payload.bossId) == "string" then payload.bossId else nil

	title.Text = if won then "VICTORY" else "DEFEAT"
	title.TextColor3 = if won then COL_WIN else COL_LOSS

	local modeLine = mode
	if bossId then
		modeLine = `{mode} · {bossId}`
	end
	subtitle.Text = modeLine

	local xp = if typeof(payload.xpGained) == "number" then payload.xpGained else 0
	local levelsGained = if typeof(payload.levelsGained) == "number" then payload.levelsGained else 0
	local unspentGained = if typeof(payload.unspentGained) == "number" then payload.unspentGained else 0
	local newLevel = if typeof(payload.level) == "number" then payload.level else nil
	if won and xp > 0 then
		xpLabel.Visible = true
		if levelsGained > 0 and newLevel then
			local pts = if unspentGained > 0 then ` · +{unspentGained} stat pts` else ""
			xpLabel.Text = `+{xp} XP · LEVEL UP → {newLevel}{pts}`
			xpLabel.TextColor3 = COL_WIN
		else
			xpLabel.Text = `+{xp} XP`
			xpLabel.TextColor3 = COL_ACCENT
		end
	else
		xpLabel.Visible = false
		xpLabel.Text = ""
	end

	local mmrDelta = if typeof(payload.mmrDelta) == "number" then payload.mmrDelta else nil
	if mmrDelta and payload.mode == "PvP" then
		xpLabel.Visible = true
		local sign = if mmrDelta >= 0 then "+" else ""
		local tier = if typeof(payload.mmrTier) == "string" then ` · {payload.mmrTier}` else ""
		xpLabel.Text = `{xpLabel.Text}  {sign}{mmrDelta} MMR{tier}`
	end

	retryBtn.Visible = not won
	lastPayload = payload

	clearDrops()
	if won then
		local order = 0
		if typeof(payload.gacha) == "table" then
			order += 1
			addDropRow(payload.gacha, order)
		end
		if typeof(payload.bossDrop) == "table" then
			order += 1
			addDropRow(payload.bossDrop, order)
		end
		if order == 0 then
			emptyLabel.Visible = true
		end
		dropsFrame.Visible = true
	else
		emptyLabel.Text = "No rewards on defeat."
		emptyLabel.Visible = true
		dropsFrame.Visible = true
	end

	gui.Enabled = true
end

continueBtn.MouseButton1Click:Connect(closeModal)
overlay.MouseButton1Click:Connect(closeModal)

retryBtn.MouseButton1Click:Connect(function()
	closeModal()
	if typeof(lastPayload) ~= "table" then
		return
	end
	if lastPayload.mode == "PvE" and StartBossDev and StartBossDev:IsA("RemoteEvent") then
		(StartBossDev :: RemoteEvent):FireServer({ bossId = lastPayload.bossId or "eye" })
	elseif lastPayload.mode == "PvP" and StartPvpDev and StartPvpDev:IsA("RemoteEvent") then
		(StartPvpDev :: RemoteEvent):FireServer()
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not gui.Enabled or processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
		closeModal()
	end
end)

LootResult.OnClientEvent:Connect(show)
