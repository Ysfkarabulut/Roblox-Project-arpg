--[[
	Rule-breaking uniques — not matrix filler. Exotic rarity, gacha rare tier.
	Each item should feel build-defining (distinct ability bundle or passive).
	familyPerk lines match ExoticPerkDefs runtime rules.
]]

local PassiveDefs = require(script.Parent.PassiveDefs)
local WeaponActiveDefs = require(script.Parent.WeaponActiveDefs)
local ArmorAbilityDefs = require(script.Parent.ArmorAbilityDefs)
local FocusAbilityDefs = require(script.Parent.FocusAbilityDefs)
local CombatKind = require(script.Parent.Parent.Combat.CombatKind)

local ExoticContent = {}

local BLADES = {
	{
		id = "b_exotic_hookfang",
		name = "Hookfang",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		rarity = "Exotic",
		familyPerk = "Backstab ×1.30 (Dagger) · Fan + Dash · Keen +5% crit",
		bladeDamageMult = 1.06,
		meshKey = "Dagger_Blade_Rare",
		abilities = { "fan_of_knives_weaponactive", "dash_weaponactive", "keen_weaponpassive" },
		desc = "Exotic dagger · fan of knives + dash · crit passive",
	},
	{
		id = "b_exotic_stormlash",
		name = "Stormlash",
		handleType = "1H_WandScepter",
		subFamily = "Wand",
		family = "Wand",
		rarity = "Exotic",
		familyPerk = "+18 Status Potency · Bolt + Bolt+ actives",
		bladeDamageMult = 1.05,
		meshKey = "Wand_Blade_Rare",
		abilities = { "bolt_weaponactive", "bolt_r_weaponactive", "potency_weaponpassive" },
		desc = "Exotic wand · common + rare bolt · potency",
	},
	{
		id = "b_exotic_bulwark_maul",
		name = "Bulwark Maul",
		handleType = "1H_AxeMace",
		subFamily = "Mace",
		family = "Mace",
		rarity = "Exotic",
		familyPerk = "Slam+ hit grants 2.5s Fortify",
		bladeDamageMult = 1.08,
		meshKey = "Mace_Blade_Rare",
		abilities = { "slam_r_weaponactive", "fortify_weaponactive", "direct_weaponpassive" },
		desc = "Exotic mace · ground slam + self fortify",
	},
	{
		id = "b_exotic_riptusk",
		name = "Riptusk",
		handleType = "1H_Sword",
		subFamily = "Sword",
		family = "Sword",
		rarity = "Exotic",
		familyPerk = "Strike+ · Keen · L3 LA signature status",
		bladeDamageMult = 1.07,
		meshKey = "Sword1H_Blade_Rare",
		abilities = { "strike_r_weaponactive", "keen_weaponpassive", "status_weaponpassive" },
		desc = "Exotic 1H sword · rare thrust · status passive",
	},
	{
		id = "b_exotic_needleswarm",
		name = "Needleswarm",
		handleType = "1H_Sword",
		subFamily = "Dagger",
		family = "Dagger",
		rarity = "Exotic",
		familyPerk = "15% LA status on L1/L2 · Fan + Dash · Direct +3%",
		bladeDamageMult = 1.04,
		meshKey = "Dagger_Blade_Rare",
		abilities = { "fan_of_knives_weaponactive", "dash_weaponactive", "direct_weaponpassive" },
		desc = "Exotic dagger · needle fan + dash · direct damage passive",
	},
	{
		id = "b_exotic_arcane_lance",
		name = "Arcane Lance",
		handleType = "1H_WandScepter",
		subFamily = "Wand",
		family = "Wand",
		rarity = "Exotic",
		familyPerk = "Pierce Bolt ignores Guard · Bolt+ · Potency +12",
		bladeDamageMult = 1.06,
		meshKey = "Wand_Blade_Rare",
		abilities = { "pierce_bolt_weaponactive", "bolt_r_weaponactive", "potency_weaponpassive" },
		desc = "Exotic wand · line pierce + rare bolt",
	},
	{
		id = "b_exotic_sanctum",
		name = "Sanctum Scepter",
		handleType = "1H_WandScepter",
		subFamily = "Scepter",
		family = "Scepter",
		rarity = "Exotic",
		familyPerk = "Renew grants self 2s Fortify · Fortify · Buff +10",
		bladeDamageMult = 1.03,
		meshKey = "Scepter_Blade_Rare",
		abilities = { "fortify_weaponactive", "renew_weaponactive", "buff_weaponpassive" },
		desc = "Exotic scepter · fortify + renew · buff potency",
	},
	{
		id = "b_exotic_skullcracker",
		name = "Skullcracker",
		handleType = "1H_AxeMace",
		subFamily = "Axe",
		family = "Axe",
		rarity = "Exotic",
		familyPerk = "Cone shatters Guard · Slam+ · Direct +3%",
		bladeDamageMult = 1.09,
		meshKey = "Axe1H_Blade_Rare",
		abilities = { "cone_weaponactive", "slam_r_weaponactive", "direct_weaponpassive" },
		desc = "Exotic 1H axe · cleave cone + slam finisher",
	},
	{
		id = "b_exotic_skyreaver",
		name = "Skyreaver",
		handleType = "2H_Sword",
		subFamily = "Sword",
		family = "Sword",
		rarity = "Exotic",
		familyPerk = "L3 +0.35s hyper armor · Cone+ · Burst · Keen",
		bladeDamageMult = 1.10,
		meshKey = "Sword2H_Blade_Rare",
		abilities = { "cone_r_weaponactive", "burst_weaponactive", "keen_weaponpassive" },
		desc = "Exotic 2H sword · rare cleave + burst strike",
	},
	{
		id = "b_exotic_null_staff",
		name = "Null Staff",
		handleType = "2H_Staff",
		subFamily = "Staff",
		family = "Staff",
		rarity = "Exotic",
		familyPerk = "Crit doubles active status apply · Bolt+ · Potency",
		bladeDamageMult = 1.05,
		meshKey = "Staff_Head_Rare",
		abilities = { "bolt_r_weaponactive", "potency_weaponpassive", "status_weaponpassive" },
		desc = "Exotic 2H staff · rare bolt · status stacking",
	},
	{
		id = "b_exotic_windstring",
		name = "Windstring",
		handleType = "2H_Bow",
		subFamily = "Bow",
		family = "Bow",
		rarity = "Exotic",
		familyPerk = "L3 LA pierces +1 target · Gale Volley · Keen · Direct",
		bladeDamageMult = 1.06,
		meshKey = "Bow_Limbs_Rare",
		abilities = { "gale_volley_weaponactive", "keen_weaponpassive", "direct_weaponpassive" },
		desc = "Exotic bow · gale volley · crit + direct",
	},
	{
		id = "b_exotic_iron_bolt",
		name = "Iron Bolt",
		handleType = "2H_Crossbow",
		subFamily = "Crossbow",
		family = "Crossbow",
		rarity = "Exotic",
		familyPerk = "Burst clears reload + Pierce CD · Pierce · Burst · Keen",
		bladeDamageMult = 1.08,
		meshKey = "Crossbow_Head_Rare",
		abilities = { "pierce_bolt_weaponactive", "burst_weaponactive", "keen_weaponpassive" },
		desc = "Exotic crossbow · pierce line + burst shot",
	},
}

local ARMOR = {
	{
		id = "a_exotic_mirrorplate",
		name = "Mirrorplate",
		kind = "Chest",
		slotHints = { "chest" },
		element = "Steel",
		defence = 88,
		resist = 24,
		rarity = "Exotic",
		familyPerk = "Thorn 20% reflect · Carapace on hit taken",
		abilities = { "thorn_reflect_armorpassive", "carapace_armorpassive" },
		desc = "Exotic chest · thorns + carapace on hit taken",
	},
	{
		id = "a_exotic_voidgrasp",
		name = "Void Grasp",
		kind = "Hands",
		slotHints = { "hands" },
		element = "Poison",
		defence = 5,
		resist = 22,
		rarity = "Exotic",
		familyPerk = "Element Touch · Stormgrasp +10 Potency",
		abilities = { "hand_touch_armoractive", "stormgrasp_armorpassive" },
		desc = "Exotic hands · poison touch + +10 Status Potency",
	},
	{
		id = "a_exotic_phantom_hood",
		name = "Phantom Hood",
		kind = "Head",
		slotHints = { "head" },
		element = "Wind",
		defence = 12,
		resist = 18,
		rarity = "Exotic",
		familyPerk = "Dodge +0.45s hyper armor · Quiet Step −8% dodge cost",
		abilities = { "phantom_step_armorpassive", "quiet_step_armorpassive" },
		desc = "Exotic head · crit phantom + quiet movement",
	},
	{
		id = "a_exotic_lifeweaver_crown",
		name = "Lifeweaver Crown",
		kind = "Head",
		slotHints = { "head" },
		element = "Water",
		defence = 8,
		resist = 22,
		rarity = "Exotic",
		familyPerk = "Lifewave overheal → 3s HoT · Grace +12 Buff Potency",
		abilities = { "lifewave_armoractive", "lifeweaver_grace_armorpassive" },
		desc = "Exotic head · wave heal + grace passive",
	},
	{
		id = "a_exotic_quakehold_boots",
		name = "Quakehold Boots",
		kind = "Feets",
		slotHints = { "feets" },
		element = "Rock",
		defence = 28,
		resist = 14,
		rarity = "Exotic",
		familyPerk = "Iron Charge roots 1.2s · Ward Step dodge Regen",
		abilities = { "charger_armoractive", "ward_step_armorpassive" },
		desc = "Exotic boots · charge slam + ward step",
	},
	{
		id = "a_exotic_warden_plate",
		name = "Warden Plate",
		kind = "Chest",
		slotHints = { "chest" },
		element = "Steel",
		defence = 92,
		resist = 20,
		rarity = "Exotic",
		familyPerk = "Bulwark Fortify · Fortify Aura to nearby allies",
		abilities = { "bulwark_wall_armoractive", "fortifyaura_armorpassive" },
		desc = "Exotic chest · wall + team fortify aura",
	},
}

local FOCUS = {
	{
		id = "o_exotic_shadow_kit",
		name = "Shadow Operative Kit",
		kind = "Focus",
		slotHints = { "off" },
		element = "Poison",
		roleHint = "Mobility",
		rarity = "Exotic",
		familyPerk = "Smoke within 4s → Grapple instant CD",
		abilities = { "smoke_bomb_focusactive", "grapple_hook_focusactive", "lucky_coin_focuspassive" },
		desc = "Exotic focus · smoke + grapple + crit charm",
	},
	{
		id = "o_exotic_war_totem",
		name = "War Totem Bundle",
		kind = "Focus",
		slotHints = { "off" },
		element = "Rock",
		roleHint = "Control",
		rarity = "Exotic",
		familyPerk = "Binding Totem · War Sigil +7% direct",
		abilities = { "binding_totem_focusactive", "war_sigil_focuspassive" },
		desc = "Exotic focus · binding totem + war sigil",
	},
}

local function normalizeWeaponAbilities(abilities: { any }?): { any }
	local out: { any } = {}
	if not abilities then
		return out
	end
	for _, ab in abilities do
		if type(ab) == "string" then
			if PassiveDefs.Get(ab) then
				table.insert(out, PassiveDefs.AbilitySlot(ab))
			else
				table.insert(out, WeaponActiveDefs.AbilitySlot(ab))
			end
		elseif ab.slotType == "Passive" then
			table.insert(out, PassiveDefs.HydrateAbilitySlot(ab))
		elseif ab.slotType == "Active" then
			table.insert(out, WeaponActiveDefs.HydrateAbilitySlot(ab))
		else
			table.insert(out, ab)
		end
	end
	return out
end

function ExoticContent.Build(): { [string]: any }
	local out: { [string]: any } = {}
	for _, b in BLADES do
		out[b.id] = {
			id = b.id,
			name = b.name,
			kind = "WeaponBlade",
			combatKind = CombatKind.FromHandleAndFamily(b.handleType, b.family),
			handleType = b.handleType,
			subFamily = b.subFamily,
			family = b.family,
			slotHints = {},
			element = nil,
			scaling = nil,
			familyPerk = b.familyPerk,
			bladeDamageMult = b.bladeDamageMult,
			meshKey = b.meshKey,
			abilities = normalizeWeaponAbilities(b.abilities),
			rarity = "Exotic",
			desc = b.desc or "Exotic blade",
		}
	end
	for _, p in ARMOR do
		out[p.id] = {
			id = p.id,
			name = p.name,
			kind = p.kind,
			slotHints = p.slotHints,
			element = p.element,
			defence = p.defence,
			resist = p.resist,
			rarity = "Exotic",
			familyPerk = p.familyPerk,
			abilities = ArmorAbilityDefs.NormalizeAbilities(p.abilities),
			desc = p.desc,
		}
	end
	for _, f in FOCUS do
		out[f.id] = {
			id = f.id,
			name = f.name,
			kind = f.kind,
			slotHints = f.slotHints,
			element = f.element,
			roleHint = f.roleHint,
			rarity = "Exotic",
			familyPerk = f.familyPerk,
			abilities = FocusAbilityDefs.NormalizeAbilities(f.abilities),
			desc = f.desc,
		}
	end
	return out
end

return ExoticContent
