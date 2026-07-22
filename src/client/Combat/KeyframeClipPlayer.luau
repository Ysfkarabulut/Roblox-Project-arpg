--[[
	Play ReplicatedStorage.CombatAnims KeyframeSequences by writing joint Transforms.
	RegisterAnimationClip yields Length=0 in Play for these Studio clips — pose applicator bypass.

	Mixamo poses use part names (UpperTorso); joints use Motor/Constraint names (Waist).
	Pose.CFrame is applied as Transform rotation (translation stripped — Mixamo Root is 100+ studs).
	Root joint is skipped: hip locomotion translation/spin fights WalkSpeed and collapses ACs.
]]

local RunService = game:GetService("RunService")

local KeyframeClipPlayer = {}

export type Handle = {
	stop: () -> (),
	isPlaying: () -> boolean,
}

local POSE_TO_JOINT: { [string]: string } = {
	LowerTorso = "Root",
	UpperTorso = "Waist",
	Head = "Neck",
	LeftUpperArm = "LeftShoulder",
	RightUpperArm = "RightShoulder",
	LeftLowerArm = "LeftElbow",
	RightLowerArm = "RightElbow",
	LeftHand = "LeftWrist",
	RightHand = "RightWrist",
	LeftUpperLeg = "LeftHip",
	RightUpperLeg = "RightHip",
	LeftLowerLeg = "LeftKnee",
	RightLowerLeg = "RightKnee",
	LeftFoot = "LeftAnkle",
	RightFoot = "RightAnkle",
	Root = "Root",
	Waist = "Waist",
	Neck = "Neck",
	LeftShoulder = "LeftShoulder",
	RightShoulder = "RightShoulder",
	LeftElbow = "LeftElbow",
	RightElbow = "RightElbow",
	LeftWrist = "LeftWrist",
	RightWrist = "RightWrist",
	LeftHip = "LeftHip",
	RightHip = "RightHip",
	LeftKnee = "LeftKnee",
	RightKnee = "RightKnee",
	LeftAnkle = "LeftAnkle",
	RightAnkle = "RightAnkle",
}

-- Root Mixamo translation is huge; we still apply Root rotation for rolls (translation stripped in apply).

local function resolveJointName(poseName: string): string?
	if poseName == "" or poseName == "HumanoidRootPart" then
		return nil
	end
	if string.find(poseName, "_end", 1, true) then
		return nil
	end
	if string.match(poseName, "%d+$") and not POSE_TO_JOINT[poseName] then
		return nil
	end
	return POSE_TO_JOINT[poseName] or poseName
end

local function collectJoints(char: Model): { [string]: Instance }
	local map = {}
	for _, d in char:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
			map[d.Name] = d
		end
	end
	return map
end

local function flattenPoses(pose: Pose, out: { [string]: CFrame })
	local jointName = resolveJointName(pose.Name)
	if jointName then
		out[jointName] = pose.CFrame
	end
	for _, child in pose:GetSubPoses() do
		flattenPoses(child, out)
	end
end

local function keyframePoseMap(kf: Keyframe): { [string]: CFrame }
	local out = {}
	for _, pose in kf:GetPoses() do
		flattenPoses(pose, out)
	end
	return out
end

local function lerpPoseMaps(a: { [string]: CFrame }, b: { [string]: CFrame }, alpha: number): { [string]: CFrame }
	local out = {}
	local names = {}
	for n in a do
		names[n] = true
	end
	for n in b do
		names[n] = true
	end
	for n in names do
		local ca = a[n]
		local cb = b[n]
		if ca and cb then
			out[n] = ca:Lerp(cb, alpha)
		elseif cb then
			out[n] = cb
		elseif ca then
			out[n] = ca
		end
	end
	return out
end

local function sampleSequence(seq: KeyframeSequence, t: number): { [string]: CFrame }
	local keys = seq:GetKeyframes()
	if #keys == 0 then
		return {}
	end
	table.sort(keys, function(x, y)
		return x.Time < y.Time
	end)
	local duration = keys[#keys].Time
	if duration <= 0 then
		return keyframePoseMap(keys[1])
	end
	t = t % duration
	if t <= keys[1].Time then
		return keyframePoseMap(keys[1])
	end
	if t >= keys[#keys].Time then
		return keyframePoseMap(keys[#keys])
	end
	for i = 1, #keys - 1 do
		local a = keys[i]
		local b = keys[i + 1]
		if t >= a.Time and t <= b.Time then
			local span = b.Time - a.Time
			local alpha = if span > 1e-6 then (t - a.Time) / span else 0
			return lerpPoseMaps(keyframePoseMap(a), keyframePoseMap(b), alpha)
		end
	end
	return keyframePoseMap(keys[#keys])
end

--- Mixamo Studio imports store absolute local bone mats. Applying them raw as Transform
--- crumples AnimationConstraint R15. Delta from first keyframe keeps rest C0 healthy.
local function makeRestMap(seq: KeyframeSequence): { [string]: CFrame }
	local keys = seq:GetKeyframes()
	if #keys == 0 then
		return {}
	end
	table.sort(keys, function(a, b)
		return a.Time < b.Time
	end)
	return keyframePoseMap(keys[1])
end

local function applyPoses(joints: { [string]: Instance }, poses: { [string]: CFrame }, rest: { [string]: CFrame })
	for name, cf in poses do
		local joint = joints[name]
		if joint then
			local restCF = rest[name]
			local tf: CFrame
			if restCF then
				tf = restCF.Rotation:Inverse() * cf.Rotation
			else
				tf = cf.Rotation
			end
			pcall(function()
				(joint :: any).Transform = tf
			end)
		end
	end
end

local function clearJoints(joints: { [string]: Instance })
	for _, joint in joints do
		pcall(function()
			(joint :: any).Transform = CFrame.new()
		end)
	end
end

local function muteAnimate(char: Model, muted: boolean)
	local animate = char:FindFirstChild("Animate")
	if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
		(animate :: Script).Disabled = muted
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator and muted then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end
end

function KeyframeClipPlayer.Play(char: Model, seq: KeyframeSequence, opts: { looped: boolean?, speed: number?, fadeOut: boolean? }?): Handle
	local looped = opts and opts.looped == true
	local speed = (opts and opts.speed) or 1
	local joints = collectJoints(char)
	local keys = seq:GetKeyframes()
	local duration = 0.01
	if #keys > 0 then
		table.sort(keys, function(a, b)
			return a.Time < b.Time
		end)
		duration = math.max(keys[#keys].Time, 0.01)
	end
	local rest = makeRestMap(seq)

	local playing = true
	local t = 0
	local conn: RBXScriptConnection? = nil
	local attrKey = "KFClipPlaying"
	char:SetAttribute(attrKey, (char:GetAttribute(attrKey) or 0) + 1)
	muteAnimate(char, true)

	local function stop()
		if not playing then
			return
		end
		playing = false
		if conn then
			conn:Disconnect()
			conn = nil
		end
		local n = (char:GetAttribute(attrKey) or 1) - 1
		char:SetAttribute(attrKey, math.max(n, 0))
		clearJoints(joints)
		if (char:GetAttribute(attrKey) or 0) <= 0 then
			muteAnimate(char, false)
		end
	end

	conn = RunService.Stepped:Connect(function(_, dt)
		if not playing or not char.Parent then
			stop()
			return
		end
		t += dt * speed
		if not looped and t >= duration then
			applyPoses(joints, sampleSequence(seq, duration), rest)
			stop()
			return
		end
		applyPoses(joints, sampleSequence(seq, t), rest)
	end)

	return {
		stop = stop,
		isPlaying = function()
			return playing
		end,
	}
end

function KeyframeClipPlayer.GetDuration(seq: KeyframeSequence): number
	local keys = seq:GetKeyframes()
	if #keys == 0 then
		return 0
	end
	table.sort(keys, function(a, b)
		return a.Time < b.Time
	end)
	return keys[#keys].Time
end

function KeyframeClipPlayer.Find(folder: Instance?, name: string): KeyframeSequence?
	if not folder then
		return nil
	end
	local inst = folder:FindFirstChild(name)
	if inst and inst:IsA("KeyframeSequence") then
		return inst
	end
	return nil
end

function KeyframeClipPlayer.DebugMatch(char: Model, seq: KeyframeSequence): { matched: number, total: number, sample: { string } }
	local joints = collectJoints(char)
	local poses = sampleSequence(seq, 0)
	local matched = 0
	local sample = {}
	local total = 0
	for name in poses do
		total += 1
		if joints[name] then
			matched += 1
			table.insert(sample, name .. " ok")
		else
			table.insert(sample, name .. " MISSING")
		end
	end
	return { matched = matched, total = total, sample = sample }
end

return KeyframeClipPlayer
