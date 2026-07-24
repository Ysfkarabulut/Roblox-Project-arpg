--[[
	The Breaker boss FSM — pursuit, aggro strike, rust mark, charge, slam.
	MODES.md §4.7
]]

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.BossEntityService)
local BossMovementService = require(script.Parent.BossMovementService)
local BossSync = require(script.Parent.BossSync)
local AggroStrikeService = require(script.Parent.mechanics.AggroStrikeService)
local RustMarkService = require(script.Parent.mechanics.RustMarkService)
local ShoulderChargeService = require(script.Parent.mechanics.ShoulderChargeService)
local CataclysmSlamService = require(script.Parent.mechanics.CataclysmSlamService)

local BreakerBossController = {}

export type ControllerHandle = {
	Stop: () -> (),
}

function BreakerBossController.Start(
	bossId: string,
	partyUserIds: { number },
	_arenaCenter: Vector3,
	_arenaRadius: number
): ControllerHandle
	local def = BossEncounterConfig.Get(bossId)
	if not def then
		error("Unknown boss")
	end

	local phase = 1
	local running = true

	local function getPhase()
		return phase
	end

	local movement = BossMovementService.Start(def.movement)
	local strike = AggroStrikeService.Start(partyUserIds, getPhase, def.aggroStrike, "AggroStrike")
	local rust = RustMarkService.Start(partyUserIds, def.rustMark)
	local charge = ShoulderChargeService.Start(partyUserIds, def.shoulderCharge, getPhase)
	local slam = CataclysmSlamService.Start(partyUserIds, def.cataclysmSlam, getPhase)

	local function broadcastState()
		local hp, maxHp = BossEntityService.GetHp()
		BossSync.FireState({
			bossId = bossId,
			displayName = def.displayName,
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
			print(`[BreakerBoss] Phase {phase} ({math.floor(pct * 100)}% HP)`)
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
			movement.Stop()
			strike.Stop()
			rust.Stop()
			charge.Stop()
			slam.Stop()
			BossSync.FireState({ active = false })
		end,
	}
end

return BreakerBossController
