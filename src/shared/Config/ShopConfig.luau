--[[
	Shop catalog — premium currency (F4). Robux IAP hook later.
	Lootboxes are NOT sold here — match drops + player trade only.
]]

local ShopConfig = {
	Offers = {
		{ id = "premium_5", premium = 5, costLabel = "Free (dev)", devOnly = true },
		-- Safe unsocket spends premium 1:1; this pack grants 3 premium (dev free).
		{ id = "gem_preserve_3", premium = 3, costPremium = 0, costLabel = "Free (dev)", devOnly = true, label = "Safe Unsocket ×3" },
		{ id = "title_contender", premium = 0, title = "Contender", costPremium = 10, label = "Title: Contender" },
	},
}

return ShopConfig
