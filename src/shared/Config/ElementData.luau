--[[
	Shared element metadata for weapon / armor matrix.
]]

local ElementData = {}

ElementData.List = {
	"Fire",
	"Water",
	"Lightning",
	"Wind",
	"Poison",
	"Rock",
	"Steel",
	"Neutral",
}

-- Signature status applied by element-flavored actives / pure x3
ElementData.Signature = {
	Fire = { id = "Ignite", short = "Ignite 3s", label = "Ignite" },
	Water = { id = "Wet", short = "Wet 5s", label = "Wet" },
	Lightning = { id = "Shock", short = "Shock 0.5s", label = "Shock" },
	Wind = { id = "Windy", short = "Windy 3s", label = "Windy" },
	Poison = { id = "Poisoned", short = "Poisoned 5s (3 DPS)", label = "Poisoned" },
	Rock = { id = "Slow", short = "Slow 50% 2s", label = "Slow" },
	Steel = { id = "Bleed", short = "Bleed 8s (4 DPS)", label = "Bleed" },
	Neutral = { id = nil, short = "no signature status", label = "Unbound" },
}

ElementData.Lower = {
	Fire = "fire",
	Water = "water",
	Lightning = "lightning",
	Wind = "wind",
	Poison = "poison",
	Rock = "rock",
	Steel = "steel",
	Neutral = "neutral",
}

return ElementData
