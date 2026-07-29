--[[
	Vesteria-style inspect hints — synergy band, element reactions, exotic perks.
]]

local ReactionTable = require(script.Parent.Parent.Config.ReactionTable)
local ElementData = require(script.Parent.Parent.Config.ElementData)

local InspectHints = {}

local function reactionLine(r: any): string
	local outcome = r.id
	if r.kind == "Burst" then
		outcome = `{r.id} (burst)`
	elseif r.chain then
		outcome = `{r.id} (chain)`
	elseif r.outputStatus then
		outcome = r.outputStatus
	end
	return `{r.a} + {r.b} → {outcome}`
end

function InspectHints.ExoticPerkLine(def: any): string?
	if not def or def.rarity ~= "Exotic" then
		return nil
	end
	if def.familyPerk and def.familyPerk ~= "" then
		return def.familyPerk
	end
	return "Rule-breaking exotic — read abilities below"
end

function InspectHints.SynergyLines(derived: any?): { string }
	if not derived then
		return {}
	end
	local lines: { string } = {}
	local band = derived.synergyBand or "None"
	if band == "None" then
		table.insert(lines, "No band — equip 3 chest pieces with elements for synergy")
	else
		local bandText = band
		if band == "Pure" and derived.synergyElement then
			bandText = `Pure ({derived.synergyElement})`
		elseif (band == "Duality" or band == "Harmony") and derived.synergyElements then
			bandText = `{band} ({table.concat(derived.synergyElements, " · ")})`
		end
		table.insert(lines, `Current build band: {bandText}`)
	end
	if derived.synergyPerk and derived.synergyPerk ~= "" then
		table.insert(lines, derived.synergyPerk)
	end
	return lines
end

function InspectHints.ReactionPrimer(maxLines: number?): { string }
	local cap = maxLines or 6
	local lines: { string } = {}
	for i, r in ReactionTable.List do
		if i > cap then
			break
		end
		table.insert(lines, reactionLine(r))
	end
	table.insert(lines, "FIFO apply order — first status on target wins pairing")
	return lines
end

function InspectHints.ReactionsForStatus(statusId: string): { string }
	local lines: { string } = {}
	for _, r in ReactionTable.List do
		if r.a == statusId or r.b == statusId then
			table.insert(lines, reactionLine(r))
		end
	end
	return lines
end

function InspectHints.ReactionsForElement(element: string?): { string }
	if not element then
		return {}
	end
	local sig = ElementData.Signature[element]
	if not sig or not sig.id then
		return {}
	end
	return InspectHints.ReactionsForStatus(sig.id)
end

return InspectHints
