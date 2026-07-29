--[[
	Focus off-hand items — each is a separate inventory item (mix & match).
]]

local FocusAbilityDefs = require(script.Parent.FocusAbilityDefs)

local FocusDefs = {}

local PIECES = {
	{
		id = "o_focus_fishnet",
		name = "Fish Net",
		kind = "Focus",
		slotHints = { "off" },
		element = "Water",
		roleHint = "Control",
		abilities = { "fish_net_focusactive" },
		desc = "Focus · throw net roots enemies in area",
	},
	{
		id = "o_focus_grapple",
		name = "Grappling Hook",
		kind = "Focus",
		slotHints = { "off" },
		element = "Steel",
		roleHint = "Mobility",
		abilities = { "grapple_hook_focusactive" },
		desc = "Focus · pull enemy or zip to anchor",
	},
	{
		id = "o_focus_smoke",
		name = "Smoke Bomb",
		kind = "Focus",
		slotHints = { "off" },
		element = "Poison",
		roleHint = "Control",
		abilities = { "smoke_bomb_focusactive" },
		desc = "Focus · lob smoke · heavy Slow in area",
	},
	{
		id = "o_focus_idol",
		name = "Healing Idol",
		kind = "Focus",
		slotHints = { "off" },
		element = "Water",
		roleHint = "Support",
		abilities = { "healing_idol_focusactive" },
		desc = "Focus · place idol · ally heal + Regen",
	},
	{
		id = "o_focus_vampire",
		name = "Vampire Teeth",
		kind = "Focus",
		slotHints = { "off" },
		element = "Poison",
		roleHint = "Sustain",
		abilities = { "lifesteal_passive" },
		desc = "Focus passive · 5% lifesteal on direct damage",
	},
	{
		id = "o_focus_spiritcharm",
		name = "Spirit Charm",
		kind = "Focus",
		slotHints = { "off" },
		element = "Lightning",
		roleHint = "INT",
		abilities = { "spirit_charm_focuspassive" },
		desc = "Focus passive · +14 Status Potency",
	},
	{
		id = "o_focus_warsigil",
		name = "War Sigil",
		kind = "Focus",
		slotHints = { "off" },
		element = "Fire",
		roleHint = "STR",
		abilities = { "war_sigil_focuspassive" },
		desc = "Focus passive · +7% direct damage",
	},
	{
		id = "o_focus_luckycoin",
		name = "Lucky Coin",
		kind = "Focus",
		slotHints = { "off" },
		element = "Wind",
		roleHint = "DEX",
		abilities = { "lucky_coin_focuspassive" },
		desc = "Focus passive · +8% crit chance",
	},
	{
		id = "o_focus_ironheart",
		name = "Iron Heart",
		kind = "Focus",
		slotHints = { "off" },
		element = "Water",
		roleHint = "Support",
		abilities = { "iron_heart_focuspassive" },
		desc = "Focus passive · +18 Buff Potency",
	},
	{
		id = "o_focus_firejar",
		name = "Fire Jar",
		kind = "Focus",
		slotHints = { "off" },
		element = "Fire",
		roleHint = "INT",
		abilities = { "fire_jar_focusactive" },
		desc = "Focus · lob Ignite jar",
	},
	{
		id = "o_focus_flashorb",
		name = "Flash Orb",
		kind = "Focus",
		slotHints = { "off" },
		element = "Lightning",
		roleHint = "INT",
		abilities = { "flash_orb_focusactive" },
		desc = "Focus · ranged Shock orb",
	},
	{
		id = "o_focus_bindingtotem",
		name = "Binding Totem",
		kind = "Focus",
		slotHints = { "off" },
		element = "Rock",
		roleHint = "Control",
		abilities = { "binding_totem_focusactive" },
		desc = "Focus · ground Root totem",
	},
}

function FocusDefs.Build(): { [string]: any }
	local out = {}
	for _, p in PIECES do
		out[p.id] = {
			id = p.id,
			name = p.name,
			kind = p.kind,
			slotHints = p.slotHints,
			element = p.element,
			roleHint = p.roleHint,
			rarity = "Rare",
			abilities = FocusAbilityDefs.NormalizeAbilities(p.abilities),
			desc = p.desc,
		}
	end
	return out
end

return FocusDefs
