--[[
	Combat action tracks + procedural L1–L3 body/weapon swings (mesh-safe).
	Dodge = soft dash lean (no hard somersault physics).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local AnimConfig = require(ReplicatedStorage.Shared.Config.AnimConfig)
local KeyframeClipPlayer = require(script.Parent.KeyframeClipPlayer)

local CombatAnim = {}

local ACTION_KEYS = { "Melee", "Cast", "Bow", "Buff", "Dodge" }

local tracks: { [string]: AnimationTrack } = {}
local loadedFor: Model? = nil
local stopTokens: { [string]: number } = {}
local swingToken = 0
local swingUntil = 0
local holdBound = false
local dodgeKfHandle: KeyframeClipPlayer.Handle? = nil

local DODGE_TARGET_SEC = 0.55
local DODGE_KF_NAMES = { "StandToRoll", "Stand To Roll", "DodgeRoll" }

local MOTOR_NAMES = {
	rs = "RightShoulder",
	re = "RightElbow",
	ls = "LeftShoulder",
	le = "LeftElbow",
	waist = "Waist",
	rh = "RightHip",
	rk = "RightKnee",
	lh = "LeftHip",
	lk = "LeftKnee",
}

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

local function findDodgeKeyframe(): KeyframeSequence?
	-- Same as sprint: Studio Mixamo KFs don't play cleanly via Transform on AC-R15.
	-- Prefer published Animation under CombatAnims, else procedural dodge.
	if not _G.UseLocalKFClips then
		return nil
	end
	local folder = ReplicatedStorage:FindFirstChild("CombatAnims")
	if not folder then
		return nil
	end
	for _, kfName in DODGE_KF_NAMES do
		local kf = KeyframeClipPlayer.Find(folder, kfName)
		if kf and KeyframeClipPlayer.GetDuration(kf) > 0.05 then
			return kf
		end
	end
	return nil
end

local function resolveAnimationId(name: string): string?
	local folder = ReplicatedStorage:FindFirstChild("CombatAnims")
	if folder then
		if name == "Dodge" then
			-- Studio KeyframeSequences play via KeyframeClipPlayer (RegisterAnimationClip → Length=0)
			local anim = folder:FindFirstChild("StandToRoll") or folder:FindFirstChild("Dodge")
			if anim and anim:IsA("Animation") and anim.AnimationId ~= "" then
				return anim.AnimationId
			end
			return nil
		end

		local animInst = folder:FindFirstChild(name)
		if animInst and animInst:IsA("Animation") and animInst.AnimationId ~= "" then
			return animInst.AnimationId
		end

		if name == "Cast" then
			local cast = folder:FindFirstChild("CastPoint")
			if cast and cast:IsA("Animation") then
				return cast.AnimationId
			end
		end
	end

	local id = AnimConfig[name]
	if typeof(id) == "string" and string.sub(id, 1, 13) == "rbxassetid://" then
		return id
	end
	return nil
end

local function ensureTracks(char: Model)
	if loadedFor == char and next(tracks) then
		return
	end
	table.clear(tracks)
	table.clear(stopTokens)
	loadedFor = char
	local animator = getAnimator(char)
	if not animator then
		return
	end
	for _, name in ACTION_KEYS do
		local id = resolveAnimationId(name)
		if id then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok and track then
				track.Priority = Enum.AnimationPriority.Action
				track.Looped = false
				tracks[name] = track
			end
		end
	end
end

local function stopActionTracks(fade: number?)
	local f = fade or 0.12
	for _, track in tracks do
		if track.IsPlaying then
			track:Stop(f)
		end
	end
end

local function scheduleAutoStop(name: string, track: AnimationTrack, maxSec: number)
	local token = (stopTokens[name] or 0) + 1
	stopTokens[name] = token
	task.delay(0.05, function()
		if stopTokens[name] ~= token then
			return
		end
		local len = track.Length
		if len ~= len or len <= 0 then
			len = maxSec
		end
		local waitSec = math.clamp(len / math.max(track.Speed, 0.01), 0.15, maxSec)
		task.delay(waitSec, function()
			if stopTokens[name] ~= token then
				return
			end
			if track.IsPlaying then
				track:Stop(0.2)
			end
		end)
	end)
end

local function findMotor(char: Model, name: string): Instance?
	local m = char:FindFirstChild(name, true)
	if m and (m:IsA("Motor6D") or m:IsA("AnimationConstraint")) then
		return m
	end
	return nil
end

local function degOffset(angles: { number }?): CFrame
	if not angles then
		return CFrame.new()
	end
	return CFrame.Angles(math.rad(angles[1] or 0), math.rad(angles[2] or 0), math.rad(angles[3] or 0))
end

local function collectWeaponWelds(char: Model): { Weld }
	local out: { Weld } = {}
	local root = char:FindFirstChild("GearVisuals")
	if not root then
		return out
	end
	for _, d in root:GetDescendants() do
		if d:IsA("Weld") and d.Part0 and d.Part1 then
			local p0, p1 = d.Part0.Name, d.Part1.Name
			local handish = string.find(p0, "Hand") or string.find(p1, "Hand") or string.find(p0, "Arm") or string.find(p1, "Arm")
			if handish then
				table.insert(out, d)
			end
		end
	end
	return out
end

local function findWeaponTipPart(char: Model): BasePart?
	local root = char:FindFirstChild("GearVisuals")
	local folder = root and root:FindFirstChild("Weapons")
	if not folder then
		return nil
	end
	local best: BasePart? = nil
	local bestVol = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Handle" then
			local vol = d.Size.X * d.Size.Y * d.Size.Z
			if vol > bestVol then
				bestVol = vol
				best = d
			end
		end
	end
	if best then
		return best
	end
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local function attachSwingTrail(tip: BasePart, dur: number, col: Color3?)
	local c = col or Color3.fromRGB(220, 230, 255)
	local a0 = Instance.new("Attachment")
	a0.Name = "SwingTrail0"
	a0.Position = Vector3.new(0, tip.Size.Y * 0.35, 0)
	a0.Parent = tip
	local a1 = Instance.new("Attachment")
	a1.Name = "SwingTrail1"
	a1.Position = Vector3.new(0, -tip.Size.Y * 0.35, 0)
	a1.Parent = tip
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.4, c),
		ColorSequenceKeypoint.new(1, c:Lerp(Color3.new(0, 0, 0), 0.4)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.22
	trail.MinLength = 0.02
	trail.FaceCamera = false
	trail.LightEmission = 0.75
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Parent = tip
	Debris:AddItem(a0, dur + 0.35)
	Debris:AddItem(a1, dur + 0.35)
	Debris:AddItem(trail, dur + 0.35)
end

local function tweenC0(motor: Motor6D | Weld, target: CFrame, outDur: number, backDur: number, base: CFrame, token: number)
	local tw = TweenService:Create(motor, TweenInfo.new(outDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		C0 = target,
	})
	tw:Play()
	tw.Completed:Connect(function()
		if swingToken ~= token then
			motor.C0 = base
			return
		end
		TweenService:Create(motor, TweenInfo.new(backDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			C0 = base,
		}):Play()
	end)
end

local function tweenMotorOffset(motor: Instance, offset: CFrame, outDur: number, backDur: number, baseC0: CFrame?, token: number)
	if motor:IsA("AnimationConstraint") then
		local ac = motor :: any
		ac.Transform = offset
		task.delay(outDur, function()
			if swingToken ~= token then
				return
			end
			task.wait(backDur * 0.15)
			if swingToken == token then
				ac.Transform = CFrame.new()
			end
		end)
		return
	end
	if motor:IsA("Motor6D") and baseC0 then
		tweenC0(motor :: Motor6D, baseC0 * offset, outDur, backDur, baseC0, token)
	end
end

local function proceduralBody(char: Model, family: string, step: number, dur: number, token: number)
	local poses = AnimConfig.BodyPose
	local set = poses[family] or poses.Sword1H
	local key = "L" .. tostring(step)
	local pose = set[key] or set.L1
	if not pose then
		return
	end
	local outDur = (pose.dur or dur) * 0.42
	local backDur = (pose.dur or dur) * 0.58
	for field, motorName in MOTOR_NAMES do
		local angles = pose[field]
		if angles then
			local motor = findMotor(char, motorName)
			if motor then
				local base = if motor:IsA("Motor6D") then (motor :: Motor6D).C0 else nil
				tweenMotorOffset(motor, degOffset(angles), outDur, backDur, base, token)
			end
		end
	end
end

local function proceduralSwing(char: Model, family: string?, step: number?, attackSpeedMult: number?)
	swingToken += 1
	local token = swingToken
	local fam = family or "Sword1H"
	local s = step or 1
	local profiles = AnimConfig.SwingProfile
	local profileSet = profiles[fam] or profiles.Sword1H
	local key = "L" .. tostring(s)
	local prof = profileSet[key] or profileSet.L1
	local stepScale = if s == 3 then 1.38 elseif s == 2 then 1.12 else 1.0
	local asMult = math.clamp(attackSpeedMult or 1, 0.65, 1.45)
	local dur = (prof.dur or 0.24) * stepScale / asMult
	local outDur = dur * 0.42
	local backDur = dur * 0.58
	swingUntil = os.clock() + dur + 0.12

	proceduralBody(char, fam, s, dur, token)

	local welds = collectWeaponWelds(char)
	for _, weld in welds do
		local base = weld.C0
		local target = base * CFrame.Angles(math.rad(prof.pitch), math.rad(prof.yaw), math.rad(prof.roll))
		tweenC0(weld, target, outDur, backDur, base, token)
	end

	local tip = findWeaponTipPart(char)
	if tip then
		local col = AnimConfig.ElementColor.Neutral
		attachSwingTrail(tip, dur, col)
	end
end

--- Directional crouch-dash lean (complements DodgeRoll KF; no somersault physics)
local dodgeLeanToken = 0

local function proceduralDodge(char: Model, moveDir: Vector3?, duration: number)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end
	local oldSpin = hrp:FindFirstChild("DodgeRollSpin")
	if oldSpin then
		oldSpin:Destroy()
	end
	hrp.AssemblyAngularVelocity = Vector3.zero

	local dir = moveDir
	if not dir or dir.Magnitude < 0.05 then
		dir = hrp.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.05 then
		dir = Vector3.new(0, 0, -1)
	end
	dir = dir.Unit

	local flatLook = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	local flatRight = Vector3.new(hrp.CFrame.RightVector.X, 0, hrp.CFrame.RightVector.Z)
	if flatLook.Magnitude < 0.05 then
		flatLook = Vector3.new(0, 0, -1)
	end
	if flatRight.Magnitude < 0.05 then
		flatRight = Vector3.new(1, 0, 0)
	end
	flatLook = flatLook.Unit
	flatRight = flatRight.Unit
	local localX = dir:Dot(flatRight) -- + = lean right
	local localZ = dir:Dot(flatLook) -- + = lean forward

	dodgeLeanToken += 1
	local token = dodgeLeanToken
	local outDur = duration * 0.28
	local holdDur = duration * 0.35
	local backDur = duration * 0.37

	local poses = {
		waist = { 28 + localZ * 12, localX * -22, localX * 8 },
		rs = { 25, 15 + localX * 10, -35 },
		ls = { 25, -15 + localX * 10, 35 },
		re = { 0, 0, -40 },
		le = { 0, 0, 40 },
		rh = { -35 - localZ * 8, localX * 8, 8 },
		lh = { -35 - localZ * 8, localX * 8, -8 },
		rk = { 55, 0, 0 },
		lk = { 55, 0, 0 },
	}

	-- AnimationConstraint.C0 is read-only — drive Transform instead
	local bases: { [Instance]: CFrame } = {}
	for field, motorName in MOTOR_NAMES do
		local angles = poses[field]
		if angles then
			local motor = findMotor(char, motorName)
			if motor then
				local offset = degOffset(angles)
				bases[motor] = CFrame.new()
				pcall(function()
					(motor :: any).Transform = offset
				end)
			end
		end
	end

	local originalCam = hum.CameraOffset
	local camDuck = originalCam + Vector3.new(localX * -0.35, -0.85, localZ * 0.15)
	TweenService:Create(hum, TweenInfo.new(outDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CameraOffset = camDuck,
	}):Play()

	task.delay(outDur + holdDur, function()
		if dodgeLeanToken ~= token then
			return
		end
		for motor, _ in bases do
			if motor.Parent then
				pcall(function()
					(motor :: any).Transform = CFrame.new()
				end)
			end
		end
		if hum.Parent then
			TweenService:Create(hum, TweenInfo.new(backDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CameraOffset = originalCam,
			}):Play()
		end
	end)
end

function CombatAnim.Play(kind: string, family: string?, comboStep: number?, opts: any?)
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then
		return
	end
	ensureTracks(char)

	local fam = family
	local step = comboStep
	if (not fam or not step) and typeof(kind) == "string" and string.find(kind, "_L") then
		local f, st = string.match(kind, "^(.+)_L(%d)$")
		if f and st then
			fam = fam or f
			step = step or tonumber(st)
		end
	end

	local look: Vector3? = nil
	if typeof(opts) == "table" and typeof(opts.look) == "Vector3" then
		look = opts.look
	elseif typeof(opts) == "Vector3" then
		look = opts
	end

	local base = "Melee"
	if kind == "Cast" or kind == "Buff" then
		base = kind
	elseif kind == "Bow" or (fam and (fam == "Bow" or fam == "Crossbow")) then
		base = "Bow"
	elseif kind == "Dodge" then
		base = "Dodge"
	elseif fam and (fam == "Wand" or fam == "Staff" or fam == "Scepter") then
		base = "Cast"
	end

	local track = tracks[base] or (if base == "Dodge" then nil else tracks.Melee)
	if base == "Dodge" then
		stopActionTracks(0.1)
		if dodgeKfHandle then
			dodgeKfHandle.stop()
			dodgeKfHandle = nil
		end
		local dodgeKf = findDodgeKeyframe()
		if dodgeKf then
			local len = KeyframeClipPlayer.GetDuration(dodgeKf)
			if len ~= len or len <= 0 then
				len = 0.9
			end
			local speed = math.clamp(len / DODGE_TARGET_SEC, 0.85, 1.25)
			dodgeKfHandle = KeyframeClipPlayer.Play(char, dodgeKf, { looped = false, speed = speed })
			-- Camera duck only — KF owns the body (procedural C0 tweens break on AnimationConstraint)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local originalCam = hum.CameraOffset
				TweenService:Create(hum, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CameraOffset = originalCam + Vector3.new(0, -0.7, 0),
				}):Play()
				task.delay(DODGE_TARGET_SEC * 0.7, function()
					if hum.Parent then
						TweenService:Create(hum, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							CameraOffset = originalCam,
						}):Play()
					end
				end)
			end
			return
		end
		if track then
			track.Looped = false
			local len = track.Length
			if len ~= len or len <= 0 then
				len = 0.9
			end
			local speed = math.clamp(len / DODGE_TARGET_SEC, 0.85, 1.25)
			track:Play(0.08, 1, speed)
			scheduleAutoStop("Dodge", track, DODGE_TARGET_SEC + 0.15)
		end
		proceduralDodge(char, look, DODGE_TARGET_SEC)
		return
	end

	if track then
		stopActionTracks(0.08)
		track.Looped = false
		local asMult = if typeof(opts) == "table" and typeof(opts.attackSpeedMult) == "number" then opts.attackSpeedMult else 1
		asMult = math.clamp(asMult, 0.65, 1.45)
		local stepMul = if step == 3 then 0.88 elseif step == 2 then 1.0 else 1.14
		local speed = if base == "Cast" then (1.15 * asMult / (if step == 3 then 1.28 elseif step == 2 then 1.1 else 1)) else (1.05 * stepMul * asMult)
		track:Play(0.05, 1, speed)
		local maxSec = if base == "Cast" or base == "Buff" then 0.65 else 0.85
		maxSec *= if step == 3 then 1.35 elseif step == 2 then 1.1 else 1
		maxSec /= asMult
		scheduleAutoStop(base, track, maxSec)
	end

	if fam and step then
		local asMult = if typeof(opts) == "table" and typeof(opts.attackSpeedMult) == "number" then opts.attackSpeedMult else 1
		proceduralSwing(char, fam, step, asMult)
	end
end

function CombatAnim.StopAll(fade: number?)
	stopActionTracks(fade)
end

local hitStopToken = 0

function CombatAnim.ApplyHitStop(sec: number)
	if sec <= 0 then
		return
	end
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	hitStopToken += 1
	local token = hitStopToken
	swingUntil = math.max(swingUntil, os.clock() + sec)

	local saved: { { AnimationTrack, number } } = {}
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Speed > 0.01 then
			table.insert(saved, { track, track.Speed })
			track:AdjustSpeed(0)
		end
	end

	task.delay(sec, function()
		if hitStopToken ~= token then
			return
		end
		for _, pair in saved do
			local track, speed = pair[1], pair[2]
			if track.IsPlaying then
				track:AdjustSpeed(speed)
			end
		end
	end)
end

function CombatAnim.PlayReload(duration: number)
	local char = Players.LocalPlayer.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local rShoulder = findMotor(char, "RightShoulder")
	if hum and rShoulder and rShoulder:IsA("Motor6D") then
		local base = rShoulder.C0
		local tucked = base * CFrame.Angles(math.rad(-25), math.rad(15), math.rad(10))
		TweenService:Create(rShoulder, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = tucked,
		}):Play()
		task.delay(duration, function()
			if rShoulder.Parent then
				TweenService:Create(rShoulder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					C0 = base,
				}):Play()
			end
		end)
	end
end

local function applyWeaponHold(char: Model)
	if os.clock() < swingUntil then
		return
	end
	-- Don't overwrite Mixamo / CombatAnims pose applicator
	local kfPlaying = char:GetAttribute("KFClipPlaying")
	if typeof(kfPlaying) == "number" and kfPlaying > 0 then
		return
	end
	local stance = Players.LocalPlayer:GetAttribute("CombatStance")
	if typeof(stance) ~= "string" then
		return
	end
	local poses = AnimConfig.HoldPose
	if not poses then
		return
	end
	local pose = poses[stance]
	if not pose then
		return
	end
	for field, motorName in MOTOR_NAMES do
		local angles = pose[field]
		if angles then
			local motor = findMotor(char, motorName)
			if motor then
				motor.Transform = degOffset(angles)
			end
		end
	end
end

local function ensureHoldLoop()
	if holdBound then
		return
	end
	holdBound = true
	-- Stepped runs after Animator writes Transforms (RenderStep is overwritten)
	RunService.Stepped:Connect(function()
		local char = Players.LocalPlayer.Character
		if char then
			applyWeaponHold(char)
		end
	end)
end

ensureHoldLoop()

Players.LocalPlayer.CharacterAdded:Connect(function()
	if dodgeKfHandle then
		dodgeKfHandle.stop()
		dodgeKfHandle = nil
	end
	table.clear(tracks)
	table.clear(stopTokens)
	loadedFor = nil
	swingToken += 1
	dodgeLeanToken += 1
	swingUntil = 0
end)

return CombatAnim
