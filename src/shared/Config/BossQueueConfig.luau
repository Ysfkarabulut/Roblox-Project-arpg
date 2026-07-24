--[[
	Boss queue preferences — specific boss or wildcard (all / random).
	Wildcard queues can match players waiting for a specific boss.
]]

local BossEncounterConfig = require(script.Parent.BossEncounterConfig)

export type BossQueuePref = "eye" | "breaker" | "all" | "random"

local BossQueueConfig = {}

local SPECIFIC: { [string]: boolean } = {
	eye = true,
	breaker = true,
}

local WILDCARD: { [string]: boolean } = {
	all = true,
	random = true,
}

local RANDOM_POOL = { "eye", "breaker" }

function BossQueueConfig.Normalize(pref: any): BossQueuePref?
	if typeof(pref) ~= "string" then
		return nil
	end
	if pref == "random" then
		return "all"
	end
	if SPECIFIC[pref] or pref == "all" then
		return pref :: BossQueuePref
	end
	return nil
end

function BossQueueConfig.IsValid(pref: any): boolean
	return BossQueueConfig.Normalize(pref) ~= nil
end

function BossQueueConfig.IsWildcard(pref: any): boolean
	return typeof(pref) == "string" and WILDCARD[pref] == true
end

function BossQueueConfig.IsSpecific(pref: any): boolean
	return typeof(pref) == "string" and SPECIFIC[pref] == true
end

function BossQueueConfig.CanMatch(a: any, b: any): boolean
	local na = BossQueueConfig.Normalize(a)
	local nb = BossQueueConfig.Normalize(b)
	if not na or not nb then
		return false
	end
	if BossQueueConfig.IsWildcard(na) or BossQueueConfig.IsWildcard(nb) then
		return true
	end
	return na == nb
end

function BossQueueConfig.Resolve(pref: BossQueuePref): string
	local norm = BossQueueConfig.Normalize(pref)
	if not norm or BossQueueConfig.IsWildcard(norm) then
		return RANDOM_POOL[math.random(1, #RANDOM_POOL)]
	end
	return norm
end

function BossQueueConfig.ResolveMatch(prefs: { BossQueuePref }): string
	for _, pref in prefs do
		local norm = BossQueueConfig.Normalize(pref)
		if norm and BossQueueConfig.IsSpecific(norm) then
			return norm
		end
	end
	return RANDOM_POOL[math.random(1, #RANDOM_POOL)]
end

function BossQueueConfig.GetDisplayName(pref: BossQueuePref): string
	if BossQueueConfig.IsWildcard(pref) then
		return "Random"
	end
	local norm = BossQueueConfig.Normalize(pref)
	if not norm then
		return tostring(pref)
	end
	local def = BossEncounterConfig.Get(norm)
	return if def then def.displayName else norm
end

function BossQueueConfig.GetWildcardOption(): { id: BossQueuePref, label: string }
	return { id = "all", label = "Random" }
end

function BossQueueConfig.GetBossList(): { { id: BossQueuePref, label: string } }
	local out = {}
	for _, id in RANDOM_POOL do
		local def = BossEncounterConfig.Get(id)
		table.insert(out, {
			id = id :: BossQueuePref,
			label = if def then def.displayName else id,
		})
	end
	return out
end

-- Back-compat for older callers
function BossQueueConfig.GetOptions(): { { id: BossQueuePref, label: string } }
	local out = { BossQueueConfig.GetWildcardOption() }
	for _, entry in BossQueueConfig.GetBossList() do
		table.insert(out, entry)
	end
	return out
end

return BossQueueConfig
