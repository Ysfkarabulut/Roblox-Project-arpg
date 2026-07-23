--[[
	Floating hover tooltip for hotbar / gear ability chips.
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local UiTheme = require(script.Parent.UiTheme)
local C = UiTheme.Colors

local HoverTooltip = {}

local panel: Frame
local titleLabel: TextLabel
local bodyLabel: TextLabel

local function ensure()
	if panel then
		return
	end
	local player = Players.LocalPlayer
	local gui = UiTheme.ScreenGui({
		name = "HoverTooltipGui",
		displayOrder = UiTheme.DisplayOrder.Tooltip,
		zIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	panel = UiTheme.Panel({
		parent = gui,
		name = "HoverTooltip",
		size = UDim2.fromOffset(280, 120),
		position = UDim2.fromOffset(0, 0),
		bg = C.Bg,
		radius = UiTheme.Radius.Md,
		visible = false,
	})
	panel.ZIndex = 100
	UiTheme.Stroke(panel, { color = C.StrokeSoft })

	titleLabel = UiTheme.Label({
		parent = panel,
		size = UDim2.new(1, -16, 0, 22),
		position = UDim2.fromOffset(8, 6),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Subtitle,
		color = C.Text,
	})
	titleLabel.ZIndex = 101

	bodyLabel = UiTheme.Label({
		parent = panel,
		size = UDim2.new(1, -16, 1, -32),
		position = UDim2.fromOffset(8, 28),
		textSize = UiTheme.TextSize.Caption,
		color = C.TextDim,
		yAlign = Enum.TextYAlignment.Top,
		wrapped = true,
	})
	bodyLabel.ZIndex = 101
end

local function positionNear(anchor: GuiObject?)
	if not anchor or not panel then
		return
	end
	local inset = GuiService:GetGuiInset()
	local pos = anchor.AbsolutePosition
	local size = anchor.AbsoluteSize
	local pw, ph = panel.AbsoluteSize.X, panel.AbsoluteSize.Y
	local x = pos.X + size.X * 0.5 - pw * 0.5
	local y = pos.Y - ph - 8
	if y < inset.Y + 4 then
		y = pos.Y + size.Y + 8
	end
	local camera = workspace.CurrentCamera
	local vp = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	x = math.clamp(x, 4, math.max(4, vp.X - pw - 4))
	panel.Position = UDim2.fromOffset(x, y)
end

function HoverTooltip.show(title: string, body: string, anchor: GuiObject?)
	ensure()
	titleLabel.Text = title
	bodyLabel.Text = body
	local lines = math.max(1, #string.split(body, "\n"))
	local h = math.clamp(36 + lines * 15, 72, 240)
	panel.Size = UDim2.fromOffset(280, h)
	panel.Visible = true
	positionNear(anchor)
end

function HoverTooltip.hide()
	if panel then
		panel.Visible = false
	end
end

return HoverTooltip
