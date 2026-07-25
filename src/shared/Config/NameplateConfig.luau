--[[
	Combat nameplate layout + status icon colors (shared palette).
]]

local UiPalette = require(script.Parent.Parent.UI.UiPalette)
local C = UiPalette.Base
local N = UiPalette.Nameplate

export type NameplateKind = "Pvp" | "Boss" | "BossAdd" | "Training" | "Player"

export type StatusVisual = {
	label: string,
	color: Color3,
	debuff: boolean,
	abbrev: string,
	icon: string,
	art: string?, -- vector icon key (BleedDrop, IgniteFlame, …)
}

local NameplateConfig = {
	Styles = {
		Player = {
			width = 190,
			statusRowH = 34,
			nameH = 18,
			barH = 14,
			studsOffset = Vector3.new(0, 3.4, 0),
			hpFill = N.PlayerHp,
			hpBg = C.HudTrack,
			nameColor = N.PlayerName,
			showPctInBar = false,
			showAbsHp = false,
			showChrome = true,
			maxDistance = 80,
		},
		Pvp = {
			width = 200,
			statusRowH = 36,
			nameH = 18,
			barH = 18,
			studsOffset = Vector3.new(0, 3.8, 0),
			hpFill = N.PvpHp,
			hpBg = C.HudTrack,
			nameColor = N.PvpName,
			showPctInBar = true,
			showAbsHp = false,
			showChrome = true,
			maxDistance = 120,
		},
		Boss = {
			width = 260,
			statusRowH = 40,
			nameH = 22,
			barH = 22,
			studsOffset = Vector3.new(0, 18, 0),
			hpFill = N.BossHp,
			hpBg = C.BarTrack,
			nameColor = N.BossName,
			showPctInBar = true,
			showAbsHp = true,
			showChrome = true,
			maxDistance = 400,
		},
		BossAdd = {
			width = 180,
			statusRowH = 34,
			nameH = 16,
			barH = 16,
			studsOffset = Vector3.new(0, 4.5, 0),
			hpFill = N.BossAddHp,
			hpBg = C.HudTrack,
			nameColor = N.BossAddName,
			showPctInBar = true,
			showAbsHp = false,
			showChrome = true,
			maxDistance = 120,
		},
		Training = {
			width = 200,
			statusRowH = 36,
			nameH = 18,
			barH = 18,
			studsOffset = Vector3.new(0, 4.5, 0),
			hpFill = N.TrainingHp,
			hpBg = C.HudTrack,
			nameColor = N.TrainingName,
			showPctInBar = true,
			showAbsHp = true,
			showChrome = true,
			maxDistance = 120,
		},
	},
	MaxStatusSlots = 8,
	Status = {
		Wet = {
			label = "Wet",
			color = Color3.fromRGB(80, 160, 255),
			debuff = true,
			abbrev = "Wt",
			icon = "≈",
			art = "Wet",
		},
		Ignite = {
			label = "Ignite",
			color = Color3.fromRGB(255, 120, 50),
			debuff = true,
			abbrev = "Ig",
			icon = "✦",
			art = "Ignite",
		},
		Shock = { label = "Shock", color = Color3.fromRGB(180, 220, 255), debuff = true, abbrev = "Sh", icon = "⚡", art = "Shock" },
		Windy = { label = "Windy", color = Color3.fromRGB(140, 255, 180), debuff = true, abbrev = "Wi", icon = "»", art = "Windy" },
		Poisoned = { label = "Poisoned", color = Color3.fromRGB(120, 220, 80), debuff = true, abbrev = "Po", icon = "☠", art = "Poisoned" },
		Slow = { label = "Slow", color = Color3.fromRGB(160, 140, 200), debuff = true, abbrev = "Sl", icon = "⏷", art = "Slow" },
		Bleed = {
			label = "Bleed",
			color = Color3.fromRGB(200, 60, 60),
			debuff = true,
			abbrev = "Bl",
			icon = "‡",
			art = "Bleed",
		},
		Chilled = { label = "Chilled", color = Color3.fromRGB(120, 200, 255), debuff = true, abbrev = "Ch", icon = "❄", art = "Chilled" },
		Stun = { label = "Stun", color = Color3.fromRGB(255, 200, 80), debuff = true, abbrev = "St", icon = "★", art = "Stun" },
		Hitstun = { label = "Hitstun", color = Color3.fromRGB(255, 170, 120), debuff = true, abbrev = "Hs", icon = "◉", art = "Hitstun" },
		HyperArmor = { label = "Hyper Armor", color = Color3.fromRGB(200, 220, 255), debuff = false, abbrev = "HA", icon = "⛨", art = "HyperArmor" },
		CcImmunity = { label = "CC Immune", color = Color3.fromRGB(180, 255, 220), debuff = false, abbrev = "CI", icon = "◎", art = "CcImmunity" },
		JuggleBreak = { label = "Juggle Break", color = Color3.fromRGB(255, 240, 160), debuff = false, abbrev = "JB", icon = "↯", art = "JuggleBreak" },
		Grounded = { label = "Grounded", color = Color3.fromRGB(150, 120, 90), debuff = true, abbrev = "Gr", icon = "▼", art = "Grounded" },
		Root = { label = "Root", color = Color3.fromRGB(120, 200, 140), debuff = true, abbrev = "Ro", icon = "╬", art = "Root" },
		WildFire = { label = "Wild Fire", color = Color3.fromRGB(255, 90, 40), debuff = true, abbrev = "WF", icon = "✸", art = "WildFire" },
		Blight = { label = "Blight", color = Color3.fromRGB(100, 180, 60), debuff = true, abbrev = "Bi", icon = "☣", art = "Blight" },
		CausticBurn = { label = "Caustic Burn", color = Color3.fromRGB(180, 255, 60), debuff = true, abbrev = "CB", icon = "✸", art = "CausticBurn" },
		Cauterize = { label = "Cauterize", color = Color3.fromRGB(255, 90, 40), debuff = true, abbrev = "Ca", icon = "⊘", art = "Cauterize" },
		Thaw = { label = "Thaw", color = Color3.fromRGB(255, 220, 160), debuff = true, abbrev = "Th", icon = "↗", art = "Thaw" },
		Fortify = { label = "Fortify", color = Color3.fromRGB(120, 180, 255), debuff = false, abbrev = "Fo", icon = "▣", art = "Fortify" },
		Regen = { label = "Regen", color = Color3.fromRGB(100, 220, 140), debuff = false, abbrev = "Rg", icon = "✚", art = "Regen" },
		Frenzy = { label = "Frenzy", color = Color3.fromRGB(255, 100, 100), debuff = false, abbrev = "Fr", icon = "!", art = "Frenzy" },
		HelmPulse = { label = "Helm Pulse", color = Color3.fromRGB(200, 180, 255), debuff = false, abbrev = "HP", icon = "◌", art = "HelmPulse" },
		Guard = { label = "Guard", color = Color3.fromRGB(180, 190, 210), debuff = false, abbrev = "Gd", icon = "▢", art = "Guard" },
		Parry = { label = "Parry", color = Color3.fromRGB(220, 220, 255), debuff = false, abbrev = "Pr", icon = "◈", art = "Parry" },
		Dodge = { label = "Dodge", color = Color3.fromRGB(200, 200, 220), debuff = false, abbrev = "Do", icon = "↻", art = "Dodge" },
	} :: { [string]: StatusVisual },
}

function NameplateConfig.StatusVisual(statusId: string): StatusVisual
	local entry = NameplateConfig.Status[statusId]
	if entry then
		return entry
	end
	local abbrev = if #statusId >= 2 then string.sub(statusId, 1, 2) else statusId
	return {
		label = statusId,
		color = N.StatusFallback,
		debuff = true,
		abbrev = abbrev,
		icon = "●",
		art = nil,
	}
end

function NameplateConfig.StyleForKind(kind: string)
	return (NameplateConfig.Styles :: any)[kind] or NameplateConfig.Styles.Player
end

return NameplateConfig
