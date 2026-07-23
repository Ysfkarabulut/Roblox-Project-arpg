--[[
	Common armor roster: Head / Chest / Hands / Feets × every element.
	Def/Res from COMBAT_STAT_SHEET tank / mage bands.
	Abilities → ArmorAbilityDefs (*_armorpassive / *_armoractive).
]]

local ElementData = require(script.Parent.ElementData)
local ArmorAbilityDefs = require(script.Parent.ArmorAbilityDefs)

local ArmorMatrix = {}

local TANK = {
	chest = { defence = 80, resist = 20 },
	head = { defence = 16, resist = 5 },
	feets = { defence = 14, resist = 10 },
	hands = { defence = 5, resist = 8 },
}

local MAGE = {
	chest = { defence = 40, resist = 45 },
	head = { defence = 8, resist = 14 },
	feets = { defence = 7, resist = 18 },
	hands = { defence = 3, resist = 16 },
}

local TANK_ELEMENTS = {
	Rock = true,
	Steel = true,
	Neutral = true,
}

local NAMES = {
	Fire = {
		head = "Cinder Visor",
		chest = "Ashen Cuirass",
		hands = "Kindling Grips",
		feets = "Pyre Striders",
	},
	Water = {
		head = "Brine Circlet",
		chest = "Tide Mail",
		hands = "Current Wraps",
		feets = "Mist Treads",
	},
	Lightning = {
		head = "Arc Crown",
		chest = "Storm Vest",
		hands = "Volt Gauntlets",
		feets = "Flash Greaves",
	},
	Wind = {
		head = "Zephyr Hood",
		chest = "Gale Vest",
		hands = "Draft Gloves",
		feets = "Howl Boots",
	},
	Poison = {
		head = "Venom Mask",
		chest = "Blight Harness",
		hands = "Toxin Claws",
		feets = "Mire Steppers",
	},
	Rock = {
		head = "Granite Helm",
		chest = "Fault Plate",
		hands = "Quake Mitts",
		feets = "Cliff Sabatons",
	},
	Steel = {
		head = "Iron Sallet",
		chest = "Forge Cuirass",
		hands = "Razor Gauntlets",
		feets = "Plate Greaves",
	},
	Neutral = {
		head = "Mute Cap",
		chest = "Hollow Mail",
		hands = "Grey Wraps",
		feets = "Quiet Boots",
	},
}

local function statsFor(el: string, slot: string)
	local band = if TANK_ELEMENTS[el] then TANK else MAGE
	return band[slot]
end

local function sig(el: string)
	return ElementData.Signature[el]
end

--- One ability per piece — slot role + element flavor name
local function abilityIdsFor(el: string, slot: string): { any }
	local s = sig(el)

	if slot == "chest" then
		if el == "Neutral" then
			return {
				ArmorAbilityDefs.AbilitySlot("unbound_hide_armorpassive", "Unbound Hide"),
			}
		end
		return {
			ArmorAbilityDefs.AbilitySlot("carapace_armorpassive", `{s.label} Carapace`),
		}
	end

	if slot == "head" then
		if el == "Rock" then
			return {
				ArmorAbilityDefs.AbilitySlot("stone_focus_armorpassive", "Stone Focus"),
			}
		end
		if el == "Neutral" then
			return {
				ArmorAbilityDefs.AbilitySlot(
					"helm_pulse_armoractive",
					"Mute Pulse",
					14
				),
			}
		end
		return {
			ArmorAbilityDefs.AbilitySlot("helm_pulse_armoractive", `{s.label} Pulse`, 14),
		}
	end

	if slot == "hands" then
		local name = if s.id then `{s.label} Touch` else "Blank Touch"
		return {
			ArmorAbilityDefs.AbilitySlot("hand_touch_armoractive", name, 11),
		}
	end

	-- feets
	if el == "Neutral" then
		return {
			ArmorAbilityDefs.AbilitySlot("quiet_step_armorpassive", "Quiet Step"),
		}
	end
	return {
		ArmorAbilityDefs.AbilitySlot("dodge_step_armorpassive", `{s.label} Step`),
	}
end

local SLOTS = {
	{ key = "head", kind = "Head", slotHints = { "head" } },
	{ key = "chest", kind = "Chest", slotHints = { "chest" } },
	{ key = "hands", kind = "Hands", slotHints = { "hands" } },
	{ key = "feets", kind = "Feets", slotHints = { "feets" } },
}

--- Steel tank set used as default playtest loadout
ArmorMatrix.TestSetIds = {
	head = "a_head_steel",
	chest = "a_chest_steel",
	hands = "a_hands_steel",
	feets = "a_feets_steel",
}

function ArmorMatrix.Build(): { [string]: any }
	local out = {}
	for _, el in ElementData.List do
		for _, slot in SLOTS do
			local st = statsFor(el, slot.key)
			local id = `a_{slot.key}_{ElementData.Lower[el]}`
			out[id] = {
				id = id,
				name = NAMES[el][slot.key],
				kind = slot.kind,
				slotHints = slot.slotHints,
				element = el,
				defence = st.defence,
				resist = st.resist,
				rarity = "Common",
				abilities = abilityIdsFor(el, slot.key),
				desc = `{el} · {slot.kind} · Def {st.defence} · Res {st.resist}`,
			}
		end
	end
	return out
end

return ArmorMatrix
