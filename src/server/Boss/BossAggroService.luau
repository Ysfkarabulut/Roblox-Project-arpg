--[[
	Boss threat / aggro — Iris Pulse and future boss target selection.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossEntityService = require(script.Parent.BossEntityService)
local BossHazardService = require(script.Parent.BossHazardService)
local GuardService = require(script.Parent.Parent.Combat.GuardService)

local BossAggroService = {}

local active = false
local activeBossId = "eye"
local partyUserIds: { number } = {}
local threat: { [number]: number } = {}
local tickConn: RBXScriptConnection? = nil

local function cfg()
	local def = BossEncounterConfig.Get(activeBossId)
	return if def and def.aggro then def.aggro else BossEncounterConfig.Eye.aggro
end

local function hasShield(userId: number): boolean
	return GuardService.GetShieldDef(userId) ~= nil
end

function BossAggroService.IsActive(): boolean
	return active
end

function BossAggroService.Start(userIds: { number }, bossId: string?)
	BossAggroService.Stop()
	active = true
	activeBossId = if typeof(bossId) == "string" then bossId else "eye"
	partyUserIds = table.clone(userIds)
	table.clear(threat)

	local a = cfg()
	for _, userId in partyUserIds do
		threat[userId] = 0
		if hasShield(userId) then
			threat[userId] = a.shieldStartThreat or 0
		end
	end

	tickConn = RunService.Heartbeat:Connect(function(dt)
		if not active then
			return
		end
		local center = BossEntityService.GetCenter()
		if not center then
			return
		end
		local guardPerSec = a.guardThreatPerSec or 0
		local guardRange = a.guardRangeStud or 24
		for _, userId in partyUserIds do
			local plr = Players:GetPlayerByUserId(userId)
			if not plr or not BossHazardService.IsAlive(plr) then
				continue
			end
			if not GuardService.IsGuarding(userId) then
				continue
			end
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end
			local flat = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z)
			if flat.Magnitude <= guardRange then
				BossAggroService.AddThreat(userId, guardPerSec * dt)
			end
		end
	end)
end

function BossAggroService.Stop()
	active = false
	table.clear(partyUserIds)
	table.clear(threat)
	if tickConn then
		tickConn:Disconnect()
		tickConn = nil
	end
end

function BossAggroService.AddThreat(userId: number, amount: number)
	if not active or amount <= 0 then
		return
	end
	for _, id in partyUserIds do
		if id == userId then
			threat[userId] = (threat[userId] or 0) + amount
			return
		end
	end
end

function BossAggroService.AddDamageThreat(userId: number, damageDealt: number)
	if damageDealt <= 0 then
		return
	end
	local a = cfg()
	local mult = a.damageThreatMult or 1
	if hasShield(userId) then
		mult *= a.shieldThreatMult or 1
	end
	BossAggroService.AddThreat(userId, damageDealt * mult)
end

function BossAggroService.GetThreat(userId: number): number
	return threat[userId] or 0
end

local function fallbackTarget(): Player?
	local center = BossEntityService.GetCenter()
	if not center then
		return nil
	end

	local shieldPlr: Player? = nil
	local closest: Player? = nil
	local closestDist = math.huge

	for _, userId in partyUserIds do
		local plr = Players:GetPlayerByUserId(userId)
		if not plr or not BossHazardService.IsAlive(plr) then
			continue
		end
		if hasShield(userId) and not shieldPlr then
			shieldPlr = plr
		end
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local d = (hrp.Position - center).Magnitude
			if d < closestDist then
				closestDist = d
				closest = plr
			end
		end
	end

	return shieldPlr or closest
end

function BossAggroService.GetThreatTarget(): Player?
	if not active then
		return nil
	end

	local best: Player? = nil
	local bestThreat = -1
	for _, userId in partyUserIds do
		local plr = Players:GetPlayerByUserId(userId)
		if not plr or not BossHazardService.IsAlive(plr) then
			continue
		end
		local t = threat[userId] or 0
		if t > bestThreat then
			bestThreat = t
			best = plr
		end
	end

	if best and bestThreat > 0 then
		return best
	end
	return fallbackTarget()
end

return BossAggroService
