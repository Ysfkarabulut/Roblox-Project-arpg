--[[
	Boss encounter lifecycle — start, wipe, win, cleanup.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local BossEncounterConfig = require(game.ReplicatedStorage.Shared.Config.BossEncounterConfig)
local BossArenaBuilder = require(script.Parent.BossArenaBuilder)
local BossEntityService = require(script.Parent.BossEntityService)
local BossCombatTargets = require(script.Parent.BossCombatTargets)
local BossHazardService = require(script.Parent.BossHazardService)
local BossSync = require(script.Parent.BossSync)
local EyeBossController = require(script.Parent.EyeBossController)
local MatchResultBridge = require(script.Parent.Parent.Loot.MatchResultBridge)
local MatchResetService = require(script.Parent.Parent.Combat.MatchResetService)

local BossEncounterService = {}

export type StartPayload = {
	bossId: string,
	partyUserIds: { number },
	partySize: number,
}

local active = false
local arena: BossArenaBuilder.ArenaHandle? = nil
local controller: any = nil
local partyUserIds: { number } = {}
local bossId: string? = nil
local ending = false
local wipeConn: RBXScriptConnection? = nil
local deathConns: { RBXScriptConnection } = {}

local function getPlayers(): { Player }
	local out: { Player } = {}
	for _, userId in partyUserIds do
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
	local dummy = ServerStorage:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		dummy.Parent = workspace
		return
	end
	local DummyService = require(script.Parent.Parent.Combat.DummyService)
	DummyService.Ensure()
end

local function teleportPlayersToArena(spawns: { CFrame })
	local players = getPlayers()
	for i, plr in players do
		local char = plr.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local spawn = spawns[((i - 1) % #spawns) + 1]
			if hrp and spawn then
				hrp.CFrame = spawn
			end
		end
	end
end

local function teleportPlayersToLobby()
	local spawn = BossEncounterConfig.LobbySpawn
	for _, plr in getPlayers() do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = CFrame.new(spawn)
		end
	end
end

local function clearDeathConns()
	for _, c in deathConns do
		c:Disconnect()
	end
	table.clear(deathConns)
end

local function finishEncounter(won: boolean)
	if ending then
		return
	end
	ending = true

	if controller then
		controller.Stop()
		controller = nil
	end
	if wipeConn then
		wipeConn:Disconnect()
		wipeConn = nil
	end
	clearDeathConns()

	local id = bossId or "eye"
	for _, plr in getPlayers() do
		MatchResetService.ResetPlayer(plr)
		if won or BossHazardService.IsAlive(plr) then
			MatchResultBridge.FinishMatch(plr, {
				mode = "PvE",
				won = won,
				bossId = id,
			})
		else
			MatchResultBridge.FinishMatch(plr, {
				mode = "PvE",
				won = false,
				bossId = id,
			})
		end
	end

	BossEntityService.Destroy()
	BossArenaBuilder.Destroy(arena)
	arena = nil
	BossCombatTargets.SetActive(false)
	restoreTrainingDummy()
	teleportPlayersToLobby()

	active = false
	bossId = nil
	table.clear(partyUserIds)
	ending = false

	print(`[BossEncounter] Ended boss={id} won={won}`)
end

local function checkWipe()
	if ending or not active then
		return
	end
	if #BossHazardService.GetAlivePlayers(partyUserIds) == 0 then
		finishEncounter(false)
	end
end

local function wirePlayerDeath(plr: Player)
	local function hook(char: Model)
		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if not hum then
			return
		end
		local c = hum.Died:Connect(function()
			task.defer(checkWipe)
		end)
		table.insert(deathConns, c)
	end
	if plr.Character then
		hook(plr.Character)
	end
	local added = plr.CharacterAdded:Connect(hook)
	table.insert(deathConns, added)
end

function BossEncounterService.IsActive(): boolean
	return active
end

function BossEncounterService.GetBossModel(): Model?
	return BossEntityService.GetModel()
end

function BossEncounterService.Start(payload: StartPayload): boolean
	if active then
		warn("[BossEncounter] Already active")
		return false
	end
	local def = BossEncounterConfig.Get(payload.bossId)
	if not def then
		warn("[BossEncounter] Unknown boss", payload.bossId)
		return false
	end
	if #payload.partyUserIds < 1 then
		return false
	end

	active = true
	ending = false
	bossId = payload.bossId
	partyUserIds = table.clone(payload.partyUserIds)

	hideTrainingDummy()

	local arenaCfg = def.arena
	arena = BossArenaBuilder.Build(arenaCfg.center, arenaCfg.radius)
	teleportPlayersToArena(arena.spawnPoints)

	local hp = BossEncounterConfig.ScaledHp(payload.bossId, payload.partySize)
	BossEntityService.Spawn(payload.bossId, arenaCfg.center + Vector3.new(0, 8, 0), hp)
	BossEntityService.SetOnDeath(function()
		finishEncounter(true)
	end)

	BossCombatTargets.SetActive(true)

	for _, plr in getPlayers() do
		wirePlayerDeath(plr)
	end

	BossSync.FireState({
		kind = "Countdown",
		seconds = def.introCountdownSec,
		bossId = payload.bossId,
	})

	task.wait(def.introCountdownSec)

	if not active then
		return false
	end

	controller = EyeBossController.Start(
		payload.bossId,
		partyUserIds,
		arenaCfg.center,
		arenaCfg.radius
	)

	wipeConn = RunService.Heartbeat:Connect(function()
		checkWipe()
	end)

	print(`[BossEncounter] Started {payload.bossId} party={payload.partySize} hp={hp}`)
	return true
end

function BossEncounterService.ForceEnd()
	if active then
		finishEncounter(false)
	end
end

return BossEncounterService
