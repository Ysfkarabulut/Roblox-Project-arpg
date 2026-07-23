--[[
	WoW-style arena greybox — floor, walls, corner pillars, team gates, spawn pads.
	Replace placeholder parts later with detailed models (same CFrame anchors).
]]

local Workspace = game:GetService("Workspace")

local PvpArenaConfig = require(game.ReplicatedStorage.Shared.Config.PvpArenaConfig)

local PvpArenaBuilder = {}

export type ArenaHandle = {
	folder: Folder,
	center: Vector3,
	bracket: PvpArenaConfig.Bracket,
	spawnPoints: { CFrame },
	gateParts: { BasePart },
	shrinkPart: BasePart?,
	destroy: () -> (),
}

local TEAM_COLORS = {
	Color3.fromRGB(70, 120, 200),
	Color3.fromRGB(200, 90, 70),
}

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?,
	parent: Instance,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.CFrame = props.cframe
	p.Anchored = true
	p.Color = props.color
	p.Material = props.material or Enum.Material.Concrete
	p.Transparency = props.transparency or 0
	p.CanCollide = if props.canCollide == nil then true else props.canCollide
	p.Parent = props.parent
	return p
end

local function buildWalls(folder: Folder, center: Vector3, sizeX: number, sizeZ: number, height: number)
	local halfX = sizeX / 2
	local halfZ = sizeZ / 2
	local wallThick = 2
	local y = center.Y + height / 2 - 1
	local specs = {
		{ "Wall_N", Vector3.new(sizeX + wallThick * 2, height, wallThick), CFrame.new(center.X, y, center.Z - halfZ - wallThick / 2) },
		{ "Wall_S", Vector3.new(sizeX + wallThick * 2, height, wallThick), CFrame.new(center.X, y, center.Z + halfZ + wallThick / 2) },
		{ "Wall_W", Vector3.new(wallThick, height, sizeZ), CFrame.new(center.X - halfX - wallThick / 2, y, center.Z) },
		{ "Wall_E", Vector3.new(wallThick, height, sizeZ), CFrame.new(center.X + halfX + wallThick / 2, y, center.Z) },
	}
	for _, spec in specs do
		makePart({
			name = spec[1],
			size = spec[2],
			cframe = spec[3],
			color = Color3.fromRGB(45, 48, 58),
			material = Enum.Material.Slate,
			parent = folder,
		})
	end
end

local function buildPillars(folder: Folder, center: Vector3, def: PvpArenaConfig.BracketDef)
	local halfX = def.floorSize.X / 2 - def.pillarRadius - 4
	local halfZ = def.floorSize.Y / 2 - def.pillarRadius - 4
	local offsets = {
		Vector3.new(-halfX, 0, -halfZ),
		Vector3.new(halfX, 0, -halfZ),
		Vector3.new(-halfX, 0, halfZ),
		Vector3.new(halfX, 0, halfZ),
	}
	for i = 1, math.min(def.pillarCount, #offsets) do
		local pos = center + offsets[i] + Vector3.new(0, def.pillarHeight / 2, 0)
		makePart({
			name = `Pillar_{i}`,
			size = Vector3.new(def.pillarRadius * 2, def.pillarHeight, def.pillarRadius * 2),
			cframe = CFrame.new(pos),
			color = Color3.fromRGB(82, 78, 72),
			material = Enum.Material.Brick,
			parent = folder,
		})
	end
end

local function teamSpawnCFrames(center: Vector3, def: PvpArenaConfig.BracketDef, teamIndex: number): { CFrame }
	local count = if def.bracket == "1v1" then 1 elseif def.bracket == "2v2" then 2 else 3
	local sign = if teamIndex == 1 then -1 else 1
	local back = sign * def.spawnBackOffset
	local spread = def.teamSpawnSpread
	local out: { CFrame } = {}
	local y = center.Y + 3
	if count == 1 then
		table.insert(out, CFrame.new(center + Vector3.new(0, 3, back)))
	else
		local xs = if count == 2 then { -spread / 2, spread / 2 } else { -spread, 0, spread }
		for _, x in xs do
			table.insert(out, CFrame.new(center + Vector3.new(x, 3, back)))
		end
	end
	return out
end

local function buildGate(folder: Folder, center: Vector3, teamIndex: number, def: PvpArenaConfig.BracketDef): { BasePart }
	local sign = if teamIndex == 1 then -1 else 1
	local gateZ = center.Z + sign * (def.spawnBackOffset - 4)
	local width = math.max(12, def.teamSpawnSpread + 8)
	local gate = makePart({
		name = `Gate_Team{teamIndex}`,
		size = Vector3.new(width, 10, 1.2),
		cframe = CFrame.new(center.X, center.Y + 4, gateZ),
		color = TEAM_COLORS[teamIndex],
		material = Enum.Material.Neon,
		transparency = 0.35,
		parent = folder,
	})
	return { gate }
end

function PvpArenaBuilder.Build(bracket: PvpArenaConfig.Bracket, center: Vector3): ArenaHandle
	local def = PvpArenaConfig.GetBracket(bracket)
	local folder = Instance.new("Folder")
	folder.Name = `Arena_{def.displayName:gsub(" ", "")}`
	folder.Parent = Workspace

	local sizeX = def.floorSize.X
	local sizeZ = def.floorSize.Y

	makePart({
		name = "Floor",
		size = Vector3.new(sizeX, 2, sizeZ),
		cframe = CFrame.new(center + Vector3.new(0, -1, 0)),
		color = Color3.fromRGB(58, 62, 72),
		material = Enum.Material.Concrete,
		parent = folder,
	})

	-- Center marker (placeholder for future asset)
	makePart({
		name = "CenterEmblem",
		size = Vector3.new(6, 0.3, 6),
		cframe = CFrame.new(center + Vector3.new(0, 0.2, 0)),
		color = Color3.fromRGB(90, 95, 110),
		material = Enum.Material.Metal,
		parent = folder,
	})

	buildWalls(folder, center, sizeX, sizeZ, def.wallHeight)
	buildPillars(folder, center, def)

	local spawnPoints: { CFrame } = {}
	local gateParts: { BasePart } = {}
	for teamIndex = 1, 2 do
		local teamSpawns = teamSpawnCFrames(center, def, teamIndex)
		for i, cf in teamSpawns do
			table.insert(spawnPoints, cf)
			makePart({
				name = `Spawn_T{teamIndex}_{i}`,
				size = Vector3.new(5, 0.25, 5),
				cframe = cf * CFrame.new(0, -2.8, 0),
				color = TEAM_COLORS[teamIndex],
				material = Enum.Material.Neon,
				transparency = 0.5,
				canCollide = false,
				parent = folder,
			})
		end
		for _, gate in buildGate(folder, center, teamIndex, def) do
			table.insert(gateParts, gate)
		end
	end

	local shrinkPart = makePart({
		name = "ShrinkZone",
		size = Vector3.new(sizeX - 4, 1, sizeZ - 4),
		cframe = CFrame.new(center + Vector3.new(0, 0.5, 0)),
		color = Color3.fromRGB(120, 40, 40),
		material = Enum.Material.Neon,
		transparency = 0.85,
		canCollide = false,
		parent = folder,
	})
	shrinkPart:SetAttribute("IsArenaShrink", true)

	local handle: ArenaHandle
	handle = {
		folder = folder,
		center = center,
		bracket = bracket,
		spawnPoints = spawnPoints,
		gateParts = gateParts,
		shrinkPart = shrinkPart,
		destroy = function()
			if folder.Parent then
				folder:Destroy()
			end
		end,
	}
	return handle
end

function PvpArenaBuilder.OpenGates(handle: ArenaHandle)
	for _, gate in handle.gateParts do
		if gate.Parent then
			gate.CanCollide = false
			gate.Transparency = 0.9
		end
	end
end

function PvpArenaBuilder.Destroy(handle: ArenaHandle?)
	if handle then
		handle.destroy()
	end
end

return PvpArenaBuilder
