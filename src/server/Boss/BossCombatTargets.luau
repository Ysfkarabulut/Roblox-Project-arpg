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
	local ws = workspace
	local m = ws:FindFirstChild("Boss_TheEye")
	if m and m:IsA("Model") and m:GetAttribute("IsBoss") then
		return m
	end
	return nil
end

return BossCombatTargets
