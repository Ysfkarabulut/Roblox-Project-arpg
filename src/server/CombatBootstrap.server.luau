--[[
	Combat bootstrap — LA, abilities, dodge, guard, stamina, reactions, visuals.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AbilityService = require(script.Parent.Combat.AbilityService)
local LightAttackService = require(script.Parent.Combat.LightAttackService)
local DamageService = require(script.Parent.Combat.DamageService)
local DummyService = require(script.Parent.Combat.DummyService)
local ReactionResolver = require(script.Parent.Combat.ReactionResolver)
local DodgeService = require(script.Parent.Combat.DodgeService)
local GuardService = require(script.Parent.Combat.GuardService)
local ParryService = require(script.Parent.Combat.ParryService)
local StaminaService = require(script.Parent.Combat.StaminaService)
local WeaponVisualService = require(script.Parent.Combat.WeaponVisualService)
local StatusService = require(script.Parent.Combat.StatusService)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "CombatRemotes"
remotesFolder.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local CastAbility = remoteEvent("CastAbility")
local LightAttack = remoteEvent("LightAttack")
local Dodge = remoteEvent("Dodge")
local GuardState = remoteEvent("GuardState")
local CombatFx = remoteEvent("CombatFx")
local CombatNotify = remoteEvent("CombatNotify")
local StaminaUpdate = remoteEvent("StaminaUpdate")
local ReactionFx = remoteEvent("ReactionFx")

DummyService.Ensure()

ReactionResolver.Bind({
	dealBurst = function(entity, amount, reactionId, sourceUserId)
		DamageService.DealBurst(entity, amount, reactionId, sourceUserId)
	end,
	onFx = function(entity, reactionId)
		local pp = (entity :: Model).PrimaryPart or entity:FindFirstChild("HumanoidRootPart")
		local pos = if pp and pp:IsA("BasePart") then pp.Position else Vector3.zero
		ReactionFx:FireAllClients(reactionId, pos)
		if entity.Name == "TrainingDummy" then
			DummyService.RefreshStatusLabel(StatusService.FormatShort(entity))
		end
	end,
})

CastAbility.OnServerEvent:Connect(function(player: Player, abilityId: string, lookVector: Vector3?, aimPosition: Vector3?)
	if typeof(abilityId) ~= "string" then
		return
	end
	local result = AbilityService.Cast(player, abilityId, lookVector, aimPosition)
	CombatNotify:FireClient(player, result)
	if result.ok and result.fx then
		CombatFx:FireAllClients(player.UserId, result.fx, result.hits)
	end
end)

LightAttack.OnServerEvent:Connect(function(player: Player, lookVector: Vector3?, aimPosition: Vector3?)
	local result = LightAttackService.Swing(player, lookVector, aimPosition)
	CombatNotify:FireClient(player, result)
	if result.ok and result.fx then
		CombatFx:FireAllClients(player.UserId, result.fx, result.hits)
	end
end)

Dodge.OnServerEvent:Connect(function(player: Player, moveDir: Vector3?)
	local ok, err = DodgeService.Try(player, moveDir)
	CombatNotify:FireClient(player, { ok = ok, reason = err, action = "Dodge" })
	if ok then
		CombatFx:FireAllClients(player.UserId, {
			anim = "Dodge",
			vfx = "Dash",
			element = "Wind",
			origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart :: BasePart).Position,
			look = (function()
				local d = moveDir
				if typeof(d) ~= "Vector3" or d.Magnitude < 0.1 then
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					d = if hrp then hrp.CFrame.LookVector else Vector3.new(0, 0, -1)
				end
				d = Vector3.new(d.X, 0, d.Z)
				return if d.Magnitude > 0.1 then d.Unit else Vector3.new(0, 0, -1)
			end)(),
			range = CombatConfig.DodgeDistance,
		}, nil)
	end
end)

-- RMB: Shield → Guard; aksi halde (main varken) → Parry
GuardState.OnServerEvent:Connect(function(player: Player, on: boolean)
	if typeof(on) ~= "boolean" then
		return
	end
	local userId = player.UserId
	local ok = false
	local action = "Defend"
	if on then
		if GuardService.GetShieldDef(userId) then
			ParryService.SetParrying(player, false)
			ok = GuardService.SetGuarding(player, true)
			action = "Guard"
		elseif ParryService.CanParry(userId) then
			GuardService.SetGuarding(player, false)
			ok = ParryService.SetParrying(player, true)
			action = "Parry"
		else
			ok = false
			action = "Defend"
		end
	else
		GuardService.SetGuarding(player, false)
		ParryService.SetParrying(player, false)
		ok = true
		action = "Defend"
	end
	CombatNotify:FireClient(player, {
		ok = ok,
		action = action,
		guarding = GuardService.IsGuarding(userId),
		parrying = ParryService.IsParrying(userId),
	})
end)

local function refreshVisual(player: Player)
	task.defer(function()
		if player.Character then
			WeaponVisualService.Refresh(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		refreshVisual(player)
	end)
end)

for _, p in Players:GetPlayers() do
	p.CharacterAdded:Connect(function()
		refreshVisual(p)
	end)
	if p.Character then
		refreshVisual(p)
	end
end

-- Expose for InventoryBootstrap
_G.RefreshWeaponVisuals = function(player: Player)
	WeaponVisualService.Refresh(player)
end

local acc = 0
local stamAcc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	stamAcc += dt
	if acc >= 0.05 then
		acc = 0
		ReactionResolver.ResolveAllPending()
	end
	if stamAcc >= 1 then
		stamAcc -= 1
		DamageService.TickDoTs()
	end
	for _, player in Players:GetPlayers() do
		local defending = GuardService.IsGuarding(player.UserId) or ParryService.IsParrying(player.UserId)
		local sprinting = player:GetAttribute("Sprinting") == true
		GuardService.Tick(player, dt)
		ParryService.Tick(player, dt)
		StaminaService.Tick(player.UserId, dt, defending, sprinting)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		for _, player in Players:GetPlayers() do
			StaminaUpdate:FireClient(player, {
				current = StaminaService.Get(player.UserId),
				max = StaminaService.Max(player.UserId),
				guarding = GuardService.IsGuarding(player.UserId),
				parrying = ParryService.IsParrying(player.UserId),
			})
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	AbilityService.Clear(player.UserId)
	LightAttackService.Clear(player.UserId)
	DodgeService.Clear(player.UserId)
	GuardService.Clear(player.UserId)
	ParryService.Clear(player.UserId)
	StaminaService.Clear(player.UserId)
end)

print("[CombatBootstrap] LA combo + dodge/guard/parry + reactions ready")
