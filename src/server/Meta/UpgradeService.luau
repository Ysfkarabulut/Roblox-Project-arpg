--[[
	Upgrade weapon frames / blades with premium currency.
]]

local UpgradeDefs = require(game.ReplicatedStorage.Shared.Config.UpgradeDefs)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local CurrencyService = require(script.Parent.Parent.Inventory.CurrencyService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local UpgradeService = {}

function UpgradeService.GetLevel(userId: number, uuid: string): number
	local inst = InventoryService.FindRaw(userId, uuid)
	if not inst then
		return 0
	end
	return if typeof(inst.upgradeLevel) == "number" then inst.upgradeLevel else 0
end

function UpgradeService.Upgrade(userId: number, uuid: string): (boolean, string?)
	local inst = InventoryService.FindRaw(userId, uuid)
	if not inst then
		return false, "NoItem"
	end
	local def = ItemDefs.Get(inst.defId)
	if not def or def.kind ~= "WeaponBlade" then
		return false, "NotUpgradeable"
	end
	local level = UpgradeService.GetLevel(userId, uuid)
	if level >= UpgradeDefs.MaxLevel then
		return false, "MaxLevel"
	end
	if not CurrencyService.TrySpendPremium(userId, UpgradeDefs.CostPremiumPerLevel) then
		return false, "NotEnoughPremium"
	end
	inst.upgradeLevel = level + 1
	return true, nil
end

return UpgradeService
