--[[
	Cataclysm Slam — boss-centered AoE, everyone must leave (P3).
]]

local Players = game:GetService("Players")

local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local CataclysmSlamService = {}

export type SlamCfg = {
	intervalSec: number?,
	firstDelaySec: number?,
	telegraphSec: number?,
	radiusStud: number?,
	damage: number?,
}

export type SlamHandle = {
	Stop: () -> (),
}

function CataclysmSlamService.Start(partyUserIds: { number }, slamCfg: SlamCfg, getPhase: (() -> number)?): SlamHandle
	local cfg = slamCfg or {}
	local running = true
	local interval = cfg.intervalSec or 16
	local telegraphSec = cfg.telegraphSec or 2.75
	local radius = cfg.radiusStud or 26
	local damage = cfg.damage or 140
	local nextAt = os.clock() + (cfg.firstDelaySec or 10)

	task.spawn(function()
		while running do
			task.wait(0.15)
			if not running then
				continue
			end
			if os.clock() < nextAt then
				continue
			end
			if getPhase and getPhase() < 3 then
				nextAt = os.clock() + 1
				continue
			end
			nextAt = os.clock() + interval

			local center = BossEntityService.GetCenter()
			if not center then
				continue
			end

			BossEntityService.SetMovementPaused(true)
			local hum = BossEntityService.GetHumanoid()
			if hum then
				hum:Move(Vector3.zero, false)
			end

			BossSync.FireTelegraph({
				kind = "CataclysmSlam",
				origin = center,
				radius = radius,
				duration = telegraphSec,
			})

			task.wait(telegraphSec)
			if not running then
				BossEntityService.SetMovementPaused(false)
				continue
			end

			center = BossEntityService.GetCenter() or center
			for _, userId in partyUserIds do
				local plr = Players:GetPlayerByUserId(userId)
				if plr and BossHazardService.IsAlive(plr) then
					local char = plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						local flat = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z)
						if flat.Magnitude <= radius then
							BossHazardService.ApplyBossDirectHit(plr, damage, center)
						end
					end
				end
			end

			BossEntityService.SetMovementPaused(false)
		end
	end)

	return {
		Stop = function()
			running = false
			BossEntityService.SetMovementPaused(false)
		end,
	}
end

return CataclysmSlamService
