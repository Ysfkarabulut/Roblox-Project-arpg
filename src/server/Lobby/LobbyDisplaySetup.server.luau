--[[
	Lobby world displays — PvE + PvP leaderboard screens in Workspace.
	Studio can replace/move parts under Lobby.Displays; defaults spawn flanking spawn.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)

if not PlaceRuntime.IsLobby() then
	return
end

local DISPLAY_TAG = "LeaderboardDisplay"
local SCREEN_PVE = "LeaderboardScreenPvE"
local SCREEN_PVP = "LeaderboardScreenPvP"

local SCREEN_SIZE = Vector3.new(28, 16, 0.45)
local SCREEN_OFFSETS = {
	PvE = Vector3.new(-19, 7, -28),
	PvP = Vector3.new(19, 7, -28),
}

local function anchorCFrame(offset: Vector3): CFrame
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		return spawn.CFrame * CFrame.new(offset)
	end
	return CFrame.new(offset + Vector3.new(0, 2, -4))
end

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Color = color
	part.Material = material
	return part
end

local function ensureScreen(displays: Folder, screenName: string, kind: string, offset: Vector3, accentColor: Color3)
	local existing = displays:FindFirstChild(screenName)
	if existing and existing:IsA("BasePart") then
		existing:SetAttribute("DisplayKind", kind)
		if not CollectionService:HasTag(existing, DISPLAY_TAG) then
			CollectionService:AddTag(existing, DISPLAY_TAG)
		end
		return
	end

	local cf = anchorCFrame(offset)
	local bezelSize = Vector3.new(SCREEN_SIZE.X + 1.2, SCREEN_SIZE.Y + 1.2, 0.35)

	local bezel = makePart(
		`{screenName}Bezel`,
		bezelSize,
		cf * CFrame.new(0, 0, -0.35),
		Color3.fromRGB(12, 14, 18),
		Enum.Material.Metal
	)
	bezel.Parent = displays

	local screen = makePart(screenName, SCREEN_SIZE, cf, Color3.fromRGB(8, 10, 14), Enum.Material.SmoothPlastic)
	screen:SetAttribute("DisplayKind", kind)
	screen.Parent = displays
	CollectionService:AddTag(screen, DISPLAY_TAG)

	local accent = makePart(
		`{screenName}Accent`,
		Vector3.new(SCREEN_SIZE.X - 2, 0.16, 0.12),
		cf * CFrame.new(0, SCREEN_SIZE.Y * 0.5 - 0.45, -0.28),
		accentColor,
		Enum.Material.Neon
	)
	accent.Parent = displays
end

local lobbyFolder = workspace:FindFirstChild("Lobby")
if not lobbyFolder then
	lobbyFolder = Instance.new("Folder")
	lobbyFolder.Name = "Lobby"
	lobbyFolder.Parent = workspace
end

local displays = lobbyFolder:FindFirstChild("Displays")
if not displays then
	displays = Instance.new("Folder")
	displays.Name = "Displays"
	displays.Parent = lobbyFolder
end

ensureScreen(displays, SCREEN_PVE, "PvE", SCREEN_OFFSETS.PvE, Color3.fromRGB(90, 170, 120))
ensureScreen(displays, SCREEN_PVP, "PvP", SCREEN_OFFSETS.PvP, Color3.fromRGB(255, 200, 90))

print("[LobbyDisplaySetup] PvE + PvP leaderboard screens ready under Workspace.Lobby.Displays")
