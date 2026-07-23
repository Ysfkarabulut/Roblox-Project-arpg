--[[
	Dungeon run lifecycle stub — trash rooms then boss handoff.
]]

local Workspace = game:GetService("Workspace")

local DungeonConfig = require(game.ReplicatedStorage.Shared.Config.DungeonConfig)
local BossEncounterService = require(script.Parent.Parent.Boss.BossEncounterService)

local DungeonRunService = {}

local active = false

function DungeonRunService.IsActive(): boolean
	return active
end

local function buildRoom(index: number, center: Vector3)
	local folder = Instance.new("Folder")
	folder.Name = `DungeonRoom_{index}`
	folder.Parent = Workspace

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = DungeonConfig.RoomSize
	floor.CFrame = CFrame.new(center)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(55, 58, 68)
	floor.Parent = folder

	for t = 1, DungeonConfig.TrashPerRoom do
		local trash = Instance.new("Part")
		trash.Name = `Trash_{t}`
		trash.Size = Vector3.new(3, 5, 3)
		trash.CFrame = CFrame.new(center + Vector3.new((t - 1.5) * 8, 3, 10))
		trash.Anchored = true
		trash.Color = Color3.fromRGB(120, 60, 60)
		trash:SetAttribute("IsCombatDummy", true)
		trash.Parent = folder
	end
	return folder
end

function DungeonRunService.Start(partyUserIds: { number }): boolean
	if active then
		return false
	end
	active = true
	local base = Vector3.new(0, 5, 300)
	for i = 1, DungeonConfig.RoomCount do
		buildRoom(i, base + Vector3.new((i - 1) * 70, 0, 0))
	end
	print("[DungeonRun] Started greybox rooms — handoff to boss")
	active = false
	BossEncounterService.Start({
		bossId = DungeonConfig.BossId,
		partyUserIds = partyUserIds,
		partySize = math.clamp(#partyUserIds, 1, 3),
	})
	return true
end

return DungeonRunService
