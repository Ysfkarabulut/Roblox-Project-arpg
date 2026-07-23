--[[
	PvP arena HUD — countdown, arena name, gas phase hints.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("PvpRemotes", 15)
if not remotes then
	return
end
local ArenaState = remotes:WaitForChild("ArenaState", 10) :: RemoteEvent?
if not ArenaState then
	return
end

local gui = UiTheme.ScreenGui({
	name = "PvpArenaHud",
	displayOrder = UiTheme.DisplayOrder.Modal,
	ignoreInset = false,
})
gui.Parent = playerGui

local banner = UiTheme.Label({
	parent = gui,
	name = "Banner",
	size = UDim2.fromOffset(420, 56),
	position = UDim2.new(0.5, -210, 0, 24),
	font = UiTheme.Font.Display,
	textSize = UiTheme.TextSize.Banner,
	color = C.TextBright,
	xAlign = Enum.TextXAlignment.Center,
	bg = C.Bg,
})
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.BackgroundTransparency = 0.25
banner.Visible = false
UiTheme.Corner(banner, UiTheme.Radius.Lg)

local sub = UiTheme.Label({
	parent = gui,
	name = "Sub",
	size = UDim2.fromOffset(420, 24),
	position = UDim2.new(0.5, -210, 0, 78),
	textSize = UiTheme.TextSize.Subtitle,
	color = C.TextDim,
	xAlign = Enum.TextXAlignment.Center,
})
sub.AnchorPoint = Vector2.new(0.5, 0)
sub.Visible = false

local function hide()
	banner.Visible = false
	sub.Visible = false
end

ArenaState.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local phase = payload.phase
	if phase == "Ended" then
		hide()
		return
	end

	banner.Visible = true
	sub.Visible = true
	banner.TextColor3 = C.TextBright

	if phase == "Countdown" then
		local sec = if typeof(payload.seconds) == "number" then payload.seconds else 3
		local name = if typeof(payload.arenaName) == "string" then payload.arenaName else "Arena"
		banner.Text = tostring(sec)
		sub.Text = `{name} · gates open soon`
	elseif phase == "Fight" then
		banner.Text = "FIGHT"
		banner.TextColor3 = C.SuccessBright
		sub.Text = if typeof(payload.arenaName) == "string" then payload.arenaName else ""
	elseif phase == "Shrink" then
		banner.Text = "ARENA SHRINKING"
		banner.TextColor3 = C.WarningDark
		sub.Text = "Move to center"
	elseif phase == "Gas" then
		banner.Text = "GAS"
		banner.TextColor3 = C.DangerBright
		sub.Text = "Outside the zone takes damage"
	else
		hide()
	end
end)
