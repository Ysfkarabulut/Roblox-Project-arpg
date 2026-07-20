--[[
	L1→L2→L3 combo — silah/yük başına (hedef değil). Window 0.6s.
]]

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)

local ComboTracker = {}

type State = {
	step: number, -- next step to perform (1-3)
	windowUntil: number,
}

local byUser: { [number]: State } = {}

local function ensure(userId: number): State
	if not byUser[userId] then
		byUser[userId] = { step = 1, windowUntil = 0 }
	end
	return byUser[userId]
end

--- Returns combo step used for this hit (1-3), then advances on success
function ComboTracker.PeekStep(userId: number): number
	local s = ensure(userId)
	local t = os.clock()
	if t > s.windowUntil then
		s.step = 1
	end
	return s.step
end

function ComboTracker.CommitHit(userId: number)
	local s = ensure(userId)
	local t = os.clock()
	if t > s.windowUntil then
		s.step = 1
	end
	local used = s.step
	if used >= 3 then
		s.step = 1
	else
		s.step = used + 1
	end
	s.windowUntil = t + CombatConfig.ComboWindowSec
	return used
end

function ComboTracker.CommitBlock(userId: number)
	-- Guard block also advances combo
	return ComboTracker.CommitHit(userId)
end

function ComboTracker.Clear(userId: number)
	byUser[userId] = nil
end

return ComboTracker
