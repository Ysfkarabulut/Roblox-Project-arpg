--[[
	Single-target aggro strike — LA rhythm (telegraph → hit → cooldown).
	Shared by Eye (IrisPulse) and Breaker (melee strike).
]]

local BossAggroService = require(script.Parent.Parent.BossAggroService)
local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local AggroStrikeService = {}

export type StrikeCfg = {
	firstDelaySec: number?,
	intervalByPhase: { number }?,
	telegraphSec: number?,
	damage: number?,
	farRangeStud: number?,
	farDamageMult: number?,
}

export type StrikeHandle = {
	Stop: () -> (),
}

local function intervalForPhase(cfg: StrikeCfg, phase: number): number
	local list = cfg.intervalByPhase
	if typeof(list) == "table" and typeof(list[phase]) == "number" then
		return list[phase]
	end
	return if typeof(list) == "table" and list[1] then list[1] else 5
end

local function flatDistToBoss(plr: Player, center: Vector3): number?
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	local flat = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z)
	return flat.Magnitude
end

local function damageForTarget(plr: Player, center: Vector3, cfg: StrikeCfg): number
	local raw = if typeof(cfg.damage) == "number" then cfg.damage else 30
	local dist = flatDistToBoss(plr, center)
	local farStud = cfg.farRangeStud or 28
	local farMult = cfg.farDamageMult or 1.3
	if dist and dist > farStud then
		raw = math.floor(raw * farMult + 0.5)
	end
	return raw
end

function AggroStrikeService.Start(
	_strikeParty: { number },
	getPhase: () -> number,
	strikeCfg: StrikeCfg,
	telegraphKind: string
): StrikeHandle
	local running = true
	local telegraphSec = strikeCfg.telegraphSec or 1.35
	local nextAt = os.clock() + (strikeCfg.firstDelaySec or 3.65)

	task.spawn(function()
		while running do
			task.wait(0.1)
			if not running or not BossAggroService.IsActive() then
				continue
			end
			if os.clock() < nextAt then
				continue
			end

			local phase = getPhase()
			local interval = intervalForPhase(strikeCfg, phase)
			local cooldownSec = math.max(0.05, interval - telegraphSec)

			local center = BossEntityService.GetCenter()
			if not center then
				nextAt = os.clock() + 0.5
				continue
			end

			local target = BossAggroService.GetThreatTarget()
			if not target or not BossHazardService.IsAlive(target) then
				nextAt = os.clock() + 0.5
				continue
			end

			BossSync.FireTelegraph({
				kind = telegraphKind,
				targetUserId = target.UserId,
				duration = telegraphSec,
				origin = center,
			})

			task.wait(telegraphSec)
			if not running or not BossAggroService.IsActive() then
				continue
			end
			if not BossHazardService.IsAlive(target) then
				nextAt = os.clock() + cooldownSec
				continue
			end

			local current = BossAggroService.GetThreatTarget()
			if current and current.UserId == target.UserId then
				center = BossEntityService.GetCenter()
				if center then
					local raw = damageForTarget(target, center, strikeCfg)
					BossHazardService.ApplyBossDirectHit(target, raw, center)
				end
			end

			nextAt = os.clock() + cooldownSec
		end
	end)

	return {
		Stop = function()
			running = false
		end,
	}
end

return AggroStrikeService
