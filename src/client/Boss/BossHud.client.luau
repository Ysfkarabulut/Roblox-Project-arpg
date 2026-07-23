--[[
	Boss HUD — HP bar, phase label, countdown.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("BossRemotes")
local BossState = remotes:WaitForChild("BossState") :: RemoteEvent
local BossTelegraph = remotes:WaitForChild("BossTelegraph") :: RemoteEvent

local gui = UiTheme.ScreenGui({
	name = "BossHud",
	displayOrder = UiTheme.DisplayOrder.Boss,
	ignoreInset = false,
	enabled = false,
})
gui.Parent = playerGui

local panel = UiTheme.Panel({
	parent = gui,
	name = "Panel",
	size = UDim2.new(0.5, 0, 0, 56),
	position = UDim2.new(0.25, 0, 0, 12),
	transparency = UiTheme.PanelTransparency,
	radius = UiTheme.Radius.Md,
})

local title = UiTheme.Label({
	parent = panel,
	text = "The Eye",
	size = UDim2.new(1, -16, 0, 20),
	position = UDim2.fromOffset(8, 6),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Title,
})

local phaseLabel = UiTheme.Label({
	parent = panel,
	text = "P1",
	size = UDim2.fromOffset(80, 20),
	position = UDim2.new(1, -88, 0, 6),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Body,
	color = C.TextMuted,
	xAlign = Enum.TextXAlignment.Right,
})

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -16, 0, 14)
barBg.Position = UDim2.fromOffset(8, 30)
barBg.BackgroundColor3 = C.BarTrack
barBg.BorderSizePixel = 0
barBg.Parent = panel
UiTheme.Corner(barBg, UiTheme.Radius.Xs)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.fromScale(1, 1)
barFill.BackgroundColor3 = C.BarHp
barFill.BorderSizePixel = 0
barFill.Parent = barBg
UiTheme.Corner(barFill, UiTheme.Radius.Xs)

local hpLabel = UiTheme.Label({
	parent = panel,
	size = UDim2.new(1, -16, 0, 14),
	position = UDim2.fromOffset(8, 30),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Caption,
})
hpLabel.ZIndex = 2

local toast = UiTheme.Label({
	parent = gui,
	size = UDim2.new(0.6, 0, 0, 36),
	position = UDim2.new(0.2, 0, 0.35, 0),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Hero,
	color = C.WarningBright,
	xAlign = Enum.TextXAlignment.Center,
})
toast.TextStrokeTransparency = 0.4

local toastToken = 0

local function showToast(msg: string, sec: number?)
	toast.Text = msg
	toastToken += 1
	local token = toastToken
	task.delay(sec or 2, function()
		if toastToken == token then
			toast.Text = ""
		end
	end)
end

local function applyState(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	if payload.kind == "Countdown" then
		gui.Enabled = true
		showToast(`Encounter in {payload.seconds}s`, payload.seconds)
		return
	end
	if payload.active == false then
		gui.Enabled = false
		return
	end
	gui.Enabled = true
	if typeof(payload.phase) == "number" then
		phaseLabel.Text = `P{payload.phase}`
	end
	if typeof(payload.hp) == "number" and typeof(payload.maxHp) == "number" and payload.maxHp > 0 then
		local pct = math.clamp(payload.hp / payload.maxHp, 0, 1)
		barFill.Size = UDim2.fromScale(pct, 1)
		hpLabel.Text = `{math.floor(payload.hp)} / {math.floor(payload.maxHp)}`
	end
end

BossState.OnClientEvent:Connect(applyState)

BossTelegraph.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	if payload.kind == "Phase" and typeof(payload.phase) == "number" then
		showToast(`PHASE {payload.phase}`, 2.5)
	elseif payload.kind == "Gaze" then
		showToast("MONOLITH GAZE — hide behind stone!", payload.duration or 4)
	elseif payload.kind == "Tentacle" then
		showToast("Tentacle — focus fire!", 2)
	end
end)
