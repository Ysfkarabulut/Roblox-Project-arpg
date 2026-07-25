--[[
	Element gem badge — same glyph, element-colored (UI overlay).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimConfig = require(ReplicatedStorage.Shared.Config.AnimConfig)

local GemSymbol = {}

local GLYPH = "◆"

function GemSymbol.Color(element: string?): Color3
	return AnimConfig.ElementColor[element or "Neutral"] or Color3.fromRGB(200, 200, 210)
end

function GemSymbol.Glyph(): string
	return GLYPH
end

export type MountOpts = {
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	zIndex: number?,
	parent: GuiObject,
	element: string?,
}

--- Corner gem badge (diamond glyph + subtle backing).
function GemSymbol.Mount(opts: MountOpts): Frame
	local element = opts.element or "Neutral"
	local color = GemSymbol.Color(element)

	local badge = Instance.new("Frame")
	badge.Name = "GemBadge"
	badge.Size = opts.size or UDim2.fromOffset(18, 18)
	badge.Position = opts.position or UDim2.new(1, -4, 0, 4)
	badge.AnchorPoint = opts.anchorPoint or Vector2.new(1, 0)
	badge.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	badge.BackgroundTransparency = 0.15
	badge.BorderSizePixel = 0
	badge.ZIndex = opts.zIndex or 6
	badge.Parent = opts.parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = badge

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.2
	stroke.Parent = badge

	local glyph = Instance.new("TextLabel")
	glyph.Name = "Glyph"
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.BackgroundTransparency = 1
	glyph.Font = Enum.Font.GothamBold
	glyph.TextSize = 13
	glyph.TextColor3 = color
	glyph.Text = GLYPH
	glyph.ZIndex = badge.ZIndex + 1
	glyph.Parent = badge

	return badge
end

return GemSymbol
