--[[
	Procedural boss arena — circular platform + spawn markers.
]]

local Workspace = game:GetService("Workspace")

local BossArenaBuilder = {}

export type ArenaHandle = {
	folder: Folder,
	center: Vector3,
	radius: number,
	spawnPoints: { CFrame },
}

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = true
	p.CanQuery = true
	p.CanTouch = true
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function BossArenaBuilder.Build(center: Vector3, radius: number): ArenaHandle
	local folder = Instance.new("Folder")
	folder.Name = "BossArena"
	folder.Parent = Workspace

	local floor = makePart(
		"Floor",
		Vector3.new(radius * 2, 2, radius * 2),
		CFrame.new(center + Vector3.new(0, -1, 0)),
		Color3.fromRGB(45, 48, 58),
		Enum.Material.Concrete
	)
	floor.Parent = folder

	local wallCount = 24
	for i = 1, wallCount do
		local ang = (i / wallCount) * math.pi * 2
		local pos = center + Vector3.new(math.cos(ang) * (radius - 2), 6, math.sin(ang) * (radius - 2))
		local wall = makePart(
			`Wall_{i}`,
			Vector3.new(8, 12, 3),
			CFrame.new(pos, center + Vector3.new(0, 6, 0)),
			Color3.fromRGB(35, 38, 48),
			Enum.Material.Basalt
		)
		wall.Parent = folder
	end

	local spawnPoints: { CFrame } = {}
	local spawnCount = 3
	for i = 1, spawnCount do
		local ang = ((i - 1) / spawnCount) * math.pi * 2 + math.pi
		local offset = Vector3.new(math.cos(ang) * (radius * 0.35), 3, math.sin(ang) * (radius * 0.35))
		local cf = CFrame.new(center + offset)
		spawnPoints[i] = cf
		local pad = makePart(
			`Spawn_{i}`,
			Vector3.new(6, 0.4, 6),
			cf * CFrame.new(0, -2.5, 0),
			Color3.fromRGB(70, 90, 110),
			Enum.Material.Neon
		)
		pad.Transparency = 0.4
		pad.CanCollide = false
		pad.Parent = folder
	end

	local centerMarker = makePart(
		"BossAnchor",
		Vector3.new(4, 0.5, 4),
		CFrame.new(center + Vector3.new(0, 0.25, 0)),
		Color3.fromRGB(120, 60, 60),
		Enum.Material.Neon
	)
	centerMarker.Transparency = 0.6
	centerMarker.CanCollide = false
	centerMarker.Parent = folder

	return {
		folder = folder,
		center = center,
		radius = radius,
		spawnPoints = spawnPoints,
	}
end

function BossArenaBuilder.Destroy(handle: ArenaHandle?)
	if handle and handle.folder and handle.folder.Parent then
		handle.folder:Destroy()
	end
end

return BossArenaBuilder
