--[[
	In-game glossary — English player-facing reference (GDD §13).
]]

local CombatConfig = require(script.Parent.CombatConfig)
local ElementData = require(script.Parent.ElementData)
local ReactionTable = require(script.Parent.ReactionTable)
local NameplateConfig = require(script.Parent.NameplateConfig)

export type GlossaryEntry = {
	id: string,
	title: string,
	body: string,
}

export type GlossarySection = {
	id: string,
	title: string,
	entries: { GlossaryEntry },
}

local GameGlossary = {}

local SECTIONS: { GlossarySection } = {
	{
		id = "stats",
		title = "Stats",
		entries = {
			{
				id = "str",
				title = "STR",
				body = "Scales direct damage (×0.012 per point). Main stat for Sword, Axe, Mace. Adds crit damage.",
			},
			{
				id = "dex",
				title = "DEX",
				body = "Attack speed tier scaling, crit chance, dodge stamina efficiency. Main stat for Dagger, Bow, Crossbow.",
			},
			{
				id = "vit",
				title = "VIT",
				body = "Max HP, stamina, Defence, and Resist. Core survivability stat.",
			},
			{
				id = "int",
				title = "INT",
				body = "Buff Potency (heals, HoT duration, Fortify/Frenzy). Main stat for Wand, Scepter, Staff.",
			},
			{
				id = "defence",
				title = "Defence & DR",
				body = `Flat Defence from armor. DR% = Defence × {CombatConfig.KDr}% (cap {CombatConfig.DrCapPvp}% in PvP). Applied to direct HP damage after perks.`,
			},
			{
				id = "resist",
				title = "Resist",
				body = "Reduces DoT and environmental damage. Separate from Defence / DR.",
			},
			{
				id = "as_tier",
				title = "Attack Speed (AS)",
				body = "Weapon AS tier (S–E) + DEX set swing cadence. Higher AS = faster light-attack recovery. L3 finishers are always slower than L1.",
			},
			{
				id = "potency",
				title = "Status / Buff Potency",
				body = "Status Potency lengthens status duration and DoT. Buff Potency scales heals, HoT, and self-buff duration/strength.",
			},
		},
	},
	{
		id = "combat",
		title = "Combat",
		entries = {
			{
				id = "la_combo",
				title = "Light Attack Combo (L1→L2→L3)",
				body = `All weapons share a 3-step chain. Combo window: {CombatConfig.ComboWindowSec}s after each hit. Whiff does not advance. L2 ×{CombatConfig.ComboL2} · L3 ×{CombatConfig.ComboL3} damage.`,
			},
			{
				id = "l3_perks",
				title = "L3 Family Finishers",
				body = "Each weapon family adds an L3 damage perk (e.g. Sword Measured Strike, Staff Empowered Bolt). See weapon tooltip for exact multipliers.",
			},
			{
				id = "dodge",
				title = "Dodge",
				body = `Costs {CombatConfig.DodgeCost} stamina. {CombatConfig.DodgeIFrameSec}s invulnerability. Brief recovery after.`,
			},
			{
				id = "guard",
				title = "Guard (Shield)",
				body = "Hold RMB with shield equipped. Chip damage + stamina drain. Stamina 0 = guard break (Stun).",
			},
			{
				id = "parry",
				title = "Parry (No Shield)",
				body = `Perfect window {CombatConfig.ParryPerfectWindowSec}s: 0 damage, attacker Stun {CombatConfig.ParryStunSec}s. Fail costs stamina.`,
			},
			{
				id = "fortify",
				title = "Fortify",
				body = "Self buff: reduces direct damage taken (typically −10%). Scales with Buff Potency duration.",
			},
			{
				id = "elements",
				title = "Elements & Matchups",
				body = "Weapon gem sets attack element. Chest armor sets defend element. Strong ×1.15 / Weak ×0.85 direct damage multiplier.",
			},
		},
	},
	{
		id = "synergy",
		title = "Loadout Synergy",
		entries = {
			{
				id = "pure",
				title = "Pure (×3 same element)",
				body = "Main + Off + Chest same non-Neutral element. Every main-hand LA hit applies signature status. Element-specific bonuses (e.g. Water splash).",
			},
			{
				id = "harmony",
				title = "Harmony",
				body = "Three different elements (×1 each). +15 Status Potency. 2H main weapons cannot reach Harmony.",
			},
			{
				id = "duality",
				title = "Duality",
				body = "Exactly two elements across loadout. +5% Defence and +5% Resist.",
			},
			{
				id = "unbound",
				title = "Unbound (Neutral ×3)",
				body = "+5% direct damage, +10% Defence, +12% Resist. Neutral chest with matching neutral pieces.",
			},
			{
				id = "reactions",
				title = "Status Reactions",
				body = "Two compatible debuffs on the same target react instantly. No priority table — FIFO picks the pair. See Reaction Matrix below.",
			},
		},
	},
	{
		id = "chemistry",
		title = "Status & Reactions",
		entries = {
			{
				id = "element_status",
				title = "Element Signatures (gem / Pure)",
				body = "", -- filled by FormatStatusReference
			},
			{
				id = "reaction_matrix",
				title = "Reaction Matrix",
				body = "", -- filled by FormatReactionMatrix
			},
			{
				id = "reaction_rules",
				title = "Reaction Rules",
				body = "Inputs are consumed when a reaction fires. Burst reactions deal instant damage from remaining DoT. Chain reactions spread the chained status to nearby targets. Hybrid = burst + new status.",
			},
		},
	},
	{
		id = "gear",
		title = "Gear & Items",
		entries = {
			{
				id = "modular",
				title = "Modular Weapons",
				body = "Frame + Handle + Blade + Pommel. Socket a Gem for element. Wrong handle type blocks blade install.",
			},
			{
				id = "gem",
				title = "Gems",
				body = "Socket into handle. Replacing a gem destroys the old one unless you use premium Safe unsocket.",
			},
			{
				id = "blade_upgrade",
				title = "Blade Upgrade",
				body = "Spend premium to upgrade blades +level (max 5). Each level adds +3% weapon damage on that blade.",
			},
			{
				id = "rarity",
				title = "Rarity",
				body = "Common: 1 active. Rare 1H: 1 active + 1 passive. Rare 2H: up to 3 abilities. Boss blades are exclusive drops.",
			},
			{
				id = "scepter",
				title = "Scepter vs Wand",
				body = "Wand: ranged bolt, Status Potency. Scepter: cone LA, Buff Potency, support actives (heal allies, HoT, AoE heals).",
			},
			{
				id = "offhand",
				title = "Off-hand",
				body = "Shield (guard), Quiver/Knot (bow/2H tag), or 1H weapon (dual wield: off-hand LA 65% damage, no status proc).",
			},
		},
	},
}

function GameGlossary.Sections(): { GlossarySection }
	return SECTIONS
end

function GameGlossary.FindEntry(entryId: string): (GlossaryEntry?, string?)
	for _, section in SECTIONS do
		for _, entry in section.entries do
			if entry.id == entryId then
				return entry, section.title
			end
		end
	end
	return nil, nil
end

local function describeReaction(r: any): string
	if r.kind == "Burst" then
		local factor = r.burstFactor or 1
		local from = r.burstFrom or "DoT"
		return `Burst — {factor}× remaining {from} damage (instant)`
	elseif r.kind == "Chain" then
		return `Chain — spreads {r.chain or "?"} to nearby targets`
	elseif r.kind == "Hybrid" then
		local burst = if r.burstFrom then ` + {r.burstFactor or 1}× {r.burstFrom} burst` else ""
		local out = r.outputStatus or "?"
		local dur = r.outputDuration or "?"
		return `Hybrid — applies {out} {dur}s{burst}`
	else
		local out = r.outputStatus or r.id
		local dur = if r.outputDurationFrom == "maxInputs"
			then "max(input durations)"
			elseif r.outputDurationFrom == "minInputs" then "min(input durations)"
			else tostring(r.outputDuration or "?")
		local dps = if r.outputDpsFactor then ` · DPS ×{r.outputDpsFactor}` else ""
		local params = ""
		if r.outputParams and r.outputParams.slowPct then
			params = ` · slow {r.outputParams.slowPct}%`
		end
		return `Status — {out} {dur}s{dps}{params}`
	end
end

--- Element signature statuses + common reaction outputs
function GameGlossary.FormatStatusReference(): string
	local parts: { string } = {}
	table.insert(parts, "Applied by gem element on weapon hits (L3 guaranteed, or 15% proc):")
	for _, el in ElementData.List do
		local sig = ElementData.Signature[el]
		if sig then
			if sig.id then
				table.insert(parts, `• {el}: {sig.label} — {sig.short}`)
			else
				table.insert(parts, `• {el}: no signature status`)
			end
		end
	end
	table.insert(parts, "")
	table.insert(parts, "Reaction-only / buff statuses:")
	local seen: { [string]: boolean } = {}
	for _, el in ElementData.List do
		local sig = ElementData.Signature[el]
		if sig and sig.id then
			seen[sig.id] = true
		end
	end
	for statusId, vis in NameplateConfig.Status do
		if not seen[statusId] then
			local tag = if vis.debuff then "debuff" else "buff"
			table.insert(parts, `• {vis.label} ({tag})`)
		end
	end
	return table.concat(parts, "\n")
end

function GameGlossary.FormatReactionMatrix(): string
	local parts: { string } = {}
	table.insert(parts, "Pair → Reaction → Effect")
	for _, r in ReactionTable.List do
		table.insert(parts, `• {r.a} + {r.b} → {r.id}`)
		table.insert(parts, `  {describeReaction(r)}`)
	end
	table.insert(parts, "")
	table.insert(parts, "Order: first matching pair in FIFO queue wins when two statuses land together.")
	return table.concat(parts, "\n")
end

--- Plain text for scrolling glossary panel
function GameGlossary.FormatAll(): string
	local statusRef = GameGlossary.FormatStatusReference()
	local reactionMat = GameGlossary.FormatReactionMatrix()
	local parts: { string } = {}
	for _, section in SECTIONS do
		table.insert(parts, `▸ {section.title}`)
		for _, entry in section.entries do
			table.insert(parts, "")
			table.insert(parts, entry.title)
			local body = entry.body
			if entry.id == "element_status" then
				body = statusRef
			elseif entry.id == "reaction_matrix" then
				body = reactionMat
			end
			table.insert(parts, body)
		end
		table.insert(parts, "")
	end
	return table.concat(parts, "\n")
end

return GameGlossary
