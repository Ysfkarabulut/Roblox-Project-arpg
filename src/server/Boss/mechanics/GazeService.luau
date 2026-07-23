--[[
	Monolith Gaze — LOS cover check, instant kill, beam pause hook.
]]

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local GazeService = {}

export type GazeHandle = {
	Stop: () -> (),
}

local function hasMonolithCover(bossPos: Vector3, playerPos: Vector3, monoliths: { BasePart }): boolean
	local dir = playerPos - bossPos
	local dist = dir.Magnitude
	if dist < 1 then
		return true
	end
	dir = dir.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = monoliths
	local result = workspace:Raycast(bossPos + dir * 2, dir * (dist - 2), params)
	return result ~= nil
end

function GazeService.RunCast(
	partyUserIds: { number },
	monoliths: { BasePart },
	onStart: () -> (),
	onEnd: () -> ()
)
	local def = BossEncounterConfig.Eye
	local castSec = def.gaze.castSec
	onStart()
	BossSync.FireTelegraph({ kind = "Gaze", duration = castSec })

	task.wait(castSec)

	local bossPos = BossEntityService.GetCenter()
	if bossPos then
		for _, userId in partyUserIds do
			local plr = game:GetService("Players"):GetPlayerByUserId(userId)
			local char = plr and plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and BossHazardService.IsAlive(plr :: Player) then
				if not hasMonolithCover(bossPos, hrp.Position, monoliths) then
					BossHazardService.InstantKill(plr :: Player)
				end
			end
		end
	end
	onEnd()
end

function GazeService.StartLoop(
	partyUserIds: { number },
	getPhase: () -> number,
	getMonoliths: () -> { BasePart },
	beamPause: { Pause: () -> (), Resume: () -> () }
): GazeHandle
	local running = true

	task.spawn(function()
		while running do
			if getPhase() < 2 then
				task.wait(1)
				continue
			end
			task.wait(BossEncounterConfig.Eye.monolith.cycleSec + 0.5)
			if not running then
				break
			end
			beamPause.Pause()
			GazeService.RunCast(partyUserIds, getMonoliths(), function() end, function()
				beamPause.Resume()
			end)
		end
	end)

	return {
		Stop = function()
			running = false
		end,
	}
end

return GazeService
