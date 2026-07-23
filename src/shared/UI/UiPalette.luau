--[[
	Shared UI color palette — ScreenGui, BillboardGui, tooltips, nameplates.
	Client UiTheme builds components on top of this.
]]

local UiPalette = {}

UiPalette.Base = {
	Bg = Color3.fromRGB(18, 20, 24),
	BgElevated = Color3.fromRGB(22, 24, 28),
	BgOverlay = Color3.fromRGB(0, 0, 0),
	Panel = Color3.fromRGB(28, 30, 36),
	Slot = Color3.fromRGB(42, 44, 52),
	SlotHover = Color3.fromRGB(50, 54, 62),
	SlotSelected = Color3.fromRGB(52, 72, 96),
	SlotEquipped = Color3.fromRGB(48, 66, 54),
	Button = Color3.fromRGB(38, 42, 52),
	ButtonMuted = Color3.fromRGB(70, 75, 90),
	ButtonDisabled = Color3.fromRGB(55, 55, 62),
	Stroke = Color3.fromRGB(70, 74, 84),
	StrokeSoft = Color3.fromRGB(70, 80, 100),
	StrokeLight = Color3.fromRGB(90, 94, 104),
	StrokeSlot = Color3.fromRGB(100, 104, 114),
	Text = Color3.fromRGB(235, 236, 240),
	TextBright = Color3.fromRGB(240, 244, 250),
	TextMuted = Color3.fromRGB(140, 146, 158),
	TextDim = Color3.fromRGB(165, 172, 188),
	Accent = Color3.fromRGB(90, 150, 220),
	AccentMuted = Color3.fromRGB(70, 90, 130),
	AccentSoft = Color3.fromRGB(90, 130, 190),
	Success = Color3.fromRGB(70, 150, 95),
	SuccessBright = Color3.fromRGB(120, 210, 150),
	SuccessDark = Color3.fromRGB(50, 110, 70),
	Danger = Color3.fromRGB(150, 60, 60),
	DangerBright = Color3.fromRGB(220, 80, 80),
	DangerDark = Color3.fromRGB(90, 55, 55),
	Warning = Color3.fromRGB(200, 150, 70),
	WarningBright = Color3.fromRGB(255, 200, 120),
	WarningDark = Color3.fromRGB(230, 180, 90),
	Boss = Color3.fromRGB(200, 140, 255),
	Premium = Color3.fromRGB(90, 75, 140),
	BarTrack = Color3.fromRGB(40, 42, 50),
	BarHp = Color3.fromRGB(180, 50, 60),
	BarXp = Color3.fromRGB(90, 150, 220),
	HudTrack = Color3.fromRGB(30, 32, 38),
	Stamina = Color3.fromRGB(90, 180, 120),
	StaminaGuard = Color3.fromRGB(100, 140, 220),
	StaminaParry = Color3.fromRGB(200, 170, 80),
	AimOn = Color3.fromRGB(120, 220, 140),
	AimOff = Color3.fromRGB(160, 170, 180),
	Dev = Color3.fromRGB(120, 220, 160),
	Viewport = Color3.fromRGB(36, 38, 44),
}

-- World-space nameplates (MMORPG-style overhead UI)
UiPalette.Nameplate = {
	ChromeBg = Color3.fromRGB(18, 20, 24),
	ChromeTransparency = 0.28,
	TextOnBar = Color3.fromRGB(240, 244, 250),
	TextMuted = Color3.fromRGB(210, 215, 225),
	StatusFallback = Color3.fromRGB(180, 180, 190),
	BuffBorder = Color3.fromRGB(70, 150, 95),
	DebuffBorder = Color3.fromRGB(220, 80, 80),
	HpHigh = Color3.fromRGB(90, 150, 220),
	HpMid = Color3.fromRGB(230, 180, 90),
	HpLow = Color3.fromRGB(220, 60, 60),
	PvpHp = Color3.fromRGB(255, 220, 60),
	BossHp = Color3.fromRGB(200, 50, 60),
	BossAddHp = Color3.fromRGB(180, 60, 120),
	TrainingHp = Color3.fromRGB(255, 220, 120),
	PlayerHp = Color3.fromRGB(100, 190, 140),
	PlayerName = Color3.fromRGB(220, 230, 245),
	PartyMemberName = Color3.fromRGB(150, 220, 255),
	PartyLeaderName = Color3.fromRGB(255, 215, 120),
	PartyMemberHp = Color3.fromRGB(70, 185, 210),
	PvpName = Color3.fromRGB(255, 245, 220),
	BossName = Color3.fromRGB(255, 210, 210),
	BossAddName = Color3.fromRGB(240, 200, 220),
	TrainingName = Color3.fromRGB(240, 240, 245),
}

function UiPalette.HpTierColor(pct: number, fullColor: Color3): Color3
	local N = UiPalette.Nameplate
	if pct <= 25 then
		return N.HpLow
	end
	if pct <= 50 then
		return N.HpMid
	end
	return fullColor
end

return UiPalette
