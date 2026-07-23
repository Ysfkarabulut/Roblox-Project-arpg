--[[
	Arena place entry — read TeleportData, wait for roster, start PvP match.
]]

local Players = game:GetService("Players")

local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
local PvpMatchService = require(script.Parent.PvpMatchService)

local ArenaMatchCoordinator = {}

type TeleportMatchData = {
	matchId: string,
	queueId: string,
	teams: { { number } },
}

local pending: TeleportMatchData? = nil
local arrived: { [number]: boolean } = {}
local started = false

local function expectedUserIds(data: TeleportMatchData): { number }
	local ids: { number } = {}
	for _, team in data.teams do
		for _, userId in team do
			table.insert(ids, userId)
		end
	end
	return ids
end

local function allArrived(data: TeleportMatchData): boolean
	for _, userId in expectedUserIds(data) do
		if not arrived[userId] then
			return false
		end
	end
	return true
end

local function tryStart()
	if started or not pending then
		return
	end
	if not allArrived(pending) then
		return
	end
	started = true
	local bracket = PlaceRuntime.GetPvpBracket() or PlaceRuntime.BracketFromQueueId(pending.queueId)
	PvpMatchService.Start({
		matchId = pending.matchId,
		queueId = pending.queueId,
		bracket = bracket,
		teams = pending.teams,
	})
end

local function parseTeleportData(raw: any): TeleportMatchData?
	if typeof(raw) ~= "table" then
		return nil
	end
	if typeof(raw.matchId) ~= "string" or typeof(raw.queueId) ~= "string" then
		return nil
	end
	if typeof(raw.teams) ~= "table" or #raw.teams < 2 then
		return nil
	end
	local teams: { { number } } = {}
	for _, team in raw.teams do
		if typeof(team) ~= "table" then
			return nil
		end
		local memberIds: { number } = {}
		for _, userId in team do
			if typeof(userId) == "number" then
				table.insert(memberIds, userId)
			end
		end
		if #memberIds < 1 then
			return nil
		end
		table.insert(teams, memberIds)
	end
	return {
		matchId = raw.matchId,
		queueId = raw.queueId,
		teams = teams,
	}
end

function ArenaMatchCoordinator.OnPlayerAdded(player: Player)
	local joinData = player:GetJoinData()
	local parsed = parseTeleportData(joinData.TeleportData)
	if not parsed then
		warn(`[ArenaMatch] Missing teleport data for {player.Name}`)
		return
	end

	if not pending then
		pending = parsed
	elseif pending.matchId ~= parsed.matchId then
		warn("[ArenaMatch] Mixed matchId in same server — ignoring", player.Name)
		return
	end

	arrived[player.UserId] = true
	tryStart()
end

function ArenaMatchCoordinator.Start()
	if not PlaceRuntime.IsPvpArena() then
		return
	end

	Players.PlayerAdded:Connect(ArenaMatchCoordinator.OnPlayerAdded)
	for _, plr in Players:GetPlayers() do
		task.defer(ArenaMatchCoordinator.OnPlayerAdded, plr)
	end

	task.delay(45, function()
		if started or not pending then
			return
		end
		-- Keep only players who actually arrived; drop empty teams.
		local filteredTeams: { { number } } = {}
		for _, team in pending.teams do
			local members: { number } = {}
			for _, userId in team do
				if arrived[userId] then
					table.insert(members, userId)
				end
			end
			if #members > 0 then
				table.insert(filteredTeams, members)
			end
		end
		if #filteredTeams == 0 then
			warn("[ArenaMatch] Join timeout — no arrived players; aborting")
			pending = nil
			return
		end
		warn("[ArenaMatch] Join timeout — starting with arrived players only")
		started = true
		local bracket = PlaceRuntime.GetPvpBracket() or PlaceRuntime.BracketFromQueueId(pending.queueId)
		PvpMatchService.Start({
			matchId = pending.matchId,
			queueId = pending.queueId,
			bracket = bracket,
			teams = filteredTeams,
		})
	end)

	print(`[ArenaMatch] Coordinator ready role={PlaceRuntime.GetRole()}`)
end

return ArenaMatchCoordinator
