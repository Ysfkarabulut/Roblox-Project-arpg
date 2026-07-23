--[[
	Hotbar / ability chip hover text (English).
]]

local AbilityRuntime = require(script.Parent.Parent.Config.AbilityRuntime)
local WeaponActiveDefs = require(script.Parent.Parent.Config.WeaponActiveDefs)
local PassiveDefs = require(script.Parent.Parent.Config.PassiveDefs)
local ArmorAbilityDefs = require(script.Parent.Parent.Config.ArmorAbilityDefs)
local FocusAbilityDefs = require(script.Parent.Parent.Config.FocusAbilityDefs)

local AbilityTooltip = {}

export type Flavor = {
	name: string?,
	desc: string?,
	cooldownSec: number?,
}

local function catalog(abilityId: string)
	return WeaponActiveDefs.Get(abilityId) or PassiveDefs.Get(abilityId) or ArmorAbilityDefs.Get(abilityId)
		or FocusAbilityDefs.Get(abilityId)
end

local function shapeLine(spec: any): string?
	local shape = spec.shape
	if shape == "Single" or shape == "Dash" then
		return `Shape: single target · {spec.range} stud`
	elseif shape == "Cone" or shape == "AllyCone" then
		return `Shape: cone · {spec.range} stud · {spec.coneDeg or 90}°`
	elseif shape == "Sphere" or shape == "AllySphere" then
		return `Shape: circle · radius {spec.radius or spec.range} stud`
	elseif shape == "GroundSphere" then
		return `Shape: thrown net · {spec.range} stud · radius {spec.radius or spec.range} stud`
	elseif shape == "Grapple" then
		return `Shape: hook · {spec.range} stud · {spec.radius or 4} stud latch radius`
	elseif shape == "Line" then
		return `Shape: line · {spec.range} stud · width {(spec.lineWidth or 3.5) * 2} stud`
	elseif shape == "AllySingle" then
		return `Shape: ally · {spec.range} stud · aim teammate`
	elseif shape == "Self" then
		return "Shape: self"
	end
	return nil
end

local function combatLines(abilityId: string, cooldownSec: number?): { string }
	local spec = AbilityRuntime.Get(abilityId, "Neutral", cooldownSec)
	local lines: { string } = {}
	local sl = shapeLine(spec)
	if sl then
		table.insert(lines, sl)
	end
	if spec.damagePct and spec.damagePct > 0 then
		table.insert(lines, `Damage: {spec.damagePct}% weapon base`)
	end
	if spec.hitCount and spec.hitCount > 1 then
		table.insert(lines, `Hits: {spec.hitCount}×`)
	end
	if spec.healBase and spec.healBase > 0 then
		table.insert(lines, `Heal: {spec.healBase} base (Buff Potency scales)`)
	end
	if spec.hotHps and spec.hotHps > 0 then
		table.insert(lines, `HoT: {spec.hotHps} HP/s for {spec.hotDuration or 5}s`)
	end
	if spec.selfBuff then
		table.insert(lines, `Buff: {spec.selfBuff} {spec.selfBuffDuration or 3}s`)
	end
	if spec.statusId then
		local extra = if spec.statusDps then ` · {spec.statusDps} DPS` else ""
		local slow = if spec.statusParams and spec.statusParams.slowPct then ` · {spec.statusParams.slowPct}% slow` else ""
		table.insert(lines, `On-hit: {spec.statusId} {spec.statusDuration or "?"}s{extra}{slow}`)
	end
	if spec.knockbackStuds and spec.knockbackStuds > 0 then
		table.insert(lines, `Knockback: {spec.knockbackStuds} stud push`)
	end
	if spec.chargeStuds and spec.chargeStuds > 0 then
		table.insert(lines, `Charge: {spec.chargeStuds} stud dash`)
	end
	if spec.retreatStuds and spec.retreatStuds > 0 then
		table.insert(lines, `Retreat: {spec.retreatStuds} stud back-dash`)
	end
	return lines
end

function AbilityTooltip.Build(abilityId: string, flavor: Flavor?): (string, string)
	flavor = flavor or {}
	local def = catalog(abilityId)
	local title = flavor.name or (def and def.name) or abilityId
	local lines: { string } = {}

	local desc = flavor.desc or (def and def.desc)
	if desc and desc ~= "" then
		table.insert(lines, desc)
	end

	for _, line in combatLines(abilityId, flavor.cooldownSec or (def and (def :: any).defaultCooldownSec)) do
		table.insert(lines, line)
	end

	if def and PassiveDefs.Get(abilityId) then
		table.insert(lines, "Passive — always active while equipped")
	elseif def and ArmorAbilityDefs.Get(abilityId) then
		table.insert(lines, "Armor active")
	end

	if #lines == 0 then
		table.insert(lines, abilityId)
	end

	return title, table.concat(lines, "\n")
end

return AbilityTooltip
