--[[
	The Eye boss FSM — phase transitions + mechanic lifecycle.
]]

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.BossEntityService)
local BossSync = require(script.Parent.BossSync)
local RotatingBeamService = require(script.Parent.mechanics.RotatingBeamService)
local MonolithService = require(script.Parent.mechanics.MonolithService)
local GazeService = require(script.Parent.mechanics.GazeService)
local TentacleService = require(script.Parent.mechanics.TentacleService)

local EyeBossController = {}

export type ControllerHandle = {
	Stop: () -> (),
}

function EyeBossController.Start(
	bossId: string,
	partyUserIds: { number },
	arenaCenter: Vector3,
	arenaRadius: number
): ControllerHandle
	local def = BossEncounterConfig.Get(bossId)
	if not def then
		error("Unknown boss")
	end

	local phase = 1
	local running = true
	local gazePaused = false

	local function getPhase()
		return phase
	end

	local function isBeamPaused()
		return gazePaused
	end

	local beam = RotatingBeamService.Start(partyUserIds, getPhase, isBeamPaused)
	local monolith = MonolithService.Start(partyUserIds, arenaCenter, arenaRadius, getPhase)
	local gaze = GazeService.StartLoop(partyUserIds, getPhase, function()
		return monolith.GetActiveMonoliths()
	end, {
		Pause = function()
			gazePaused = true
			beam.Pause()
		end,
		Resume = function()
			gazePaused = false
			beam.Resume()
		end,
	})
	local tentacle = TentacleService.Start(partyUserIds, getPhase)

	local function broadcastState()
		local hp, maxHp = BossEntityService.GetHp()
		BossSync.FireState({
			bossId = bossId,
			phase = phase,
			hp = hp,
			maxHp = maxHp,
			active = true,
		})
	end

	BossEntityService.SetOnHpChanged(function(hp, maxHp, _)
		local pct = if maxHp > 0 then hp / maxHp else 0
		local newPhase = phase
		if pct <= def.phase3Pct then
			newPhase = 3
		elseif pct <= def.phase2Pct then
			newPhase = 2
		else
			newPhase = 1
		end
		if newPhase ~= phase then
			phase = newPhase
			BossEntityService.SetPhase(phase)
			print(`[EyeBoss] Phase {phase} ({math.floor(pct * 100)}% HP)`)
			BossSync.FireTelegraph({ kind = "Phase", phase = phase })
		end
		broadcastState()
	end)

	broadcastState()

	return {
		Stop = function()
			if not running then
				return
			end
			running = false
			beam.Stop()
			monolith.Stop()
			gaze.Stop()
			tentacle.Stop()
			BossSync.FireState({ active = false })
		end,
	}
end

return EyeBossController
