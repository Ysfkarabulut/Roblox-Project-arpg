--[[
	Shield combat params — Guard chip / drain / slow.
]]

local ShieldDefs = {
	o_buckler = {
		chipPct = 0.60,
		drainPerSec = 0.5,
		guardSlow = 0.10,
		defence = 60,
	},
	o_kite = {
		chipPct = 0.40,
		drainPerSec = 1.0,
		guardSlow = 0.20,
		defence = 120,
	},
	o_tower = {
		chipPct = 0.30,
		drainPerSec = 1.5,
		guardSlow = 0.30,
		defence = 160,
	},
	o_round = {
		chipPct = 0.45,
		drainPerSec = 0.8,
		guardSlow = 0.15,
		defence = 90,
	},
	o_spiked = {
		chipPct = 0.50,
		drainPerSec = 1.1,
		guardSlow = 0.18,
		defence = 100,
		-- proto: no thorn on chip (Thorn status separate)
	},
}

function ShieldDefs.Get(defId: string?)
	if not defId then
		return nil
	end
	return ShieldDefs[defId]
end

return ShieldDefs
