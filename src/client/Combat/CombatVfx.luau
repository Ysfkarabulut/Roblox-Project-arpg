--[[
	Rich combat VFX — VfxConfig profiles + optional CombatVfxAssets hooks.
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local VfxConfig = require(game.ReplicatedStorage.Shared.Config.VfxConfig)
local VfxAssets = require(script.Parent.VfxAssets)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)

local CombatVfx = {}

local folder = Instance.new("Folder")
folder.Name = "CombatVfxFolder"
folder.Parent = Workspace

local GROUND_RAY = RaycastParams.new()
GROUND_RAY.FilterType = Enum.RaycastFilterType.Exclude
GROUND_RAY.FilterDescendantsInstances = { folder }

local function seq(c: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.35, c),
		ColorSequenceKeypoint.new(1, c:Lerp(Color3.new(0, 0, 0), 0.5)),
	})
end

local function numSeq(a: number, b: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, a),
		NumberSequenceKeypoint.new(1, b),
	})
end

local function anchorPart(cf: CFrame, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size or Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = cf
	p.Parent = folder
	return p
end

local function fadeDestroy(inst: Instance, sec: number)
	Debris:AddItem(inst, sec)
	if inst:IsA("BasePart") then
		TweenService:Create(inst, TweenInfo.new(sec * 0.85), { Transparency = 1 }):Play()
		for _, d in inst:GetDescendants() do
			if d:IsA("PointLight") then
				TweenService:Create(d, TweenInfo.new(sec * 0.7), { Brightness = 0 }):Play()
			end
		end
	end
end

local function fadePart(part: BasePart, life: number, startTransparency: number?)
	part.Transparency = startTransparency or part.Transparency
	TweenService:Create(part, TweenInfo.new(life * 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
	}):Play()
	fadeDestroy(part, life + 0.08)
end

local function addLight(parent: Instance, col: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = col
	l.Brightness = brightness
	l.Range = range
	l.Parent = parent
	return l
end

local function scaled(ctx: VfxConfig.VfxContext, n: number): number
	return n * ctx.stepScale.particleMult * (ctx.profile.particleMult or 1)
end

local function scaledLife(ctx: VfxConfig.VfxContext, n: number): number
	return n * ctx.stepScale.lifeMult * (ctx.profile.lifeMult or 1)
end

local function burstParticles(
	att: Attachment,
	ctx: VfxConfig.VfxContext,
	presetName: string,
	overrides: {
		rate: number?,
		life: number?,
		speed: number?,
		size: number?,
		spread: number?,
	}?
)
	overrides = overrides or {}
	local preset = VfxConfig.Particles[presetName] or VfxConfig.Particles.SparkBurst
	local hookKey = if presetName == "SmokePuff"
		then "ParticleSmoke"
		elseif presetName == "HealMotes" then "ParticleHeal"
		else "ParticleSpark"
	local hookPath = VfxConfig.AssetHooks[hookKey]
	if hookPath and VfxAssets.TryEmitTemplate(hookPath, att, overrides.rate or 28) then
		return
	end

	local life = scaledLife(ctx, overrides.life or preset.life or 0.35)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = seq(ctx.accent)
	pe.LightEmission = preset.lightEmission or 0.7
	pe.LightInfluence = 0.2
	local size0 = scaled(ctx, overrides.size or preset.sizeStart or 0.6)
	local size1 = scaled(ctx, preset.sizeEnd or 0.05)
	pe.Size = numSeq(size0, size1)
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(life, life * 1.4)
	local spd = overrides.speed or preset.speed or 8
	pe.Speed = NumberRange.new(spd * 0.6, spd)
	pe.SpreadAngle = Vector2.new(overrides.spread or preset.spread or 25, overrides.spread or preset.spread or 25)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-90, 90)
	pe.Acceleration = Vector3.new(0, preset.accelY or -2, 0)
	pe.Drag = 2
	pe.Rate = 0
	pe.Texture = VfxAssets.GetTexture(preset.textureKey)
	pe.Parent = att
	pe:Emit(overrides.rate or preset.rate or 28)
	return pe
end

local function smokePuff(att: Attachment, ctx: VfxConfig.VfxContext, count: number?)
	burstParticles(att, ctx, "SmokePuff", { rate = count or 12, life = 0.65, speed = 3, size = 1.2, spread = 38 })
end

local function addTrail(a0: Attachment, a1: Attachment, col: Color3, lifetime: number?)
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = seq(col)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = lifetime or 0.28
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.LightEmission = 0.6
	trail.WidthScale = numSeq(1, 0)
	trail.Parent = a0.Parent
	return trail
end

local function addBeam(a0: Attachment, a1: Attachment, col: Color3)
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Color = seq(col)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1, 0.85),
	})
	beam.Width0 = 0.9
	beam.Width1 = 0.15
	beam.FaceCamera = true
	beam.LightEmission = 0.85
	beam.Segments = 12
	beam.Texture = VfxAssets.GetTexture("Beam")
	beam.TextureSpeed = 3
	beam.TextureLength = 2
	beam.Parent = a0.Parent
	return beam
end

local function raycastGround(pos: Vector3): Vector3
	local hit = Workspace:Raycast(pos + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), GROUND_RAY)
	if hit then
		return hit.Position + Vector3.new(0, 0.08, 0)
	end
	return Vector3.new(pos.X, pos.Y - 2.8, pos.Z)
end

local function flatUnit(v: Vector3): Vector3
	local flat = Vector3.new(v.X, 0, v.Z)
	if flat.Magnitude < 0.05 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

local function rotateFlatY(dir: Vector3, deg: number): Vector3
	local rad = math.rad(deg)
	local c, s = math.cos(rad), math.sin(rad)
	return Vector3.new(dir.X * c - dir.Z * s, 0, dir.X * s + dir.Z * c).Unit
end

local function isAreaShape(shape: string?): boolean
	return shape == "Cone"
		or shape == "AllyCone"
		or shape == "Sphere"
		or shape == "AllySphere"
		or shape == "Line"
end

local function resolveShape(fx: any, vfx: string): string?
	if typeof(fx.shape) == "string" then
		return fx.shape
	end
	if vfx == "Cone" then
		return "Cone"
	end
	if vfx == "Burst" and (fx.radius or fx.range) then
		return "Sphere"
	end
	return nil
end

local function cameraKick(intensity: number)
	if intensity <= 0 then
		return
	end
	local char = Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local seed = math.random() * 1000
	local start = os.clock()
	local dur = 0.13
	local mag = intensity * 0.35
	local conn: RBXScriptConnection?
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t >= dur then
			hum.CameraOffset = Vector3.zero
			if conn then
				conn:Disconnect()
			end
			return
		end
		local falloff = 1 - (t / dur)
		hum.CameraOffset = Vector3.new(
			math.noise(seed, t * 90) * mag * falloff,
			math.noise(seed + 1, t * 90) * mag * falloff * 0.5,
			0
		)
	end)
end

local function playImpactRing(pos: Vector3, ctx: VfxConfig.VfxContext, radius: number?)
	local impactScale = ctx.stepScale.impactScale or 1
	local r = (radius or 2.2 * ctx.stepScale.particleMult) * impactScale
	local life = scaledLife(ctx, 0.32)
	local host = anchorPart(CFrame.new(pos))
	addLight(host, ctx.glow, (ctx.profile.lightBrightness or 2.8) * ctx.stepScale.lightMult, r * 2)
	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, ctx, "ImpactFlash", {
		rate = scaled(ctx, 32),
		speed = 14,
		size = 0.55,
		spread = 120,
		life = 0.28,
	})
	VfxAssets.TrySpawn(VfxConfig.AssetHooks.SlashImpact, CFrame.new(pos), folder, life + 0.1)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = ctx.primary
	ring.Size = Vector3.new(0.2, 0.5, 0.5)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.12
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.12, r * 2, r * 2),
		Transparency = 1,
	}):Play()
	fadeDestroy(ring, life + 0.05)
	fadeDestroy(host, life + 0.1)
end

--- Ground fan — readable cone telegraph
local function playAreaCone(
	origin: Vector3,
	look: Vector3,
	range: number,
	coneDeg: number,
	ctx: VfxConfig.VfxContext,
	life: number?
)
	local tele = VfxConfig.Profiles.Telegraph
	life = life or scaledLife(ctx, 0.52)
	local floor = raycastGround(origin)
	local forward = flatUnit(look)
	local half = coneDeg * 0.5
	local segs = math.clamp(math.floor(coneDeg / 5), 8, 18)
	local col = ctx.primary
	local fillT = tele.fillTransparency or 0.58
	local edgeT = tele.edgeTransparency or 0.1

	local left = rotateFlatY(forward, half)
	local right = rotateFlatY(forward, -half)

	local function edgeBeam(dir: Vector3)
		local len = range
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CanTouch = false
		beam.Material = Enum.Material.Neon
		beam.Color = col
		beam.Size = Vector3.new(0.14, 0.18, len)
		beam.CFrame = CFrame.lookAt(floor + Vector3.new(0, 0.06, 0), floor + dir * len + Vector3.new(0, 0.06, 0))
		beam.Transparency = edgeT
		beam.Parent = folder
		fadePart(beam, life, edgeT)
	end

	edgeBeam(left)
	edgeBeam(right)

	for i = 1, segs do
		local a0 = -half + (i - 1) * (coneDeg / segs)
		local a1 = -half + i * (coneDeg / segs)
		local mid = (a0 + a1) * 0.5
		local dir = rotateFlatY(forward, mid)
		local spanRad = math.rad(coneDeg / segs)
		local segW = math.max(0.35, range * math.tan(spanRad) * 1.05)

		local fill = Instance.new("Part")
		fill.Anchored = true
		fill.CanCollide = false
		fill.CanQuery = false
		fill.CanTouch = false
		fill.Material = Enum.Material.ForceField
		fill.Color = col
		fill.Size = Vector3.new(segW, 0.1, range * 0.96)
		fill.CFrame = CFrame.lookAt(floor, floor + dir) * CFrame.new(0, 0.05, -range * 0.48)
		fill.Transparency = fillT
		fill.Parent = folder
		fadePart(fill, life, fillT)
	end

	for i = 0, segs do
		local a = -half + i * (coneDeg / segs)
		local dir = rotateFlatY(forward, a)
		local tip = floor + dir * range + Vector3.new(0, 0.1, 0)
		local dot = Instance.new("Part")
		dot.Shape = Enum.PartType.Ball
		dot.Anchored = true
		dot.CanCollide = false
		dot.Material = Enum.Material.Neon
		dot.Color = col
		dot.Size = Vector3.new(0.45, 0.45, 0.45)
		dot.CFrame = CFrame.new(tip)
		dot.Transparency = 0.2
		dot.Parent = folder
		fadePart(dot, life * 0.85, 0.2)
	end

	local host = anchorPart(CFrame.new(floor + forward * (range * 0.55) + Vector3.new(0, 1.2, 0)))
	addLight(host, col, (tele.lightBrightness or 2.2) * ctx.stepScale.lightMult, range)
	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, ctx, "SparkBurst", { rate = 20, speed = 8, size = 0.4, spread = coneDeg * 0.35, life = 0.28 })
	fadeDestroy(host, life)
end

local function playAreaCircle(center: Vector3, radius: number, ctx: VfxConfig.VfxContext, life: number?)
	local tele = VfxConfig.Profiles.Telegraph
	life = life or scaledLife(ctx, 0.55)
	local floor = raycastGround(center)
	local col = ctx.primary
	local fillT = tele.fillTransparency or 0.58

	local disk = Instance.new("Part")
	disk.Shape = Enum.PartType.Cylinder
	disk.Anchored = true
	disk.CanCollide = false
	disk.CanQuery = false
	disk.CanTouch = false
	disk.Material = Enum.Material.ForceField
	disk.Color = col
	disk.Size = Vector3.new(0.12, radius * 2, radius * 2)
	disk.CFrame = CFrame.new(floor + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disk.Transparency = fillT
	disk.Parent = folder
	fadePart(disk, life, fillT)

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = col
	ring.Size = Vector3.new(0.22, math.max(1, radius * 0.4), math.max(1, radius * 0.4))
	ring.CFrame = CFrame.new(floor + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = tele.edgeTransparency or 0.15
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(life * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.14, radius * 2.15, radius * 2.15),
		Transparency = 1,
	}):Play()
	fadeDestroy(ring, life + 0.1)

	local host = anchorPart(CFrame.new(floor + Vector3.new(0, 1.5, 0)))
	addLight(host, col, (tele.lightBrightness or 3.5) * ctx.stepScale.lightMult, radius * 1.6)
	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, ctx, "SparkBurst", { rate = 24, speed = 10, size = 0.45, spread = 180, life = 0.3 })
	if ctx.isSupport then
		burstParticles(att, ctx, "HealMotes", { rate = 16, speed = 2.5, size = 0.45, spread = 180, life = 0.7 })
	else
		smokePuff(att, ctx, 8)
	end
	fadeDestroy(host, life)
end

local function playAreaLine(
	origin: Vector3,
	look: Vector3,
	range: number,
	halfWidth: number,
	ctx: VfxConfig.VfxContext,
	life: number?
)
	local tele = VfxConfig.Profiles.Telegraph
	life = life or scaledLife(ctx, 0.5)
	local floor = raycastGround(origin)
	local forward = flatUnit(look)
	local width = math.max(0.8, halfWidth * 2)
	local col = ctx.primary
	local fillT = tele.fillTransparency or 0.55

	local box = Instance.new("Part")
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.Material = Enum.Material.ForceField
	box.Color = col
	box.Size = Vector3.new(width, 0.12, range)
	box.CFrame = CFrame.lookAt(floor + Vector3.new(0, 0.06, 0), floor + forward * range + Vector3.new(0, 0.06, 0))
		* CFrame.new(0, 0, -range * 0.5)
	box.Transparency = fillT
	box.Parent = folder
	fadePart(box, life, fillT)

	for _, side in { -1, 1 } do
		local rail = Instance.new("Part")
		rail.Anchored = true
		rail.CanCollide = false
		rail.Material = Enum.Material.Neon
		rail.Color = col
		rail.Size = Vector3.new(0.14, 0.18, range)
		rail.CFrame = box.CFrame * CFrame.new(side * width * 0.5, 0.02, 0)
		rail.Transparency = tele.edgeTransparency or 0.1
		rail.Parent = folder
		fadePart(rail, life, tele.edgeTransparency or 0.1)
	end

	local endCap = Instance.new("Part")
	endCap.Anchored = true
	endCap.CanCollide = false
	endCap.Material = Enum.Material.Neon
	endCap.Color = col
	endCap.Size = Vector3.new(width, 0.16, 0.16)
	endCap.CFrame = CFrame.lookAt(floor + forward * range, floor + forward * (range + 1))
	endCap.Transparency = tele.edgeTransparency or 0.15
	endCap.Parent = folder
	fadePart(endCap, life, tele.edgeTransparency or 0.15)

	local host = anchorPart(CFrame.lookAt(floor + Vector3.new(0, 1.2, 0), floor + forward * range + Vector3.new(0, 1.2, 0)))
	addLight(host, col, (tele.lightBrightness or 2.8) * ctx.stepScale.lightMult, range * 0.6)
	local a0 = Instance.new("Attachment")
	a0.Parent = host
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, -range)
	a1.Parent = host
	addBeam(a0, a1, col)
	burstParticles(a1, ctx, "SparkBurst", { rate = 22, speed = 11, size = 0.42, spread = 35, life = 0.3 })
	fadeDestroy(host, life + 0.05)
end

local function playAreaTelegraph(fx: any, origin: Vector3, look: Vector3, ctx: VfxConfig.VfxContext, range: number, shape: string)
	if shape == "Cone" or shape == "AllyCone" then
		playAreaCone(origin, look, range, fx.coneDeg or 90, ctx)
	elseif shape == "Sphere" or shape == "AllySphere" or shape == "GroundSphere" then
		local center = origin
		if (shape == "AllySphere" or shape == "GroundSphere") and typeof(fx.aimPos) == "Vector3" then
			center = fx.aimPos
		end
		playAreaCircle(center, fx.radius or range, ctx)
	elseif shape == "Line" then
		playAreaLine(origin, look, range, fx.lineWidth or 3.5, ctx)
	elseif shape == "Grapple" and typeof(fx.hookPos) == "Vector3" then
		local hook = fx.hookPos
		local dir = hook - origin
		local dist = dir.Magnitude
		if dist > 0.5 then
			playAreaLine(origin, dir.Unit, dist, 1.2, ctx)
		end
		playAreaCircle(hook, 2.5, ctx)
	end
end

local function slashArc(
	origin: Vector3,
	look: Vector3,
	ctx: VfxConfig.VfxContext,
	opts: {
		arcDeg: number?,
		dist: number?,
		height: number?,
		segments: number?,
		thickness: number?,
		life: number?,
		pitchBias: number?,
		side: number?,
		impactAtEnd: boolean?,
	}
)
	local col = ctx.primary
	local arcDeg = opts.arcDeg or 80
	local dist = opts.dist or 6
	local height = opts.height or 1.1
	local segs = opts.segments or 8
	local thick = opts.thickness or 0.14
	local life = scaledLife(ctx, opts.life or 0.32)
	local pitchBias = math.rad(opts.pitchBias or 0)
	local side = opts.side or 1

	local basis = CFrame.lookAt(origin, origin + look)
	local startAng = -math.rad(arcDeg) * 0.5 * side
	local endAng = math.rad(arcDeg) * 0.5 * side

	local host = anchorPart(basis * CFrame.new(0, height, -dist * 0.15))
	addLight(host, ctx.glow, (ctx.profile.lightBrightness or 2.8) * ctx.stepScale.lightMult, ctx.profile.lightRange or 11)

	for i = 1, segs do
		local t0 = (i - 1) / segs
		local t1 = i / segs
		local a0 = startAng + (endAng - startAng) * t0
		local a1 = startAng + (endAng - startAng) * t1
		local mid = (a0 + a1) * 0.5
		local span = math.abs(a1 - a0)

		local wedge = Instance.new("WedgePart")
		wedge.Anchored = true
		wedge.CanCollide = false
		wedge.CanQuery = false
		wedge.CanTouch = false
		wedge.Material = Enum.Material.Neon
		wedge.Color = col
		wedge.Transparency = 0.15
		local width = math.max(0.8, dist * math.tan(span * 0.55) * 2)
		wedge.Size = Vector3.new(thick, width * 0.55, dist * 0.92)
		local localCf = CFrame.new(0, height * 0.15, 0)
			* CFrame.Angles(pitchBias, mid, 0)
			* CFrame.new(0, 0, -dist * 0.48)
			* CFrame.Angles(0, 0, math.rad(90))
		wedge.CFrame = basis * localCf
		wedge.Parent = folder

		wedge.Transparency = 0.85
		task.delay(t0 * life * 0.35, function()
			if wedge.Parent then
				TweenService:Create(wedge, TweenInfo.new(0.05), { Transparency = 0.12 }):Play()
				task.delay(life * 0.45, function()
					if wedge.Parent then
						TweenService:Create(wedge, TweenInfo.new(life * 0.4), { Transparency = 1 }):Play()
					end
				end)
			end
		end)
		fadeDestroy(wedge, life + 0.15)
	end

	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, ctx, "SparkBurst", {
		rate = scaled(ctx, 18 + segs * 2),
		speed = 9 + dist * 0.4,
		size = 0.4,
		spread = arcDeg * 0.4,
		life = 0.28,
	})
	fadeDestroy(host, life + 0.2)

	if opts.impactAtEnd or ctx.stepScale.impact then
		local hitPos = origin + look * dist * 0.75 + Vector3.new(0, height * 0.5, 0)
		playImpactRing(hitPos, ctx, dist * 0.35)
	end
end

local function stabLines(origin: Vector3, look: Vector3, ctx: VfxConfig.VfxContext, count: number, dist: number)
	local col = ctx.primary
	local basis = CFrame.lookAt(origin + Vector3.new(0, 1.2, 0), origin + look * dist + Vector3.new(0, 1.2, 0))
	for i = 1, count do
		local offset = Vector3.new((i - (count + 1) / 2) * 0.35, (i % 2) * 0.25, 0)
		local line = Instance.new("Part")
		line.Anchored = true
		line.CanCollide = false
		line.Material = Enum.Material.Neon
		line.Color = col
		line.Size = Vector3.new(0.12, 0.12, dist * (0.55 + i * 0.08))
		line.CFrame = basis * CFrame.new(offset) * CFrame.new(0, 0, -dist * 0.4)
		line.Transparency = 0.2
		line.Parent = folder
		TweenService:Create(line, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = line.CFrame * CFrame.new(0, 0, -dist * 0.25),
			Transparency = 1,
		}):Play()
		fadeDestroy(line, 0.28)
	end
end

local function smashRing(origin: Vector3, look: Vector3, ctx: VfxConfig.VfxContext, radius: number)
	local col = ctx.primary
	local hit = origin + look * (radius * 0.55) + Vector3.new(0, 0.15, 0)
	playImpactRing(hit, ctx, radius)
	local host = anchorPart(CFrame.new(hit))
	addLight(host, col, 4 * ctx.stepScale.lightMult, radius * 1.4)
	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, ctx, "SparkBurst", { rate = 40, speed = 14, size = 0.55, spread = 60, life = 0.35 })
	smokePuff(att, ctx, 14)
	fadeDestroy(host, 0.45)
end

local function playSlashFamily(fx: any, origin: Vector3, look: Vector3, ctx: VfxConfig.VfxContext, step: number, range: number)
	local fam = fx.family or "Sword1H"
	local dist = range * (0.5 + step * 0.1)

	if fam == "Dagger" then
		stabLines(origin, look, ctx, 2 + step, dist * 0.85)
		slashArc(origin, look, ctx, {
			arcDeg = 40 + step * 12,
			dist = dist * 0.7,
			segments = 5,
			thickness = 0.1,
			life = 0.22,
			pitchBias = -12,
			side = if step == 2 then -1 else 1,
		})
	elseif fam == "Mace1H" or fam == "Mace2H" then
		slashArc(origin, look, ctx, {
			arcDeg = 50 + step * 10,
			dist = dist * 0.75,
			segments = 6,
			thickness = 0.22,
			life = 0.28,
			pitchBias = 55 + step * 8,
			side = 1,
		})
		if step >= 2 then
			smashRing(origin, look, ctx, dist * 0.55)
		end
	elseif fam == "Axe1H" or fam == "Axe2H" then
		slashArc(origin, look, ctx, {
			arcDeg = 70 + step * 18,
			dist = dist,
			segments = 7 + step,
			thickness = 0.18,
			life = 0.34,
			pitchBias = 35 + step * 10,
			side = if step == 2 then -1 else 1,
		})
		if step == 3 then
			smashRing(origin, look, ctx, dist * 0.45)
		end
	elseif fam == "Scepter" then
		slashArc(origin, look, ctx, {
			arcDeg = 95 + step * 15,
			dist = dist * 1.05,
			segments = 9,
			thickness = 0.12,
			life = 0.3,
			pitchBias = 5,
			side = if step == 2 then -1 else 1,
		})
	else
		slashArc(origin, look, ctx, {
			arcDeg = 75 + step * 22,
			dist = dist,
			segments = 7 + step,
			thickness = 0.12 + step * 0.02,
			life = 0.28 + step * 0.03,
			pitchBias = if step == 3 then 18 else (if step == 2 then -8 else 5),
			side = if step == 2 then -1 else 1,
		})
	end
end

function CombatVfx.Play(fx: any)
	if typeof(fx) ~= "table" then
		return
	end
	if fx.vfx == "None" or fx.vfx == false then
		return
	end
	local ctx = VfxConfig.BuildContext(fx)
	local origin: Vector3 = fx.origin or Vector3.zero
	local look: Vector3 = fx.look or Vector3.new(0, 0, -1)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	look = look.Unit
	local col = ctx.primary
	local range = fx.range or 8
	local vfx = fx.vfx or "Slash"
	local step = ctx.step
	local fam = fx.family or ""
	local shape = resolveShape(fx, vfx)

	if shape and isAreaShape(shape) then
		playAreaTelegraph(fx, origin, look, ctx, range, shape)
	end

	if vfx == "Bolt" then
		if shape == "Line" then
			return
		end
		local tip = origin + look * math.clamp(range * 0.9, 6, 40) + Vector3.new(0, 1.3, 0)
		local start = origin + Vector3.new(0, 1.3, 0)
		local dist = (tip - start).Magnitude
		local host = anchorPart(CFrame.lookAt(start, tip))
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.zero
		a0.Parent = host
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 0, -dist)
		a1.Parent = host
		addBeam(a0, a1, col)
		addLight(host, col, (ctx.profile.lightBrightness or 3.2) * ctx.stepScale.lightMult, ctx.profile.lightRange or 14)
		burstParticles(a0, ctx, "MuzzleFlash", { rate = 14 + step * 4, speed = 5, size = 0.3, spread = 8, life = 0.25 })
		burstParticles(a1, ctx, "SparkBurst", { rate = 30 + step * 8, speed = 12, life = 0.45, size = 0.5, spread = 28 })
		smokePuff(a1, ctx, 5 + step)

		VfxAssets.TrySpawn(VfxConfig.AssetHooks.BoltStreak, CFrame.lookAt(start:Lerp(tip, 0.5), tip), folder, 0.25)
		local streak = Instance.new("Part")
		streak.Anchored = true
		streak.CanCollide = false
		streak.Material = Enum.Material.Neon
		streak.Color = col
		local thick = if fam == "Staff" then 0.28 else (if fam == "Crossbow" then 0.22 else 0.16)
		streak.Size = Vector3.new(thick + step * 0.04, thick, dist)
		streak.CFrame = CFrame.lookAt(start:Lerp(tip, 0.5), tip)
		streak.Transparency = 0.2
		streak.Parent = folder
		fadeDestroy(streak, scaledLife(ctx, 0.18 + step * 0.03))
		fadeDestroy(host, scaledLife(ctx, 0.42))

		local muzzle = anchorPart(CFrame.new(start))
		local matt = Instance.new("Attachment")
		matt.Parent = muzzle
		burstParticles(matt, ctx, "MuzzleFlash", { rate = 16, speed = 8, size = 0.35, spread = 40, life = 0.2 })
		fadeDestroy(muzzle, 0.3)

		playImpactRing(tip, ctx, 2.5 + step * 0.4)
	elseif vfx == "Slash" then
		if shape == "Cone" then
			return
		end
		playSlashFamily(fx, origin, look, ctx, step, range)
	elseif vfx == "Cone" then
		if shape == "Cone" or shape == "AllyCone" then
			if shape == "Cone" then
				local dist = range * (0.55 + step * 0.08)
				slashArc(origin, look, ctx, {
					arcDeg = fx.coneDeg or 90,
					dist = dist * 0.65,
					segments = 6,
					thickness = 0.1,
					life = 0.24,
					pitchBias = 8,
					side = 1,
				})
			end
			return
		end
		local arc = fx.coneDeg or 90
		local dist = range * (0.55 + step * 0.08)
		slashArc(origin, look, ctx, {
			arcDeg = arc,
			dist = dist,
			segments = 10,
			thickness = 0.11,
			life = 0.36,
			pitchBias = 0,
			side = 1,
			impactAtEnd = true,
		})
		local host = anchorPart(CFrame.lookAt(origin, origin + look * dist) + look * (dist * 0.4) + Vector3.new(0, 1, 0))
		local aMid = Instance.new("Attachment")
		aMid.Parent = host
		burstParticles(aMid, ctx, "SparkBurst", {
			rate = 28 + step * 10,
			speed = 11,
			size = 0.5,
			spread = arc * 0.45,
			life = 0.32,
		})
		smokePuff(aMid, ctx, 12)
		addLight(host, col, (ctx.profile.lightBrightness or 3) * ctx.stepScale.lightMult, 12)
		fadeDestroy(host, 0.45)
	elseif vfx == "Burst" then
		if shape == "Sphere" or shape == "AllySphere" then
			return
		end
		local r = (fx.radius or range)
		local host = anchorPart(CFrame.new(origin + Vector3.new(0, 1, 0)))
		addLight(host, col, (ctx.profile.lightBrightness or 5) * ctx.stepScale.lightMult, r * 1.5)
		local att = Instance.new("Attachment")
		att.Parent = host
		burstParticles(att, ctx, "SparkBurst", { rate = 55, speed = 18, size = 0.7, spread = 180 })
		smokePuff(att, ctx, 20)
		VfxAssets.TrySpawn(VfxConfig.AssetHooks.ReactionBurst, CFrame.new(origin + Vector3.new(0, 1, 0)), folder, 0.5)
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = col
		ring.Size = Vector3.new(0.35, 1, 1)
		ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.2
		ring.Parent = folder
		TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.2, r * 2, r * 2),
			Transparency = 1,
		}):Play()
		fadeDestroy(ring, 0.45)
		fadeDestroy(host, 0.55)
	elseif vfx == "Dash" then
		local tip = origin + look * (range * 0.5)
		local dist = (tip - origin).Magnitude
		local host = anchorPart(CFrame.lookAt(origin, tip))
		local a0 = Instance.new("Attachment")
		a0.Parent = host
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 0, -dist)
		a1.Parent = host
		local t0 = Instance.new("Attachment")
		t0.Position = Vector3.new(0, 0.4, 0)
		t0.Parent = host
		local t1 = Instance.new("Attachment")
		t1.Position = Vector3.new(0, -0.4, 0)
		t1.Parent = host
		addTrail(t0, t1, col, 0.4)
		burstParticles(a0, ctx, "SparkBurst", { rate = 30, speed = 12, size = 0.5, spread = 20 })
		smokePuff(a0, ctx, 8)
		addLight(host, col, (ctx.profile.lightBrightness or 2) * ctx.stepScale.lightMult, 10)
		fadeDestroy(host, 0.4)
	elseif vfx == "Aura" then
		local host = anchorPart(CFrame.new(origin + Vector3.new(0, 2, 0)))
		addLight(host, col, (ctx.profile.lightBrightness or 2.5) * ctx.stepScale.lightMult, 12)
		local att = Instance.new("Attachment")
		att.Parent = host
		local preset = if ctx.isSupport then "HealMotes" else "SparkBurst"
		burstParticles(att, ctx, preset, {
			rate = if ctx.isSupport then 28 else 40,
			speed = if ctx.isSupport then 2.5 else 3,
			size = 0.8,
			spread = 180,
			life = if ctx.isSupport then 0.8 else 0.6,
		})
		local shell = Instance.new("Part")
		shell.Shape = Enum.PartType.Ball
		shell.Anchored = true
		shell.CanCollide = false
		shell.Material = Enum.Material.ForceField
		shell.Color = col
		shell.Size = Vector3.new(5, 5, 5)
		shell.Position = origin + Vector3.new(0, 2, 0)
		shell.Transparency = if ctx.isSupport then 0.38 else 0.45
		shell.Parent = folder
		fadeDestroy(shell, 0.7)
		fadeDestroy(host, 0.7)
	end
end

function CombatVfx.CameraKick(intensity: number)
	cameraKick(intensity)
end

function CombatVfx.PlayReaction(reactionId: string, position: Vector3)
	local style = VfxConfig.ReactionStyle(reactionId)
	local col = VfxConfig.ReactionColor(reactionId)
	local scale = style.scale or 1
	local life = 0.55 + scale * 0.12

	local cf = CFrame.new(position + Vector3.new(0, 2.2, 0))
	if VfxAssets.TryReactionModel(reactionId, cf, folder, life + 0.2) then
		local host = anchorPart(cf)
		if style.label then
			UiTheme.BillboardLabel({
				parent = host,
				text = reactionId,
				color = col,
				textSize = UiTheme.TextSize.Heading,
			})
		end
		fadeDestroy(host, life + 0.3)
		return
	end

	local ctx = VfxConfig.BuildContext({ element = "Neutral", comboStep = 2, vfx = "Burst" })
	ctx.primary = col
	ctx.accent = col
	ctx.glow = col

	local host = anchorPart(cf)
	addLight(host, col, (style.flash or 42) * 0.12, 16 * scale)
	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, ctx, "SparkBurst", {
		rate = scaled(ctx, 48 * scale),
		speed = 16 * scale,
		life = 0.9,
		size = 0.7 * scale,
		spread = 180,
	})
	smokePuff(att, ctx, math.floor(16 * scale))

	VfxAssets.TrySpawn(VfxConfig.AssetHooks.ReactionBurst, cf, folder, life)

	local ringSize = (style.ring or 8) * scale
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Ball
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.ForceField
	ring.Color = col
	ring.Size = Vector3.new(1.2, 1.2, 1.2) * scale
	ring.Position = position + Vector3.new(0, 2.2, 0)
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(0.45), {
		Size = Vector3.new(ringSize, ringSize, ringSize),
		Transparency = 1,
	}):Play()

	if style.label then
		UiTheme.BillboardLabel({
			parent = host,
			text = reactionId,
			color = col,
			textSize = UiTheme.TextSize.Heading,
		})
	end

	fadeDestroy(ring, life)
	fadeDestroy(host, life + 0.1)
end

function CombatVfx.SprintDust(hrp: BasePart, stanceColor: Color3?)
	local col = stanceColor or Color3.fromRGB(200, 200, 200)
	local ctx = VfxConfig.BuildContext({ element = "Neutral", vfx = "Dash", comboStep = 1 })
	ctx.primary = col
	ctx.accent = col
	local host = anchorPart(hrp.CFrame * CFrame.new(0, -2.5, 0))
	local att = Instance.new("Attachment")
	att.Parent = host
	smokePuff(att, ctx, 5)
	burstParticles(att, ctx, "SparkBurst", { rate = 8, speed = 4, size = 0.35, life = 0.25, spread = 30 })
	fadeDestroy(host, 0.35)
end

return CombatVfx
