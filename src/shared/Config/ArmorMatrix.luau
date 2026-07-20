--[[
	Common armor roster: Head / Chest / Hands / Feets × every element.
	Def/Res from COMBAT_STAT_SHEET §12.10b (tank band); mage-lean invert for soft elements.
	Rare named pieces in ItemDefs override matching ids if same id — rares use unique ids.
]]

local ElementData = require(script.Parent.ElementData)

local ArmorMatrix = {}

-- Tank band (§12.10b)
local TANK = {
	chest = { defence = 80, resist = 20 },
	head = { defence = 16, resist = 5 },
	feets = { defence = 14, resist = 10 },
	hands = { defence = 5, resist = 8 },
}

-- Mage-lean (low Def, high Res) — Fire/Water/Lightning/Wind/Poison
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

-- One ability per piece — slot role + element flavor
local function abilityFor(el: string, slot: string): any
	local s = sig(el)
	local low = ElementData.Lower[el]

	if slot == "chest" then
		if el == "Neutral" then
			-- Common hollow mail — light unbound, not full Thornplate
			return {
				id = "unbound_hide",
				name = "Unbound Hide",
				slotType = "Passive",
				desc = "Direct taken −3% (after DR) · no Thorn",
			}
		end
		return {
			id = `{low}_carapace`,
			name = `{s.label} Carapace`,
			slotType = "Passive",
			desc = if s.id
				then `When you take Direct HP damage: 10% chance apply {s.short} to attacker (not chip; no chain)`
				else "Direct taken −3% (after DR)",
		}
	end

	if slot == "head" then
		if el == "Rock" then
			return {
				id = "stone_focus",
				name = "Stone Focus",
				slotType = "Passive",
				desc = "Fortify from any source: duration +0.5s",
			}
		end
		return {
			id = `{low}_helm_pulse`,
			name = `{s.label} Pulse`,
			slotType = "Active",
			cooldownSec = 14,
			desc = if s.id
				then `Self: next 2 light attacks apply {s.short} · 6s window · stam 0`
				else "Self: Direct +8% for 4s · stam 0",
		}
	end

	if slot == "hands" then
		return {
			id = `{low}_hand_cast`,
			name = if s.id then `{s.label} Touch` else "Blank Touch",
			slotType = "Active",
			cooldownSec = 11,
			desc = if s.id
				then `Touch strike · 6 stud · 120% main WeaponBase · {s.short} · stam 0`
				else "Touch strike · 6 stud · 120% main WeaponBase · stam 0",
		}
	end

	-- feets
	return {
		id = `{low}_step`,
		name = if s.id then `{s.label} Step` else "Quiet Step",
		slotType = "Passive",
		desc = if s.id
			then `On Dodge start: {s.short} to enemies in 4 stud radius at dodge origin`
			else "Dodge stamina cost −8%",
	}
end

local SLOTS = {
	{ key = "head", kind = "Head", slotHints = { "head" } },
	{ key = "chest", kind = "Chest", slotHints = { "chest" } },
	{ key = "hands", kind = "Hands", slotHints = { "hands" } },
	{ key = "feets", kind = "Feets", slotHints = { "feets" } },
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
				abilities = { abilityFor(el, slot.key) },
				desc = `{el} · {slot.kind} · Def {st.defence} · Res {st.resist}`,
			}
		end
	end
	return out
end

return ArmorMatrix
