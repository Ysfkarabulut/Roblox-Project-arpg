--[[
	Stance-based sprint locomotion (7 styles).
	CombatAnims KeyframeSequence (clipName) via KeyframeClipPlayer when present;
	otherwise catalog AnimationTrack. Foot dust VFX.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AnimConfig = require(game.ReplicatedStorage.Shared.Config.AnimConfig)
local AnimResolver = require(game.ReplicatedStorage.Shared.Config.AnimResolver)
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local StatusQuery = require(game.ReplicatedStorage.Shared.Combat.StatusQuery)
local CombatVfx = require(script.Parent.CombatVfx)
local KeyframeClipPlayer = require(script.Parent.KeyframeClipPlayer)

local player = Players.LocalPlayer

local sprintTracks: { [string]: AnimationTrack } = {}
local sprintKf: { [string]: KeyframeSequence } = {}
local activeTrack: AnimationTrack? = nil
local activeKfHandle: KeyframeClipPlayer.Handle? = nil
local activeKfStance: string? = nil
local loadedChar: Model? = nil
local dustAcc = 0
local baseWalkSpeed = CombatConfig.WalkSpeed

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

local function findCombatAnimKf(cfg: any): KeyframeSequence?
	-- Local KeyframeSequence playback via Transform is unreliable for Mixamo imports
	-- on AnimationConstraint R15 (RegisterAnimationClip → Length=0). Use published
	-- Animation instances / catalog animId instead. Set UseLocalKFClips=true to experiment.
	if not _G.UseLocalKFClips then
		return nil
	end
	local folder = ReplicatedStorage:FindFirstChild("CombatAnims")
	if not folder or typeof(cfg) ~= "table" then
		return nil
	end
	local names: { string } = {}
	if typeof(cfg.clipName) == "string" then
		table.insert(names, cfg.clipName)
	end
	if typeof(cfg.clipNameAlts) == "table" then
		for _, n in cfg.clipNameAlts do
			if typeof(n) == "string" then
				table.insert(names, n)
			end
		end
	end
	for _, name in names do
		local kf = KeyframeClipPlayer.Find(folder, name)
		if kf and KeyframeClipPlayer.GetDuration(kf) > 0.05 then
			return kf
		end
	end
	return nil
end

--- Catalog / Animation instance id (no KeyframeSequence registration — that path is Length=0 in Play).
local function resolveCatalogAnimId(stance: string): string
	local resolved = AnimResolver.ResolveSprint(stance)
	if resolved then
		return resolved.animId
	end
	return AnimConfig.SprintFallback
end

local function loadSprintTracks(char: Model)
	if loadedChar == char and (next(sprintTracks) or next(sprintKf)) then
		return
	end
	table.clear(sprintTracks)
	table.clear(sprintKf)
	loadedChar = char
	local animator = getAnimator(char)

	for stance, cfg in AnimConfig.Sprint do
		local kf = findCombatAnimKf(cfg)
		if kf then
			sprintKf[stance] = kf
		elseif animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = resolveCatalogAnimId(stance)
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
end

local function currentStance(): string
	local s = player:GetAttribute("CombatStance")
	if typeof(s) == "string" and AnimConfig.Sprint[s] then
		return s
	end
	return "OneHandFocus"
end

local function stopSprint()
	if activeKfHandle then
		activeKfHandle.stop()
		activeKfHandle = nil
		activeKfStance = nil
	end
	if activeTrack then
		activeTrack:Stop(0.2)
		activeTrack = nil
	end
end

local function startSprint(stance: string)
	local char = player.Character
	if not char then
		return
	end
	loadSprintTracks(char)

	local kf = sprintKf[stance]
	if kf then
		if activeKfStance == stance and activeKfHandle and activeKfHandle.isPlaying() then
			return
		end
		stopSprint()
		local cfg = AnimConfig.Sprint[stance]
		activeKfHandle = KeyframeClipPlayer.Play(char, kf, {
			looped = true,
			speed = (cfg and cfg.speed) or 1,
		})
		activeKfStance = stance
		return
	end

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
	local leanFolder = char:FindFirstChild("SprintLean")
	if not on then
		if leanFolder then
			leanFolder:Destroy()
		end
		return
	end
	char:SetAttribute("SprintLean", leanDeg)
end

local function moveSpeedMult(char: Model): number
	local mult = 1
	local attr = char:GetAttribute("MoveSpeedMult")
	if typeof(attr) == "number" then
		mult *= math.clamp(attr, 0, 1)
	end
	local combo = char:GetAttribute("ComboMoveMult")
	if typeof(combo) == "number" then
		mult *= math.clamp(combo, 0, 1)
	end
	return mult
end

local function isDodgeRolling(char: Model): boolean
	local untilAt = char:GetAttribute("DodgeRolling")
	return typeof(untilAt) == "number" and os.clock() < untilAt
end

local function applyWalkSpeed(hum: Humanoid, char: Model, sprinting: boolean)
	local mult = moveSpeedMult(char)
	local speed = if sprinting then CombatConfig.SprintWalkSpeed else baseWalkSpeed
	hum.WalkSpeed = speed * mult
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
	local stam = player:GetAttribute("Stamina")
	if typeof(stam) == "number" and stam <= 0 then
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

	local hum = char:FindFirstChildOfClass("Humanoid")
	local rolling = isDodgeRolling(char)
	local stance = currentStance()
	local cfg = AnimConfig.Sprint[stance] or AnimConfig.Sprint.OneHandFocus
	local sprinting = not rolling and isSprinting()

	if hum then
		if rolling then
			hum.WalkSpeed = 0
		else
			applyWalkSpeed(hum, char, sprinting)
		end
	end

	if rolling then
		stopSprint()
		applyLean(char, 0, false)
		dustAcc = 0
		return
	end

	if sprinting then
		startSprint(stance)
		applyLean(char, cfg.lean, true)
		dustAcc += dt
		if dustAcc >= 0.12 then
			dustAcc = 0
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
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

player.CharacterAdded:Connect(function(char)
	stopSprint()
	table.clear(sprintTracks)
	table.clear(sprintKf)
	loadedChar = nil
	activeTrack = nil
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if hum then
		baseWalkSpeed = CombatConfig.WalkSpeed
		hum.WalkSpeed = baseWalkSpeed
	end
end)

_G.GetCombatStance = currentStance

print("[SprintController] sprint ready (KF clip player + catalog fallback)")
