--[[
	PvP team registry — friendly fire, combat lock, enemy lookup.
]]

local Players = game:GetService("Players")

local PvpTeamService = {}

local teamByUser: { [number]: number } = {}
local deathAtMs: { [number]: number } = {}
local combatLocked = false
local teamMatch = false
local practiceMode = false

function PvpTeamService.Clear()
	table.clear(teamByUser)
	table.clear(deathAtMs)
	combatLocked = false
	teamMatch = false
	practiceMode = false
	for _, plr in Players:GetPlayers() do
		plr:SetAttribute("PvpTeam", nil)
		plr:SetAttribute("CombatLocked", nil)
	end
end

function PvpTeamService.RegisterMatch(teams: { { number } }, opts: { practice: boolean? }?)
	PvpTeamService.Clear()
	practiceMode = opts and opts.practice == true or false
	teamMatch = not practiceMode and #teams >= 2
	combatLocked = true

	for teamIndex, members in teams do
		for _, userId in members do
			teamByUser[userId] = teamIndex
			local plr = Players:GetPlayerByUserId(userId)
			if plr then
				plr:SetAttribute("PvpTeam", teamIndex)
				plr:SetAttribute("CombatLocked", true)
			end
		end
	end
end

function PvpTeamService.SetCombatLocked(locked: boolean)
	combatLocked = locked
	for _, plr in Players:GetPlayers() do
		if teamByUser[plr.UserId] then
			plr:SetAttribute("CombatLocked", locked)
		end
	end
end

function PvpTeamService.IsTeamMatch(): boolean
	return teamMatch
end

function PvpTeamService.IsPracticeMode(): boolean
	return practiceMode
end

function PvpTeamService.IsMatchActive(): boolean
	return next(teamByUser) ~= nil or practiceMode
end

function PvpTeamService.GetTeam(userId: number): number?
	return teamByUser[userId]
end

function PvpTeamService.GetTeamUserIds(teamIndex: number): { number }
	local out: { number } = {}
	for userId, team in teamByUser do
		if team == teamIndex then
			table.insert(out, userId)
		end
	end
	return out
end

function PvpTeamService.GetEnemyPlayers(attackerUserId: number): { Player }
	local myTeam = teamByUser[attackerUserId]
	if not myTeam then
		return {}
	end
	local out: { Player } = {}
	for userId, team in teamByUser do
		if team ~= myTeam then
			local plr = Players:GetPlayerByUserId(userId)
			if plr then
				table.insert(out, plr)
			end
		end
	end
	return out
end

function PvpTeamService.GetAllyPlayers(userId: number): { Player }
	local out: { Player } = {}
	if teamMatch then
		local myTeam = teamByUser[userId]
		if not myTeam then
			return out
		end
		for allyId, team in teamByUser do
			if team == myTeam and allyId ~= userId then
				local plr = Players:GetPlayerByUserId(allyId)
				if plr then
					table.insert(out, plr)
				end
			end
		end
		return out
	end
	for _, plr in Players:GetPlayers() do
		if plr.UserId ~= userId then
			table.insert(out, plr)
		end
	end
	return out
end

function PvpTeamService.CanDamage(attackerUserId: number, victimUserId: number): boolean
	if not teamMatch then
		return false
	end
	local aTeam = teamByUser[attackerUserId]
	local vTeam = teamByUser[victimUserId]
	if not aTeam or not vTeam then
		return false
	end
	return aTeam ~= vTeam
end

function PvpTeamService.IsCombatLocked(userId: number): boolean
	if combatLocked then
		return true
	end
	local plr = Players:GetPlayerByUserId(userId)
	return plr ~= nil and plr:GetAttribute("CombatLocked") == true
end

function PvpTeamService.RecordDeath(userId: number)
	if not deathAtMs[userId] then
		deathAtMs[userId] = DateTime.now().UnixTimestampMillis
	end
end

function PvpTeamService.GetDeathMs(userId: number): number?
	return deathAtMs[userId]
end

function PvpTeamService.IsTeamEliminated(teamIndex: number): boolean
	for _, userId in PvpTeamService.GetTeamUserIds(teamIndex) do
		local plr = Players:GetPlayerByUserId(userId)
		if plr and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				return false
			end
		end
	end
	return true
end

function PvpTeamService.ResolveWinningTeam(): number?
	if not teamMatch then
		return nil
	end
	local t1Dead = PvpTeamService.IsTeamEliminated(1)
	local t2Dead = PvpTeamService.IsTeamEliminated(2)
	if t1Dead and not t2Dead then
		return 2
	end
	if t2Dead and not t1Dead then
		return 1
	end
	if t1Dead and t2Dead then
		local earliestTeam = 2
		local earliestMs = math.huge
		for teamIndex = 1, 2 do
			for _, userId in PvpTeamService.GetTeamUserIds(teamIndex) do
				local ms = deathAtMs[userId]
				if ms and ms < earliestMs then
					earliestMs = ms
					earliestTeam = teamIndex
				end
			end
		end
		if earliestTeam == 1 then
			return 2
		end
		return 1
	end
	return nil
end

return PvpTeamService
