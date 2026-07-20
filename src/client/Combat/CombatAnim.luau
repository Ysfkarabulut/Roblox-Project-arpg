--[[
	R15 catalog track + procedural GearVisuals swing by family/L-step.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local AnimConfig = require(game.ReplicatedStorage.Shared.Config.AnimConfig)

local CombatAnim = {}

local tracks: { [string]: AnimationTrack } = {}
local loadedFor: Model? = nil

local function ensureTracks(char: Model)
	if loadedFor == char and next(tracks) then
		return
	end
	table.clear(tracks)
	loadedFor = char
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	for name, id in AnimConfig do
		if typeof(id) == "string" and string.sub(id, 1, 13) == "rbxassetid://" then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok and track then
				track.Priority = Enum.AnimationPriority.Action
				tracks[name] = track
			end
		end
	end
end

local function proceduralSwing(char: Model, family: string?, step: number?)
	local root = char:FindFirstChild("GearVisuals")
	local folder = root and root:FindFirstChild("Weapons") or root
	if not folder then
		return
	end
	local profiles = AnimConfig.SwingProfile
	local fam = family or "Sword1H"
	local profileSet = profiles[fam] or profiles.Sword1H
	local key = "L" .. tostring(step or 1)
	local prof = profileSet[key] or profileSet.L1
	for _, part in folder:GetChildren() do
		if part:IsA("BasePart") then
			local weld = part:FindFirstChildOfClass("Weld")
			if weld then
				local base = weld.C0
				local target = base
					* CFrame.Angles(math.rad(prof.pitch), math.rad(prof.yaw), math.rad(prof.roll))
				local tw = TweenService:Create(weld, TweenInfo.new(prof.dur * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					C0 = target,
				})
				tw:Play()
				tw.Completed:Connect(function()
					TweenService:Create(weld, TweenInfo.new(prof.dur * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						C0 = base,
					}):Play()
				end)
			end
		end
	end
end

function CombatAnim.Play(kind: string, family: string?, comboStep: number?)
	local player = Players.LocalPlayer
	local char = player.Character
	if not char then
		return
	end
	ensureTracks(char)

	local base = "Melee"
	if kind == "Cast" or kind == "Buff" then
		base = kind
	elseif kind == "Bow" or (family and (family == "Bow" or family == "Crossbow")) then
		base = "Bow"
	elseif kind == "Dodge" then
		base = "Dodge"
	elseif family and (family == "Wand" or family == "Staff") then
		base = "Cast"
	end

	local track = tracks[base] or tracks.Melee
	if track then
		track:Play(0.08, 1, 1.1)
	end

	if family and comboStep then
		proceduralSwing(char, family, comboStep)
	elseif typeof(kind) == "string" and string.find(kind, "_L") then
		local fam, step = string.match(kind, "^(.+)_L(%d)$")
		if fam and step then
			proceduralSwing(char, fam, tonumber(step))
		end
	end
end

Players.LocalPlayer.CharacterAdded:Connect(function()
	table.clear(tracks)
	loadedFor = nil
end)

return CombatAnim
