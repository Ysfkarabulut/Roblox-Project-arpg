--[[
	Shared ARPG UI theme — palette, typography, spacing, component factories.
	All client ScreenGuis should use this for a consistent look.
]]

local UiPalette = require(game.ReplicatedStorage.Shared.UI.UiPalette)

local UiTheme = {}

UiTheme.Colors = UiPalette.Base
UiTheme.Nameplate = UiPalette.Nameplate

UiTheme.Radius = {
	Sm = 6,
	Md = 8,
	Lg = 10,
	Xl = 12,
	Xs = 4,
}

UiTheme.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
	Display = Enum.Font.GothamBlack,
	Mono = Enum.Font.Code,
}

UiTheme.TextSize = {
	Caption = 11,
	Body = 12,
	Subtitle = 13,
	Title = 14,
	Heading = 16,
	Display = 18,
	Hero = 22,
	Banner = 28,
}

UiTheme.Spacing = {
	Xs = 4,
	Sm = 8,
	Md = 12,
	Lg = 16,
}

UiTheme.DisplayOrder = {
	Hud = 5,
	Panel = 10,
	Tutorial = 40,
	Shop = 42,
	Leaderboard = 44,
	Lobby = 45,
	Dev = 50,
	Boss = 70,
	Modal = 80,
	Trade = 85,
	Tooltip = 90,
	Toast = 95,
}

UiTheme.OverlayTransparency = 0.45
UiTheme.PanelTransparency = 0.15

local BUTTON_COLORS = {
	primary = UiTheme.Colors.Accent,
	success = UiTheme.Colors.SuccessDark,
	danger = UiTheme.Colors.DangerDark,
	warning = UiTheme.Colors.Warning,
	muted = UiTheme.Colors.ButtonMuted,
	accent = UiTheme.Colors.AccentSoft,
	panel = UiTheme.Colors.Panel,
	button = UiTheme.Colors.Button,
	premium = UiTheme.Colors.Premium,
}

function UiTheme.ButtonColor(variant: string?): Color3
	return BUTTON_COLORS[variant or "primary"] or UiTheme.Colors.Accent
end

function UiTheme.Corner(parent: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or UiTheme.Radius.Md)
	c.Parent = parent
	return c
end

function UiTheme.Stroke(
	parent: Instance,
	opts: { color: Color3?, thickness: number?, transparency: number? }?
): UIStroke
	opts = opts or {}
	local s = Instance.new("UIStroke")
	s.Color = opts.color or UiTheme.Colors.Stroke
	s.Thickness = opts.thickness or 1
	if opts.transparency then
		s.Transparency = opts.transparency
	end
	s.Parent = parent
	return s
end

function UiTheme.Padding(parent: Instance, padding: number?): UIPadding
	local p = Instance.new("UIPadding")
	local pad = padding or UiTheme.Spacing.Sm
	p.PaddingTop = UDim.new(0, pad)
	p.PaddingBottom = UDim.new(0, pad)
	p.PaddingLeft = UDim.new(0, pad)
	p.PaddingRight = UDim.new(0, pad)
	p.Parent = parent
	return p
end

export type ScreenGuiOpts = {
	name: string,
	displayOrder: number?,
	ignoreInset: boolean?,
	zIndexBehavior: Enum.ZIndexBehavior?,
	enabled: boolean?,
}

function UiTheme.ScreenGui(opts: ScreenGuiOpts): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = opts.name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = opts.displayOrder or UiTheme.DisplayOrder.Panel
	if opts.ignoreInset ~= false then
		gui.IgnoreGuiInset = true
	end
	if opts.zIndexBehavior then
		gui.ZIndexBehavior = opts.zIndexBehavior
	end
	if opts.enabled ~= nil then
		gui.Enabled = opts.enabled
	end
	return gui
end

export type PanelOpts = {
	parent: Instance,
	name: string?,
	size: UDim2?,
	position: UDim2?,
	bg: Color3?,
	transparency: number?,
	radius: number?,
	stroke: boolean?,
	visible: boolean?,
}

function UiTheme.Panel(opts: PanelOpts): Frame
	local frame = Instance.new("Frame")
	frame.Name = opts.name or "Panel"
	frame.Size = opts.size or UDim2.fromOffset(320, 200)
	frame.Position = opts.position or UDim2.fromOffset(0, 0)
	frame.BackgroundColor3 = opts.bg or UiTheme.Colors.Bg
	frame.BackgroundTransparency = opts.transparency or 0
	frame.BorderSizePixel = 0
	if opts.visible ~= nil then
		frame.Visible = opts.visible
	end
	frame.Parent = opts.parent
	UiTheme.Corner(frame, opts.radius or UiTheme.Radius.Lg)
	if opts.stroke then
		UiTheme.Stroke(frame)
	end
	return frame
end

export type LabelOpts = {
	parent: Instance,
	name: string?,
	text: string?,
	size: UDim2?,
	position: UDim2?,
	font: Enum.Font?,
	textSize: number?,
	color: Color3?,
	xAlign: Enum.TextXAlignment?,
	yAlign: Enum.TextYAlignment?,
	wrapped: boolean?,
	rich: boolean?,
	bg: Color3?,
	bgTransparency: number?,
	radius: number?,
}

function UiTheme.Label(opts: LabelOpts): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = opts.name or "Label"
	label.Size = opts.size or UDim2.new(1, 0, 0, 20)
	label.Position = opts.position or UDim2.fromOffset(0, 0)
	label.BackgroundTransparency = if opts.bg then 0 else 1
	if opts.bg then
		label.BackgroundColor3 = opts.bg
		UiTheme.Corner(label, opts.radius or UiTheme.Radius.Sm)
	end
	label.Font = opts.font or UiTheme.Font.Body
	label.TextSize = opts.textSize or UiTheme.TextSize.Body
	label.TextColor3 = opts.color or UiTheme.Colors.Text
	label.TextXAlignment = opts.xAlign or Enum.TextXAlignment.Left
	label.TextYAlignment = opts.yAlign or Enum.TextYAlignment.Center
	label.TextWrapped = opts.wrapped == true
	label.RichText = opts.rich == true
	label.Text = opts.text or ""
	label.BorderSizePixel = 0
	label.Parent = opts.parent
	return label
end

export type ButtonOpts = {
	parent: Instance,
	name: string?,
	text: string?,
	size: UDim2?,
	position: UDim2?,
	variant: string?,
	font: Enum.Font?,
	textSize: number?,
	textColor: Color3?,
	radius: number?,
	autoButtonColor: boolean?,
}

function UiTheme.Button(opts: ButtonOpts): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = opts.name or "Button"
	btn.Size = opts.size or UDim2.fromOffset(120, 32)
	btn.Position = opts.position or UDim2.fromOffset(0, 0)
	btn.BackgroundColor3 = UiTheme.ButtonColor(opts.variant)
	btn.BorderSizePixel = 0
	btn.Font = opts.font or UiTheme.Font.Title
	btn.TextSize = opts.textSize or UiTheme.TextSize.Subtitle
	btn.TextColor3 = opts.textColor or UiTheme.Colors.Text
	btn.Text = opts.text or ""
	btn.AutoButtonColor = if opts.autoButtonColor == nil then true else opts.autoButtonColor
	btn.Parent = opts.parent
	UiTheme.Corner(btn, opts.radius or UiTheme.Radius.Sm)
	return btn
end

export type TextBoxOpts = {
	parent: Instance,
	name: string?,
	placeholder: string?,
	size: UDim2?,
	position: UDim2?,
}

function UiTheme.TextBox(opts: TextBoxOpts): TextBox
	local box = Instance.new("TextBox")
	box.Name = opts.name or "TextBox"
	box.Size = opts.size or UDim2.new(1, 0, 0, 34)
	box.Position = opts.position or UDim2.fromOffset(0, 0)
	box.BackgroundColor3 = UiTheme.Colors.Panel
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = UiTheme.Font.Body
	box.TextSize = UiTheme.TextSize.Subtitle
	box.TextColor3 = UiTheme.Colors.Text
	box.PlaceholderText = opts.placeholder or ""
	box.Text = ""
	box.Parent = opts.parent
	UiTheme.Corner(box, UiTheme.Radius.Sm)
	return box
end

export type ScrollOpts = {
	parent: Instance,
	name: string?,
	size: UDim2?,
	position: UDim2?,
	bgTransparency: number?,
}

function UiTheme.ScrollFrame(opts: ScrollOpts): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = opts.name or "Scroll"
	scroll.Size = opts.size or UDim2.new(1, 0, 1, 0)
	scroll.Position = opts.position or UDim2.fromOffset(0, 0)
	scroll.BackgroundTransparency = opts.bgTransparency or 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.Parent = opts.parent
	return scroll
end

export type BillboardLabelOpts = {
	parent: Instance,
	text: string?,
	size: UDim2?,
	studsOffset: Vector3?,
	font: Enum.Font?,
	textSize: number?,
	color: Color3?,
	strokeTransparency: number?,
}

function UiTheme.BillboardLabel(opts: BillboardLabelOpts): (BillboardGui, TextLabel)
	local bill = Instance.new("BillboardGui")
	bill.Size = opts.size or UDim2.fromOffset(140, 28)
	bill.StudsOffset = opts.studsOffset or Vector3.new(0, 2.5, 0)
	bill.AlwaysOnTop = true
	bill.Parent = opts.parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = opts.font or UiTheme.Font.Title
	label.TextSize = opts.textSize or UiTheme.TextSize.Display
	label.TextColor3 = opts.color or UiTheme.Colors.TextBright
	label.TextStrokeTransparency = opts.strokeTransparency or 0.45
	label.Text = opts.text or ""
	label.Parent = bill
	return bill, label
end

function UiTheme.HpTierColor(pct: number, fullColor: Color3): Color3
	return UiPalette.HpTierColor(pct, fullColor)
end

return UiTheme
