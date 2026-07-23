--[[
	Premium currency — gem safe-unsocket and future shop.
	Persisted via PlayerProfileService (Faz 2).
]]

local CurrencyService = {}

export type PremiumSpendResult = {
	ok: boolean,
	reason: string?,
}

--- Cost to unsocket a gem without destroying it
CurrencyService.GemPreserveUnsocketCost = 1

local premiumByUser: { [number]: number } = {}

function CurrencyService.GetPremium(userId: number): number
	return premiumByUser[userId] or 0
end

function CurrencyService.GrantPremium(userId: number, amount: number)
	if typeof(amount) ~= "number" or amount <= 0 then
		return
	end
	premiumByUser[userId] = CurrencyService.GetPremium(userId) + math.floor(amount)
end

function CurrencyService.SetPremium(userId: number, amount: number)
	premiumByUser[userId] = math.max(0, math.floor(amount))
end

function CurrencyService.AddPremium(userId: number, amount: number)
	CurrencyService.GrantPremium(userId, amount)
end

function CurrencyService.TrySpendPremium(userId: number, amount: number): boolean
	if amount <= 0 then
		return true
	end
	if CurrencyService.GetPremium(userId) < amount then
		return false
	end
	premiumByUser[userId] = CurrencyService.GetPremium(userId) - math.floor(amount)
	return true
end

function CurrencyService.CanPreserveGemUnsocket(userId: number): boolean
	return CurrencyService.GetPremium(userId) >= CurrencyService.GemPreserveUnsocketCost
end

function CurrencyService.TrySpendForGemPreserveUnsocket(userId: number): PremiumSpendResult
	local cost = CurrencyService.GemPreserveUnsocketCost
	local balance = CurrencyService.GetPremium(userId)
	if balance < cost then
		return { ok = false, reason = "InsufficientPremium" }
	end
	premiumByUser[userId] = balance - cost
	return { ok = true }
end

function CurrencyService.Clear(userId: number)
	premiumByUser[userId] = nil
end

return CurrencyService
