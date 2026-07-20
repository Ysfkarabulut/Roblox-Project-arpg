--[[
	Combat input — LMB light attack, hotbar actives, Shift dodge, RMB guard/parry.
	Aim: soft aimlock (F4) or mouse ray.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local HotbarConfig = require(ReplicatedStorage.Shared.Config.HotbarConfig)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)
local CombatAnim = require(script.Parent.CombatAnim)
local CombatVfx = require(script.Parent.CombatVfx)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local combatRemotes = ReplicatedStorage:WaitForChild("CombatRemotes")
local CastAbility = combatRemotes:WaitForChild("CastAbility") :: RemoteEvent
local LightAttack = combatRemotes:WaitForChild("LightAttack") :: RemoteEvent
local DodgeRemote = combatRemotes:WaitForChild("Dodge") :: RemoteEvent
local GuardState = combatRemotes:WaitForChild("GuardState") :: RemoteEvent
local CombatFx = combatRemotes:WaitForChild("CombatFx") :: RemoteEvent
local CombatNotify = combatRemotes:WaitForChild("CombatNotify") :: RemoteEvent
local StaminaUpdate = combatRemotes:WaitForChild("StaminaUpdate") :: RemoteEvent
local ReactionFx = combatRemotes:WaitForChild("ReactionFx") :: RemoteEvent

local invRemotes = ReplicatedStorage:WaitForChild("InventoryRemotes")
local InventoryUpdated = invRemotes:WaitForChild("InventoryUpdated") :: RemoteEvent
local GetSnapshot = invRemotes:WaitForChild("GetSnapshot") :: RemoteFunction

local hotbar: { [number]: string? } = {}
local cdUntil: { [string]: number } = {}
local aimlock = true
-- Server-authoritative defend stance (guard OR parry). Do not set locally on RMB.
local defending = false
local rmbHeld = false

-- Stamina HUD
local gui = Instance.new("ScreenGui")
gui.Name = "CombatHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local stamBarBg = Instance.new("Frame")
stamBarBg.Size = UDim2.fromOffset(220, 14)
stamBarBg.Position = UDim2.new(0.5, -110, 1, -110)
stamBarBg.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
stamBarBg.BorderSizePixel = 0
stamBarBg.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = stamBarBg
end
local stamFill = Instance.new("Frame")
stamFill.Size = UDim2.fromScale(1, 1)
stamFill.BackgroundColor3 = Color3.fromRGB(90, 180, 120)
stamFill.BorderSizePixel = 0
stamFill.Parent = stamBarBg
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = stamFill
end
local aimLabel = Instance.new("TextLabel")
aimLabel.Size = UDim2.fromOffset(160, 18)
aimLabel.Position = UDim2.new(0.5, -80, 1, -132)
aimLabel.BackgroundTransparency = 1
aimLabel.Font = Enum.Font.Gotham
aimLabel.TextSize = 11
aimLabel.TextColor3 = Color3.fromRGB(160, 170, 180)
aimLabel.Text = "Aimlock ON (F4)"
aimLabel.Parent = gui

local function refreshHotbar(snap: any)
	if typeof(snap) == "table" and typeof(snap.hotbar) == "table" then
		hotbar = snap.hotbar
	end
end

task.defer(function()
	local ok, snap = pcall(function()
		return GetSnapshot:InvokeServer()
	end)
	if ok then
		refreshHotbar(snap)
	end
end)
InventoryUpdated.OnClientEvent:Connect(refreshHotbar)

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function findAimlockTarget(): Vector3?
	if not aimlock or not player.Character then
		return nil
	end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	local look = camera.CFrame.LookVector
	local best: BasePart? = nil
	local bestScore = -1e9
	local function consider(model: Model)
		if model == player.Character then
			return
		end
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		local offset = pp.Position - hrp.Position
		local dist = offset.Magnitude
		if dist > CombatConfig.AimlockRange or dist < 1 then
			return
		end
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude < 0.2 then
			return
		end
		local ang = math.deg(math.acos(math.clamp(look:Dot(offset.Unit), -1, 1)))
		if ang > CombatConfig.AimlockConeDeg then
			return
		end
		local score = -ang * 2 - dist * 0.1
		if score > bestScore then
			bestScore = score
			best = pp
		end
	end
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		consider(dummy)
	end
	for _, plr in Players:GetPlayers() do
		if plr ~= player and plr.Character then
			consider(plr.Character)
		end
	end
	return if best then best.Position else nil
end

local function aimPayload(): (Vector3, Vector3)
	local lockPos = findAimlockTarget()
	local look = camera.CFrame.LookVector
	if lockPos then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local to = (lockPos - hrp.Position)
			if to.Magnitude > 0.1 then
				look = look:Lerp(to.Unit, CombatConfig.AimlockSoftness)
			end
		end
		return look, lockPos
	end
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		params.FilterDescendantsInstances = { player.Character }
	end
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 100, params)
	local aimPos = if hit then hit.Position else ray.Origin + ray.Direction * 50
	return look, aimPos
end

local function tryCastSlot(slotIndex: number)
	local abilityId = hotbar[slotIndex]
	if not abilityId then
		return
	end
	if (cdUntil[abilityId] or 0) > os.clock() then
		return
	end
	local look, aim = aimPayload()
	CombatAnim.Play("Cast")
	CastAbility:FireServer(abilityId, look, aim)
end

local function doLightAttack()
	if defending then
		return
	end
	local look, aim = aimPayload()
	LightAttack:FireServer(look, aim)
end

local function doDodge()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local dir = if hum then hum.MoveDirection else Vector3.zero
	if dir.Magnitude < 0.1 then
		dir = camera.CFrame.LookVector
	end
	CombatAnim.Play("Dodge")
	DodgeRemote:FireServer(dir)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or isTyping() then
		return
	end
	if input.KeyCode == Enum.KeyCode.F4 then
		aimlock = not aimlock
		aimLabel.Text = if aimlock then "Aimlock ON (F4)" else "Aimlock OFF · mouse (F4)"
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		doLightAttack()
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rmbHeld = true
		GuardState:FireServer(true)
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		doDodge()
		return
	end
	for slot, key in HotbarConfig.Keys do
		if input.KeyCode == key then
			tryCastSlot(slot)
			return
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rmbHeld = false
		defending = false
		GuardState:FireServer(false)
	end
end)

-- Sprint: hold Ctrl
RunService.RenderStepped:Connect(function()
	local sprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
	player:SetAttribute("Sprinting", sprint)
end)

CombatFx.OnClientEvent:Connect(function(userId: number, fx: any, _hits: any)
	if typeof(fx) ~= "table" then
		return
	end
	if userId == player.UserId then
		local animKey = fx.anim or "Melee"
		CombatAnim.Play(animKey, fx.family, fx.comboStep)
	end
	CombatVfx.Play(fx)
end)

ReactionFx.OnClientEvent:Connect(function(reactionId: string, pos: Vector3)
	CombatVfx.PlayReaction(reactionId, pos)
end)

CombatNotify.OnClientEvent:Connect(function(result: any)
	if typeof(result) ~= "table" then
		return
	end
	if result.action == "Guard" or result.action == "Parry" or result.action == "Defend" then
		defending = rmbHeld and result.ok == true and (result.guarding == true or result.parrying == true)
		if result.ok == false and rmbHeld then
			-- Dual/Focus/no-main: server rejected — do not lock LMB
			defending = false
		end
	end
	if result.ok and result.fx and typeof(result.fx.cooldownSec) == "number" and result.abilityId then
		cdUntil[result.abilityId] = os.clock() + result.fx.cooldownSec
	end
	if result.ok and result.hits then
		for _, h in result.hits do
			local tags = {}
			if h.crit then
				table.insert(tags, "CRIT")
			end
			if h.blocked then
				table.insert(tags, "BLOCK")
			end
			if h.dodged then
				table.insert(tags, "DODGE")
			end
			if h.perfectParry then
				table.insert(tags, "PERFECT")
			elseif h.parried then
				table.insert(tags, "PARRY_FAIL")
			end
			if h.comboStep then
				table.insert(tags, "L" .. tostring(h.comboStep))
			end
			print("[Combat]", table.concat(tags, " "), "dmg", h.dealt, "mu", h.matchupMult, "dr", h.drPct)
		end
	elseif result.ok and result.whiff then
		print("[Combat] whiff L" .. tostring(result.comboStep))
	elseif not result.ok and result.reason then
		print("[Combat] fail:", result.reason)
	end
end)

StaminaUpdate.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local cur = payload.current or 0
	local max = math.max(1, payload.max or 1)
	stamFill.Size = UDim2.fromScale(math.clamp(cur / max, 0, 1), 1)
	if payload.guarding then
		stamFill.BackgroundColor3 = Color3.fromRGB(100, 140, 220)
	elseif payload.parrying then
		stamFill.BackgroundColor3 = Color3.fromRGB(200, 170, 80)
	else
		stamFill.BackgroundColor3 = Color3.fromRGB(90, 180, 120)
	end
end)

print("[CombatInput] LMB LA · Shift dodge · RMB guard/parry · Ctrl sprint · F4 aimlock · QER123")
