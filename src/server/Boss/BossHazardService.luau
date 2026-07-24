--[[
	Environmental boss hazards — beam tick, aura, instant kill, mitigated direct hits.
]]

local Players = game:GetService("Players")

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local DodgeService = require(script.Parent.Parent.Combat.DodgeService)local GuardService = require(script.Parent.Parent.Combat.GuardService)
local ParryService = require(script.Parent.Parent.Combat.ParryService)
local StatService = require(script.Parent.Parent.Combat.StatService)
local StatusService = require(script.Parent.Parent.Combat.StatusService)

local BossHazardService = {}

local function victimDamageTakenMult(entity: Instance): number
	local f = StatusService.Get(entity, "Fortify")
	if f and f.params and typeof(f.params.damageTakenMult) == "number" then
		return f.params.damageTakenMult
	end
	local slow = StatusService.Get(entity, "Slow")
	if slow and slow.params and typeof(slow.params.damageTakenMult) == "number" then
		return slow.params.damageTakenMult
	end
	return 1
end

export type BossHitResult = {
	dealt: number,
	blocked: boolean,
	parried: boolean,
	dodged: boolean,
}

--- Boss direct burst — dodge / parry / guard / DR (Iris Pulse).
function BossHazardService.ApplyBossDirectHit(player: Player, rawDamage: number, bossOrigin: Vector3): BossHitResult
	local empty: BossHitResult = { dealt = 0, blocked = false, parried = false, dodged = false }
	local char = player.Character
	if not char or rawDamage <= 0 then
		return empty
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return empty
	end

	if DodgeService.IsIFraming(char) then
		empty.dodged = true
		return empty
	end

	local defence = StatService.Derived(player.UserId).totalDefence or 0
	local drPct = math.min(defence * CombatConfig.KDr, CombatConfig.DrCapPvp)
	local afterDr = math.max(1, math.floor(rawDamage * (1 - drPct / 100) + 0.5))
	afterDr = math.max(1, math.floor(afterDr * victimDamageTakenMult(char) + 0.5))

	local handled, perfect = ParryService.TryParry(player.UserId, char, nil, bossOrigin)
	if handled then
		if perfect then
			empty.parried = true
			return empty
		end
	end

	local blocked, chip = GuardService.TryBlock(player.UserId, char, bossOrigin, afterDr, 1)
	if blocked then
		hum:TakeDamage(math.max(1, math.floor(chip + 0.5)))
		empty.blocked = true
		empty.dealt = math.max(1, math.floor(chip + 0.5))
		return empty
	end

	hum:TakeDamage(afterDr)
	empty.dealt = afterDr
	return empty
end

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
