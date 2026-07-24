--[[
	In-game shop — spends premium currency.
]]

local ShopConfig = require(game.ReplicatedStorage.Shared.Config.ShopConfig)
local CurrencyService = require(script.Parent.Parent.Inventory.CurrencyService)

local ShopService = {}

local titlesByUser: { [number]: { [string]: boolean } } = {}

function ShopService.HasTitle(userId: number, title: string): boolean
	local bag = titlesByUser[userId]
	return bag ~= nil and bag[title] == true
end

function ShopService.Ensure(userId: number)
	if not titlesByUser[userId] then
		titlesByUser[userId] = {}
	end
end

function ShopService.GrantTitle(userId: number, title: string)
	if typeof(title) ~= "string" or title == "" then
		return
	end
	ShopService.Ensure(userId)
	titlesByUser[userId][title] = true
end

function ShopService.Export(userId: number): { [string]: boolean }
	ShopService.Ensure(userId)
	return table.clone(titlesByUser[userId])
end

function ShopService.Import(userId: number, titles: { [string]: boolean }?)
	ShopService.Ensure(userId)
	if typeof(titles) ~= "table" then
		return
	end
	for key, val in titles do
		if typeof(key) == "string" and val == true then
			titlesByUser[userId][key] = true
		end
	end
end

function ShopService.Clear(userId: number)
	titlesByUser[userId] = nil
end

function ShopService.Purchase(userId: number, offerId: string): (boolean, string?)
	for _, offer in ShopConfig.Offers do
		if offer.id ~= offerId then
			continue
		end
		if offer.lootboxGrant or offer.itemDefId then
			local defId = offer.lootboxGrant or offer.itemDefId
			local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
			local def = ItemDefs.Get(defId)
			if def and def.kind == "LootBox" then
				return false, "LootBoxNotSold"
			end
		end
		if offer.devOnly then
			if offer.premium and offer.premium > 0 then
				CurrencyService.AddPremium(userId, offer.premium)
			end
			if typeof(offer.title) == "string" and offer.title ~= "" then
				ShopService.GrantTitle(userId, offer.title)
			end
			return true, nil
		end
		local cost = offer.costPremium or 0
		if cost > 0 and not CurrencyService.TrySpendPremium(userId, cost) then
			return false, "NotEnoughPremium"
		end
		if offer.premium and offer.premium > 0 then
			CurrencyService.AddPremium(userId, offer.premium)
		end
		if typeof(offer.title) == "string" and offer.title ~= "" then
			ShopService.GrantTitle(userId, offer.title)
		end
		if typeof(offer.itemGrant) == "string" and offer.itemGrant ~= "" then
			local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
			local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
			local def = ItemDefs.Get(offer.itemGrant)
			if not def then
				CurrencyService.AddPremium(userId, cost) -- refund
				return false, "UnknownItemGrant"
			end
			InventoryService.AddItem(userId, offer.itemGrant)
		end
		return true, nil
	end
	return false, "UnknownOffer"
end

return ShopService
