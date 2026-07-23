--[[
	Meta systems bootstrap — tutorial, shop, upgrade remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)

local TutorialService = require(script.Parent.Meta.TutorialService)
local ShopService = require(script.Parent.Meta.ShopService)
local UpgradeService = require(script.Parent.Meta.UpgradeService)
local PlayerProfileService = require(script.Parent.Profile.PlayerProfileService)

local folder = Instance.new("Folder")
folder.Name = "MetaRemotes"
folder.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = folder
	return r
end

local function remoteFunction(name: string): RemoteFunction
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = folder
	return r
end

local CompleteTutorialStep = remoteEvent("CompleteTutorialStep")
local GetTutorialState = remoteFunction("GetTutorialState")
local ShopPurchase = remoteEvent("ShopPurchase")
local ShopPurchaseResult = remoteEvent("ShopPurchaseResult")
local UpgradeItem = remoteEvent("UpgradeItem")

GetTutorialState.OnServerInvoke = function(player: Player)
	return {
		flags = TutorialService.Export(player.UserId),
		nextStep = TutorialService.NextStep(player.UserId),
	}
end

CompleteTutorialStep.OnServerEvent:Connect(function(player: Player, step: string)
	if typeof(step) ~= "string" then
		return
	end
	TutorialService.Complete(player.UserId, step)
end)

if PlaceRuntime.IsLobby() then
	ShopPurchase.OnServerEvent:Connect(function(player: Player, offerId: string)
		if typeof(offerId) ~= "string" then
			return
		end
		local ok, err = ShopService.Purchase(player.UserId, offerId)
		ShopPurchaseResult:FireClient(player, { ok = ok, reason = err, offerId = offerId })
		if ok and _G.PushInventory then
			_G.PushInventory(player)
		end
	end)

	UpgradeItem.OnServerEvent:Connect(function(player: Player, uuid: string)
		if typeof(uuid) ~= "string" then
			return
		end
		local ok, err = UpgradeService.Upgrade(player.UserId, uuid)
		if not ok then
			warn(`[Upgrade] failed for {player.Name}: {err}`)
			return
		end
		PlayerProfileService.Save(player.UserId)
		if _G.PushInventory then
			_G.PushInventory(player)
		end
	end)
end

print("[MetaBootstrap] Tutorial + shop + upgrade ready")
