--[[
	Rich item inspection text for Gear UI (English).
]]

local ItemDefs = require(script.Parent.Parent.Config.ItemDefs)
local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local WeaponFamilyConfig = require(script.Parent.Parent.Config.WeaponFamilyConfig)
local WeaponActiveDefs = require(script.Parent.Parent.Config.WeaponActiveDefs)
local PassiveDefs = require(script.Parent.Parent.Config.PassiveDefs)
local ArmorAbilityDefs = require(script.Parent.Parent.Config.ArmorAbilityDefs)
local FocusAbilityDefs = require(script.Parent.Parent.Config.FocusAbilityDefs)
local UpgradeDefs = require(script.Parent.Parent.Config.UpgradeDefs)

local ItemTooltip = {}

export type TooltipContext = {
	defId: string?,
	def: any?,
	itemData: any?,
	resolvedMain: any?,
	isEquippedMain: boolean?,
}

local function line(lines: { string }, text: string?)
	if text and text ~= "" then
		table.insert(lines, text)
	end
end

local function header(lines: { string }, title: string)
	table.insert(lines, title)
end

local function section(lines: { string }, title: string)
	table.insert(lines, "")
	table.insert(lines, `— {title} —`)
end

local function abilityLines(lines: { string }, abilities: { any }?)
	if not abilities then
		return
	end
	for _, ab in abilities do
		local id: string? = nil
		local name: string? = nil
		local desc: string? = nil
		local cd: number? = nil
		local slotType = "Active"
		if typeof(ab) == "string" then
			id = ab
		elseif typeof(ab) == "table" then
			id = ab.id
			name = ab.name
			desc = ab.desc
			cd = ab.cooldownSec
			slotType = ab.slotType or "Active"
		else
			continue
		end
		if typeof(id) == "string" then
			local def = WeaponActiveDefs.Get(id)
				or PassiveDefs.Get(id)
				or ArmorAbilityDefs.Get(id)
				or FocusAbilityDefs.Get(id)
			if def then
				name = name or def.name or id
				desc = desc or def.desc
				if def.kind == "Passive" then
					slotType = "Passive"
				elseif def.kind == "Active" then
					slotType = "Active"
				end
			end
		end
		local cdText = if typeof(cd) == "number" then ` · {cd}s CD` else ""
		line(lines, `• [{slotType}] {name or id}{cdText}`)
		if desc then
			line(lines, `  {desc}`)
		end
	end
end

local function weaponBladeLines(lines: { string }, def: any, upgradeLevel: number)
	section(lines, "Weapon Blade")
	if def.family then
		-- Scaling lives on the handle, not the blade part.
		line(lines, `Family: {def.family} · Handle type: {def.handleType or "?"}`)
	end
	if def.bladeDamageMult then
		line(lines, `Blade damage mult: ×{string.format("%.2f", def.bladeDamageMult or 1)}`)
	end
	if def.familyPerk then
		line(lines, `Family perk: {def.familyPerk}`)
	end
	for _, perkLine in WeaponFamilyConfig.LaPerkLines(def) do
		line(lines, perkLine)
	end
	line(lines, `Combo recovery scales with AS · L3 slowest (×{CombatConfig.ComboRecoveryStepMult[3]} recovery)`)
	abilityLines(lines, def.abilities)
	if upgradeLevel > 0 then
		local pct = math.floor(UpgradeDefs.DamagePctPerLevel * 100 + 0.5)
		line(lines, `Upgrade +{upgradeLevel}: +{upgradeLevel * pct}% blade damage`)
	end
end

local function resolvedFrameLines(lines: { string }, rm: any)
	section(lines, "Assembled Weapon")
	line(lines, `DMG {rm.baseDamage} · {rm.element} · Scale {rm.scaling or "STR"} · AS ×{string.format("%.2f", rm.attackSpeedMult or 1)}`)
	if rm.family then
		line(lines, `Family: {rm.family} · Kind: {rm.kind or "?"}`)
	end
	line(lines, `Handle: {rm.handleDefId or "?"} · Blade: {rm.bladeDefId or "?"}`)
	line(lines, `Pommel: {rm.pommelDefId or "?"} · Gem: {rm.gemDefId or "Neutral"}`)
	local pseudo = {
		family = rm.family,
		kind = rm.kind,
		asTier = rm.asTier,
	}
	for _, perkLine in WeaponFamilyConfig.LaPerkLines(pseudo) do
		line(lines, perkLine)
	end
	abilityLines(lines, rm.abilities)
end

local function armorLines(lines: { string }, def: any)
	section(lines, "Armor")
	if def.defence then
		line(lines, `Defence: {def.defence} · Resist: {def.resist or 0}`)
	end
	if def.element then
		line(lines, `Chest element: {def.element}`)
	end
	if def.roleHint then
		line(lines, `Role lean: {def.roleHint} (optional — mix slots freely)`)
	end
	abilityLines(lines, def.abilities)
end

local function handleLines(lines: { string }, def: any)
	section(lines, "Handle")
	line(lines, def.desc or def.handleType or "")
	line(lines, `Scaling: {def.scaling or "?"} · AS tier {def.asTier or "?"}`)
	line(lines, "Accepts matching blade family · 1 gem socket")
end

local function pommelLines(lines: { string }, def: any)
	section(lines, "Pommel / String")
	line(lines, def.desc or "")
	if def.damageMult or def.attackSpeedMult then
		line(lines, `DMG ×{string.format("%.2f", def.damageMult or 1)} · AS ×{string.format("%.2f", def.attackSpeedMult or 1)}`)
	end
end

function ItemTooltip.Build(ctx: TooltipContext): string
	local lines: { string } = {}
	local def = ctx.def
	local defId = ctx.defId or (def and def.id)
	if not def and defId then
		def = ItemDefs.Get(defId)
	end
	if not def then
		return "Unknown item."
	end

	local title = def.name or defId or "?"
	if defId == "weapon_frame" and ctx.resolvedMain and ctx.resolvedMain.complete then
		title = ctx.resolvedMain.displayName or title
	end

	header(lines, title)
	local kind = def.kind or ""
	local bits = { kind }
	if def.rarity then
		table.insert(bits, 1, def.rarity)
	end
	if def.element then
		table.insert(bits, `Element: {def.element}`)
	end
	line(lines, table.concat(bits, " · "))

	local upgradeLevel = if ctx.itemData and typeof(ctx.itemData.upgradeLevel) == "number"
		then ctx.itemData.upgradeLevel
		else 0

	if defId == "weapon_frame" and ctx.resolvedMain then
		resolvedFrameLines(lines, ctx.resolvedMain)
	elseif kind == "WeaponHandle" or kind == "Handle" then
		handleLines(lines, def)
	elseif kind == "WeaponBlade" then
		weaponBladeLines(lines, def, upgradeLevel)
	elseif kind == "Armor" or string.sub(kind, 1, 6) == "Armor" then
		armorLines(lines, def)
	elseif kind == "Pommel" or kind == "String" or kind == "WeaponPommel" then
		pommelLines(lines, def)
	elseif kind == "ElementGem" or kind == "Gem" then
		section(lines, "Gem")
		line(lines, def.desc or `Element: {def.element}`)
		line(lines, "Socket into weapon handle. Replaces existing gem.")
	elseif kind == "Head" or kind == "Chest" or kind == "Hands" or kind == "Feets" then
		armorLines(lines, def)
	elseif kind == "Focus" then
		section(lines, "Focus")
		if def.roleHint then
			line(lines, `Role lean: {def.roleHint} (optional)`)
		end
		abilityLines(lines, def.abilities)
	elseif kind == "Shield" then
		section(lines, "Shield")
		if def.defence then
			line(lines, `Defence: {def.defence}`)
		end
		abilityLines(lines, def.abilities)
	elseif kind == "LootBox" then
		section(lines, "Lootbox")
		line(lines, `Pool: {def.lootBoxPoolId or "?"}`)
		if def.bossId then
			line(lines, `Boss: {def.bossId}`)
		end
		line(lines, if def.tradeable ~= false then "Tradeable · Open from Gear or trade with players." else "Bind-on-pickup")
	elseif def.defence or def.resist then
		armorLines(lines, def)
	end

	if def.desc then
		section(lines, "Notes")
		line(lines, def.desc)
	end

	if ctx.itemData and ctx.itemData.installedIn then
		line(lines, "")
		line(lines, "[Installed in frame]")
	elseif ctx.isEquippedMain then
		line(lines, "")
		line(lines, "[Equipped — Main]")
	end

	return table.concat(lines, "\n")
end

return ItemTooltip
