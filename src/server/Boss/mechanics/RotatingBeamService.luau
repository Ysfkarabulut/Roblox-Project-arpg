--[[
	Rotating beam — MODES.md §4.6 common mechanic.
]]

local RunService = game:GetService("RunService")

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local RotatingBeamService = {}

export type BeamHandle = {
	Stop: () -> (),
	Pause: () -> (),
	Resume: () -> (),
}

local function flatDistToLine(point: Vector3, center: Vector3, angleRad: number): number
	local flat = Vector3.new(point.X - center.X, 0, point.Z - center.Z)
	local dir = Vector3.new(math.cos(angleRad), 0, math.sin(angleRad))
	local along = flat:Dot(dir)
	local perp = flat - dir * along
	return perp.Magnitude
end

local function lineCountForPhase(phase: number, cycleIndex: number): number
	if phase <= 1 then
		return math.clamp(1 + math.floor(cycleIndex / 2), 1, 2)
	end
	return 4
end

function RotatingBeamService.Start(
	partyUserIds: { number },
	getPhase: () -> number,
	isPaused: () -> boolean
): BeamHandle
	local def = BossEncounterConfig.Eye
	local cfg = def.beam
	local running = true
	local paused = false
	local startClock = os.clock()
	local cycleIndex = 0
	local beamAngle = 0
	local activeUntil = 0
	local nextBeamAt = cfg.firstDelaySec
	local conn: RBXScriptConnection? = nil

	local function fireBeamVisual(lineCount: number, angle: number, duration: number)
		BossSync.FireTelegraph({
			kind = "Beam",
			lineCount = lineCount,
			angle = angle,
			duration = duration,
			center = BossEntityService.GetCenter(),
		})
	end

	conn = RunService.Heartbeat:Connect(function(dt)
		if not running then
			return
		end
		if paused or isPaused() then
			return
		end
		local now = os.clock() - startClock
		local center = BossEntityService.GetCenter()
		if not center then
			return
		end

		if now >= nextBeamAt and now >= activeUntil then
			cycleIndex += 1
			local phase = getPhase()
			local lineCount = lineCountForPhase(phase, cycleIndex)
			beamAngle = (cycleIndex * 0.7) % (math.pi * 2)
			activeUntil = now + cfg.activeSec
			nextBeamAt = activeUntil + cfg.cooldownSec
			fireBeamVisual(lineCount, beamAngle, cfg.activeSec)
		end

		if now < activeUntil then
			beamAngle += math.rad(cfg.rotationDegPerSec) * dt
			local phase = getPhase()
			local lineCount = lineCountForPhase(phase, cycleIndex)
			local angles = { beamAngle }
			if lineCount >= 2 then
				table.insert(angles, beamAngle + math.pi / 2)
			end
			if lineCount >= 4 then
				table.insert(angles, beamAngle + math.pi / 4)
				table.insert(angles, beamAngle - math.pi / 4)
			end

			for _, userId in partyUserIds do
				local plr = game:GetService("Players"):GetPlayerByUserId(userId)
				local char = plr and plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp and BossHazardService.IsAlive(plr :: Player) then
					local hit = false
					for _, ang in angles do
						if flatDistToLine(hrp.Position, center, ang) <= cfg.beamHalfThickness then
							hit = true
							break
						end
					end
					if hit then
						BossHazardService.ApplyTickDamage(plr :: Player, cfg.tickDps, dt)
					end
				end
			end
		end
	end)

	return {
		Stop = function()
			running = false
			if conn then
				conn:Disconnect()
			end
		end,
		Pause = function()
			paused = true
		end,
		Resume = function()
			paused = false
		end,
	}
end

return RotatingBeamService
