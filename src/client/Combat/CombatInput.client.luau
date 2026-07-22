--[[
	Combat input — LMB light attack, hotbar actives, Shift dodge, RMB guard/parry.
	F4: classic shift lock (mouse center + face camera). Soft aimlock deferred.
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
local shiftLock = true
-- Server-authoritative defend stance (guard OR parry). Do not set locally on RMB.
local defending = false
local rmbHeld = false

local SHIFT_LOCK_OFFSET = CombatConfig.ShiftLockCameraOffset or Vector3.new(1.75, 0, 0)

-- Stamina HUD
local gui = Instance.new("ScreenGui")
gui.Name = "CombatHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local stamBarBg = Instance.new("Frame")
stamBarBg.Size = UDim2.fromOffset(220, 14)
stamBarBg.Position = UDim2.new(0.5, -110, 1, -200)
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
aimLabel.Position = UDim2.new(0.5, -80, 1, -222)
aimLabel.BackgroundTransparency = 1
aimLabel.Font = Enum.Font.Gotham
aimLabel.TextSize = 11
aimLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
aimLabel.Text = "ShiftLock ON (F4)"
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

local function getHumanoid(): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function applyShiftLockState()
	local hum = getHumanoid()
	if shiftLock then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		if hum then
			hum.AutoRotate = false
			hum.CameraOffset = SHIFT_LOCK_OFFSET
		end
		aimLabel.Text = "ShiftLock ON (F4)"
		aimLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if hum then
			hum.AutoRotate = true
			hum.CameraOffset = Vector3.zero
		end
		aimLabel.Text = "ShiftLock OFF (F4)"
		aimLabel.TextColor3 = Color3.fromRGB(160, 170, 180)
	end
end

--- Face camera yaw only — never override camera CFrame (that caused pitch slide).
local function updateShiftLockCharacter()
	if not shiftLock or isTyping() then
		return
	end
	camera = Workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not hrp then
		return
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	local flat = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if flat.Magnitude > 0.1 then
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit)
	end
end

local function aimPayload(): (Vector3, Vector3)
	camera = Workspace.CurrentCamera
	local look = camera.CFrame.LookVector
	local ray
	if shiftLock then
		local vp = camera.ViewportSize
		ray = camera:ViewportPointToRay(vp.X * 0.5, vp.Y * 0.5)
	else
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	end
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
	DodgeRemote:FireServer(dir)
end

UserInputService.InputBegan:Connect(function(input, processed)
	-- F4 shift lock — Studio/UI often marks this processed; still allow
	if input.KeyCode == Enum.KeyCode.F4 and not isTyping() then
		shiftLock = not shiftLock
		applyShiftLockState()
		return
	end
	if processed or isTyping() then
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
	local sprint = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and not isTyping()
	player:SetAttribute("Sprinting", sprint)
end)

-- Character yaw only; Roblox camera owns pitch/yaw from mouse
RunService:BindToRenderStep("CombatShiftLock", Enum.RenderPriority.Character.Value, function()
	if isTyping() then
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
		return
	end
	updateShiftLockCharacter()
end)

player.CharacterAdded:Connect(function()
	task.defer(applyShiftLockState)
end)

applyShiftLockState()

CombatFx.OnClientEvent:Connect(function(userId: number, fx: any, _hits: any)
	if typeof(fx) ~= "table" then
		return
	end
	if userId == player.UserId then
		local animKey = fx.anim or "Melee"
		CombatAnim.Play(animKey, fx.family, fx.comboStep, fx)
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

print("[CombatInput] LMB LA · Shift dodge · RMB guard/parry · Ctrl sprint · F4 shiftlock · QER123")
