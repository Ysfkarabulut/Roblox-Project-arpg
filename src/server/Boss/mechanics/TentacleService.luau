--[[
	Tentacle add — farthest player tether, stacking damage.
]]

local Workspace = game:GetService("Workspace")

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local TentacleService = {}

export type TentacleHandle = {
	Stop: () -> (),
}

function TentacleService.Start(partyUserIds: { number }, getPhase: () -> number): TentacleHandle
	local def = BossEncounterConfig.Eye
	local cfg = def.tentacle
	local running = true
	local folder = Instance.new("Folder")
	folder.Name = "BossTentacles"
	folder.Parent = Workspace

	local function spawnTentacle()
		local origin = BossEntityService.GetCenter()
		if not origin then
			return
		end
		local target = BossHazardService.FarthestPlayer(origin, partyUserIds)
		if not target or not target.Character then
			return
		end

		local model = Instance.new("Model")
		model.Name = "Tentacle"
		model:SetAttribute("IsBossAdd", true)
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(3, 3, 3)
		root.Anchored = true
		root.CanCollide = false
		root.Transparency = 1
		root.CFrame = CFrame.new(origin + Vector3.new(0, 4, 0))
		root.Parent = model
		model.PrimaryPart = root

		local pod = Instance.new("Part")
		pod.Name = "Pod"
		pod.Shape = Enum.PartType.Ball
		pod.Size = Vector3.new(5, 5, 5)
		pod.Anchored = true
		pod.CanCollide = true
		pod.Color = Color3.fromRGB(120, 40, 80)
		pod.Material = Enum.Material.Neon
		pod.CFrame = root.CFrame
		pod.Parent = model

		local hum = Instance.new("Humanoid")
		hum.MaxHealth = cfg.hp
		hum.Health = cfg.hp
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.Parent = model
		model.Parent = folder
		local NameplateService = require(script.Parent.Parent.Parent.Combat.NameplateService)
		NameplateService.Setup(model, "BossAdd", "Tentacle")

		BossSync.FireTelegraph({
			kind = "Tentacle",
			targetUserId = target.UserId,
			origin = origin,
		})

		local stacks = 0
		local tentacleHp = cfg.hp
		local stackAcc = 0
		local tickConn: RBXScriptConnection? = nil
		tickConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
			if not model.Parent or tentacleHp <= 0 then
				if tickConn then
					tickConn:Disconnect()
				end
				if model.Parent then
					model:Destroy()
				end
				return
			end
			local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp or not BossHazardService.IsAlive(target) then
				if tickConn then
					tickConn:Disconnect()
				end
				model:Destroy()
				return
			end
			stackAcc += dt
			if stackAcc >= 1 then
				stacks = math.min(stacks + 1, cfg.maxStacks)
				stackAcc = 0
			end
			local mult = cfg.stackMult ^ math.max(0, stacks - 1)
			BossHazardService.ApplyTickDamage(target, cfg.baseDps * mult, dt)
			pod.CFrame = CFrame.new(origin:Lerp(hrp.Position, 0.15) + Vector3.new(0, 3, 0))
		end)

		hum.HealthChanged:Connect(function(hp)
			tentacleHp = hp
			if hp <= 0 and model.Parent then
				model:Destroy()
			end
		end)
	end

	task.spawn(function()
		while running do
			if getPhase() < 3 then
				task.wait(1)
				continue
			end
			spawnTentacle()
			task.wait(cfg.intervalSec)
		end
	end)

	return {
		Stop = function()
			running = false
			if folder.Parent then
				folder:Destroy()
			end
		end,
	}
end

return TentacleService
