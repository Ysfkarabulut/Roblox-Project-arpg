--[[
	Rust Mark — random party target, foot circle (P1+).
]]

local Players = game:GetService("Players")

local BossAggroService = require(script.Parent.Parent.BossAggroService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local RustMarkService = {}

export type RustCfg = {
	intervalSec: number?,
	firstDelaySec: number?,
	telegraphSec: number?,
	radiusStud: number?,
	damage: number?,
	tankWeight: number?,
}

export type RustHandle = {
	Stop: () -> (),
}

local function pickTarget(partyUserIds: { number }, tankWeight: number): Player?
	local tank = BossAggroService.GetThreatTarget()
	local pool: { { plr: Player, w: number } } = {}
	for _, userId in partyUserIds do
		local plr = Players:GetPlayerByUserId(userId)
		if plr and BossHazardService.IsAlive(plr) then
			local w = 1
			if tank and tank.UserId == userId then
				w = tankWeight
			end
			table.insert(pool, { plr = plr, w = w })
		end
	end
	if #pool == 0 then
		return nil
	end
	local total = 0
	for _, e in pool do
		total += e.w
	end
	local roll = math.random() * total
	local acc = 0
	for _, e in pool do
		acc += e.w
		if roll <= acc then
			return e.plr
		end
	end
	return pool[#pool].plr
end

function RustMarkService.Start(partyUserIds: { number }, rustCfg: RustCfg): RustHandle
	local cfg = rustCfg or {}
	local running = true
	local interval = cfg.intervalSec or 12
	local telegraphSec = cfg.telegraphSec or 1.2
	local radius = cfg.radiusStud or 6
	local damage = cfg.damage or 55
	local tankWeight = cfg.tankWeight or 0.15
	local nextAt = os.clock() + (cfg.firstDelaySec or 8)

	task.spawn(function()
		while running do
			task.wait(0.15)
			if not running or not BossAggroService.IsActive() then
				continue
			end
			if os.clock() < nextAt then
				continue
			end
			nextAt = os.clock() + interval

			local target = pickTarget(partyUserIds, tankWeight)
			if not target or not BossHazardService.IsAlive(target) then
				continue
			end

			local char = target.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end

			local markPos = hrp.Position
			BossSync.FireTelegraph({
				kind = "RustMark",
				targetUserId = target.UserId,
				position = markPos,
				radius = radius,
				duration = telegraphSec,
			})

			task.wait(telegraphSec)
			if not running or not BossAggroService.IsAlive(target) then
				continue
			end

			local hrp2 = target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp2 then
				continue
			end
			local flat = Vector3.new(hrp2.Position.X - markPos.X, 0, hrp2.Position.Z - markPos.Z)
			if flat.Magnitude <= radius then
				BossHazardService.ApplyBossDirectHit(target, damage, markPos)
			end
		end
	end)

	return {
		Stop = function()
			running = false
		end,
	}
end

return RustMarkService
