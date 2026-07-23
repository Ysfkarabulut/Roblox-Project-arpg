--[[

	Movement / CC queries from active status list (STATUS_SYSTEM.md §3.1c).

]]



local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)

local PressureTypes = require(script.Parent.PressureTypes)



export type StatusEntry = {

	id: string,

	params: { [string]: any }?,

}



local StatusQuery = {}



local HARD_CC = PressureTypes.HARD_CC

local ROOT = { Root = true }

local KNOCKBACK = { Knockback = true }

local HITSTUN = PressureTypes.PRESSURE_CC



local DEFAULT_SLOW_PCT: { [string]: number } = {

	Windy = 30,

	Slow = 50,

	Grounded = 80,

	Hitstun = CombatConfig.HitstunMoveSlowPct or 42,

}



local function slowPctFromStatus(status: StatusEntry): number?

	if HARD_CC[status.id] or KNOCKBACK[status.id] or ROOT[status.id] then

		return 100

	end



	local params = status.params

	if params then

		if typeof(params.slowPct) == "number" then

			return math.clamp(params.slowPct, 0, 100)

		end

		if typeof(params.slow) == "number" then

			local v = params.slow

			if v > 0 and v <= 1 then

				return math.clamp(v * 100, 0, 100)

			end

			return math.clamp(v, 0, 100)

		end

	end



	local default = DEFAULT_SLOW_PCT[status.id]

	if default then

		return default

	end

	return nil

end



function StatusQuery.GetMoveSpeedMult(statusList: { StatusEntry }): number

	local mult = 1

	for _, status in statusList do

		local slowPct = slowPctFromStatus(status)

		if slowPct then

			if slowPct >= 100 then

				return 0

			end

			mult = math.min(mult, 1 - slowPct / 100)

		end

	end

	return math.clamp(mult, 0, 1)

end



function StatusQuery.CanMove(statusList: { StatusEntry }): boolean

	return StatusQuery.GetMoveSpeedMult(statusList) > 0

end



function StatusQuery.CanAttack(statusList: { StatusEntry }): boolean

	for _, status in statusList do

		if HARD_CC[status.id] or KNOCKBACK[status.id] or HITSTUN[status.id] then

			return false

		end

	end

	return true

end



function StatusQuery.HasHyperArmor(statusList: { StatusEntry }): boolean

	for _, status in statusList do

		if status.id == "HyperArmor" then

			return true

		end

	end

	return false

end



function StatusQuery.HasCcImmunity(statusList: { StatusEntry }): boolean

	for _, status in statusList do

		if status.id == "CcImmunity" or status.id == "JuggleBreak" then

			return true

		end

	end

	return false

end



return StatusQuery

