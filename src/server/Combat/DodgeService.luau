--[[
	Dodge — stamina + i-frames + smooth horizontal dash.
]]

local RunService = game:GetService("RunService")
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local StaminaService = require(script.Parent.StaminaService)
local StatusService = require(script.Parent.StatusService)

local DodgeService = {}

local recoveryUntil: { [number]: number } = {}
local dashTokens: { [number]: number } = {}

function DodgeService.Can(userId: number): boolean
	return os.clock() >= (recoveryUntil[userId] or 0)
end

function DodgeService.IsIFraming(entity: Instance): boolean
	return StatusService.Has(entity, "Dodge")
end

local function clearLegacyMovers(hrp: BasePart)
	for _, name in { "DodgeLV", "DodgeLVAtt", "DodgeRollSpin" } do
		local old = hrp:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	for _, c in hrp:GetChildren() do
		if c:IsA("BodyVelocity") or c:IsA("LinearVelocity") then
			c:Destroy()
		end
	end
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
		dir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	end
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(0, 0, -1)
	end
	dir = dir.Unit

	clearLegacyMovers(hrp)
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Face dash direction (upright) so roll KF reads forward
	local pos = hrp.Position
	hrp.CFrame = CFrame.lookAt(pos, pos + dir)

	local dashSec = CombatConfig.DodgeDashSec or 0.32
	local speed = CombatConfig.DodgeDistance / dashSec

	dashTokens[userId] = (dashTokens[userId] or 0) + 1
	local token = dashTokens[userId]
	local t0 = os.clock()

	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		if dashTokens[userId] ~= token or not hrp.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end
		local a = (os.clock() - t0) / dashSec
		if a >= 1 then
			if conn then
				conn:Disconnect()
			end
			-- Keep vertical vel; bleed horizontal
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.25, v.Y, v.Z * 0.25)
			return
		end
		-- Ease-out curve: fast start, soft finish
		local mul = (1 - a) * (1 - a * 0.35)
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(dir.X * speed * mul, v.Y, dir.Z * speed * mul)
	end)

	recoveryUntil[userId] = os.clock() + CombatConfig.DodgeIFrameSec + CombatConfig.DodgeRecoverySec
	return true, nil
end

function DodgeService.Clear(userId: number)
	recoveryUntil[userId] = nil
	dashTokens[userId] = (dashTokens[userId] or 0) + 1
end

return DodgeService
