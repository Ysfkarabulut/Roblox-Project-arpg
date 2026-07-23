--[[
	Spectate camera — server assigns target on death.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("PvpRemotes", 20)
if not remotes then
	return
end
local SpectateTarget = remotes:WaitForChild("SpectateTarget", 10) :: RemoteEvent?
if not SpectateTarget then
	return
end

local spectating = false
local targetUserId: number? = nil

local function stopSpectate()
	spectating = false
	targetUserId = nil
	if player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			camera.CameraSubject = hum
		end
	end
end

SpectateTarget.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.targetUserId) ~= "number" then
		stopSpectate()
		return
	end
	spectating = true
	targetUserId = payload.targetUserId
end)

RunService.RenderStepped:Connect(function()
	if not spectating or not targetUserId then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		camera.CameraSubject = hum
	else
		stopSpectate()
	end
end)

player.CharacterAdded:Connect(function()
	if not spectating then
		return
	end
	task.defer(stopSpectate)
end)
