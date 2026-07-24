--[[
	Shoulder Charge — farthest player, line telegraph + boss dash (P2+).
]]

local Players = game:GetService("Players")

local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local ShoulderChargeService = {}

export type ChargeCfg = {
	intervalSec: number?,
	firstDelaySec: number?,
	telegraphSec: number?,
	chargeSec: number?,
	pathRadiusStud: number?,
	damage: number?,
	stopStudBeforeTarget: number?,
}

export type ChargeHandle = {
	Stop: () -> (),
}

function ShoulderChargeService.Start(partyUserIds: { number }, chargeCfg: ChargeCfg, getPhase: (() -> number)?): ChargeHandle
	local cfg = chargeCfg or {}
	local running = true
	local interval = cfg.intervalSec or 18
	local telegraphSec = cfg.telegraphSec or 1.5
	local chargeSec = cfg.chargeSec or 0.55
	local pathRadius = cfg.pathRadiusStud or 5
	local damage = cfg.damage or 70
	local stopBefore = cfg.stopStudBeforeTarget or 4
	local nextAt = os.clock() + (cfg.firstDelaySec or 14)

	task.spawn(function()
		while running do
			task.wait(0.15)
			if not running then
				continue
			end
			if os.clock() < nextAt then
				continue
			end
			if getPhase and getPhase() < 2 then
				nextAt = os.clock() + 1
				continue
			end
			nextAt = os.clock() + interval

			local origin = BossEntityService.GetCenter()
			if not origin then
				continue
			end

			local target = BossHazardService.FarthestPlayer(origin, partyUserIds)
			if not target or not BossHazardService.IsAlive(target) then
				continue
			end

			local char = target.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end

			local targetPos = hrp.Position
			BossSync.FireTelegraph({
				kind = "ShoulderCharge",
				targetUserId = target.UserId,
				origin = origin,
				targetPos = targetPos,
				duration = telegraphSec,
			})

			task.wait(telegraphSec)
			if not running then
				continue
			end

			local model = BossEntityService.GetModel()
			if not model or not model.PrimaryPart then
				continue
			end

			origin = model.PrimaryPart.Position
			local flat = Vector3.new(targetPos.X - origin.X, 0, targetPos.Z - origin.Z)
			if flat.Magnitude < 0.5 then
				continue
			end
			local dir = flat.Unit
			local endPos = origin + dir * math.max(0, flat.Magnitude - stopBefore)
			endPos = Vector3.new(endPos.X, origin.Y, endPos.Z)

			BossEntityService.SetMovementPaused(true)
			local hum = BossEntityService.GetHumanoid()
			if hum then
				hum:Move(Vector3.zero, false)
			end

			local startCf = model:GetPivot()
			local endCf = CFrame.lookAt(endPos, endPos + dir)
			local t0 = os.clock()
			local hitOnce: { [number]: boolean } = {}
			while os.clock() - t0 < chargeSec do
				if not running or not model.Parent then
					break
				end
				local alpha = math.clamp((os.clock() - t0) / chargeSec, 0, 1)
				local pos = startCf.Position:Lerp(endPos, alpha)
				local cf = CFrame.lookAt(pos, pos + dir)
				model:PivotTo(cf)

				for _, userId in partyUserIds do
					local plr = Players:GetPlayerByUserId(userId)
					if plr and BossHazardService.IsAlive(plr) then
						local c = plr.Character
						local p = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
						if p then
							local toPath = p.Position - pos
							local along = toPath:Dot(dir)
							local perp = (toPath - dir * along).Magnitude
							if along >= -2 and along <= 6 and perp <= pathRadius then
								if not hitOnce[userId] then
									hitOnce[userId] = true
									BossHazardService.ApplyBossDirectHit(plr, damage, pos)
								end
							end
						end
					end
				end
				task.wait()
			end
			model:PivotTo(endCf)
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

return ShoulderChargeService
