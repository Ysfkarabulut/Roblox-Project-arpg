--[[
	Shared boss encounter state for combat targeting.
]]

local BossCombatTargets = {}

local active = false

function BossCombatTargets.SetActive(on: boolean)
	active = on
end

function BossCombatTargets.IsActive(): boolean
	return active
end

function BossCombatTargets.GetBossModel(): Model?
	if not active then
		return nil
	end
	local eye = workspace:FindFirstChild("Boss_TheEye")
	if eye and eye:IsA("Model") and eye:GetAttribute("IsBoss") then
		return eye
	end
	local breaker = workspace:FindFirstChild("Boss_TheBreaker")
	if breaker and breaker:IsA("Model") and breaker:GetAttribute("IsBoss") then
		return breaker
	end
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("IsBoss") then
			return child
		end
	end
	return nil
end

return BossCombatTargets
