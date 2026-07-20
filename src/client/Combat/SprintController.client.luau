--[[
	Stance-based sprint locomotion (7 styles).
	Catalog anim + playback speed/lean; foot dust VFX.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AnimConfig = require(game.ReplicatedStorage.Shared.Config.AnimConfig)
local StanceConfig = require(game.ReplicatedStorage.Shared.Config.StanceConfig)
local CombatVfx = require(script.Parent.CombatVfx)

local player = Players.LocalPlayer

local sprintTracks: { [string]: AnimationTrack } = {}
local activeTrack: AnimationTrack? = nil
local loadedChar: Model? = nil
local dustAcc = 0

local function getAnimator(char: Model): Animator?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	return animator
end

local function loadSprintTracks(char: Model)
	if loadedChar == char and next(sprintTracks) then
		return
	end
	table.clear(sprintTracks)
	loadedChar = char
	local animator = getAnimator(char)
	if not animator then
		return
	end
	for stance, cfg in AnimConfig.Sprint do
		local anim = Instance.new("Animation")
		anim.AnimationId = cfg.animId
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not ok or not track then
			anim.AnimationId = AnimConfig.SprintFallback
			ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
		end
		if ok and track then
			track.Looped = true
			track.Priority = Enum.AnimationPriority.Movement
			sprintTracks[stance] = track
		end
	end
end

local function currentStance(): string
	local s = player:GetAttribute("CombatStance")
	if typeof(s) == "string" and AnimConfig.Sprint[s] then
		return s
	end
	return "OneHandFocus"
end

local function stopSprint()
	if activeTrack then
		activeTrack:Stop(0.2)
		activeTrack = nil
	end
end

local function startSprint(stance: string)
	loadSprintTracks(player.Character :: Model)
	local track = sprintTracks[stance]
	if not track then
		return
	end
	if activeTrack == track and track.IsPlaying then
		return
	end
	stopSprint()
	local cfg = AnimConfig.Sprint[stance]
	track:Play(0.2, 1, cfg and cfg.speed or 1)
	activeTrack = track
end

local function applyLean(char: Model, leanDeg: number, on: boolean)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	-- Soft visual lean via attribute consumed nowhere else — optional BodyGyro avoided.
	-- Use Humanoid CameraOffset-ish: tilt accessory folder
	local leanFolder = char:FindFirstChild("SprintLean")
	if not on then
		if leanFolder then
			leanFolder:Destroy()
		end
		return
	end
	-- Store lean for dust color / debug
	char:SetAttribute("SprintLean", leanDeg)
end

local function isSprinting(): boolean
	if UserInputService:GetFocusedTextBox() then
		return false
	end
	if not player:GetAttribute("Sprinting") then
		return false
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.MoveDirection.Magnitude < 0.15 then
		return false
	end
	if hum.FloorMaterial == Enum.Material.Air then
		return false
	end
	return true
end

RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	if not char then
		stopSprint()
		return
	end
	loadSprintTracks(char)

	local stance = currentStance()
	local cfg = AnimConfig.Sprint[stance] or AnimConfig.Sprint.OneHandFocus

	if isSprinting() then
		startSprint(stance)
		applyLean(char, cfg.lean, true)
		dustAcc += dt
		if dustAcc >= 0.12 then
			dustAcc = 0
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				-- Stance tint: map stance to slight color variation
				local tint = Color3.fromRGB(190, 190, 195)
				if stance == "Bow" or stance == "Staff" then
					tint = Color3.fromRGB(160, 200, 255)
				elseif stance == "TwoHandMelee" then
					tint = Color3.fromRGB(200, 170, 140)
				elseif stance == "DualWield" then
					tint = Color3.fromRGB(220, 200, 160)
				elseif stance == "OneHandShield" then
					tint = Color3.fromRGB(170, 180, 200)
				elseif stance == "Crossbow" then
					tint = Color3.fromRGB(180, 160, 140)
				end
				CombatVfx.SprintDust(hrp, tint)
			end
		end
	else
		stopSprint()
		applyLean(char, 0, false)
		dustAcc = 0
	end
end)

player.CharacterAdded:Connect(function()
	table.clear(sprintTracks)
	loadedChar = nil
	activeTrack = nil
end)

-- Expose for UI / debug
_G.GetCombatStance = currentStance

print("[SprintController] 7 stance sprints ready")
