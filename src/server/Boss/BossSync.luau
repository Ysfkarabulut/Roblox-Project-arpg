--[[
	Boss state replication to clients.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossSync = {}

local stateRemote: RemoteEvent? = nil
local telegraphRemote: RemoteEvent? = nil

function BossSync.SetRemotes(state: RemoteEvent, telegraph: RemoteEvent)
	stateRemote = state
	telegraphRemote = telegraph
end

function BossSync.FireState(payload: any)
	if stateRemote then
		stateRemote:FireAllClients(payload)
	end
end

function BossSync.FireTelegraph(payload: any)
	if telegraphRemote then
		telegraphRemote:FireAllClients(payload)
	end
end

return BossSync
