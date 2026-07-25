--[[
	Unified vector status icons for combat nameplates.
	Layered rounded shapes + highlight accents (same style as Wet / Bleed / Ignite).
	Reaction outputs: parent icons split at center and merged.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NameplateConfig = require(ReplicatedStorage.Shared.Config.NameplateConfig)
local ReactionTable = require(ReplicatedStorage.Shared.Config.ReactionTable)

local StatusIconArt = {}

local ART_HEIGHT = 15

local function clearHost(host: GuiObject)
	for _, c in host:GetChildren() do
		if c.Name == "StatusArt" then
			c:Destroy()
		end
	end
end

local function addPart(
	parent: Instance,
	opts: {
		size: UDim2,
		position: UDim2,
		color: Color3,
		rotation: number?,
		transparency: number?,
		corner: number?,
		zIndex: number?,
	}
): Frame
	local f = Instance.new("Frame")
	f.Name = "Part"
	f.Size = opts.size
	f.Position = opts.position
	f.BackgroundColor3 = opts.color
	f.BackgroundTransparency = opts.transparency or 0
	f.BorderSizePixel = 0
	f.Rotation = opts.rotation or 0
	f.ZIndex = opts.zIndex or 2
	f.Parent = parent
	if opts.corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(opts.corner, 0)
		c.Parent = f
	end
	return f
end

local CENTER = Vector2.new(13, 9)

local function shades(color: Color3, darkRgb: Color3?, brightRgb: Color3?)
	return {
		dark = color:Lerp(darkRgb or Color3.fromRGB(24, 26, 32), 0.28),
		mid = color:Lerp(brightRgb or Color3.fromRGB(255, 255, 255), 0.22),
		bright = color:Lerp(Color3.fromRGB(255, 255, 255), 0.42),
	}
end

local function artRoot(host: GuiObject): Frame
	local root = Instance.new("Frame")
	root.Name = "StatusArt"
	root.Size = UDim2.fromOffset(26, ART_HEIGHT)
	root.Position = UDim2.new(0.5, -13, 0, 2)
	root.BackgroundTransparency = 1
	root.Parent = host
	return root
end

local function dot(
	root: Frame,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	opts: { rot: number?, trans: number?, z: number? }?
)
	opts = opts or {}
	addPart(root, {
		size = UDim2.fromOffset(w, h),
		position = UDim2.fromOffset(CENTER.X + x - w / 2, CENTER.Y + y - h / 2),
		color = color,
		rotation = opts.rot,
		transparency = opts.trans,
		corner = 1,
		zIndex = opts.z or 2,
	})
end

local function mountBleedDrop(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(40, 10, 10), Color3.fromRGB(255, 200, 200))

	dot(root, 0, -1, 9, 12, s.dark)
	dot(root, 0, -4, 6, 6, s.bright, { z = 3 })
	dot(root, 0, 3, 4, 5, color)
end

local function mountWetDrop(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(20, 60, 140), Color3.fromRGB(120, 200, 255))
	local highlight = Color3.fromRGB(220, 245, 255)
	-- Water teardrop — rounder, cleaner than blood
	addPart(root, {
		size = UDim2.fromOffset(10, 11),
		position = UDim2.new(0.5, -5, 0.5, -3),
		color = s.dark,
		corner = 1,
		zIndex = 2,
	})
	addPart(root, {
		size = UDim2.fromOffset(8, 9),
		position = UDim2.new(0.5, -4, 0.5, -4),
		color = s.mid,
		corner = 1,
		zIndex = 3,
	})
	addPart(root, {
		size = UDim2.fromOffset(5, 5),
		position = UDim2.new(0.5, -4, 0, 1),
		color = highlight,
		corner = 1,
		transparency = 0.15,
		zIndex = 4,
	})
	-- Pointed drip tip
	addPart(root, {
		size = UDim2.fromOffset(4, 4),
		position = UDim2.new(0.5, -2, 0.5, 4),
		color = color,
		corner = 1,
		zIndex = 2,
	})
	-- Tiny surface glint
	addPart(root, {
		size = UDim2.fromOffset(2, 2),
		position = UDim2.new(0.5, -1, 0, 3),
		color = highlight,
		corner = 1,
		transparency = 0.1,
		zIndex = 5,
	})
end

local function mountIgniteFlame(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(120, 30, 0), Color3.fromRGB(255, 255, 200))
	local tip = color:Lerp(Color3.fromRGB(255, 60, 0), 0.15)
	-- Central fire beam
	addPart(root, {
		size = UDim2.fromOffset(5, 13),
		position = UDim2.new(0.5, -2, 0.5, -5),
		color = s.bright,
		corner = 1,
		zIndex = 3,
	})
	addPart(root, {
		size = UDim2.fromOffset(3, 8),
		position = UDim2.new(0.5, -1, 0, -1),
		color = Color3.fromRGB(255, 250, 180),
		corner = 1,
		zIndex = 4,
	})
	-- Side wisps
	addPart(root, {
		size = UDim2.fromOffset(4, 9),
		position = UDim2.new(0.5, -8, 0.5, -3),
		color = tip,
		rotation = -18,
		corner = 1,
		zIndex = 2,
	})
	addPart(root, {
		size = UDim2.fromOffset(4, 9),
		position = UDim2.new(0.5, 4, 0.5, -3),
		color = tip,
		rotation = 18,
		corner = 1,
		zIndex = 2,
	})
	-- Upward streak
	addPart(root, {
		size = UDim2.fromOffset(2, 6),
		position = UDim2.new(0.5, -1, 0, -2),
		color = Color3.fromRGB(255, 240, 120),
		corner = 1,
		zIndex = 5,
	})
end

local function mountShockBolt(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(40, 80, 140), Color3.fromRGB(240, 250, 255))
	dot(root, -1, 2, 3, 7, s.dark, { rot = -22, z = 2 })
	dot(root, 1, -1, 3, 8, color, { rot = 18, z = 3 })
	dot(root, -2, -4, 3, 6, s.bright, { rot = -28, z = 4 })
	dot(root, 0, -5, 2, 3, s.bright, { z = 5 })
end

local function mountWindStreak(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(30, 100, 60), Color3.fromRGB(200, 255, 220))
	dot(root, 1, -4, 10, 3, s.dark, { rot = -8, z = 2 })
	dot(root, 0, 0, 12, 3, color, { rot = -5, z = 3 })
	dot(root, -1, 4, 9, 3, s.bright, { rot = -10, z = 4 })
end

local function mountPoisonBubble(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(30, 80, 20), Color3.fromRGB(200, 255, 160))
	dot(root, 0, -2, 10, 9, s.dark)
	dot(root, 0, -3, 7, 7, s.mid, { z = 3 })
	dot(root, -2, -3, 2, 2, s.bright, { z = 4 })
	dot(root, 2, -3, 2, 2, s.bright, { z = 4 })
	dot(root, -3, 3, 3, 3, color, { rot = 45, z = 2 })
	dot(root, 3, 3, 3, 3, color, { rot = -45, z = 2 })
end

local function mountSlowHourglass(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(50, 40, 80), Color3.fromRGB(220, 210, 255))
	dot(root, 0, -4, 8, 5, s.dark, { rot = 45, z = 2 })
	dot(root, 0, 4, 8, 5, s.dark, { rot = 45, z = 2 })
	dot(root, 0, 0, 2, 2, s.bright, { z = 4 })
	dot(root, 0, -1, 1, 4, color, { z = 3 })
end

local function mountChillCrystal(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(30, 70, 120), Color3.fromRGB(220, 245, 255))
	for i = 0, 5 do
		local rot = i * 60
		dot(root, 0, 0, 2, 7, if i % 2 == 0 then color else s.mid, { rot = rot, z = 2 + i })
	end
	dot(root, 0, 0, 3, 3, s.bright, { z = 6 })
end

local function mountStunStar(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(120, 80, 20), Color3.fromRGB(255, 240, 180))
	for _, rot in { 0, 45, 90, 135 } do
		dot(root, 0, 0, 2, 8, color, { rot = rot, z = 3 })
	end
	dot(root, 0, 0, 4, 4, s.bright, { z = 5 })
end

local function mountHitstunRing(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(100, 60, 30), Color3.fromRGB(255, 220, 180))
	dot(root, 0, 0, 12, 12, s.dark, { trans = 0.35, z = 2 })
	dot(root, 0, 0, 8, 8, color, { z = 3 })
	dot(root, 0, 0, 3, 3, s.bright, { z = 4 })
end

local function mountHyperShield(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(40, 60, 100), Color3.fromRGB(230, 240, 255))
	dot(root, 0, -1, 10, 10, s.dark)
	dot(root, 0, -2, 7, 7, s.mid, { z = 3 })
	dot(root, 0, 5, 5, 5, color, { rot = 45, z = 4 })
	dot(root, 0, -4, 4, 2, s.bright, { z = 5 })
end

local function mountCcBarrier(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(30, 90, 70), Color3.fromRGB(220, 255, 240))
	dot(root, 0, 0, 12, 12, s.dark, { trans = 0.4, z = 2 })
	dot(root, 0, 0, 8, 8, color, { z = 3 })
	dot(root, -1, 0, 2, 5, s.bright, { rot = 45, z = 4 })
	dot(root, 1, 1, 2, 4, s.bright, { rot = -45, z = 4 })
end

local function mountJuggleBreak(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(120, 90, 20), Color3.fromRGB(255, 250, 200))
	dot(root, -4, 2, 3, 3, s.dark)
	dot(root, 4, 2, 3, 3, s.dark)
	dot(root, 0, 1, 2, 6, color, { z = 3 })
	dot(root, 0, -4, 4, 4, s.bright, { rot = 45, z = 4 })
end

local function mountGroundedArrow(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(60, 40, 20), Color3.fromRGB(200, 180, 150))
	dot(root, 0, 5, 12, 2, s.dark, { z = 2 })
	dot(root, 0, -1, 3, 7, color, { z = 3 })
	dot(root, -3, 1, 4, 3, color, { rot = 45, z = 3 })
	dot(root, 3, 1, 4, 3, color, { rot = -45, z = 3 })
end

local function mountRootVines(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(30, 80, 40), Color3.fromRGB(180, 255, 200))
	dot(root, -3, 3, 3, 6, s.dark, { rot = -15, z = 2 })
	dot(root, 0, 2, 3, 7, color, { z = 3 })
	dot(root, 3, 3, 3, 6, s.dark, { rot = 15, z = 2 })
	dot(root, 0, -3, 2, 2, s.bright, { z = 4 })
end

local function mountWildFire(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(120, 30, 0), Color3.fromRGB(255, 255, 200))
	dot(root, -5, 0, 8, 3, color:Lerp(Color3.fromRGB(140, 255, 180), 0.35), { rot = -10, z = 2 })
	dot(root, 0, -2, 5, 12, s.bright, { z = 3 })
	dot(root, 4, -1, 4, 9, color, { rot = 15, z = 4 })
	dot(root, 0, -5, 2, 5, Color3.fromRGB(255, 240, 120), { z = 5 })
end

local function mountBlightCloud(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(40, 70, 20), Color3.fromRGB(200, 255, 160))
	dot(root, -3, -1, 6, 6, s.dark)
	dot(root, 2, -2, 7, 7, color)
	dot(root, 0, 2, 8, 5, s.mid, { z = 3 })
	dot(root, -1, -2, 2, 2, s.bright, { z = 4 })
	dot(root, 2, -3, 2, 2, s.bright, { z = 4 })
end

local function mountCausticBubble(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(60, 100, 10), Color3.fromRGB(220, 255, 140))
	dot(root, 0, 0, 11, 11, s.dark)
	dot(root, 0, -1, 7, 7, color, { z = 3 })
	dot(root, 0, -2, 4, 5, Color3.fromRGB(255, 140, 40), { z = 4 })
	dot(root, -2, -3, 2, 2, s.bright, { trans = 0.1, z = 5 })
end

local function mountCauterize(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(120, 30, 0), Color3.fromRGB(255, 220, 180))
	dot(root, 0, 3, 5, 6, Color3.fromRGB(180, 50, 40), { z = 2 })
	dot(root, 0, -3, 4, 6, s.bright, { z = 3 })
	dot(root, 0, -5, 2, 4, Color3.fromRGB(255, 240, 120), { z = 4 })
end

local function mountThawMelt(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local ice = shades(Color3.fromRGB(120, 200, 255), Color3.fromRGB(30, 70, 120), Color3.fromRGB(220, 245, 255))
	local warm = shades(color, Color3.fromRGB(120, 80, 20), Color3.fromRGB(255, 250, 200))
	dot(root, -1, 0, 3, 8, ice.mid, { rot = -12, z = 2 })
	dot(root, 2, 1, 3, 7, ice.dark, { rot = 18, z = 2 })
	dot(root, 0, -3, 4, 4, warm.bright, { z = 4 })
	dot(root, 3, -4, 3, 3, warm.mid, { z = 3 })
end

local function mountFortifyWall(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(40, 70, 120), Color3.fromRGB(200, 230, 255))
	dot(root, -3, -3, 5, 4, s.dark)
	dot(root, 3, -3, 5, 4, s.dark)
	dot(root, 0, 1, 5, 4, color, { z = 3 })
	dot(root, -3, 5, 5, 4, s.mid, { z = 3 })
	dot(root, 3, 5, 5, 4, s.mid, { z = 3 })
end

local function mountRegenPulse(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(30, 90, 50), Color3.fromRGB(200, 255, 220))
	dot(root, 0, 0, 11, 11, s.dark, { trans = 0.45, z = 2 })
	dot(root, 0, 0, 2, 7, color, { z = 3 })
	dot(root, 0, 0, 7, 2, color, { z = 3 })
	dot(root, 0, 0, 3, 3, s.bright, { z = 4 })
end

local function mountFrenzyBurst(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(100, 20, 20), Color3.fromRGB(255, 200, 200))
	for _, rot in { 0, 60, 120 } do
		dot(root, 0, 0, 2, 7, s.dark, { rot = rot, z = 2 })
	end
	dot(root, 0, -2, 3, 8, color, { z = 4 })
	dot(root, 0, 4, 2, 3, s.bright, { z = 5 })
end

local function mountHelmPulse(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(70, 50, 120), Color3.fromRGB(240, 230, 255))
	dot(root, 0, 0, 13, 13, s.mid, { trans = 0.5, z = 2 })
	dot(root, 0, -1, 10, 8, s.dark, { z = 3 })
	dot(root, 0, 3, 8, 4, color, { z = 4 })
	dot(root, 0, -3, 4, 2, s.bright, { z = 5 })
end

local function mountGuardShield(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(50, 55, 70), Color3.fromRGB(230, 235, 245))
	dot(root, 0, -1, 11, 11, s.dark)
	dot(root, 0, -2, 7, 8, s.mid, { z = 3 })
	dot(root, 0, 0, 6, 2, color, { z = 4 })
	dot(root, 0, 4, 4, 4, color, { rot = 45, z = 4 })
end

local function mountParryDeflect(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(60, 60, 100), Color3.fromRGB(245, 245, 255))
	dot(root, 0, 0, 12, 12, s.dark, { trans = 0.55, z = 2 })
	dot(root, -1, 0, 3, 10, color, { rot = 45, z = 3 })
	dot(root, 1, 0, 3, 10, color, { rot = -45, z = 3 })
	dot(root, 0, 0, 3, 3, s.bright, { z = 4 })
end

local function mountDodgeDash(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color, Color3.fromRGB(50, 50, 70), Color3.fromRGB(240, 240, 255))
	dot(root, -4, -3, 7, 3, s.dark, { rot = -20, z = 2 })
	dot(root, 0, 0, 8, 3, color, { rot = -18, z = 3 })
	dot(root, 4, 3, 7, 3, s.bright, { rot = -16, z = 4 })
end

local function mountGenericOrb(host: GuiObject, color: Color3)
	local root = artRoot(host)
	local s = shades(color)
	dot(root, 0, 0, 11, 11, s.dark)
	dot(root, 0, -1, 7, 7, s.mid, { z = 3 })
	dot(root, -2, -3, 3, 3, s.bright, { trans = 0.15, z = 4 })
end

local MOUNTERS: { [string]: (GuiObject, Color3) -> () } = {
	Wet = mountWetDrop,
	Bleed = mountBleedDrop,
	Ignite = mountIgniteFlame,
	Shock = mountShockBolt,
	Windy = mountWindStreak,
	Poisoned = mountPoisonBubble,
	Slow = mountSlowHourglass,
	Chilled = mountChillCrystal,
	Stun = mountStunStar,
	Hitstun = mountHitstunRing,
	HyperArmor = mountHyperShield,
	CcImmunity = mountCcBarrier,
	JuggleBreak = mountJuggleBreak,
	Grounded = mountGroundedArrow,
	Root = mountRootVines,
	WildFire = mountWildFire,
	Blight = mountBlightCloud,
	CausticBurn = mountCausticBubble,
	Cauterize = mountCauterize,
	Thaw = mountThawMelt,
	Fortify = mountFortifyWall,
	Regen = mountRegenPulse,
	Frenzy = mountFrenzyBurst,
	HelmPulse = mountHelmPulse,
	Guard = mountGuardShield,
	Parry = mountParryDeflect,
	Dodge = mountDodgeDash,
}

local function mountByVisual(host: GuiObject, statusId: string, vis: NameplateConfig.StatusVisual)
	local mounter = MOUNTERS[statusId]
	if mounter then
		mounter(host, vis.color)
	else
		mountGenericOrb(host, vis.color)
	end
end

local function mountHalf(
	iconHost: GuiObject,
	statusId: string,
	side: "left" | "right",
	vis: NameplateConfig.StatusVisual
)
	local clip = Instance.new("Frame")
	clip.Name = "StatusArt"
	clip.Size = UDim2.new(0.5, 0, 0, ART_HEIGHT + 2)
	clip.Position = if side == "left" then UDim2.fromOffset(0, 2) else UDim2.new(0.5, 0, 0, 2)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = 2
	clip.Parent = iconHost

	local artHost = Instance.new("Frame")
	artHost.Size = UDim2.fromOffset(26, ART_HEIGHT)
	artHost.Position = if side == "left" then UDim2.fromOffset(0, 0) else UDim2.fromOffset(-13, 0)
	artHost.BackgroundTransparency = 1
	artHost.Parent = clip

	mountByVisual(artHost, statusId, vis)
end

function StatusIconArt.Clear(host: GuiObject)
	clearHost(host)
	for _, c in host:GetChildren() do
		if c.Name == "MergeSeam" then
			c:Destroy()
		end
	end
end

function StatusIconArt.Mount(host: GuiObject, statusId: string)
	StatusIconArt.Clear(host)
	local vis = NameplateConfig.StatusVisual(statusId)
	local artHost = Instance.new("Frame")
	artHost.Name = "StatusArt"
	artHost.Size = UDim2.new(1, 0, 0, ART_HEIGHT + 2)
	artHost.Position = UDim2.fromOffset(0, 2)
	artHost.BackgroundTransparency = 1
	artHost.ZIndex = 2
	artHost.Parent = host
	mountByVisual(artHost, statusId, vis)
end

function StatusIconArt.MountMerge(host: GuiObject, statusId: string, parentA: string, parentB: string)
	StatusIconArt.Clear(host)
	local visA = NameplateConfig.StatusVisual(parentA)
	local visB = NameplateConfig.StatusVisual(parentB)

	mountHalf(host, parentA, "left", visA)
	mountHalf(host, parentB, "right", visB)

	local seam = Instance.new("Frame")
	seam.Name = "MergeSeam"
	seam.Size = UDim2.new(0, 1, 0, ART_HEIGHT)
	seam.Position = UDim2.new(0.5, 0, 0, 3)
	seam.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	seam.BackgroundTransparency = 0.35
	seam.BorderSizePixel = 0
	seam.ZIndex = 5
	seam.Parent = host
end

function StatusIconArt.MountForStatus(host: GuiObject, statusId: string)
	local parentA, parentB = ReactionTable.OutputParents(statusId)
	if parentA and parentB then
		StatusIconArt.MountMerge(host, statusId, parentA, parentB)
	else
		StatusIconArt.Mount(host, statusId)
	end
end

return StatusIconArt
