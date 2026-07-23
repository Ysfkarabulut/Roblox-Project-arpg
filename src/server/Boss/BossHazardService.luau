--[[
	Environmental boss hazards — beam tick, aura, instant kill.
]]

local Players = game:GetService("Players")

local BossHazardService = {}

function BossHazardService.InstantKill(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum.Health = 0
	end
end

function BossHazardService.ApplyTickDamage(player: Player, dps: number, dt: number)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	local amount = math.max(1, math.floor(dps * dt + 0.5))
	hum:TakeDamage(amount)
end

function BossHazardService.IsAlive(player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

function BossHazardService.GetAlivePlayers(partyUserIds: { number }): { Player }
	local out: { Player } = {}
	for _, userId in partyUserIds do
		local plr = Players:GetPlayerByUserId(userId)
		if plr and BossHazardService.IsAlive(plr) then
			table.insert(out, plr)
		end
	end
	return out
end

function BossHazardService.FarthestPlayer(origin: Vector3, partyUserIds: { number }): Player?
	local best: Player? = nil
	local bestDist = -1
	for _, userId in partyUserIds do
		local plr = Players:GetPlayerByUserId(userId)
		local char = plr and plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and BossHazardService.IsAlive(plr :: Player) then
			local d = (hrp.Position - origin).Magnitude
			if d > bestDist then
				bestDist = d
				best = plr
			end
		end
	end
	return best
end

return BossHazardService
