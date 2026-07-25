--[[
	Current place role — Lobby vs dedicated PvP arena places.
	Server: game.PlaceId + ServerStorage.PlaceRole (Rojo project).
	Client: ReplicatedStorage.PlaceRole (published at boot).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local PlaceConfig = require(script.Parent.PlaceConfig)

local PlaceRuntime = {}

local function roleFromPlaceId(): PlaceConfig.PlaceKey?
	local placeId = game.PlaceId
	for key, configuredId in PlaceConfig.PlaceIds do
		if typeof(configuredId) == "number" and configuredId > 0 and configuredId == placeId then
			return key
		end
	end
	return nil
end

local function roleFromServerStorage(): PlaceConfig.PlaceKey?
	local roleValue = ServerStorage:FindFirstChild("PlaceRole")
	if roleValue and roleValue:IsA("StringValue") then
		local role = roleValue.Value
		if PlaceConfig.PlaceIds[role :: any] ~= nil then
			return role :: PlaceConfig.PlaceKey
		end
	end
	return nil
end

function PlaceRuntime.ResolveRole(): PlaceConfig.PlaceKey
	return roleFromPlaceId() or roleFromServerStorage() or "Lobby"
end

function PlaceRuntime.PublishRoleForClients()
	if not RunService:IsServer() then
		return
	end
	local role = PlaceRuntime.ResolveRole()
	local existing = ReplicatedStorage:FindFirstChild("PlaceRole")
	if existing then
		existing:Destroy()
	end
	local value = Instance.new("StringValue")
	value.Name = "PlaceRole"
	value.Value = role
	value.Parent = ReplicatedStorage
end

function PlaceRuntime.GetRole(): PlaceConfig.PlaceKey
	if RunService:IsServer() then
		return PlaceRuntime.ResolveRole()
	end
	local replicated = ReplicatedStorage:FindFirstChild("PlaceRole")
	if not replicated then
		replicated = ReplicatedStorage:WaitForChild("PlaceRole", 15)
	end
	if replicated and replicated:IsA("StringValue") then
		local role = replicated.Value
		if PlaceConfig.PlaceIds[role :: any] ~= nil then
			return role :: PlaceConfig.PlaceKey
		end
	end
	return roleFromPlaceId() or "Lobby"
end

function PlaceRuntime.IsLobby(): boolean
	return PlaceRuntime.GetRole() == "Lobby"
end

function PlaceRuntime.IsPveBoss(): boolean
	local role = PlaceRuntime.GetRole()
	return role == "PveBoss" or role == "PveBossEye"
end

function PlaceRuntime.IsPvpArena(): boolean
	local role = PlaceRuntime.GetRole()
	return role == "Pvp1v1" or role == "Pvp2v2" or role == "Pvp3v3"
end

function PlaceRuntime.GetPvpBracket(): "1v1" | "2v2" | "3v3"?
	local role = PlaceRuntime.GetRole()
	if role == "Pvp1v1" then
		return "1v1"
	end
	if role == "Pvp2v2" then
		return "2v2"
	end
	if role == "Pvp3v3" then
		return "3v3"
	end
	return nil
end

function PlaceRuntime.BracketFromPlaceKey(placeKey: string): "1v1" | "2v2" | "3v3"
	if placeKey == "Pvp2v2" then
		return "2v2"
	end
	if placeKey == "Pvp3v3" then
		return "3v3"
	end
	return "1v1"
end

function PlaceRuntime.BracketFromQueueId(queueId: string): "1v1" | "2v2" | "3v3"
	if string.find(queueId, "2v2", 1, true) then
		return "2v2"
	end
	if string.find(queueId, "3v3", 1, true) then
		return "3v3"
	end
	return "1v1"
end

return PlaceRuntime
