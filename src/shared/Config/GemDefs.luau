--[[
	Element gems — socket into weapon handle; element tag source.
]]

local ElementData = require(script.Parent.ElementData)

local GemDefs = {}

function GemDefs.Build(): { [string]: any }
	local out = {}
	for _, el in ElementData.List do
		local lower = ElementData.Lower[el]
		local sig = ElementData.Signature[el]
		local id = `gem_{lower}`
		out[id] = {
			id = id,
			name = `{sig.label} Gem`,
			kind = "ElementGem",
			element = el,
			slotHints = {},
			rarity = "Common",
			desc = `Socket into weapon handle · element {el}`,
		}
	end
	return out
end

return GemDefs
