--[[
	Dodge — stamina + i-frames + smooth horizontal dash.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local StaminaService = require(script.Parent.StaminaService)
local StatusService = require(script.Parent.StatusService)
local PassiveService = require(script.Parent.PassiveService)
local CombatPressureService = require(script.Parent.CombatPressureService)

local DodgeService = {}

local recoveryUntil: { [number]: number } = {}
local dashTokens: { [number]: number } = {}

local function dashSpeedMul(alpha: number): number
	local t = math.clamp(alpha, 0, 1)
	-- Soft ramp-in, sustained mid-roll, gentle stop
	if t < 0.14 then
		return 0.55 + (t / 0.14) * 0.45
	end
	if t < 0.72 then
		return 1
	end
	local u = (t - 0.72) / 0.28
	return math.max(0.1, 1 - u * u)
end

local function averageDashMul(samples: number): number
	local n = math.max(8, samples)
	local sum = 0
	for i = 0, n - 1 do
		sum += dashSpeedMul(i / (n - 1))
	end
	return sum / n
end

local function dodgeCost(userId: number): number
	if PassiveService.HasPassive(userId, "quiet_step_armorpassive") then
		return CombatConfig.DodgeCost * 0.92
	end
	return CombatConfig.DodgeCost
end

local function applyDodgeStep(userId: number, origin: Vector3)
	if not PassiveService.HasPassive(userId, "dodge_step_armorpassive") then
		return
	end
	local element = PassiveService.GetSlotElement(userId, "feets")
	if not element or element == "Neutral" then
		return
	end
	local status = PassiveService.ElementStatus(element)
	if not status then
		return
	end
	local scaled = PassiveService.ScaleOnHitStatus(userId, status)

	local function tryApply(model: Model)
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		if (pp.Position - origin).Magnitude > 4 then
			return
		end
		StatusService.Apply(model, scaled.id, scaled.duration, {
			sourceUserId = userId,
			dps = scaled.dps,
		})
	end

	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		tryApply(dummy)
	end
	for _, plr in Players:GetPlayers() do
		if plr.UserId ~= userId and plr.Character then
			tryApply(plr.Character)
		end
	end
end

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
	local char = player.Character
	if not char or not CombatPressureService.CanMoveEntity(char) or not CombatPressureService.CanAttackEntity(char) then
		return false, "Stunned"
	end
	if not StaminaService.Spend(userId, dodgeCost(userId)) then
		return false, "NoStamina"
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return false, "NoChar"
	end

	StatusService.Apply(char, "Dodge", CombatConfig.DodgeIFrameSec, {
		sourceUserId = userId,
		params = { iframesActive = true },
		silentBatch = true,
	})

	local dashSec = CombatConfig.DodgeDashSec or 0.50
	StatusService.Apply(char, "DodgeMove", dashSec, {
		sourceUserId = userId,
		params = { slowPct = 100 },
		silentBatch = true,
	})
	char:SetAttribute("DodgeRolling", os.clock() + dashSec + 0.06)
	task.delay(dashSec + 0.08, function()
		if char.Parent then
			char:SetAttribute("DodgeRolling", nil)
		end
	end)

	local okNameplate, NameplateService = pcall(function()
		return require(script.Parent.NameplateService)
	end)
	if okNameplate then
		NameplateService.Sync(char)
	end

	applyDodgeStep(userId, hrp.Position)

	if PassiveService.HasPassive(userId, "ward_step_armorpassive") then
		StatusService.Apply(char, "Regen", 3, {
			sourceUserId = userId,
			hps = 5,
		})
	end

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

	local dashAvg = averageDashMul(24)
	local speed = CombatConfig.DodgeDistance / (dashSec * dashAvg)

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
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.2, v.Y, v.Z * 0.2)
			return
		end
		local mul = dashSpeedMul(a)
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
