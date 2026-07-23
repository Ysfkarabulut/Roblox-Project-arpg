--[[
	Direct heal — no overheal. Buff Potency scales amount.
]]

local HealService = {}

function HealService.Apply(entity: Instance, amount: number): number
	if amount <= 0 then
		return 0
	end
	local hum = entity:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return 0
	end
	local before = hum.Health
	hum.Health = math.min(hum.MaxHealth, hum.Health + math.floor(amount + 0.5))
	return hum.Health - before
end

return HealService
