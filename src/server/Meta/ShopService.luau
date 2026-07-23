--[[
	In-game shop — spends premium currency.
]]

local ShopConfig = require(game.ReplicatedStorage.Shared.Config.ShopConfig)
local CurrencyService = require(script.Parent.Parent.Inventory.CurrencyService)

local ShopService = {}

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
			CurrencyService.AddPremium(userId, offer.premium or 0)
			return true, nil
		end
		local cost = offer.costPremium or 0
		if cost > 0 and not CurrencyService.TrySpendPremium(userId, cost) then
			return false, "NotEnoughPremium"
		end
		if offer.premium and offer.premium > 0 then
			CurrencyService.AddPremium(userId, offer.premium)
		end
		return true, nil
	end
	return false, "UnknownOffer"
end

return ShopService
