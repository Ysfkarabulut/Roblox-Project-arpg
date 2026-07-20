--[[
	Dodge — stamina cost + i-frame status + impulse.
]]

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local StaminaService = require(script.Parent.StaminaService)
local StatusService = require(script.Parent.StatusService)

local DodgeService = {}

local recoveryUntil: { [number]: number } = {}

function DodgeService.Can(userId: number): boolean
	return os.clock() >= (recoveryUntil[userId] or 0)
end

function DodgeService.IsIFraming(entity: Instance): boolean
	return StatusService.Has(entity, "Dodge")
end

function DodgeService.Try(player: Player, moveDir: Vector3?): (boolean, string?)
	local userId = player.UserId
	if not DodgeService.Can(userId) then
		return false, "Recovery"
	end
	if not StaminaService.Spend(userId, CombatConfig.DodgeCost) then
		return false, "NoStamina"
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return false, "NoChar"
	end

	StatusService.Apply(char, "Dodge", CombatConfig.DodgeIFrameSec, {
		sourceUserId = userId,
		params = { iframesActive = true },
		silentBatch = true,
	})

	local dir = moveDir
	if not dir or dir.Magnitude < 0.1 then
		dir = hrp.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then
		dir = hrp.CFrame.LookVector
	end
	dir = dir.Unit

	-- BodyVelocity impulse
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5, 0, 1e5)
	bv.Velocity = dir * (CombatConfig.DodgeDistance / 0.2)
	bv.Parent = hrp
	task.delay(0.18, function()
		bv:Destroy()
	end)

	recoveryUntil[userId] = os.clock() + CombatConfig.DodgeIFrameSec + CombatConfig.DodgeRecoverySec
	return true, nil
end

function DodgeService.Clear(userId: number)
	recoveryUntil[userId] = nil
end

return DodgeService
