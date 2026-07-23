--[[
	Loot remotes + match result bridge (Faz 3).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchResultBridge = require(script.Parent.Loot.MatchResultBridge)

local existing = ReplicatedStorage:FindFirstChild("LootRemotes")
if existing then
	existing:Destroy()
end

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "LootRemotes"
remotesFolder.Parent = ReplicatedStorage

local LootResult = Instance.new("RemoteEvent")
LootResult.Name = "LootResult"
LootResult.Parent = remotesFolder

MatchResultBridge.SetLootResultRemote(LootResult)

print("[LootBootstrap] Loot remotes ready")
