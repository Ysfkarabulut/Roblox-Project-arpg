--[[
	PvP match lifecycle — WoW-style team elimination arenas.
	Practice (solo) vs dummy; 1v1/2v2/3v3 team matches; gas phase v1.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local PvpArenaConfig = require(game.ReplicatedStorage.Shared.Config.PvpArenaConfig)
local PlaceConfig = require(game.ReplicatedStorage.Shared.Config.PlaceConfig)
local PlaceRuntime = require(game.ReplicatedStorage.Shared.Config.PlaceRuntime)
local PvpArenaBuilder = require(script.Parent.PvpArenaBuilder)
local PvpTeamService = require(script.Parent.PvpTeamService)
local NameplateService = require(script.Parent.Parent.Combat.NameplateService)
local BossCombatTargets = require(script.Parent.Parent.Boss.BossCombatTargets)
local MatchResultBridge = require(script.Parent.Parent.Loot.MatchResultBridge)
local MatchResetService = require(script.Parent.Parent.Combat.MatchResetService)
local SpectateService = require(script.Parent.SpectateService)
local RankedService = require(script.Parent.Parent.Ranked.RankedService)
local RankedConfig = require(game.ReplicatedStorage.Shared.Config.RankedConfig)
local LoadoutLockService = require(script.Parent.Parent.Combat.LoadoutLockService)
local QueueConfig = require(game.ReplicatedStorage.Shared.Config.QueueConfig)

local PvpMatchService = {}

export type StartPayload = {
	matchId: string?,
	queueId: string?,
	bracket: PvpArenaConfig.Bracket,
	teams: { { number } },
}

local active = false
local arena: PvpArenaBuilder.ArenaHandle? = nil
local matchTeams: { { number } } = {}
local bracket: PvpArenaConfig.Bracket = "1v1"
local matchQueueId: string? = nil
local matchRanked = false
local opponent: Model? = nil
local ending = false
local deathConns: { RBXScriptConnection } = {}
local gasThread: thread? = nil
local arenaStateRemote: RemoteEvent? = nil

local function getArenaStateRemote(): RemoteEvent
	if arenaStateRemote and arenaStateRemote.Parent then
		return arenaStateRemote
	end
	local folder = ReplicatedStorage:FindFirstChild("PvpRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PvpRemotes"
		folder.Parent = ReplicatedStorage
	end
	local existing = folder:FindFirstChild("ArenaState")
	if existing and existing:IsA("RemoteEvent") then
		arenaStateRemote = existing
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = "ArenaState"
	remote.Parent = folder
	arenaStateRemote = remote
	return remote
end

local function broadcastState(payload: { [string]: any })
	getArenaStateRemote():FireAllClients(payload)
end

local function allUserIds(): { number }
	local ids: { number } = {}
	for _, team in matchTeams do
		for _, userId in team do
			table.insert(ids, userId)
		end
	end
	return ids
end

local function getPlayers(): { Player }
	local out: { Player } = {}
	for _, userId in allUserIds() do
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			table.insert(out, plr)
		end
	end
	return out
end

local function hideTrainingDummy()
	local dummy = workspace:FindFirstChild("TrainingDummy")
	if dummy then
		dummy.Parent = ServerStorage
	end
end

local function restoreTrainingDummy()
	if not PlaceRuntime.IsLobby() then
		return
	end
	local dummy = ServerStorage:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		dummy.Parent = workspace
	end
end

local function clearDeathConns()
	for _, c in deathConns do
		c:Disconnect()
	end
	table.clear(deathConns)
end

local function stopGas()
	if gasThread then
		task.cancel(gasThread)
		gasThread = nil
	end
end

local function teleportToSpawns()
	if not arena then
		return
	end
	local slotsPerTeam = if bracket == "1v1" then 1 elseif bracket == "2v2" then 2 else 3
	for teamIndex, team in matchTeams do
		for memberIndex, userId in team do
			local spawnIndex = (teamIndex - 1) * slotsPerTeam + memberIndex
			local cf = arena.spawnPoints[spawnIndex]
			local plr = Players:GetPlayerByUserId(userId)
			local hrp = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and cf then
				hrp.CFrame = cf
			end
		end
	end
end

local function teleportLobby()
	local spawn = PvpArenaConfig.LobbySpawn
	for _, plr in getPlayers() do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = CFrame.new(spawn)
		end
	end
end

local function returnToLobbyPlace(players: { Player })
	local lobbyId = PlaceConfig.GetPlaceId("Lobby")
	if lobbyId > 0 and #players > 0 then
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(lobbyId, players)
		end)
		if not ok then
			warn("[PvpMatch] Return teleport failed:", err)
			teleportLobby()
		end
	else
		teleportLobby()
	end
end

local function healForLobby(plr: Player)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = hum.MaxHealth
	end
end

local function buildOpponent(center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "PvpOpponent"
	model:SetAttribute("IsPvpOpponent", true)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 2)
	root.Anchored = true
	root.CanCollide = true
	root.Color = Color3.fromRGB(90, 100, 180)
	root.CFrame = CFrame.new(center + Vector3.new(0, 3, 12))
	root.Parent = model
	model.PrimaryPart = root

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = PvpArenaConfig.practiceOpponentHp
	hum.Health = PvpArenaConfig.practiceOpponentHp
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.Parent = workspace
	NameplateService.Setup(model, "Pvp", "Arena Opponent")
	return model
end

local function finishMatch(winningTeam: number?, winnerUserId: number?)
	if ending then
		return
	end
	ending = true
	stopGas()
	clearDeathConns()
	broadcastState({ phase = "Ended", winningTeam = winningTeam })

	local players = getPlayers()
	local winners: { number } = {}
	local losers: { number } = {}
	for _, plr in players do
		local won = false
		if winningTeam and PvpTeamService.IsTeamMatch() then
			won = PvpTeamService.GetTeam(plr.UserId) == winningTeam
		elseif winnerUserId then
			won = plr.UserId == winnerUserId
		end
		if won then
			table.insert(winners, plr.UserId)
		else
			table.insert(losers, plr.UserId)
		end
	end

	local mmrResults = {}
	if matchQueueId and RankedConfig.BracketKey(matchQueueId) and #winners > 0 then
		mmrResults = RankedService.ApplyMatchResult(matchQueueId, winners, losers)
	end

	for _, plr in players do
		local won = table.find(winners, plr.UserId) ~= nil
		local mmr = mmrResults[plr.UserId]
		MatchResultBridge.FinishMatch(plr, {
			mode = "PvP",
			won = won,
			queueId = matchQueueId,
			mmrDelta = if mmr then mmr.delta else nil,
			mmr = if mmr then mmr.mmr else nil,
			mmrTier = if mmr then mmr.tier else nil,
		})
		MatchResetService.ResetPlayer(plr)
	end

	LoadoutLockService.UnlockMany(allUserIds())
	SpectateService.ClearAll(allUserIds())

	if opponent and opponent.Parent then
		opponent:Destroy()
	end
	opponent = nil
	PvpArenaBuilder.Destroy(arena)
	arena = nil
	BossCombatTargets.SetActive(false)
	PvpTeamService.Clear()
	restoreTrainingDummy()

	task.delay(PvpArenaConfig.postMatchLobbyDelaySec, function()
		returnToLobbyPlace(players)
	end)

	active = false
	table.clear(matchTeams)
	matchQueueId = nil
	matchRanked = false
	ending = false
	print("[PvpMatch] Ended team=", winningTeam, "soloWinner=", winnerUserId)
end

local function checkTeamElimination()
	if not PvpTeamService.IsTeamMatch() or ending then
		return
	end
	local winner = PvpTeamService.ResolveWinningTeam()
	if winner then
		finishMatch(winner, nil)
	end
end

local function wireDeath(plr: Player)
	local function hook(char: Model)
		NameplateService.SetupPlayerCharacter(plr, char)
		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if hum then
			local c = hum.Died:Connect(function()
				PvpTeamService.RecordDeath(plr.UserId)
				if PvpTeamService.IsTeamMatch() then
					local allies = PvpTeamService.GetTeamUserIds(PvpTeamService.GetTeam(plr.UserId) or 1)
					local enemies = PvpTeamService.GetTeamUserIds(if (PvpTeamService.GetTeam(plr.UserId) or 1) == 1 then 2 else 1)
					SpectateService.BeginSpectate(plr.UserId, allies, enemies)
					checkTeamElimination()
				else
					finishMatch(nil, nil)
				end
			end)
			table.insert(deathConns, c)
		end
	end
	if plr.Character then
		hook(plr.Character)
	end
	table.insert(deathConns, plr.CharacterAdded:Connect(hook))
end

local function startGasPhase()
	if not arena or not arena.shrinkPart then
		return
	end
	local shrink = arena.shrinkPart
	local def = PvpArenaConfig.GetBracket(bracket)
	local startSize = shrink.Size
	local endSize = Vector3.new(8, 1, 8)
	local gasCfg = PvpArenaConfig.GasTiming(matchRanked)
	local shrinkDuration = gasCfg.shrinkSec
	local dpsDuration = gasCfg.gasDpsSec
	local dps = gasCfg.gasDps

	gasThread = task.spawn(function()
		broadcastState({ phase = "Shrink", seconds = shrinkDuration })
		local t0 = os.clock()
		while os.clock() - t0 < shrinkDuration do
			if ending or not active then
				return
			end
			local alpha = (os.clock() - t0) / shrinkDuration
			shrink.Size = startSize:Lerp(endSize, alpha)
			task.wait(0.25)
		end

		broadcastState({ phase = "Gas", dps = dps, seconds = dpsDuration })
		local gasEnd = os.clock() + dpsDuration
		while os.clock() < gasEnd do
			if ending or not active then
				return
			end
			for _, plr in getPlayers() do
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and arena and arena.shrinkPart then
					local half = arena.shrinkPart.Size / 2
					local localPos = arena.shrinkPart.CFrame:PointToObjectSpace(hrp.Position)
					if math.abs(localPos.X) > half.X or math.abs(localPos.Z) > half.Z then
						hum:TakeDamage(dps * 0.25)
					end
				end
			end
			checkTeamElimination()
			task.wait(0.25)
		end

		if active and not ending then
			-- Timeout — higher total HP team wins; tie → first death team loses
			local t1Hp, t2Hp = 0, 0
			for _, userId in PvpTeamService.GetTeamUserIds(1) do
				local plr = Players:GetPlayerByUserId(userId)
				local hum = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					t1Hp += hum.Health
				end
			end
			for _, userId in PvpTeamService.GetTeamUserIds(2) do
				local plr = Players:GetPlayerByUserId(userId)
				local hum = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					t2Hp += hum.Health
				end
			end
			if t1Hp > t2Hp then
				finishMatch(1, nil)
			elseif t2Hp > t1Hp then
				finishMatch(2, nil)
			else
				finishMatch(PvpTeamService.ResolveWinningTeam(), nil)
			end
		end
	end)
end

function PvpMatchService.IsActive(): boolean
	return active
end

function PvpMatchService.Start(payload: StartPayload): boolean
	if active then
		return false
	end
	if #payload.teams < 1 then
		return false
	end

	local totalPlayers = 0
	for _, team in payload.teams do
		totalPlayers += #team
	end
	if totalPlayers < 1 then
		return false
	end

	active = true
	ending = false
	bracket = payload.bracket
	matchTeams = payload.teams
	matchQueueId = payload.queueId
	if matchQueueId then
		local qdef = QueueConfig.Get(matchQueueId :: any)
		matchRanked = qdef and qdef.ranked == true or false
	else
		matchRanked = false
	end

	for _, userId in allUserIds() do
		LoadoutLockService.Lock(userId)
	end

	local practice = totalPlayers == 1 or #payload.teams < 2
	PvpTeamService.RegisterMatch(payload.teams, { practice = practice })
	hideTrainingDummy()

	local useStudioOffset = PlaceRuntime.IsLobby() or not PlaceRuntime.IsPvpArena()
	local center = PvpArenaConfig.ArenaCenter(bracket, useStudioOffset)
	arena = PvpArenaBuilder.Build(bracket, center)
	teleportToSpawns()

	local def = PvpArenaConfig.GetBracket(bracket)
	broadcastState({
		phase = "Countdown",
		seconds = PvpArenaConfig.introCountdownSec,
		bracket = bracket,
		arenaName = def.displayName,
	})

	for i = PvpArenaConfig.introCountdownSec, 1, -1 do
		broadcastState({ phase = "Countdown", seconds = i, bracket = bracket, arenaName = def.displayName })
		task.wait(1)
	end

	if arena then
		PvpArenaBuilder.OpenGates(arena)
	end
	PvpTeamService.SetCombatLocked(false)
	broadcastState({ phase = "Fight", bracket = bracket, arenaName = def.displayName })

	local players = getPlayers()
	if practice then
		opponent = buildOpponent(center)
		BossCombatTargets.SetActive(true)
		local hum = opponent:FindFirstChildOfClass("Humanoid")
		if hum then
			table.insert(deathConns, hum.Died:Connect(function()
				finishMatch(nil, players[1] and players[1].UserId)
			end))
		end
		if players[1] then
			wireDeath(players[1])
		end
	else
		for _, plr in players do
			wireDeath(plr)
		end
		local gasCfg = PvpArenaConfig.GasTiming(matchRanked)
		task.delay(gasCfg.combatSec, function()
			if active and not ending then
				startGasPhase()
			end
		end)
	end

	print(`[PvpMatch] Started bracket={bracket} players={totalPlayers} practice={practice}`)
	return true
end

return PvpMatchService
