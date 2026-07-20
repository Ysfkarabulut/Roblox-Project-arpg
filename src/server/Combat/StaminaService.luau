--[[
	Stamina — dodge / sprint / guard / parry stance (regen pause).
]]

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local StatService = require(script.Parent.StatService)

local StaminaService = {}

local current: { [number]: number } = {}
local regenPausedUntil: { [number]: number } = {}

function StaminaService.Max(userId: number): number
	return StatService.Derived(userId).stamina
end

function StaminaService.Get(userId: number): number
	if current[userId] == nil then
		current[userId] = StaminaService.Max(userId)
	end
	return current[userId]
end

function StaminaService.Set(userId: number, value: number)
	current[userId] = math.clamp(value, 0, StaminaService.Max(userId))
end

function StaminaService.Spend(userId: number, amount: number): boolean
	local cur = StaminaService.Get(userId)
	if cur < amount then
		return false
	end
	StaminaService.Set(userId, cur - amount)
	regenPausedUntil[userId] = os.clock() + 0.4
	return true
end

function StaminaService.Drain(userId: number, amount: number)
	StaminaService.Set(userId, StaminaService.Get(userId) - amount)
end

function StaminaService.Tick(userId: number, dt: number, defending: boolean, sprinting: boolean)
	local max = StaminaService.Max(userId)
	local cur = StaminaService.Get(userId)
	if sprinting then
		StaminaService.Drain(userId, CombatConfig.SprintDrainPerSec * dt)
		return
	end
	if defending then
		return -- guard drain / parry: no regen while stance open
	end
	local pause = regenPausedUntil[userId] or 0
	if os.clock() < pause then
		return
	end
	local regen = 8 + StatService.Get(userId).VIT * 0.08
	StaminaService.Set(userId, cur + regen * dt)
end

function StaminaService.Clear(userId: number)
	current[userId] = nil
	regenPausedUntil[userId] = nil
end

return StaminaService
