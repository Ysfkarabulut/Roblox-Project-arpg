--[[
	Boss telegraph VFX — beams, monolith warnings (placeholder parts).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:WaitForChild("BossRemotes")
local BossTelegraph = remotes:WaitForChild("BossTelegraph") :: RemoteEvent

local vfxFolder: Folder? = nil

local function ensureFolder(): Folder
	if vfxFolder and vfxFolder.Parent then
		return vfxFolder
	end
	local f = Instance.new("Folder")
	f.Name = "BossVfxClient"
	f.Parent = Workspace
	vfxFolder = f
	return f
end

local function clearBeams()
	local folder = ensureFolder()
	for _, c in folder:GetChildren() do
		if c.Name == "BeamLine" then
			c:Destroy()
		end
	end
end

local function drawBeam(center: Vector3, angle: number, halfThickness: number, length: number, duration: number)
	local folder = ensureFolder()
	local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local part = Instance.new("Part")
	part.Name = "BeamLine"
	part.Size = Vector3.new(halfThickness * 2, 0.6, length)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 80, 80)
	part.Transparency = 0.35
	part.CFrame = CFrame.lookAt(center + dir * (length / 2), center + dir * (length / 2) + dir)
	part.Parent = folder
	task.delay(duration, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

BossTelegraph.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.kind == "Beam" then
		clearBeams()
		local center = if typeof(payload.center) == "Vector3" then payload.center else Vector3.zero
		local lineCount = if typeof(payload.lineCount) == "number" then payload.lineCount else 1
		local angle = if typeof(payload.angle) == "number" then payload.angle else 0
		local duration = if typeof(payload.duration) == "number" then payload.duration else 5
		local length = 180
		local half = 2.5
		drawBeam(center, angle, half, length, duration)
		if lineCount >= 2 then
			drawBeam(center, angle + math.pi / 2, half, length, duration)
		end
		if lineCount >= 4 then
			drawBeam(center, angle + math.pi / 4, half, length, duration)
			drawBeam(center, angle - math.pi / 4, half, length, duration)
		end
	elseif payload.kind == "MonolithTelegraph" then
		local pos = if typeof(payload.position) == "Vector3" then payload.position else nil
		local radius = if typeof(payload.radius) == "number" then payload.radius else 5
		local duration = if typeof(payload.duration) == "number" then payload.duration else 1
		if not pos then
			return
		end
		local folder = ensureFolder()
		local warn = Instance.new("Part")
		warn.Name = "MonolithWarn"
		warn.Shape = Enum.PartType.Cylinder
		warn.Size = Vector3.new(0.5, radius * 2, radius * 2)
		warn.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		warn.Anchored = true
		warn.CanCollide = false
		warn.Color = Color3.fromRGB(255, 60, 60)
		warn.Material = Enum.Material.Neon
		warn.Transparency = 0.4
		warn.Parent = folder
		TweenService:Create(warn, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Transparency = 0.75,
		}):Play()
		task.delay(duration, function()
			if warn.Parent then
				warn:Destroy()
			end
		end)
	end
end)
