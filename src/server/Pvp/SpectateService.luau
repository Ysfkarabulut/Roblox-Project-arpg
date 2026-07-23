--[[
	Dead player spectate — follow living teammates / enemies.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpectateService = {}

local spectateTarget: { [number]: number } = {}

local function getRemote(): RemoteEvent
	local folder = ReplicatedStorage:FindFirstChild("PvpRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PvpRemotes"
		folder.Parent = ReplicatedStorage
	end
	local r = folder:FindFirstChild("SpectateTarget")
	if r and r:IsA("RemoteEvent") then
		return r
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = "SpectateTarget"
	remote.Parent = folder
	return remote
end

local function livingPlayers(userIds: { number }): { Player }
	local out: { Player } = {}
	for _, id in userIds do
		local plr = Players:GetPlayerByUserId(id)
		local hum = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if plr and hum and hum.Health > 0 then
			table.insert(out, plr)
		end
	end
	return out
end

function SpectateService.BeginSpectate(deadUserId: number, allyUserIds: { number }, enemyUserIds: { number })
	local plr = Players:GetPlayerByUserId(deadUserId)
	if not plr then
		return
	end
	plr:SetAttribute("Spectating", true)

	local targets = livingPlayers(allyUserIds)
	if #targets == 0 then
		targets = livingPlayers(enemyUserIds)
	end
	if #targets == 0 then
		return
	end
	local target = targets[1]
	spectateTarget[deadUserId] = target.UserId
	getRemote():FireClient(plr, { targetUserId = target.UserId })
end

function SpectateService.Clear(userId: number)
	spectateTarget[userId] = nil
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		plr:SetAttribute("Spectating", nil)
	end
end

function SpectateService.ClearAll(userIds: { number })
	for _, id in userIds do
		SpectateService.Clear(id)
	end
end

return SpectateService
