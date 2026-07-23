--[[
	Boss place entry — TeleportData → BossEncounterService.
]]

local Players = game:GetService("Players")

local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
local BossEncounterService = require(script.Parent.BossEncounterService)

local BossMatchCoordinator = {}

function BossMatchCoordinator.OnPlayerAdded(player: Player)
	local data = player:GetJoinData().TeleportData
	if typeof(data) ~= "table" then
		return
	end
	if BossEncounterService.IsActive() then
		return
	end
	local teams = data.teams
	if typeof(teams) ~= "table" or #teams < 1 then
		return
	end
	local userIds: { number } = {}
	for _, team in teams do
		for _, id in team do
			if typeof(id) == "number" then
				table.insert(userIds, id)
			end
		end
	end
	if #userIds < 1 then
		return
	end
	BossEncounterService.Start({
		bossId = "eye",
		partyUserIds = userIds,
		partySize = math.clamp(#userIds, 1, 3),
	})
end

function BossMatchCoordinator.Start()
	if PlaceRuntime.GetRole() ~= "PveBossEye" then
		return
	end
	Players.PlayerAdded:Connect(BossMatchCoordinator.OnPlayerAdded)
	for _, plr in Players:GetPlayers() do
		task.defer(BossMatchCoordinator.OnPlayerAdded, plr)
	end
	print("[BossMatchCoordinator] Ready")
end

return BossMatchCoordinator
