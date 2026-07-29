--[[
	Reaction pairs — CHEMISTRY §5. FIFO, no R-ID priority.
]]

local ReactionTable = {}

export type ReactionDef = {
	id: string,
	a: string,
	b: string,
	kind: "Burst" | "Status" | "Hybrid" | "Chain",
	-- Burst: remainingDoTKey * factor
	burstFrom: string?, -- which status remaining damage
	burstFactor: number?,
	outputStatus: string?,
	outputDuration: number?,
	outputDurationFrom: ("maxInputs" | "minInputs")?,
	outputParams: { [string]: any }?,
	outputDpsFactor: number?, -- vs ignite dps etc.
	chain: ("Shock" | "Poisoned")?,
}

-- Order in list is NOT priority; FIFO uses apply order
ReactionTable.List = {
	{ id = "Vaporize", a = "Wet", b = "Ignite", kind = "Burst", burstFrom = "Ignite", burstFactor = 1.25 },
	{ id = "ChainShock", a = "Wet", b = "Shock", kind = "Chain", chain = "Shock" },
	{ id = "ChillReaction", a = "Wet", b = "Windy", kind = "Status", outputStatus = "Chilled", outputDuration = 1.5 },
	{ id = "Thaw", a = "Chilled", b = "Ignite", kind = "Status", outputStatus = "Thaw", outputDuration = 2 },
	{ id = "Cauterize", a = "Bleed", b = "Ignite", kind = "Hybrid", burstFrom = "Bleed", burstFactor = 0.75, outputStatus = "Cauterize", outputDuration = 3, outputDpsFactor = 1 },
	{ id = "Blight", a = "Bleed", b = "Poisoned", kind = "Status", outputStatus = "Blight", outputDurationFrom = "maxInputs", outputDpsFactor = 2 },
	{ id = "Grounded", a = "Windy", b = "Slow", kind = "Status", outputStatus = "Grounded", outputDurationFrom = "maxInputs", outputParams = { slowPct = 80 } },
	{ id = "Contamination", a = "Wet", b = "Poisoned", kind = "Chain", chain = "Poisoned" },
	{ id = "WildFire", a = "Windy", b = "Ignite", kind = "Status", outputStatus = "WildFire", outputDuration = 3, outputDpsFactor = 1.5 },
	{ id = "CausticBurn", a = "Ignite", b = "Poisoned", kind = "Status", outputStatus = "CausticBurn", outputDurationFrom = "minInputs", outputDpsFactor = 2 },
} :: { ReactionDef }

function ReactionTable.FindPair(idA: string, idB: string): ReactionDef?
	for _, r in ReactionTable.List do
		if (r.a == idA and r.b == idB) or (r.a == idB and r.b == idA) then
			return r
		end
	end
	return nil
end

--- If status is a reaction output, return the two parent status ids (for split icon UI).
function ReactionTable.OutputParents(outputStatus: string): (string?, string?)
	for _, r in ReactionTable.List do
		if r.outputStatus == outputStatus then
			return r.a, r.b
		end
	end
	return nil, nil
end

return ReactionTable
