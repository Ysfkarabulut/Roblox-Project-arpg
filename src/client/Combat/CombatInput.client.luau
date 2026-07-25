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
local CombatHitStop = require(script.Parent.CombatHitStop)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

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
-- During dodge, face dash direction instead of camera (one forward roll anim covers all dirs).
local dodgeFaceUntil = 0
local dodgeFaceDir: Vector3? = nil
-- Server-authoritative defend stance (guard OR parry). Do not set locally on RMB.
local defending = false
local rmbHeld = false
local reloadUntil = 0

local SHIFT_LOCK_OFFSET = CombatConfig.ShiftLockCameraOffset or Vector3.new(1.75, 0, 0)

local function beginDodgeFacing(dir: Vector3)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	dodgeFaceDir = flat.Unit
	local hold = CombatConfig.DodgeFaceHoldSec or ((CombatConfig.DodgeDashSec or 0.50) + 0.08)
	dodgeFaceUntil = os.clock() + hold
	-- Face once at dodge start — per-frame HRP snaps fight replication and shake the camera.
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dodgeFaceDir)
	end
end

-- Stamina HUD
local gui = UiTheme.ScreenGui({
	name = "CombatHud",
	displayOrder = UiTheme.DisplayOrder.Hud + 1,
})
gui.Parent = playerGui

local stamBarBg = Instance.new("Frame")
stamBarBg.Size = UDim2.fromOffset(220, 14)
stamBarBg.Position = UDim2.new(0.5, -110, 1, -200)
stamBarBg.BackgroundColor3 = C.HudTrack
stamBarBg.BorderSizePixel = 0
stamBarBg.Parent = gui
UiTheme.Corner(stamBarBg, UiTheme.Radius.Xs)
local stamFill = Instance.new("Frame")
stamFill.Size = UDim2.fromScale(1, 1)
stamFill.BackgroundColor3 = C.Stamina
stamFill.BorderSizePixel = 0
stamFill.Parent = stamBarBg
UiTheme.Corner(stamFill, UiTheme.Radius.Xs)
local aimLabel = UiTheme.Label({
	parent = gui,
	size = UDim2.fromOffset(160, 18),
	position = UDim2.new(0.5, -80, 1, -222),
	text = "ShiftLock ON (F4)",
	textSize = UiTheme.TextSize.Caption,
	color = C.AimOn,
	xAlign = Enum.TextXAlignment.Center,
})

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

local function isReloading(): boolean
	return os.clock() < reloadUntil
end

local function getHumanoid(): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function applyShiftLockState()
	local hum = getHumanoid()
	player:SetAttribute("ShiftLock", shiftLock)
	if shiftLock then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		if hum then
			hum.AutoRotate = false
			hum.CameraOffset = SHIFT_LOCK_OFFSET
		end
		aimLabel.Text = "ShiftLock ON (F4)"
		aimLabel.TextColor3 = C.AimOn
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if hum then
			hum.AutoRotate = true
			hum.CameraOffset = Vector3.zero
		end
		aimLabel.Text = "ShiftLock OFF (F4)"
		aimLabel.TextColor3 = C.AimOff
	end
end

--- Face camera yaw only — never override camera CFrame (that caused pitch slide).
--- During dodge, rotation is set once in beginDodgeFacing (no per-frame snap).
local function updateShiftLockCharacter()
	if not shiftLock or isTyping() then
		return
	end
	if os.clock() < dodgeFaceUntil then
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
		local target = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit)
		hrp.CFrame = target
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
	if isReloading() then
		return
	end
	local look, aim = aimPayload()
	CastAbility:FireServer(abilityId, look, aim)
end

local function doLightAttack()
	if defending or isReloading() then
		return
	end
	local look, aim = aimPayload()
	LightAttack:FireServer(look, aim)
end

local function setDodgeRolling(active: boolean)
	local char = player.Character
	if not char then
		return
	end
	if active then
		local dashSec = CombatConfig.DodgeDashSec or 0.50
		char:SetAttribute("DodgeRolling", os.clock() + dashSec + 0.08)
	else
		char:SetAttribute("DodgeRolling", nil)
	end
end

local function doDodge()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local dir = if hum then hum.MoveDirection else Vector3.zero
	if dir.Magnitude < 0.1 then
		dir = camera.CFrame.LookVector
	end
	beginDodgeFacing(dir)
	setDodgeRolling(true)
	CombatAnim.PlayDodge(dir)
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
		if animKey == "Dodge" and typeof(fx.look) == "Vector3" then
			beginDodgeFacing(fx.look)
			if not CombatAnim.IsDodgePlaying() then
				CombatAnim.Play("Dodge", fx.family, fx.comboStep, fx)
			end
		else
			CombatAnim.Play(animKey, fx.family, fx.comboStep, fx)
		end
		if typeof(fx.recoverySec) == "number" and fx.recoverySec > 0 and player.Character then
			local char = player.Character
			local comboMult = if typeof(fx.comboMoveMult) == "number" then fx.comboMoveMult else 1
			char:SetAttribute("ComboMoveMult", comboMult)
			task.delay(fx.recoverySec, function()
				if char.Parent then
					char:SetAttribute("ComboMoveMult", 1)
				end
			end)
		end
		if typeof(fx.reloadSec) == "number" and fx.reloadSec > 0 then
			reloadUntil = os.clock() + fx.reloadSec
			CombatAnim.PlayReload(fx.reloadSec)
		end
	else
		local other = Players:GetPlayerByUserId(userId)
		local char = other and other.Character
		if char and typeof(fx.anim) == "string" then
			CombatAnim.PlayOnCharacter(char, fx.anim, fx.family, fx.comboStep, fx)
		end
	end
	CombatVfx.Play(fx)
	if fx.anim ~= "Dodge" then
		CombatHitStop.TryOnFx(userId, fx, _hits)
	end
end)

ReactionFx.OnClientEvent:Connect(function(reactionId: string, pos: Vector3)
	CombatVfx.PlayReaction(reactionId, pos)
end)

CombatNotify.OnClientEvent:Connect(function(result: any)
	if typeof(result) ~= "table" then
		return
	end
	if result.action == "Dodge" and result.ok == false then
		dodgeFaceUntil = 0
		dodgeFaceDir = nil
		setDodgeRolling(false)
		CombatAnim.CancelDodge(0.06)
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
		if result.reason == "Reloading" then
			aimLabel.Text = "RELOADING"
		end
		print("[Combat] fail:", result.reason)
	end
	if result.ok and typeof(result.reloadSec) == "number" and result.reloadSec > 0 then
		reloadUntil = os.clock() + result.reloadSec
		CombatAnim.PlayReload(result.reloadSec)
	end
end)

RunService.Heartbeat:Connect(function()
	if isReloading() then
		local left = reloadUntil - os.clock()
		aimLabel.Text = string.format("RELOAD %.1fs", math.max(0, left))
	elseif shiftLock then
		aimLabel.Text = "ShiftLock ON (F4)"
	else
		aimLabel.Text = "ShiftLock OFF (F4)"
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
		stamFill.BackgroundColor3 = C.StaminaGuard
	elseif payload.parrying then
		stamFill.BackgroundColor3 = C.StaminaParry
	else
		stamFill.BackgroundColor3 = C.Stamina
	end
end)

print("[CombatInput] LMB LA · Shift dodge · RMB guard/parry · Ctrl sprint · F4 shiftlock · QER123")
