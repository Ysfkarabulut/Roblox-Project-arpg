--[[
	Common roster: every weapon family × every element (1 each).
	Handcrafted / boss defs in ItemDefs override matching ids.
]]

local ElementData = require(script.Parent.ElementData)

local WeaponMatrix = {}

local function sig(el: string)
	return ElementData.Signature[el]
end

-- Element name flavors (index matches ElementData.List)
local PREFIX = {
	Fire = { "Ember", "Cinder", "Ashen", "Blazing", "Pyre", "Kindling", "Scorch", "Infernal" },
	Water = { "Tide", "Brine", "Ripple", "Flood", "Mist", "Deep", "Azure", "Current" },
	Lightning = { "Storm", "Arc", "Volt", "Thunder", "Spark", "Flash", "Static", "Bolt" },
	Wind = { "Gale", "Zephyr", "Gust", "Sky", "Draft", "Howl", "Breeze", "Cyclone" },
	Poison = { "Venom", "Blight", "Toxin", "Serpent", "Mire", "Plague", "Fang", "Spore" },
	Rock = { "Stone", "Granite", "Fault", "Boulder", "Quake", "Cliff", "Bedrock", "Shard" },
	Steel = { "Iron", "Steel", "Razor", "Forge", "Cold", "Plate", "Wire", "Tempered" },
	Neutral = { "Hollow", "Mute", "Grey", "Quiet", "Plain", "Blank", "Simple", "Common" },
}

local function elIndex(el: string): number
	for i, e in ElementData.List do
		if e == el then
			return i
		end
	end
	return 1
end

local function nameOf(el: string, noun: string, familyIndex: number): string
	local list = PREFIX[el]
	local p = list[((familyIndex + elIndex(el) - 2) % #list) + 1]
	return `{p} {noun}`
end

local function activeStatus(el: string, pct: number, shape: string): any
	local s = sig(el)
	local statusLine = if s.id
		then ` · isabette {s.short}`
		else " · Unbound (+3% direct on hit, playtest)"
	return {
		id = `mx_{ElementData.Lower[el]}_strike`,
		name = if s.id then `{s.label} Strike` else "Unbound Strike",
		slotType = "Active",
		cooldownSec = 9 + (elIndex(el) % 4),
		desc = `{shape} · {pct}% weapon base{statusLine} · stam 0`,
	}
end

local function passiveStatus(el: string, flavor: string): any
	local s = sig(el)
	if s.id then
		return {
			id = `mx_{ElementData.Lower[el]}_edge`,
			name = `{s.label} Edge`,
			slotType = "Passive",
			desc = `{flavor} · light-attack hit: 15% chance {s.short}`,
		}
	end
	return {
		id = "mx_neutral_edge",
		name = "Unbound Edge",
		slotType = "Passive",
		desc = `{flavor} · Direct +3% (Unbound-friendly)`,
	}
end

local function passiveUtility(el: string, text: string): any
	return {
		id = `mx_{ElementData.Lower[el]}_util`,
		name = text.name,
		slotType = "Passive",
		desc = text.desc,
	}
end

-- familyIndex used only for naming variety
local FAMILIES = {
	{
		key = "dagger",
		family = "Dagger",
		kind = "Weapon1H",
		noun = "Shiv",
		slotHints = { "main", "off" },
		scaling = "DEX",
		asTier = "D",
		baseDamage = 30,
		requires = { DEX = 28 },
		familyPerk = "Backstab ×1.30 (arka 180°)",
		slots = "1H",
		familyIndex = 1,
		shape = "Dash thrust ~7 stud",
		pct = 120,
	},
	{
		key = "sword_1h",
		family = "Sword",
		kind = "Weapon1H",
		noun = "Longsword",
		slotHints = { "main", "off" },
		scaling = "STR",
		asTier = "C",
		baseDamage = 40,
		requires = { STR = 28 },
		familyPerk = "Measured Strike L3 ×1.35",
		slots = "1H",
		familyIndex = 2,
		shape = "Thrust 6 stud",
		pct = 130,
	},
	{
		key = "axe_1h",
		family = "Axe",
		kind = "Weapon1H",
		noun = "Hatchet",
		slotHints = { "main", "off" },
		scaling = "STR",
		asTier = "B",
		baseDamage = 46,
		requires = { STR = 30 },
		familyPerk = "Anti-guard stamina ×1.25",
		slots = "1H",
		familyIndex = 3,
		shape = "Cleaving chop 5 stud",
		pct = 140,
	},
	{
		key = "mace_1h",
		family = "Mace",
		kind = "Weapon1H",
		noun = "Mace",
		slotHints = { "main", "off" },
		scaling = "STR",
		asTier = "A",
		baseDamage = 48,
		requires = { STR = 32 },
		familyPerk = "Defence Shred (1H)",
		slots = "1H",
		familyIndex = 4,
		shape = "Overhead smash 5 stud",
		pct = 145,
	},
	{
		key = "wand",
		family = "Wand",
		kind = "Wand",
		noun = "Wand",
		slotHints = { "main", "off" },
		scaling = "INT",
		asTier = "D",
		baseDamage = 30,
		requires = { INT = 28 },
		familyPerk = "+Status Potency · Arc Bolt L3 ×1.20",
		slots = "1H",
		familyIndex = 5,
		shape = "Bolt ~22 stud",
		pct = 125,
	},
	{
		key = "scepter",
		family = "Scepter",
		kind = "Scepter",
		noun = "Scepter",
		slotHints = { "main", "off" },
		scaling = "INT",
		asTier = "E",
		baseDamage = 28,
		requires = { INT = 30 },
		familyPerk = "+Buff Potency · Radiant Sweep L3 ×1.25 · cone",
		slots = "1H",
		familyIndex = 6,
		shape = "Cone ~45° · 16 stud · max 3",
		pct = 115,
	},
	{
		key = "sword_2h",
		family = "Sword",
		kind = "Weapon2H",
		noun = "Greatblade",
		slotHints = { "main" },
		scaling = "STR",
		asTier = "B",
		baseDamage = 50,
		requires = { STR = 36 },
		familyPerk = "Measured Strike L3 ×1.40",
		slots = "2H",
		familyIndex = 7,
		shape = "Wide sweep 8 stud",
		pct = 140,
	},
	{
		key = "axe_2h",
		family = "Axe",
		kind = "Weapon2H",
		noun = "Greataxe",
		slotHints = { "main" },
		scaling = "STR",
		asTier = "A",
		baseDamage = 54,
		requires = { STR = 38 },
		familyPerk = "Anti-guard stamina ×1.50 (2H)",
		slots = "2H",
		familyIndex = 8,
		shape = "Front cone 6 stud",
		pct = 155,
	},
	{
		key = "mace_2h",
		family = "Mace",
		kind = "Weapon2H",
		noun = "Warhammer",
		slotHints = { "main" },
		scaling = "STR",
		asTier = "S",
		baseDamage = 58,
		requires = { STR = 40 },
		familyPerk = "Defence Shred (yüksek) 2H",
		slots = "2H",
		familyIndex = 9,
		shape = "Ground slam 8 stud",
		pct = 150,
	},
	{
		key = "staff",
		family = "Staff",
		kind = "Staff",
		noun = "Staff",
		slotHints = { "main" },
		scaling = "INT",
		asTier = "B",
		baseDamage = 46,
		requires = { INT = 34 },
		familyPerk = "+Status Potency++ · Empowered Bolt L3 ×1.30",
		slots = "2H",
		familyIndex = 10,
		shape = "Bolt ~30 stud",
		pct = 135,
	},
	{
		key = "bow",
		family = "Bow",
		kind = "Bow",
		noun = "Longbow",
		slotHints = { "main" },
		scaling = "DEX",
		asTier = "C",
		baseDamage = 40,
		requires = { DEX = 32 },
		familyPerk = "+Crit Chance · Focused Shot L3 ×1.25",
		slots = "2H",
		familyIndex = 11,
		shape = "Arrow ~28 stud",
		pct = 130,
	},
	{
		key = "crossbow",
		family = "Crossbow",
		kind = "Crossbow",
		noun = "Crossbow",
		slotHints = { "main" },
		scaling = "DEX",
		asTier = "S",
		baseDamage = 58,
		requires = { DEX = 34 },
		familyPerk = "+Crit Damage · Heavy Bolt L3 ×1.40 + reload 1.2s",
		slots = "2H",
		familyIndex = 12,
		shape = "Bolt ~26 stud",
		pct = 160,
	},
}

local function build1H(fam, el: string)
	local useActive = (elIndex(el) + fam.familyIndex) % 2 == 0
	local abilities = if useActive
		then { activeStatus(el, fam.pct, fam.shape) }
		else { passiveStatus(el, fam.family) }

	local slotKind = if useActive then "Active" else "Passive"
	local id = `w_{fam.key}_{ElementData.Lower[el]}`
	return id, {
		id = id,
		name = nameOf(el, fam.noun, fam.familyIndex),
		kind = fam.kind,
		family = fam.family,
		slotHints = fam.slotHints,
		element = el,
		scaling = fam.scaling,
		asTier = fam.asTier,
		baseDamage = fam.baseDamage,
		requires = fam.requires,
		familyPerk = fam.familyPerk,
		onHitAffix = nil,
		rarity = "Common",
		abilities = abilities,
		desc = `{el} · {fam.family} · yalnız 1 {slotKind}`,
	}
end

local function build2H(fam, el: string)
	local pattern = (elIndex(el) + fam.familyIndex) % 3 -- 0=1A+1P, 1=2A, 2=2P
	local abilities
	if pattern == 1 then
		abilities = {
			activeStatus(el, fam.pct, fam.shape),
			{
				id = `mx_{ElementData.Lower[el]}_burst`,
				name = "Second Wind",
				slotType = "Active",
				cooldownSec = 14,
				desc = `Self Move Speed +20% 3s · next LA +25% · stam 0`,
			},
		}
	elseif pattern == 2 then
		abilities = {
			passiveStatus(el, fam.family),
			passiveUtility(el, {
				name = "Steady Grip",
				desc = "Crit Chance +3% (flat, before cap)",
			}),
		}
	else
		abilities = {
			activeStatus(el, fam.pct, fam.shape),
			passiveStatus(el, fam.family),
		}
	end

	local slotLabel = if pattern == 1 then "2 Active" elseif pattern == 2 then "2 Passive" else "1 Active + 1 Passive"
	local offNote = if fam.kind == "Bow" or fam.kind == "Crossbow" then "Quiver off" else "Knot off"
	local id = `w_{fam.key}_{ElementData.Lower[el]}`
	return id, {
		id = id,
		name = nameOf(el, fam.noun, fam.familyIndex),
		kind = fam.kind,
		family = fam.family,
		slotHints = fam.slotHints,
		element = el,
		scaling = fam.scaling,
		asTier = fam.asTier,
		baseDamage = fam.baseDamage,
		requires = fam.requires,
		familyPerk = fam.familyPerk,
		onHitAffix = nil,
		rarity = "Common",
		abilities = abilities,
		desc = `{el} · {fam.family} · {slotLabel} · {offNote}`,
	}
end

function WeaponMatrix.Build(): { [string]: any }
	local out = {}
	for _, fam in FAMILIES do
		for _, el in ElementData.List do
			local id, def
			if fam.slots == "1H" then
				id, def = build1H(fam, el)
			else
				id, def = build2H(fam, el)
			end
			out[id] = def
		end
	end
	return out
end

return WeaponMatrix
