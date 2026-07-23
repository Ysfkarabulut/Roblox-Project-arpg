--[[
	Bottom-center toast notifications for shop, trade, lootbox, etc.
]]

local Players = game:GetService("Players")

local UiTheme = require(script.Parent.UiTheme)
local C = UiTheme.Colors

local UiToast = {}

local gui: ScreenGui
local label: TextLabel
local hideToken = 0

local function ensure()
	if gui then
		return
	end
	local player = Players.LocalPlayer
	gui = UiTheme.ScreenGui({
		name = "UiToast",
		displayOrder = UiTheme.DisplayOrder.Toast,
		ignoreInset = true,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -88)
	frame.Size = UDim2.fromOffset(360, 36)
	frame.BackgroundColor3 = C.BgElevated
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui
	UiTheme.Corner(frame, UiTheme.Radius.Md)
	UiTheme.Stroke(frame, { color = C.StrokeSoft })

	label = UiTheme.Label({
		parent = frame,
		size = UDim2.new(1, -16, 1, 0),
		position = UDim2.fromOffset(8, 0),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Subtitle,
		wrapped = true,
	})
end

function UiToast.Show(message: string, duration: number?, kind: string?)
	ensure()
	if message == "" then
		return
	end
	hideToken += 1
	local token = hideToken
	local frame = label.Parent :: Frame
	frame.Visible = true
	label.Text = message
	if kind == "success" then
		label.TextColor3 = C.SuccessBright
	elseif kind == "error" then
		label.TextColor3 = C.DangerBright
	elseif kind == "warn" then
		label.TextColor3 = C.WarningDark
	else
		label.TextColor3 = C.Text
	end
	task.delay(duration or 2.5, function()
		if hideToken ~= token then
			return
		end
		frame.Visible = false
		label.Text = ""
	end)
end

return UiToast
