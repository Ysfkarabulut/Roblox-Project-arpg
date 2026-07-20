--[[
	Rich combat VFX — ParticleEmitter, Trail, Beam, PointLight, neon parts.
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local AnimConfig = require(game.ReplicatedStorage.Shared.Config.AnimConfig)

local CombatVfx = {}

local folder = Instance.new("Folder")
folder.Name = "CombatVfxFolder"
folder.Parent = Workspace

local function colorOf(element: string?): Color3
	return AnimConfig.ElementColor[element or "Neutral"] or AnimConfig.ElementColor.Neutral
end

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

local function addLight(parent: Instance, col: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = col
	l.Brightness = brightness
	l.Range = range
	l.Parent = parent
	return l
end

local function burstParticles(att: Attachment, col: Color3, opts: {
	rate: number?,
	life: number?,
	speed: number?,
	size: number?,
	spread: number?,
	lightEmission: number?,
	texture: string?,
}?)
	opts = opts or {}
	local pe = Instance.new("ParticleEmitter")
	pe.Color = seq(col)
	pe.LightEmission = opts.lightEmission or 0.7
	pe.LightInfluence = 0.2
	pe.Size = numSeq(opts.size or 0.6, 0.05)
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(opts.life or 0.35, (opts.life or 0.35) * 1.4)
	pe.Speed = NumberRange.new((opts.speed or 8) * 0.6, opts.speed or 8)
	pe.SpreadAngle = Vector2.new(opts.spread or 25, opts.spread or 25)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-90, 90)
	pe.Acceleration = Vector3.new(0, -2, 0)
	pe.Drag = 2
	pe.Rate = 0
	pe.Texture = opts.texture or "rbxasset://textures/particles/sparkles_main.dds"
	pe.Parent = att
	pe:Emit(opts.rate or 28)
	return pe
end

local function smokePuff(att: Attachment, col: Color3, count: number?)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = seq(col:Lerp(Color3.new(1, 1, 1), 0.3))
	pe.LightEmission = 0.15
	pe.Size = numSeq(1.2, 2.5)
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(1, 4)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.Acceleration = Vector3.new(0, 3, 0)
	pe.Drag = 3
	pe.Rate = 0
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Parent = att
	pe:Emit(count or 12)
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
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureSpeed = 3
	beam.TextureLength = 2
	beam.Parent = a0.Parent
	return beam
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

function CombatVfx.Play(fx: any)
	if typeof(fx) ~= "table" then
		return
	end
	local origin: Vector3 = fx.origin or Vector3.zero
	local look: Vector3 = fx.look or Vector3.new(0, 0, -1)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	look = look.Unit
	local col = colorOf(fx.element)
	local range = fx.range or 8
	local vfx = fx.vfx or "Slash"
	local step = fx.comboStep or 1

	if vfx == "Bolt" then
		local tip = origin + look * math.clamp(range * 0.9, 6, 40)
		local dist = (tip - origin).Magnitude
		local host = anchorPart(CFrame.lookAt(origin, tip))
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.zero
		a0.Parent = host
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 0, -dist)
		a1.Parent = host
		addBeam(a0, a1, col)
		addLight(host, col, 3, 14)
		burstParticles(a0, col, { rate = 18, speed = 6, size = 0.35, spread = 0.4, spread = 12 })
		burstParticles(a1, col, { rate = 36, speed = 14, size = 0.5, size = 0.55, spread = 35 })
		smokePuff(a1, col, 6)
		-- streak part
		local streak = Instance.new("Part")
		streak.Anchored = true
		streak.CanCollide = false
		streak.Material = Enum.Material.Neon
		streak.Color = col
		streak.Size = Vector3.new(0.2 + step * 0.05, 0.2, dist)
		streak.CFrame = CFrame.lookAt(origin:Lerp(tip, 0.5), tip)
		streak.Transparency = 0.25
		streak.Parent = folder
		fadeDestroy(streak, 0.2)
		fadeDestroy(host, 0.45)
	elseif vfx == "Slash" or vfx == "Cone" then
		local arc = if vfx == "Cone" then (fx.coneDeg or 90) else (55 + step * 22)
		local dist = range * (0.55 + step * 0.08)
		local host = anchorPart(CFrame.lookAt(origin, origin + look * dist) + look * (dist * 0.45))
		addLight(host, col, 2.5 + step * 0.4, 10 + step * 2)
		local aMid = Instance.new("Attachment")
		aMid.Parent = host
		burstParticles(aMid, col, {
			rate = 22 + step * 10,
			speed = 10 + step * 3,
			size = 0.45 + step * 0.1,
			spread = arc * 0.5,
			life = 0.3,
		})
		-- trail slash ribbon
		local p0 = anchorPart(CFrame.new(origin + look * 1.5 + Vector3.new(0, 1.2, 0)))
		local p1 = anchorPart(CFrame.new(origin + look * dist + Vector3.new(0, 0.4, 0)))
		local t0 = Instance.new("Attachment")
		t0.Parent = p0
		local t1 = Instance.new("Attachment")
		t1.Parent = p1
		addTrail(t0, t1, col, 0.35)
		local blade = Instance.new("Part")
		blade.Anchored = true
		blade.CanCollide = false
		blade.Material = Enum.Material.Neon
		blade.Color = col
		blade.Transparency = 0.35
		local w = math.rad(arc)
		blade.Size = Vector3.new(math.clamp(dist * math.tan(w / 2) * 2, 2.5, 16), 0.12 + step * 0.04, dist)
		blade.CFrame = CFrame.lookAt(origin + look * (dist / 2 + 1), origin + look * dist)
		blade.Parent = folder
		if vfx == "Cone" then
			smokePuff(aMid, col, 10)
		end
		fadeDestroy(blade, 0.28)
		fadeDestroy(host, 0.4)
		fadeDestroy(p0, 0.4)
		fadeDestroy(p1, 0.4)
	elseif vfx == "Burst" then
		local r = (fx.radius or range)
		local host = anchorPart(CFrame.new(origin + Vector3.new(0, 1, 0)))
		addLight(host, col, 5, r * 1.5)
		local att = Instance.new("Attachment")
		att.Parent = host
		burstParticles(att, col, { rate = 55, speed = 18, size = 0.8, spread = 0.7, spread = 180 })
		smokePuff(att, col, 20)
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
		local host = anchorPart(CFrame.lookAt(origin, tip))
		local a0 = Instance.new("Attachment")
		a0.Parent = host
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 0, -dist)
		a1.Parent = host
		addTrail(
			(function()
				local x = Instance.new("Attachment")
				x.Position = Vector3.new(0, 0.4, 0)
				x.Parent = host
				return x
			end)(),
			(function()
				local x = Instance.new("Attachment")
				x.Position = Vector3.new(0, -0.4, 0)
				x.Parent = host
				return x
			end)(),
			col,
			0.4
		)
		burstParticles(a0, col, { rate = 30, speed = 12, size = 0.45, spread = 0.5, spread = 20 })
		smokePuff(a0, col, 8)
		addLight(host, col, 2, 10)
		fadeDestroy(host, 0.4)
	elseif vfx == "Aura" then
		local host = anchorPart(CFrame.new(origin + Vector3.new(0, 2, 0)))
		addLight(host, col, 2.5, 12)
		local att = Instance.new("Attachment")
		att.Parent = host
		local pe = Instance.new("ParticleEmitter")
		pe.Color = seq(col)
		pe.LightEmission = 0.8
		pe.Size = numSeq(0.8, 0.1)
		pe.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		pe.Lifetime = NumberRange.new(0.6, 1.0)
		pe.Speed = NumberRange.new(1, 3)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Acceleration = Vector3.new(0, 4, 0)
		pe.Rate = 40
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Parent = att
		local shell = Instance.new("Part")
		shell.Shape = Enum.PartType.Ball
		shell.Anchored = true
		shell.CanCollide = false
		shell.Material = Enum.Material.ForceField
		shell.Color = col
		shell.Size = Vector3.new(5, 5, 5)
		shell.Position = origin + Vector3.new(0, 2, 0)
		shell.Transparency = 0.45
		shell.Parent = folder
		fadeDestroy(shell, 0.7)
		fadeDestroy(host, 0.7)
	end
end

function CombatVfx.PlayReaction(reactionId: string, position: Vector3)
	local col = AnimConfig.ReactionColor[reactionId] or Color3.fromRGB(255, 255, 200)
	local host = anchorPart(CFrame.new(position + Vector3.new(0, 2.2, 0)))
	addLight(host, col, 6, 16)
	local att = Instance.new("Attachment")
	att.Parent = host
	burstParticles(att, col, { rate = 48, speed = 16, size = 0.9, size = 0.7, spread = 180 })
	smokePuff(att, col, 16)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Ball
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.ForceField
	ring.Color = col
	ring.Size = Vector3.new(1.2, 1.2, 1.2)
	ring.Position = position + Vector3.new(0, 2.2, 0)
	ring.Parent = folder
	TweenService:Create(ring, TweenInfo.new(0.45), {
		Size = Vector3.new(9, 9, 9),
		Transparency = 1,
	}):Play()
	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(140, 28)
	bill.StudsOffset = Vector3.new(0, 2.5, 0)
	bill.AlwaysOnTop = true
	bill.Parent = host
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = col
	t.TextStrokeTransparency = 0.5
	t.Text = reactionId
	t.Parent = bill
	fadeDestroy(ring, 0.5)
	fadeDestroy(host, 0.65)
end

--- Foot dust while sprinting (stance-tinted)
function CombatVfx.SprintDust(hrp: BasePart, stanceColor: Color3?)
	local col = stanceColor or Color3.fromRGB(200, 200, 200)
	local host = anchorPart(hrp.CFrame * CFrame.new(0, -2.5, 0))
	local att = Instance.new("Attachment")
	att.Parent = host
	smokePuff(att, col, 5)
	burstParticles(att, col, { rate = 8, speed = 4, size = 0.35, life = 0.25, spread = 30, lightEmission = 0.2 })
	fadeDestroy(host, 0.35)
end

return CombatVfx
