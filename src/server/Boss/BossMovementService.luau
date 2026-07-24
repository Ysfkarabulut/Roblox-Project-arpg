--[[
	Boss pursuit — walk toward aggro target (mobile bosses).
]]

local RunService = game:GetService("RunService")

local BossEntityService = require(script.Parent.BossEntityService)
local BossAggroService = require(script.Parent.BossAggroService)
local BossHazardService = require(script.Parent.BossHazardService)

local BossMovementService = {}

export type MovementCfg = {
	walkSpeed: number?,
	stopRangeStud: number?,
	turnSpeed: number?,
}

export type MovementHandle = {
	Stop: () -> (),
}

function BossMovementService.Start(moveCfg: MovementCfg?): MovementHandle
	local running = true
	local cfg = moveCfg or {}
	local stopRange = cfg.stopRangeStud or 10
	local walkSpeed = cfg.walkSpeed or 14

	local conn = RunService.Heartbeat:Connect(function()
		if not running or BossEntityService.IsMovementPaused() then
			return
		end
		local hum = BossEntityService.GetHumanoid()
		local model = BossEntityService.GetModel()
		if not hum or not model or not model.PrimaryPart then
			return
		end
		hum.WalkSpeed = walkSpeed

		local target = BossAggroService.GetThreatTarget()
		if not target or not BossHazardService.IsAlive(target) then
			hum:Move(Vector3.zero, false)
			return
		end

		local char = target.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local bossPos = model.PrimaryPart.Position
		local flat = Vector3.new(hrp.Position.X - bossPos.X, 0, hrp.Position.Z - bossPos.Z)
		local dist = flat.Magnitude
		if dist <= stopRange then
			hum:Move(Vector3.zero, false)
			return
		end

		if dist > 0.1 then
			hum:Move(flat.Unit, false)
		else
			hum:Move(Vector3.zero, false)
		end
	end)

	return {
		Stop = function()
			running = false
			conn:Disconnect()
			local hum = BossEntityService.GetHumanoid()
			if hum then
				hum:Move(Vector3.zero, false)
			end
		end,
	}
end

return BossMovementService
