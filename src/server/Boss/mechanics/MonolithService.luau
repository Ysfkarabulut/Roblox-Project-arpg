--[[
	Monolith drops — telegraph, instant kill, aura DPS.
]]

local Workspace = game:GetService("Workspace")

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.Parent.BossEntityService)
local BossHazardService = require(script.Parent.Parent.BossHazardService)
local BossSync = require(script.Parent.Parent.BossSync)

local MonolithService = {}

export type MonolithHandle = {
	Stop: () -> (),
	GetActiveMonoliths: () -> { BasePart },
}

local function randomPointInArena(center: Vector3, radius: number, innerMargin: number, bossCenter: Vector3): Vector3
	for _ = 1, 20 do
		local ang = math.random() * math.pi * 2
		local dist = innerMargin + math.random() * (radius - innerMargin * 2)
		local pos = center + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)
		if (pos - bossCenter).Magnitude > 16 then
			return pos
		end
	end
	return center + Vector3.new(radius * 0.4, 0, 0)
end

function MonolithService.Start(
	partyUserIds: { number },
	arenaCenter: Vector3,
	arenaRadius: number,
	getPhase: () -> number
): MonolithHandle
	local def = BossEncounterConfig.Eye
	local cfg = def.monolith
	local running = true
	local monoliths: { BasePart } = {}
	local folder = Instance.new("Folder")
	folder.Name = "BossMonoliths"
	folder.Parent = Workspace

	local function cleanupMonoliths()
		for _, p in monoliths do
			if p.Parent then
				p:Destroy()
			end
		end
		table.clear(monoliths)
	end

	task.spawn(function()
		while running do
			if getPhase() < 2 then
				task.wait(1)
				continue
			end

			for drop = 1, math.floor(cfg.cycleSec / cfg.dropIntervalSec) do
				if not running then
					break
				end
				local bossCenter = BossEntityService.GetCenter() or arenaCenter
				local targetPos = randomPointInArena(arenaCenter, arenaRadius, cfg.innerMargin, bossCenter)

				BossSync.FireTelegraph({
					kind = "MonolithTelegraph",
					position = targetPos,
					radius = cfg.partRadius,
					duration = cfg.telegraphSec,
				})

				task.wait(cfg.telegraphSec)
				if not running then
					break
				end

				local mono = Instance.new("Part")
				mono.Name = "Monolith"
				mono.Shape = Enum.PartType.Cylinder
				mono.Size = Vector3.new(14, cfg.partRadius * 2, cfg.partRadius * 2)
				mono.CFrame = CFrame.new(targetPos + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90))
				mono.Anchored = true
				mono.CanCollide = true
				mono.Color = Color3.fromRGB(80, 80, 90)
				mono.Material = Enum.Material.Slate
				mono:SetAttribute("IsMonolith", true)
				mono.Parent = folder
				table.insert(monoliths, mono)

				for _, userId in partyUserIds do
					local plr = game:GetService("Players"):GetPlayerByUserId(userId)
					local char = plr and plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp and BossHazardService.IsAlive(plr :: Player) then
						local flat = Vector3.new(hrp.Position.X - targetPos.X, 0, hrp.Position.Z - targetPos.Z)
						if flat.Magnitude <= cfg.partRadius then
							BossHazardService.InstantKill(plr :: Player)
						end
					end
				end

				task.wait(cfg.dropIntervalSec)
			end

			if running then
				task.wait(0.5)
			end
		end
	end)

	task.spawn(function()
		while running do
			task.wait(0.25)
			if getPhase() < 2 then
				continue
			end
			for _, mono in monoliths do
				if not mono.Parent then
					continue
				end
				local pos = mono.Position
				for _, userId in partyUserIds do
					local plr = game:GetService("Players"):GetPlayerByUserId(userId)
					local char = plr and plr.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp and BossHazardService.IsAlive(plr :: Player) then
						local flat = Vector3.new(hrp.Position.X - pos.X, 0, hrp.Position.Z - pos.Z)
						if flat.Magnitude <= cfg.auraRadius then
							BossHazardService.ApplyTickDamage(plr :: Player, cfg.auraDps, 0.25)
						end
					end
				end
			end
		end
	end)

	return {
		Stop = function()
			running = false
			cleanupMonoliths()
			if folder.Parent then
				folder:Destroy()
			end
		end,
		GetActiveMonoliths = function()
			local out: { BasePart } = {}
			for _, m in monoliths do
				if m.Parent then
					table.insert(out, m)
				end
			end
			return out
		end,
	}
end

return MonolithService
