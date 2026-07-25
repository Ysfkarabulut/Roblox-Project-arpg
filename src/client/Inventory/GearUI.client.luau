--[[
	3-panel gear UI: Stats | Loadout | Inventory
	I toggle · Esc close
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)

local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COL_BG = C.Bg
local COL_PANEL = C.Panel
local COL_SLOT = C.Slot
local COL_SLOT_EQ = C.SlotEquipped
local COL_SLOT_SEL = C.SlotSelected
local COL_STROKE = C.Stroke
local COL_TEXT = C.Text
local COL_MUTED = C.TextMuted
local COL_DANGER = C.DangerBright

local function corner(parent: Instance, r: number?)
	UiTheme.Corner(parent, r)
end

local function stroke(parent: Instance, color: Color3?, t: number?)
	UiTheme.Stroke(parent, { color = color, thickness = t })
end

local gui = UiTheme.ScreenGui({
	name = "GearUI",
	displayOrder = UiTheme.DisplayOrder.Gear,
	zIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
gui.Parent = playerGui

local bootStatus = Instance.new("TextLabel")
bootStatus.Name = "BootStatus"
bootStatus.Size = UDim2.fromOffset(420, 28)
bootStatus.Position = UDim2.new(0.5, -210, 1, -200)
bootStatus.BackgroundTransparency = 1
bootStatus.Font = Enum.Font.Gotham
bootStatus.TextSize = 12
bootStatus.TextColor3 = COL_MUTED
bootStatus.Text = "Loading inventory…"
bootStatus.ZIndex = 50
bootStatus.Parent = gui

local function failBoot(msg: string)
	bootStatus.Text = msg
	bootStatus.TextColor3 = COL_DANGER
	warn("[GearUI]", msg)
end

local okDefs, ItemDefsOrErr = pcall(function()
	return require(ReplicatedStorage.Shared.Config.ItemDefs)
end)
if not okDefs then
	failBoot("ItemDefs require failed — check Output")
	return
end
local ItemDefs = ItemDefsOrErr

local okSlots, LoadoutSlots = pcall(function()
	return require(ReplicatedStorage.Shared.Config.LoadoutSlots)
end)
local okHotbar, HotbarConfig = pcall(function()
	return require(ReplicatedStorage.Shared.Config.HotbarConfig)
end)
local okCombat, CombatConfig = pcall(function()
	return require(ReplicatedStorage.Shared.Config.CombatConfig)
end)
local okUpgrade, UpgradeDefs = pcall(function()
	return require(ReplicatedStorage.Shared.Config.UpgradeDefs)
end)
local okTooltip, ItemTooltip = pcall(function()
	return require(ReplicatedStorage.Shared.UI.ItemTooltip)
end)
local okResolver, WeaponResolver = pcall(function()
	return require(ReplicatedStorage.Shared.Combat.WeaponResolver)
end)
local okGlossary, GameGlossary = pcall(function()
	return require(ReplicatedStorage.Shared.Config.GameGlossary)
end)
local okAbilityTip, AbilityTooltip = pcall(function()
	return require(ReplicatedStorage.Shared.UI.AbilityTooltip)
end)
local okHoverTip, HoverTooltip = pcall(function()
	return require(script.Parent.Parent.UI.HoverTooltip)
end)
local okToast, UiToast = pcall(function()
	return require(script.Parent.Parent.UI.UiToast)
end)
local okIcon, ItemIcon = pcall(function()
	return require(script.Parent.ItemIcon)
end)
local okGemSymbol, GemSymbol = pcall(function()
	return require(ReplicatedStorage.Shared.UI.GemSymbol)
end)
if not (okSlots and okHotbar and okCombat and okIcon and okUpgrade and okTooltip and okGlossary and okAbilityTip and okHoverTip and okToast and okResolver) then
	failBoot("GearUI config require failed — check Output")
	return
end

local remotes = ReplicatedStorage:WaitForChild("InventoryRemotes", 30)
if not remotes then
	failBoot("InventoryRemotes missing — Rojo sync / InventoryBootstrap failed")
	return
end
bootStatus:Destroy()

local GetSnapshot = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local EquipItem = remotes:WaitForChild("EquipItem") :: RemoteEvent
local UnequipSlot = remotes:WaitForChild("UnequipSlot") :: RemoteEvent
local BindAbility = remotes:WaitForChild("BindAbility") :: RemoteEvent
local UnbindHotbar = remotes:WaitForChild("UnbindHotbar") :: RemoteEvent
local DiscardItem = remotes:WaitForChild("DiscardItem") :: RemoteEvent

local tradeFolder = ReplicatedStorage:WaitForChild("TradeRemotes", 15)
local OpenLootBox: RemoteEvent? = nil
local LootBoxResult: RemoteEvent? = nil
local TradeUI = {
	OpenInvite = function()
		UiToast.Show("Trade system not ready.", 2, "error")
	end,
	AddSelected = function(_uuid: string) end,
	IsActive = function()
		return false
	end,
}
if tradeFolder then
	local okTrade, tradeModule = pcall(function()
		return require(script.Parent.TradeUI)
	end)
	if okTrade then
		TradeUI = tradeModule
	end
	local openEv = tradeFolder:FindFirstChild("OpenLootBox")
	local resultEv = tradeFolder:FindFirstChild("LootBoxResult")
	if openEv and openEv:IsA("RemoteEvent") then
		OpenLootBox = openEv
	end
	if resultEv and resultEv:IsA("RemoteEvent") then
		LootBoxResult = resultEv
	end
else
	warn("[GearUI] TradeRemotes missing — trade / lootbox open unavailable")
end

local InventoryUpdated = remotes:WaitForChild("InventoryUpdated") :: RemoteEvent
local InstallWeaponPart = remotes:WaitForChild("InstallWeaponPart") :: RemoteEvent
local RemoveWeaponPart = remotes:WaitForChild("RemoveWeaponPart") :: RemoteEvent
local SocketGem = remotes:WaitForChild("SocketGem") :: RemoteEvent
local UnsocketGem = remotes:WaitForChild("UnsocketGem") :: RemoteEvent
local CreateWeaponFrame = remotes:WaitForChild("CreateWeaponFrame") :: RemoteEvent
local ForgeWeapon = remotes:WaitForChild("ForgeWeapon") :: RemoteEvent
local ForgeResult = remotes:WaitForChild("ForgeResult") :: RemoteEvent
local AllocateStat = remotes:WaitForChild("AllocateStat") :: RemoteEvent

local UpgradeItem: RemoteEvent? = nil
task.spawn(function()
	local meta = ReplicatedStorage:WaitForChild("MetaRemotes", 60)
	if meta then
		local ev = meta:FindFirstChild("UpgradeItem")
		if ev and ev:IsA("RemoteEvent") then
			UpgradeItem = ev
		end
	end
end)

type ActiveInfo = { abilityId: string, name: string, desc: string, sourceUuid: string, defId: string }

local snapshot = {
	items = {} :: { { uuid: string, defId: string } },
	loadout = {} :: { [string]: string? },
	hotbar = {} :: { [number]: string? },
	actives = {} :: { ActiveInfo },
	stats = { level = 1, STR = 10, DEX = 10, VIT = 10, INT = 10 },
	derived = {
		hp = 0,
		stamina = 0,
		defenceFromVit = 0,
		resistFromVit = 0,
		totalDefence = 0,
		totalResist = 0,
		synergyBand = "None",
		synergyElement = nil,
		synergyPerk = "",
		synergyDefenceBonusPct = 0,
		synergyResistBonusPct = 0,
	},
	resolvedMain = nil :: any,
	premiumCurrency = 0,
	gemPreserveUnsocketCost = 1,
	xpProgress = nil :: any,
}

local invFilter = "All"
local pendingInstallSlot: string? = nil
local assemblyFrameUuid: string? = nil
local pendingConfirmAction: (() -> ())? = nil
local gemUnsocketMode = false
local pendingGemUnsocketUuid: string? = nil
local forgeApi: any = nil
local pendingForgeResult: { ok: boolean, gemSkipped: string? }? = nil
local pendingForgeNeutral = false

local FORGE_ERROR_MESSAGES: { [string]: string } = {
	BadParts = "Invalid forge parts.",
	DuplicateParts = "Same part attached twice.",
	NotOwned = "One or more parts are missing from your bag.",
	AlreadyInstalled = "A part is already installed on another weapon.",
	NeedHandle = "Attach a valid handle.",
	NeedBlade = "Attach a valid blade.",
	NeedPommel = "Attach a valid pommel or string.",
	IncompatibleHandle = "Blade or pommel does not fit this handle.",
	WrongPartKind = "Wrong part type for that slot.",
	NeedString = "This handle needs a string, not a pommel.",
	InstallHandleFirst = "Install the handle first.",
	FrameFailed = "Could not create weapon frame.",
	LoadoutLocked = "Cannot forge during a match.",
	ForgeFailed = "Forge failed.",
}

local function forgeErrorMessage(code: string?): string
	if code and FORGE_ERROR_MESSAGES[code] then
		return FORGE_ERROR_MESSAGES[code]
	end
	return if code then `Forge failed: {code}` else "Forge failed."
end

local FILTER_OPTIONS = {
	{ id = "All", label = "All" },
	{ id = "Frames", label = "Frame" },
	{ id = "Handles", label = "Handle" },
	{ id = "Blades", label = "Blade" },
	{ id = "Pommels", label = "Pommel" },
	{ id = "Gems", label = "Gem" },
}

local SLOT_TO_FILTER = {
	handle = "Handles",
	blade = "Blades",
	pommel = "Pommels",
}

local COL_PENDING = Color3.fromRGB(180, 140, 50)

-- Forward decls — assembly buttons wire before refresh bodies are assigned.
local refreshDetail: () -> ()
local refreshInventory: () -> ()
local refreshGear: () -> ()
local refreshSkills: () -> ()
local refreshFilterBar: () -> ()

local function clearAssemblyPick()
	pendingInstallSlot = nil
	assemblyFrameUuid = nil
end

local function findItemByUuid(uuid: string?)
	if not uuid then
		return nil
	end
	for _, item in snapshot.items do
		if item.uuid == uuid then
			return item
		end
	end
	return nil
end

local function resolveWeaponFrame(item: any)
	if not okResolver or not WeaponResolver or not item or item.defId ~= "weapon_frame" then
		return nil
	end
	return WeaponResolver.ResolveFrame(player.UserId, item, function(_uid, partUuid)
		return findItemByUuid(partUuid)
	end)
end

local function frameDisplayName(item: any, resolved: any?): string
	if resolved and resolved.complete and resolved.displayName then
		return resolved.displayName
	end
	if resolved and resolved.frameUuid then
		return "Incomplete Frame"
	end
	local def = item and ItemDefs.Get(item.defId)
	return def and def.name or "?"
end

local function mountItemIcon(host: GuiObject, item: any, opts: { zIndex: number?, yawDeg: number?, pitchDeg: number?, distanceMul: number? }?)
	opts = opts or {}
	if item.defId == "weapon_frame" then
		local resolved = resolveWeaponFrame(item)
		if resolved then
			ItemIcon.MountFrame(host, {
				bladeDefId = resolved.bladeDefId,
				element = resolved.element,
				zIndex = opts.zIndex or 2,
				yawDeg = opts.yawDeg,
				pitchDeg = opts.pitchDeg,
				distanceMul = opts.distanceMul,
			})
			return
		end
	end
	ItemIcon.Mount(host, item.defId, opts)
end

local function frameHandleType(frameUuid: string?): string?
	local frame = findItemByUuid(frameUuid)
	if not frame or not frame.parts or not frame.parts.handle then
		return nil
	end
	local handleItem = findItemByUuid(frame.parts.handle)
	local def = handleItem and ItemDefs.Get(handleItem.defId)
	return def and def.handleType
end

local function frameBladeHandleType(frameUuid: string?): string?
	local frame = findItemByUuid(frameUuid)
	if not frame or not frame.parts or not frame.parts.blade then
		return nil
	end
	local bladeItem = findItemByUuid(frame.parts.blade)
	local def = bladeItem and ItemDefs.Get(bladeItem.defId)
	return def and def.handleType
end

local function isRangedHandleType(handleType: string?): boolean
	return handleType == "2H_Bow" or handleType == "2H_Crossbow"
end

--- True if this free bag item can fill the pending assembly slot.
local function matchesAssemblyPick(defId: string): boolean
	if not pendingInstallSlot then
		return true
	end
	local def = ItemDefs.Get(defId)
	if not def then
		return false
	end
	if pendingInstallSlot == "handle" then
		if def.kind ~= "WeaponHandle" then
			return false
		end
		local bladeHt = frameBladeHandleType(assemblyFrameUuid)
		if bladeHt and def.handleType and def.handleType ~= bladeHt then
			return false
		end
		return true
	elseif pendingInstallSlot == "blade" then
		if def.kind ~= "WeaponBlade" then
			return false
		end
		local ht = frameHandleType(assemblyFrameUuid)
		if ht and def.handleType and def.handleType ~= ht then
			return false
		end
		return true
	elseif pendingInstallSlot == "pommel" then
		if def.kind ~= "WeaponPommel" then
			return false
		end
		local ht = frameHandleType(assemblyFrameUuid)
		local role = (def :: any).pommelRole or "Pommel"
		if isRangedHandleType(ht) then
			return role == "String"
		end
		return role == "Pommel"
	end
	return false
end

local function beginAssemblyPick(slotName: string)
	if not selectedUuid then
		return
	end
	local frame = findItemByUuid(selectedUuid)
	if not frame or frame.defId ~= "weapon_frame" then
		UiToast.Show("Select a Weapon Frame first.", 2, "warn")
		return
	end
	if pendingInstallSlot == slotName and assemblyFrameUuid == selectedUuid then
		clearAssemblyPick()
		invFilter = "All"
		UiToast.Show("Install cancelled.", 1.2, "warn")
		return
	end

	pendingInstallSlot = slotName
	assemblyFrameUuid = selectedUuid
	invFilter = SLOT_TO_FILTER[slotName] or "All"

	local freeCount = 0
	for _, item in snapshot.items do
		if not item.installedIn and matchesAssemblyPick(item.defId) then
			freeCount += 1
		end
	end
	if freeCount == 0 then
		local hint = if slotName == "handle"
			then "F8 grant: h_1h_wandscepter"
			elseif slotName == "blade"
			then "F8 grant: b_scepter_st"
			else "F8 grant: p_balanced"
		UiToast.Show(`No free {slotName}s in bag. {hint}`, 3.5, "warn")
	else
		UiToast.Show(`Click a {slotName} in inventory ({freeCount} ready).`, 2.5, "info")
	end
end

local selectedUuid: string? = nil
local selectedAbility: string? = nil
local open = false

local PRIMARY_COLORS = {
	STR = Color3.fromRGB(230, 90, 90),
	DEX = Color3.fromRGB(90, 200, 120),
	VIT = Color3.fromRGB(90, 170, 255),
	INT = Color3.fromRGB(200, 130, 255),
}

local SYNERGY_COLORS = {
	None = COL_MUTED,
	Pure = Color3.fromRGB(255, 180, 90),
	Duality = Color3.fromRGB(120, 190, 255),
	Harmony = Color3.fromRGB(200, 150, 255),
	Unbound = Color3.fromRGB(220, 220, 230),
}

-- Confirm modal (gem unsocket etc.)
local confirmOverlay = Instance.new("Frame")
confirmOverlay.Name = "ConfirmOverlay"
confirmOverlay.Size = UDim2.fromScale(1, 1)
confirmOverlay.BackgroundColor3 = C.BgOverlay
confirmOverlay.BackgroundTransparency = 0.45
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 30
confirmOverlay.Parent = gui

local confirmBox = Instance.new("Frame")
confirmBox.Size = UDim2.fromOffset(320, 148)
confirmBox.Position = UDim2.new(0.5, -160, 0.5, -74)
confirmBox.BackgroundColor3 = COL_PANEL
confirmBox.BorderSizePixel = 0
confirmBox.Parent = confirmOverlay
corner(confirmBox, 10)
stroke(confirmBox, C.StrokeLight, 1.5)

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Size = UDim2.new(1, -20, 0, 28)
confirmTitle.Position = UDim2.fromOffset(10, 10)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextSize = 15
confirmTitle.TextColor3 = COL_TEXT
confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
confirmTitle.Text = "Confirm"
confirmTitle.Parent = confirmBox

local confirmBody = Instance.new("TextLabel")
confirmBody.Size = UDim2.new(1, -20, 0, 52)
confirmBody.Position = UDim2.fromOffset(10, 38)
confirmBody.BackgroundTransparency = 1
confirmBody.Font = Enum.Font.Gotham
confirmBody.TextSize = 12
confirmBody.TextColor3 = COL_MUTED
confirmBody.TextXAlignment = Enum.TextXAlignment.Left
confirmBody.TextYAlignment = Enum.TextYAlignment.Top
confirmBody.TextWrapped = true
confirmBody.Text = ""
confirmBody.Parent = confirmBox

local confirmYes = Instance.new("TextButton")
confirmYes.Size = UDim2.fromOffset(120, 32)
confirmYes.Position = UDim2.new(1, -252, 1, -42)
confirmYes.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
confirmYes.BorderSizePixel = 0
confirmYes.Font = Enum.Font.GothamBold
confirmYes.TextSize = 13
confirmYes.TextColor3 = COL_TEXT
confirmYes.Text = "Confirm"
confirmYes.Parent = confirmBox
corner(confirmYes, 6)

local confirmNo = Instance.new("TextButton")
confirmNo.Size = UDim2.fromOffset(120, 32)
confirmNo.Position = UDim2.new(1, -126, 1, -42)
confirmNo.BackgroundColor3 = COL_SLOT
confirmNo.BorderSizePixel = 0
confirmNo.Font = Enum.Font.GothamBold
confirmNo.TextSize = 13
confirmNo.TextColor3 = COL_TEXT
confirmNo.Text = "Cancel"
confirmNo.Parent = confirmBox
corner(confirmNo, 6)

local confirmPremium = Instance.new("TextButton")
confirmPremium.Size = UDim2.fromOffset(94, 32)
confirmPremium.Position = UDim2.new(0.5, -47, 1, -42)
confirmPremium.BackgroundColor3 = C.Premium
confirmPremium.BorderSizePixel = 0
confirmPremium.Font = Enum.Font.GothamBold
confirmPremium.TextSize = 11
confirmPremium.TextColor3 = COL_TEXT
confirmPremium.Text = "Safe (1)"
confirmPremium.Visible = false
confirmPremium.Parent = confirmBox
corner(confirmPremium, 6)

local DEFAULT_CONFIRM_SIZE = UDim2.fromOffset(320, 148)
local GEM_CONFIRM_SIZE = UDim2.fromOffset(320, 168)

local function hideConfirm()
	confirmOverlay.Visible = false
	pendingConfirmAction = nil
	gemUnsocketMode = false
	pendingGemUnsocketUuid = nil
	confirmPremium.Visible = false
	confirmBox.Size = DEFAULT_CONFIRM_SIZE
	confirmYes.Text = "Confirm"
	confirmYes.Position = UDim2.new(1, -252, 1, -42)
end

local function showConfirm(title: string, body: string, onYes: () -> ())
	gemUnsocketMode = false
	pendingGemUnsocketUuid = nil
	confirmPremium.Visible = false
	confirmBox.Size = DEFAULT_CONFIRM_SIZE
	confirmYes.Text = "Confirm"
	confirmYes.Position = UDim2.new(1, -252, 1, -42)
	confirmTitle.Text = title
	confirmBody.Text = body
	pendingConfirmAction = onYes
	confirmOverlay.Visible = true
end

local function showGemUnsocketConfirm(frameUuid: string)
	gemUnsocketMode = true
	pendingGemUnsocketUuid = frameUuid
	pendingConfirmAction = nil
	confirmBox.Size = GEM_CONFIRM_SIZE
	confirmTitle.Text = "Unsocket Gem?"
	local cost = snapshot.gemPreserveUnsocketCost or 1
	local bal = snapshot.premiumCurrency or 0
	confirmBody.Text = `Break: the gem is destroyed and the weapon becomes Neutral.\n\nSafe unsocket: spend {cost} premium currency ({bal} owned) — gem returns to your bag.`
	confirmYes.Text = "Break Gem"
	confirmYes.Position = UDim2.new(0, 10, 1, -42)
	confirmPremium.Visible = true
	confirmPremium.Text = `Safe ({cost})`
	local canSafe = bal >= cost
	confirmPremium.BackgroundColor3 = if canSafe then C.Premium else C.ButtonDisabled
	confirmPremium.AutoButtonColor = canSafe
	confirmPremium.Active = canSafe
	confirmPremium.TextTransparency = if canSafe then 0 else 0.35
	confirmOverlay.Visible = true
end

confirmYes.MouseButton1Click:Connect(function()
	if gemUnsocketMode and pendingGemUnsocketUuid then
		local uuid = pendingGemUnsocketUuid
		hideConfirm()
		UnsocketGem:FireServer(uuid, false)
		return
	end
	local action = pendingConfirmAction
	hideConfirm()
	if action then
		action()
	end
end)

confirmPremium.MouseButton1Click:Connect(function()
	if not gemUnsocketMode or not pendingGemUnsocketUuid then
		return
	end
	local uuid = pendingGemUnsocketUuid
	hideConfirm()
	UnsocketGem:FireServer(uuid, true)
end)

confirmNo.MouseButton1Click:Connect(function()
	hideConfirm()
end)

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function shortName(name: string, maxLen: number): string
	if #name <= maxLen then
		return name
	end
	return string.sub(name, 1, maxLen - 1) .. "…"
end

local function isEquipped(uuid: string): boolean
	for _, slot in LoadoutSlots.Order do
		if snapshot.loadout[slot] == uuid then
			return true
		end
	end
	return false
end

local function suggestSlot(defId: string): string?
	local def = ItemDefs.Get(defId)
	if not def then
		return nil
	end
	if ItemDefs.IsPartKind(def.kind) then
		return nil
	end
	local hints = (def :: any).slotHints
	if typeof(hints) == "table" and hints[1] then
		return hints[1]
	end
	local kind = def.kind
	if kind == "Head" then
		return "head"
	elseif kind == "Chest" then
		return "chest"
	elseif kind == "Hands" then
		return "hands"
	elseif kind == "Feets" then
		return "feets"
	elseif kind == "Shield" or kind == "Focus" or kind == "Knot" or kind == "Quiver" then
		return "off"
	elseif kind == "WeaponFrame" then
		return "main"
	end
	return "main"
end

local function secondaryFromStats()
	local s = snapshot.stats
	local d = snapshot.derived
	local str, dex, vit, int_ = s.STR or 10, s.DEX or 10, s.VIT or 10, s.INT or 10
	local critPass = d.passiveCritChance or 0
	local critChance = math.min(CombatConfig.BaseCrit + dex * CombatConfig.KDexCrit + critPass, CombatConfig.CritChanceCap)
	local critLabel = if critPass > 0.01
		then string.format("%.1f%% (+%.0f gear)", critChance, critPass)
		else string.format("%.1f%%", critChance)
	local critDmg = math.min(CombatConfig.BaseCritDmg + str * CombatConfig.KStrCritDmg, CombatConfig.CritDmgCap)
	local asMult = math.min(1 + dex * CombatConfig.KDexAs, CombatConfig.AsCap)
	local defence = d.totalDefence or d.defenceFromVit or (vit * CombatConfig.KVitDef)
	local resist = d.totalResist or d.resistFromVit or (vit * CombatConfig.KVitRes)
	local dr = math.min(defence * CombatConfig.KDr, CombatConfig.DrCapPvp)
	local defSynergyPct = (d.synergyDefenceBonusPct or 0) * 100
	local resSynergyPct = (d.synergyResistBonusPct or 0) * 100
	local defenceLabel = if defSynergyPct > 0
		then string.format("%.0f  (DR %.0f%% · +%.0f%% synergy)", defence, dr, defSynergyPct)
		else string.format("%.0f  (DR %.0f%%)", defence, dr)
	local resistLabel = if resSynergyPct > 0
		then string.format("%.0f  (+%.0f%% synergy)", resist, resSynergyPct)
		else string.format("%.0f", resist)
	local statusPot = int_ * 0.5 + (d.passiveStatusPotency or 0)
	local buffPot = d.totalBuffPotency or (int_ * 0.25 + (d.passiveBuffPotency or 0))
	local directMult = d.passiveDirectMult or 1
	local directBonus = math.max(0, (directMult - 1) * 100)
	local directLabel = if directBonus > 0.5
		then string.format("+%.0f%%", directBonus)
		else "—"
	local rows = {
		{ "HP", string.format("%d", math.floor(d.hp or 0)), Color3.fromRGB(100, 220, 130) },
		{ "Stamina", string.format("%d", math.floor(d.stamina or 0)), Color3.fromRGB(240, 210, 80) },
		{ "Defence", defenceLabel, Color3.fromRGB(120, 190, 255) },
		{ "Resist", resistLabel, Color3.fromRGB(150, 200, 255) },
		{ "Crit Chance", critLabel, Color3.fromRGB(255, 180, 100) },
		{ "Crit Damage", string.format("%.0f%%", critDmg), Color3.fromRGB(255, 120, 100) },
		{ "Attack Speed", string.format("%.0f%%", asMult * 100), Color3.fromRGB(180, 255, 180) },
		{ "Direct Damage", directLabel, Color3.fromRGB(255, 150, 110) },
		{ "Status Potency", string.format("+%.0f", statusPot), Color3.fromRGB(200, 150, 255) },
		{ "Buff Potency", string.format("+%.0f", buffPot), Color3.fromRGB(180, 160, 255) },
	}
	return rows
end

-- Overlay
local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = C.BgOverlay
root.BackgroundTransparency = 0.5
root.Visible = false
root.Parent = gui

local shell = Instance.new("Frame")
shell.Name = "Shell"
shell.Size = UDim2.new(0.94, 0, 0.84, 0)
shell.Position = UDim2.new(0.03, 0, 0.07, 0)
shell.BackgroundTransparency = 1
shell.Parent = root

local function makePanel(name: string, size: UDim2, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = COL_PANEL
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	f.Parent = shell
	corner(f, 10)
	stroke(f)
	return f
end

local function makeHeader(parent: Frame, text: string, withClose: boolean?): (TextLabel, TextButton?)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 36)
	bar.BackgroundColor3 = C.BgElevated
	bar.BackgroundTransparency = 0.2
	bar.BorderSizePixel = 0
	bar.Parent = parent
	corner(bar, 10)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, if withClose then -44 else -16, 1, 0)
	t.Position = UDim2.fromOffset(12, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = COL_TEXT
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.Parent = bar

	local closeBtn: TextButton? = nil
	if withClose then
		local x = Instance.new("TextButton")
		x.Size = UDim2.fromOffset(28, 28)
		x.Position = UDim2.new(1, -32, 0.5, -14)
		x.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
		x.BorderSizePixel = 0
		x.Font = Enum.Font.GothamBold
		x.TextSize = 14
		x.TextColor3 = COL_TEXT
		x.Text = "X"
		x.Parent = bar
		corner(x, 6)
		closeBtn = x
	end
	return t, closeBtn
end

-- ========== LEFT: STATS ==========
local statsPanel = makePanel("Stats", UDim2.new(0.22, -8, 1, 0), UDim2.new(0, 0, 0, 0))
makeHeader(statsPanel, "STATS")

local statsBody = Instance.new("ScrollingFrame")
statsBody.Size = UDim2.new(1, -16, 1, -48)
statsBody.Position = UDim2.fromOffset(8, 42)
statsBody.BackgroundTransparency = 1
statsBody.BorderSizePixel = 0
statsBody.ScrollBarThickness = 3
statsBody.CanvasSize = UDim2.fromOffset(0, 0)
statsBody.Parent = statsPanel

local statsList = Instance.new("UIListLayout")
statsList.Padding = UDim.new(0, 4)
statsList.SortOrder = Enum.SortOrder.LayoutOrder
statsList.Parent = statsBody

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, 0, 0, 22)
levelLabel.BackgroundTransparency = 1
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 13
levelLabel.TextColor3 = COL_MUTED
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.LayoutOrder = 0
levelLabel.Text = "Level —"
levelLabel.Parent = statsBody

local xpBarBg = Instance.new("Frame")
xpBarBg.Name = "XpBarBg"
xpBarBg.Size = UDim2.new(1, 0, 0, 10)
xpBarBg.BackgroundColor3 = COL_SLOT
xpBarBg.BorderSizePixel = 0
xpBarBg.LayoutOrder = 1
xpBarBg.Parent = statsBody
corner(xpBarBg, 4)

local xpBarFill = Instance.new("Frame")
xpBarFill.Name = "Fill"
xpBarFill.Size = UDim2.fromScale(0, 1)
xpBarFill.BackgroundColor3 = C.Accent
xpBarFill.BorderSizePixel = 0
xpBarFill.Parent = xpBarBg
corner(xpBarFill, 4)

local xpBarLabel = Instance.new("TextLabel")
xpBarLabel.Name = "XpLabel"
xpBarLabel.Size = UDim2.new(1, 0, 0, 14)
xpBarLabel.BackgroundTransparency = 1
xpBarLabel.Font = Enum.Font.Gotham
xpBarLabel.TextSize = 10
xpBarLabel.TextColor3 = COL_MUTED
xpBarLabel.TextXAlignment = Enum.TextXAlignment.Left
xpBarLabel.LayoutOrder = 2
xpBarLabel.Text = "XP — / —"
xpBarLabel.Parent = statsBody

local primaryHeader = Instance.new("TextLabel")
primaryHeader.Size = UDim2.new(1, 0, 0, 18)
primaryHeader.BackgroundTransparency = 1
primaryHeader.Font = Enum.Font.GothamBold
primaryHeader.TextSize = 11
primaryHeader.TextColor3 = COL_MUTED
primaryHeader.TextXAlignment = Enum.TextXAlignment.Left
primaryHeader.LayoutOrder = 3
primaryHeader.Text = "PRIMARY"
primaryHeader.Parent = statsBody

local unspentLabel = Instance.new("TextLabel")
unspentLabel.Size = UDim2.new(1, 0, 0, 18)
unspentLabel.BackgroundTransparency = 1
unspentLabel.Font = Enum.Font.GothamBold
unspentLabel.TextSize = 11
unspentLabel.TextColor3 = Color3.fromRGB(120, 200, 140)
unspentLabel.TextXAlignment = Enum.TextXAlignment.Left
unspentLabel.LayoutOrder = 4
unspentLabel.Text = ""
unspentLabel.Parent = statsBody

local primaryLabels: { [string]: TextLabel } = {}
local statPlusBtns: { [string]: TextButton } = {}
for i, key in { "STR", "DEX", "VIT", "INT" } do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = COL_SLOT
	row.BorderSizePixel = 0
	row.LayoutOrder = 4 + i
	row.Parent = statsBody
	corner(row, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextColor3 = PRIMARY_COLORS[key]
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = `  {key}  —`
	label.Parent = row
	primaryLabels[key] = label

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.fromOffset(28, 22)
	plus.Position = UDim2.new(1, -34, 0.5, -11)
	plus.BackgroundColor3 = C.SuccessDark
	plus.BorderSizePixel = 0
	plus.Font = Enum.Font.GothamBold
	plus.TextSize = 16
	plus.TextColor3 = Color3.fromRGB(240, 250, 240)
	plus.Text = "+"
	plus.Parent = row
	corner(plus, 4)
	statPlusBtns[key] = plus
	plus.MouseButton1Click:Connect(function()
		AllocateStat:FireServer(key)
	end)
end

local synergyHeader = Instance.new("TextLabel")
synergyHeader.Size = UDim2.new(1, 0, 0, 18)
synergyHeader.BackgroundTransparency = 1
synergyHeader.Font = Enum.Font.GothamBold
synergyHeader.TextSize = 11
synergyHeader.TextColor3 = COL_MUTED
synergyHeader.TextXAlignment = Enum.TextXAlignment.Left
synergyHeader.LayoutOrder = 20
synergyHeader.Text = "SYNERGY"
synergyHeader.Parent = statsBody

local synergyBandLabel = Instance.new("TextLabel")
synergyBandLabel.Size = UDim2.new(1, 0, 0, 24)
synergyBandLabel.BackgroundTransparency = 1
synergyBandLabel.Font = Enum.Font.GothamBold
synergyBandLabel.TextSize = 14
synergyBandLabel.TextColor3 = COL_MUTED
synergyBandLabel.TextXAlignment = Enum.TextXAlignment.Left
synergyBandLabel.LayoutOrder = 21
synergyBandLabel.Text = "Band: None"
synergyBandLabel.Parent = statsBody

local synergyPerkLabel = Instance.new("TextLabel")
synergyPerkLabel.Size = UDim2.new(1, 0, 0, 36)
synergyPerkLabel.BackgroundTransparency = 1
synergyPerkLabel.Font = Enum.Font.Gotham
synergyPerkLabel.TextSize = 11
synergyPerkLabel.TextColor3 = COL_MUTED
synergyPerkLabel.TextXAlignment = Enum.TextXAlignment.Left
synergyPerkLabel.TextYAlignment = Enum.TextYAlignment.Top
synergyPerkLabel.TextWrapped = true
synergyPerkLabel.LayoutOrder = 22
synergyPerkLabel.Text = ""
synergyPerkLabel.Parent = statsBody

local secHeader = Instance.new("TextLabel")
secHeader.Size = UDim2.new(1, 0, 0, 18)
secHeader.BackgroundTransparency = 1
secHeader.Font = Enum.Font.GothamBold
secHeader.TextSize = 11
secHeader.TextColor3 = COL_MUTED
secHeader.TextXAlignment = Enum.TextXAlignment.Left
	secHeader.LayoutOrder = 30
secHeader.Text = "SECONDARY"
secHeader.Parent = statsBody

local secondaryLabels: { TextLabel } = {}
for i = 1, 9 do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.Gotham
	row.TextSize = 12
	row.TextColor3 = COL_TEXT
	row.TextXAlignment = Enum.TextXAlignment.Left
		row.LayoutOrder = 30 + i
	row.Text = ""
	row.Parent = statsBody
	secondaryLabels[i] = row
end

-- ========== MIDDLE: LOADOUT ==========
local loadPanel = makePanel("Loadout", UDim2.new(0.40, -8, 1, 0), UDim2.new(0.22, 4, 0, 0))
local _, loadCloseBtn = makeHeader(loadPanel, "LOADOUT", true)

local dollArea = Instance.new("Frame")
dollArea.Size = UDim2.new(1, -20, 1, -170)
dollArea.Position = UDim2.fromOffset(10, 44)
dollArea.BackgroundTransparency = 1
dollArea.Parent = loadPanel

local SLOT = 58
local gearButtons: { [string]: TextButton } = {}
local gearLabels: { [string]: TextLabel } = {}

local function makeGearSlot(slotId: string, anchor: UDim2, caption: string)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(SLOT + 4, SLOT + 18)
	wrap.Position = anchor
	wrap.AnchorPoint = Vector2.new(0.5, 0.5)
	wrap.BackgroundTransparency = 1
	wrap.Parent = dollArea

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(SLOT, SLOT)
	btn.Position = UDim2.new(0.5, 0, 0, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BackgroundColor3 = COL_SLOT
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.Parent = wrap
	corner(btn, 8)
	stroke(btn, C.StrokeSlot)

	local name = Instance.new("TextLabel")
	name.Name = "ItemName"
	name.Size = UDim2.new(1, -4, 0, 14)
	name.Position = UDim2.new(0, 2, 1, -16)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 8
	name.TextColor3 = COL_TEXT
	name.TextWrapped = true
	name.Text = ""
	name.ZIndex = 4
	name.Parent = btn

	local iconHost = Instance.new("Frame")
	iconHost.Name = "IconHost"
	iconHost.Size = UDim2.new(1, -6, 1, -18)
	iconHost.Position = UDim2.fromOffset(3, 3)
	iconHost.BackgroundTransparency = 1
	iconHost.ZIndex = 2
	iconHost.Parent = btn

	local cap = Instance.new("TextLabel")
	cap.Size = UDim2.new(1, 0, 0, 14)
	cap.Position = UDim2.new(0, 0, 1, -14)
	cap.BackgroundTransparency = 1
	cap.Font = Enum.Font.Gotham
	cap.TextSize = 10
	cap.TextColor3 = COL_MUTED
	cap.Text = caption
	cap.Parent = wrap

	gearButtons[slotId] = btn
	gearLabels[slotId] = name

	btn.MouseButton1Click:Connect(function()
		if selectedUuid then
			EquipItem:FireServer(selectedUuid, slotId)
			selectedUuid = nil
		else
			local uuid = snapshot.loadout[slotId]
			if uuid then
				UnequipSlot:FireServer(slotId)
			end
		end
	end)
end

makeGearSlot("head", UDim2.new(0.12, 0, 0.18, 0), "Head")
makeGearSlot("chest", UDim2.new(0.12, 0, 0.48, 0), "Chest")
makeGearSlot("feets", UDim2.new(0.12, 0, 0.78, 0), "Boots")
makeGearSlot("main", UDim2.new(0.88, 0, 0.18, 0), "Main")
makeGearSlot("off", UDim2.new(0.88, 0, 0.48, 0), "Off")
makeGearSlot("hands", UDim2.new(0.88, 0, 0.78, 0), "Hands")

local vp = Instance.new("ViewportFrame")
vp.Size = UDim2.new(0.56, 0, 0.92, 0)
vp.Position = UDim2.new(0.5, 0, 0.5, 0)
vp.AnchorPoint = Vector2.new(0.5, 0.5)
vp.BackgroundColor3 = C.Viewport
vp.BorderSizePixel = 0
vp.Parent = dollArea
corner(vp, 8)
stroke(vp, Color3.fromRGB(55, 58, 66))

local worldModel = Instance.new("WorldModel")
worldModel.Parent = vp
local cam = Instance.new("Camera")
cam.Parent = vp
vp.CurrentCamera = cam

local previewChar: Model? = nil
local previewConn: RBXScriptConnection? = nil

local function clearPreview()
	if previewConn then
		previewConn:Disconnect()
		previewConn = nil
	end
	if previewChar then
		previewChar:Destroy()
		previewChar = nil
	end
end

local function refreshPreview()
	clearPreview()
	local char = player.Character
	if not char then
		return
	end
	local prevArchivable = char.Archivable
	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = prevArchivable
	if not clone then
		return
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	clone.Parent = worldModel
	previewChar = clone
	local hrp = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local pivot = hrp.Position
	cam.CFrame = CFrame.new(pivot + Vector3.new(0, 1.2, -6.2), pivot + Vector3.new(0, 1.0, 0))
	previewConn = RunService.RenderStepped:Connect(function()
		local rootPart = previewChar and previewChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(0.35), 0)
		end
	end)
end

-- Skills
local skillsLabel = Instance.new("TextLabel")
skillsLabel.Size = UDim2.new(1, -20, 0, 16)
skillsLabel.Position = UDim2.new(0, 10, 1, -118)
skillsLabel.BackgroundTransparency = 1
skillsLabel.Font = Enum.Font.GothamBold
skillsLabel.TextSize = 11
skillsLabel.TextColor3 = COL_MUTED
skillsLabel.TextXAlignment = Enum.TextXAlignment.Left
skillsLabel.Text = "SKILLS  Q E R 1 2 3"
skillsLabel.Parent = loadPanel

local skillBar = Instance.new("Frame")
skillBar.Size = UDim2.new(1, -20, 0, 50)
skillBar.Position = UDim2.new(0, 10, 1, -98)
skillBar.BackgroundTransparency = 1
skillBar.Parent = loadPanel

local skillButtons: { [number]: TextButton } = {}
local skillLayout = Instance.new("UIListLayout")
skillLayout.FillDirection = Enum.FillDirection.Horizontal
skillLayout.Padding = UDim.new(0, 5)
skillLayout.Parent = skillBar

for i = 1, HotbarConfig.SlotCount do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(48, 48)
	btn.BackgroundColor3 = COL_SLOT
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.TextColor3 = COL_TEXT
	btn.Text = HotbarConfig.Labels[i]
	btn.LayoutOrder = i
	btn.Parent = skillBar
	corner(btn, 6)
	stroke(btn)
	skillButtons[i] = btn
	btn.MouseEnter:Connect(function()
		local slotId = snapshot.hotbar[i]
		if not slotId then
			return
		end
		for _, a in snapshot.actives do
			if a.abilityId == slotId then
				local title, body = AbilityTooltip.Build(slotId, { name = a.name, desc = a.desc })
				HoverTooltip.show(title, body, btn)
				return
			end
		end
		local title, body = AbilityTooltip.Build(slotId, nil)
		HoverTooltip.show(title, body, btn)
	end)
	btn.MouseLeave:Connect(function()
		HoverTooltip.hide()
	end)
	btn.MouseButton1Click:Connect(function()
		if selectedAbility then
			BindAbility:FireServer(selectedAbility, i)
			selectedAbility = nil
		elseif snapshot.hotbar[i] then
			UnbindHotbar:FireServer(i)
		end
	end)
end

local abilityStrip = Instance.new("ScrollingFrame")
abilityStrip.Size = UDim2.new(1, -20, 0, 26)
abilityStrip.Position = UDim2.new(0, 10, 1, -42)
abilityStrip.BackgroundTransparency = 1
abilityStrip.BorderSizePixel = 0
abilityStrip.ScrollBarThickness = 2
abilityStrip.ScrollingDirection = Enum.ScrollingDirection.X
abilityStrip.CanvasSize = UDim2.fromOffset(0, 0)
abilityStrip.Parent = loadPanel

local abilityLayout = Instance.new("UIListLayout")
abilityLayout.FillDirection = Enum.FillDirection.Horizontal
abilityLayout.Padding = UDim.new(0, 4)
abilityLayout.Parent = abilityStrip

-- ========== RIGHT: INVENTORY + DETAIL ==========
local invPanel = makePanel("Inventory", UDim2.new(0.38, -4, 1, 0), UDim2.new(0.62, 4, 0, 0))
makeHeader(invPanel, "INVENTORY")

local filterBar = Instance.new("Frame")
filterBar.Name = "FilterBar"
filterBar.Size = UDim2.new(1, -20, 0, 28)
filterBar.Position = UDim2.fromOffset(10, 40)
filterBar.BackgroundTransparency = 1
filterBar.Parent = invPanel

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0, 4)
filterLayout.Parent = filterBar

local filterButtons: { [string]: TextButton } = {}

local invGrid = Instance.new("ScrollingFrame")
invGrid.Size = UDim2.new(1, -20, 0, 168)
invGrid.Position = UDim2.fromOffset(10, 72)
invGrid.ZIndex = 4
invGrid.BackgroundColor3 = Color3.fromRGB(24, 26, 30)
invGrid.BorderSizePixel = 0
invGrid.ScrollBarThickness = 3
invGrid.CanvasSize = UDim2.fromOffset(0, 0)
invGrid.Parent = invPanel
corner(invGrid, 8)

local gridPad = Instance.new("UIPadding")
gridPad.PaddingTop = UDim.new(0, 6)
gridPad.PaddingLeft = UDim.new(0, 6)
gridPad.PaddingRight = UDim.new(0, 6)
gridPad.Parent = invGrid

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(64, 64)
gridLayout.CellPadding = UDim2.fromOffset(5, 5)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = invGrid

-- ========== FORGE (module — keeps GearUI under Luau local register limit) ==========
do
	local GearForgePanel = require(script.Parent.GearForgePanel)
	forgeApi = GearForgePanel.Mount({
		parent = invPanel,
		panelPosition = UDim2.new(0, 10, 0, 248),
		panelSize = UDim2.new(1, -20, 0, 100),
		colors = {
			slot = COL_SLOT,
			slotEq = COL_SLOT_EQ,
			text = COL_TEXT,
			muted = COL_MUTED,
		},
		corner = corner,
		stroke = stroke,
		shortName = shortName,
		toast = function(msg, dur, kind)
			UiToast.Show(msg, dur, kind)
		end,
		getSelectedUuid = function()
			return selectedUuid
		end,
		setSelectedUuid = function(uuid)
			selectedUuid = uuid
		end,
		findItemByUuid = findItemByUuid,
		refreshInventory = function()
			refreshInventory()
		end,
		refreshDetail = function()
			refreshDetail()
		end,
		forgeRemote = ForgeWeapon,
		showConfirm = showConfirm,
		onForgeWithoutGem = function()
			pendingForgeNeutral = true
		end,
	})
end

local function isUuidInForge(uuid: string): boolean
	return forgeApi ~= nil and forgeApi.isUuidInForge(uuid)
end

local function clearForgeAttached()
	if forgeApi then
		forgeApi.clear()
	end
end

local function refreshForge()
	if forgeApi then
		forgeApi.refresh()
	end
end

local detail = Instance.new("Frame")
detail.Name = "Detail"
detail.Size = UDim2.new(1, -20, 1, -364)
detail.Position = UDim2.new(0, 10, 0, 356)
detail.ZIndex = 5
detail.BackgroundColor3 = Color3.fromRGB(24, 26, 30)
detail.BorderSizePixel = 0
detail.Parent = invPanel
corner(detail, 8)
stroke(detail, Color3.fromRGB(55, 58, 66))

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, -100, 0, 28)
detailTitle.Position = UDim2.fromOffset(10, 8)
detailTitle.BackgroundTransparency = 1
detailTitle.Font = Enum.Font.GothamBold
detailTitle.TextSize = 16
detailTitle.TextColor3 = COL_TEXT
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.Text = "Select an item"
detailTitle.Parent = detail

local detailIconHost = Instance.new("Frame")
detailIconHost.Name = "DetailIconHost"
detailIconHost.Size = UDim2.fromOffset(88, 88)
detailIconHost.Position = UDim2.new(1, -98, 0, 10)
detailIconHost.BackgroundColor3 = COL_SLOT
detailIconHost.BorderSizePixel = 0
detailIconHost.Parent = detail
corner(detailIconHost, 8)
stroke(detailIconHost, Color3.fromRGB(70, 74, 82))

local detailScroll = Instance.new("ScrollingFrame")
detailScroll.Name = "DetailScroll"
detailScroll.Size = UDim2.new(1, -120, 1, -120)
detailScroll.Position = UDim2.fromOffset(10, 40)
detailScroll.BackgroundTransparency = 1
detailScroll.BorderSizePixel = 0
detailScroll.ScrollBarThickness = 4
detailScroll.CanvasSize = UDim2.fromOffset(0, 0)
detailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailScroll.Parent = detail

local detailDesc = Instance.new("TextLabel")
detailDesc.Size = UDim2.new(1, -4, 0, 0)
detailDesc.AutomaticSize = Enum.AutomaticSize.Y
detailDesc.BackgroundTransparency = 1
detailDesc.Font = Enum.Font.Gotham
detailDesc.TextSize = 11
detailDesc.TextColor3 = COL_MUTED
detailDesc.TextXAlignment = Enum.TextXAlignment.Left
detailDesc.TextYAlignment = Enum.TextYAlignment.Top
detailDesc.TextWrapped = true
detailDesc.RichText = false
detailDesc.Text = "Click an inventory slot to inspect."
detailDesc.Parent = detailScroll

local glossaryBtn = Instance.new("TextButton")
glossaryBtn.Size = UDim2.fromOffset(72, 24)
glossaryBtn.Position = UDim2.new(1, -178, 0, 10)
glossaryBtn.BackgroundColor3 = Color3.fromRGB(52, 58, 72)
glossaryBtn.BorderSizePixel = 0
glossaryBtn.Font = Enum.Font.GothamBold
glossaryBtn.TextSize = 11
glossaryBtn.TextColor3 = COL_TEXT
glossaryBtn.Text = "Glossary"
glossaryBtn.Parent = detail
corner(glossaryBtn, 5)

local glossaryPanel = Instance.new("Frame")
glossaryPanel.Name = "GlossaryPanel"
glossaryPanel.Size = UDim2.new(1, -24, 1, -24)
glossaryPanel.Position = UDim2.fromOffset(12, 12)
glossaryPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
glossaryPanel.Visible = false
glossaryPanel.ZIndex = 30
glossaryPanel.Parent = root
corner(glossaryPanel, 10)
stroke(glossaryPanel, Color3.fromRGB(80, 90, 110), 1)

local glossaryTitle = Instance.new("TextLabel")
glossaryTitle.Size = UDim2.new(1, -80, 0, 28)
glossaryTitle.Position = UDim2.fromOffset(12, 8)
glossaryTitle.BackgroundTransparency = 1
glossaryTitle.Font = Enum.Font.GothamBold
glossaryTitle.TextSize = 16
glossaryTitle.TextColor3 = COL_TEXT
glossaryTitle.TextXAlignment = Enum.TextXAlignment.Left
glossaryTitle.Text = "Glossary"
glossaryTitle.ZIndex = 31
glossaryTitle.Parent = glossaryPanel

local glossaryClose = Instance.new("TextButton")
glossaryClose.Size = UDim2.fromOffset(64, 26)
glossaryClose.Position = UDim2.new(1, -76, 0, 8)
glossaryClose.BackgroundColor3 = Color3.fromRGB(60, 64, 74)
glossaryClose.Font = Enum.Font.GothamBold
glossaryClose.TextSize = 12
glossaryClose.TextColor3 = COL_TEXT
glossaryClose.Text = "Close"
glossaryClose.ZIndex = 31
glossaryClose.Parent = glossaryPanel
corner(glossaryClose, 6)

local glossaryScroll = Instance.new("ScrollingFrame")
glossaryScroll.Size = UDim2.new(1, -20, 1, -48)
glossaryScroll.Position = UDim2.fromOffset(10, 40)
glossaryScroll.BackgroundTransparency = 1
glossaryScroll.BorderSizePixel = 0
glossaryScroll.ScrollBarThickness = 5
glossaryScroll.CanvasSize = UDim2.fromOffset(0, 0)
glossaryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
glossaryScroll.ZIndex = 31
glossaryScroll.Parent = glossaryPanel

local glossaryBody = Instance.new("TextLabel")
glossaryBody.Size = UDim2.new(1, -8, 0, 0)
glossaryBody.AutomaticSize = Enum.AutomaticSize.Y
glossaryBody.BackgroundTransparency = 1
glossaryBody.Font = Enum.Font.Gotham
glossaryBody.TextSize = 11
glossaryBody.TextColor3 = COL_MUTED
glossaryBody.TextXAlignment = Enum.TextXAlignment.Left
glossaryBody.TextYAlignment = Enum.TextYAlignment.Top
glossaryBody.TextWrapped = true
glossaryBody.Text = GameGlossary.FormatAll()
glossaryBody.ZIndex = 31
glossaryBody.Parent = glossaryScroll

local glossaryOpen = false
local function setGlossaryOpen(state: boolean)
	glossaryOpen = state
	glossaryPanel.Visible = state
end

glossaryBtn.MouseButton1Click:Connect(function()
	glossaryBody.Text = GameGlossary.FormatAll()
	setGlossaryOpen(not glossaryOpen)
end)
glossaryClose.MouseButton1Click:Connect(function()
	setGlossaryOpen(false)
end)

local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(1, -20, 0, 32)
equipBtn.Position = UDim2.new(0, 10, 1, -78)
equipBtn.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
equipBtn.BorderSizePixel = 0
equipBtn.Font = Enum.Font.GothamBold
equipBtn.TextSize = 14
equipBtn.TextColor3 = COL_TEXT
equipBtn.Text = "Equip"
equipBtn.AutoButtonColor = true
equipBtn.Parent = detail
corner(equipBtn, 6)

local discardBtn = Instance.new("TextButton")
discardBtn.Size = UDim2.new(1, -20, 0, 32)
discardBtn.Position = UDim2.new(0, 10, 1, -40)
discardBtn.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
discardBtn.BorderSizePixel = 0
discardBtn.Font = Enum.Font.GothamBold
discardBtn.TextSize = 14
discardBtn.TextColor3 = COL_TEXT
discardBtn.Text = "Discard"
discardBtn.AutoButtonColor = true
discardBtn.Parent = detail
corner(discardBtn, 6)

local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Size = UDim2.new(1, -20, 0, 32)
upgradeBtn.Position = UDim2.new(0, 10, 1, -116)
upgradeBtn.BackgroundColor3 = Color3.fromRGB(90, 120, 200)
upgradeBtn.BorderSizePixel = 0
upgradeBtn.Font = Enum.Font.GothamBold
upgradeBtn.TextSize = 13
upgradeBtn.TextColor3 = COL_TEXT
upgradeBtn.Text = "Upgrade Blade"
upgradeBtn.AutoButtonColor = true
upgradeBtn.Visible = false
upgradeBtn.Parent = detail
corner(upgradeBtn, 6)

local openBoxBtn = Instance.new("TextButton")
openBoxBtn.Size = UDim2.new(1, -20, 0, 32)
openBoxBtn.Position = UDim2.new(0, 10, 1, -154)
openBoxBtn.BackgroundColor3 = C.Warning
openBoxBtn.BorderSizePixel = 0
openBoxBtn.Font = Enum.Font.GothamBold
openBoxBtn.TextSize = 14
openBoxBtn.TextColor3 = COL_TEXT
openBoxBtn.Text = "Open Lootbox"
openBoxBtn.AutoButtonColor = true
openBoxBtn.Visible = false
openBoxBtn.Parent = detail
corner(openBoxBtn, 6)

local tradeBtn = Instance.new("TextButton")
tradeBtn.Size = UDim2.new(1, -20, 0, 32)
tradeBtn.Position = UDim2.new(0, 10, 1, -192)
tradeBtn.BackgroundColor3 = C.AccentSoft
tradeBtn.BorderSizePixel = 0
tradeBtn.Font = Enum.Font.GothamBold
tradeBtn.TextSize = 14
tradeBtn.TextColor3 = COL_TEXT
tradeBtn.Text = "Trade…"
tradeBtn.AutoButtonColor = true
tradeBtn.Visible = false
tradeBtn.Parent = detail
corner(tradeBtn, 6)

local assemblyPanel = Instance.new("Frame")
assemblyPanel.Name = "AssemblyPanel"
assemblyPanel.Size = UDim2.new(1, -20, 0, 108)
assemblyPanel.Position = UDim2.new(0, 10, 1, -226)
assemblyPanel.BackgroundColor3 = Color3.fromRGB(32, 34, 40)
assemblyPanel.BorderSizePixel = 0
assemblyPanel.Visible = false
assemblyPanel.Parent = detail
corner(assemblyPanel, 6)
stroke(assemblyPanel)

local assemblyTitle = Instance.new("TextLabel")
assemblyTitle.Size = UDim2.new(1, -8, 0, 18)
assemblyTitle.Position = UDim2.fromOffset(6, 4)
assemblyTitle.BackgroundTransparency = 1
assemblyTitle.Font = Enum.Font.GothamBold
assemblyTitle.TextSize = 11
assemblyTitle.TextColor3 = COL_MUTED
assemblyTitle.TextXAlignment = Enum.TextXAlignment.Left
assemblyTitle.Text = "FRAME EDIT (remove / gem)"
assemblyTitle.Parent = assemblyPanel

local partSlots = { "handle", "blade", "pommel" }
local partButtons: { [string]: TextButton } = {}
for i, slotName in partSlots do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(88, 36)
	btn.Position = UDim2.fromOffset(6 + (i - 1) * 94, 24)
	btn.BackgroundColor3 = COL_SLOT
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 9
	btn.TextColor3 = COL_TEXT
	btn.Text = string.upper(slotName) .. "\n(empty)"
	btn.Parent = assemblyPanel
	corner(btn, 4)
	partButtons[slotName] = btn
	btn.MouseButton1Click:Connect(function()
		beginAssemblyPick(slotName)
		refreshInventory()
	end)
	btn.MouseButton2Click:Connect(function()
		if not selectedUuid then
			return
		end
		for _, item in snapshot.items do
			if item.uuid == selectedUuid and item.defId == "weapon_frame" and item.parts then
				local partUuid = (item.parts :: any)[slotName]
				if partUuid then
					RemoveWeaponPart:FireServer(selectedUuid, slotName)
					clearAssemblyPick()
				end
				break
			end
		end
	end)

	local removeBtn = Instance.new("TextButton")
	removeBtn.Name = "RemovePart"
	removeBtn.Size = UDim2.fromOffset(16, 16)
	removeBtn.Position = UDim2.new(1, -18, 0, 2)
	removeBtn.BackgroundColor3 = Color3.fromRGB(130, 60, 60)
	removeBtn.BorderSizePixel = 0
	removeBtn.Font = Enum.Font.GothamBold
	removeBtn.TextSize = 12
	removeBtn.TextColor3 = COL_TEXT
	removeBtn.Text = "-"
	removeBtn.ZIndex = 2
	removeBtn.Parent = btn
	corner(removeBtn, 3)
	removeBtn.MouseButton1Click:Connect(function()
		if not selectedUuid then
			return
		end
		for _, item in snapshot.items do
			if item.uuid == selectedUuid and item.defId == "weapon_frame" and item.parts then
				local partUuid = (item.parts :: any)[slotName]
				if partUuid then
					RemoveWeaponPart:FireServer(selectedUuid, slotName)
					clearAssemblyPick()
				end
				break
			end
		end
	end)
end

local gemBtn = Instance.new("TextButton")
gemBtn.Size = UDim2.fromOffset(88, 36)
gemBtn.Position = UDim2.fromOffset(6, 66)
gemBtn.BackgroundColor3 = COL_SLOT
gemBtn.BorderSizePixel = 0
gemBtn.Font = Enum.Font.Gotham
gemBtn.TextSize = 9
gemBtn.TextColor3 = COL_TEXT
gemBtn.Text = "GEM\n(empty)"
gemBtn.Parent = assemblyPanel
corner(gemBtn, 4)

local unsocketBtn = Instance.new("TextButton")
unsocketBtn.Size = UDim2.fromOffset(88, 28)
unsocketBtn.Position = UDim2.fromOffset(100, 70)
unsocketBtn.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
unsocketBtn.BorderSizePixel = 0
unsocketBtn.Font = Enum.Font.GothamBold
unsocketBtn.TextSize = 9
unsocketBtn.TextColor3 = COL_TEXT
unsocketBtn.Text = "Unsocket Gem"
unsocketBtn.Parent = assemblyPanel
corner(unsocketBtn, 4)

local createFrameBtn = Instance.new("TextButton")
createFrameBtn.Size = UDim2.fromOffset(100, 28)
createFrameBtn.Position = UDim2.fromOffset(196, 70)
createFrameBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
createFrameBtn.BorderSizePixel = 0
createFrameBtn.Font = Enum.Font.GothamBold
createFrameBtn.TextSize = 9
createFrameBtn.TextColor3 = COL_TEXT
createFrameBtn.Text = "+ New Frame"
createFrameBtn.Parent = assemblyPanel
corner(createFrameBtn, 4)

unsocketBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	showGemUnsocketConfirm(selectedUuid)
end)

createFrameBtn.MouseButton1Click:Connect(function()
	CreateWeaponFrame:FireServer()
end)

equipBtn.Size = UDim2.new(0.48, -6, 0, 32)
equipBtn.Position = UDim2.new(0, 10, 1, -78)
discardBtn.Size = UDim2.new(0.48, -6, 0, 32)
discardBtn.Position = UDim2.new(0.52, 0, 1, -78)

equipBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	local defId = nil
	for _, item in snapshot.items do
		if item.uuid == selectedUuid then
			defId = item.defId
			break
		end
	end
	local slot = if defId then suggestSlot(defId) else "main"
	if slot then
		EquipItem:FireServer(selectedUuid, slot)
	end
end)

discardBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	DiscardItem:FireServer(selectedUuid)
	selectedUuid = nil
end)

openBoxBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	if not OpenLootBox then
		UiToast.Show("Lootbox open unavailable.", 2, "error")
		return
	end
	OpenLootBox:FireServer(selectedUuid)
end)

local LOOTBOX_ERRORS = {
	NoItem = "Lootbox not found.",
	NotLootBox = "Not a lootbox.",
	BadPool = "Invalid loot pool.",
	Installed = "Remove installed parts first.",
	Equipped = "Unequip the lootbox first.",
	EmptyRoll = "Loot pool is empty.",
	RemoveFailed = "Could not consume lootbox.",
	GrantFailed = "Could not grant reward.",
}
if LootBoxResult then
	LootBoxResult.OnClientEvent:Connect(function(result: any)
		if typeof(result) ~= "table" then
			return
		end
		if result.ok then
			local rewardName = "item"
			if typeof(result.reward) == "table" and typeof(result.reward.defId) == "string" then
				local rewardDef = ItemDefs.Get(result.reward.defId)
				rewardName = if rewardDef and rewardDef.name then rewardDef.name else result.reward.defId
			end
			UiToast.Show(`Opened! Got {rewardName}`, 3, "success")
			selectedUuid = nil
			refreshDetail()
		else
			local reason = if typeof(result.reason) == "string" then result.reason else "Error"
			local msg = LOOTBOX_ERRORS[reason] or reason
			UiToast.Show(msg, 2.5, "error")
			detailDesc.Text = msg
		end
	end)
end

tradeBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	TradeUI.OpenInvite(selectedUuid)
end)

upgradeBtn.MouseButton1Click:Connect(function()
	if not selectedUuid then
		return
	end
	if not PlaceRuntime.IsLobby() then
		UiToast.Show("Upgrades are lobby-only.", 2, "warn")
		return
	end
	if not UpgradeItem then
		UiToast.Show("Upgrade service not ready.", 2, "error")
		return
	end
	UpgradeItem:FireServer(selectedUuid)
end)

-- ========== REFRESH ==========

local function matchesInvFilter(defId: string): boolean
	if pendingInstallSlot then
		return matchesAssemblyPick(defId)
	end
	if invFilter == "All" then
		return true
	end
	local def = ItemDefs.Get(defId)
	if not def then
		return false
	end
	if invFilter == "Frames" then
		return defId == "weapon_frame"
	elseif invFilter == "Handles" then
		return def.kind == "WeaponHandle"
	elseif invFilter == "Blades" then
		return def.kind == "WeaponBlade"
	elseif invFilter == "Pommels" then
		return def.kind == "WeaponPommel"
	elseif invFilter == "Gems" then
		return def.kind == "ElementGem"
	end
	return true
end

local function abilityName(id: string?): string
	if not id then
		return ""
	end
	for _, a in snapshot.actives do
		if a.abilityId == id then
			return a.name
		end
	end
	return id
end

local function refreshStats()
	local s = snapshot.stats
	levelLabel.Text = `Level {s.level or 1}`
	local xp = snapshot.xpProgress
	if typeof(xp) == "table" and typeof(xp.xpToNext) == "number" and xp.xpToNext > 0 then
		local into = math.max(0, math.floor(xp.xpIntoLevel or 0))
		local need = math.max(1, math.floor(xp.xpToNext))
		xpBarFill.Size = UDim2.fromScale(math.clamp(into / need, 0, 1), 1)
		xpBarLabel.Text = `XP {into} / {need}`
		xpBarBg.Visible = true
		xpBarLabel.Visible = true
	elseif typeof(xp) == "table" and (xp.xpToNext or 0) == 0 then
		xpBarFill.Size = UDim2.fromScale(1, 1)
		xpBarLabel.Text = "MAX LEVEL"
		xpBarBg.Visible = true
		xpBarLabel.Visible = true
	else
		xpBarBg.Visible = false
		xpBarLabel.Visible = false
	end
	local unspent = if typeof(s.unspent) == "number" then s.unspent else 0
	if unspent > 0 then
		unspentLabel.Visible = true
		unspentLabel.Text = `{unspent} stat point{if unspent == 1 then "" else "s"} to spend`
	else
		unspentLabel.Visible = false
		unspentLabel.Text = ""
	end
	for _, key in { "STR", "DEX", "VIT", "INT" } do
		local row = primaryLabels[key]
		local plus = statPlusBtns[key]
		if row then
			row.Text = `  {key}   {s[key] or 0}`
		end
		if plus then
			plus.Visible = unspent > 0
			plus.BackgroundColor3 = if unspent > 0 then C.SuccessDark else Color3.fromRGB(60, 60, 68)
		end
	end
	local d = snapshot.derived
	local band = (d and d.synergyBand) or "None"
	local bandColor = SYNERGY_COLORS[band] or COL_MUTED
	local bandText = band
	if band == "Pure" and d.synergyElement then
		bandText = `Pure ({d.synergyElement})`
	elseif (band == "Duality" or band == "Harmony") and d.synergyElements then
		bandText = `{band} ({table.concat(d.synergyElements, " · ")})`
	end
	synergyBandLabel.Text = `Band: {bandText}`
	synergyBandLabel.TextColor3 = bandColor
	synergyPerkLabel.Text = (d and d.synergyPerk) or ""
	synergyPerkLabel.TextColor3 = if band == "None" then COL_MUTED else Color3.fromRGB(170, 175, 190)
	local secs = secondaryFromStats()
	for i, row in secondaryLabels do
		local entry = secs[i]
		if entry then
			row.Text = `{entry[1]}:  {entry[2]}`
			row.TextColor3 = entry[3]
		else
			row.Text = ""
		end
	end
	statsBody.CanvasSize = UDim2.fromOffset(0, statsList.AbsoluteContentSize.Y + 12)
end

refreshGear = function()
	for _, slotId in LoadoutSlots.Order do
		local btn = gearButtons[slotId]
		local label = gearLabels[slotId]
		if btn and label then
			local uuid = snapshot.loadout[slotId]
			local iconHost = btn:FindFirstChild("IconHost")
			if uuid then
				local frameItem = findItemByUuid(uuid)
				local defId = frameItem and frameItem.defId
				local resolved = frameItem and resolveWeaponFrame(frameItem)
				local displayName = frameDisplayName(frameItem, resolved)
				if slotId == "main" and snapshot.resolvedMain and snapshot.resolvedMain.displayName then
					displayName = shortName(snapshot.resolvedMain.displayName, 10)
				elseif frameItem and frameItem.defId == "weapon_frame" then
					displayName = shortName(displayName, 10)
				else
					local def = defId and ItemDefs.Get(defId)
					displayName = shortName(def and def.name or "?", 10)
				end
				label.Text = displayName
				btn.BackgroundColor3 = COL_SLOT_EQ
				if iconHost and iconHost:IsA("GuiObject") and frameItem then
					mountItemIcon(iconHost, frameItem, { zIndex = 2, yawDeg = 40, pitchDeg = -18 })
				end
			else
				label.Text = ""
				btn.BackgroundColor3 = if selectedUuid then COL_SLOT_SEL else COL_SLOT
				if iconHost and iconHost:IsA("GuiObject") then
					ItemIcon.Clear(iconHost)
				end
			end
		end
	end
end

refreshDetail = function()
	if not selectedUuid then
		detailTitle.Text = "Select an item"
		detailDesc.Text = "Click an inventory slot to inspect."
		ItemIcon.Clear(detailIconHost)
		assemblyPanel.Visible = false
		upgradeBtn.Visible = false
		openBoxBtn.Visible = false
		tradeBtn.Visible = false
		return
	end
	local itemData = nil
	for _, item in snapshot.items do
		if item.uuid == selectedUuid then
			itemData = item
			break
		end
	end
	local defId = itemData and itemData.defId
	local def = defId and ItemDefs.Get(defId)
	local isFrame = defId == "weapon_frame"
	local upgradeLevel = if itemData and typeof((itemData :: any).upgradeLevel) == "number"
		then (itemData :: any).upgradeLevel
		else 0
	local canUpgrade = def and def.kind == "WeaponBlade"
	local isLootBox = def and def.kind == "LootBox"
	upgradeBtn.Visible = canUpgrade == true and not isLootBox and PlaceRuntime.IsLobby()
	openBoxBtn.Visible = isLootBox == true
	tradeBtn.Visible = isLootBox == true and def.tradeable ~= false
	equipBtn.Visible = not isLootBox
	if canUpgrade then
		local cost = UpgradeDefs.CostPremiumPerLevel
		local maxLvl = UpgradeDefs.MaxLevel
		local pct = math.floor(UpgradeDefs.DamagePctPerLevel * 100 + 0.5)
		if upgradeLevel >= maxLvl then
			upgradeBtn.Text = `+{upgradeLevel} MAX (+{pct}%/lvl applied)`
			upgradeBtn.BackgroundColor3 = Color3.fromRGB(70, 74, 82)
		else
			upgradeBtn.Text = `Upgrade +{upgradeLevel}→{upgradeLevel + 1}  ({cost} premium, +{pct}% DMG)`
			upgradeBtn.BackgroundColor3 = Color3.fromRGB(90, 120, 200)
		end
	end
	assemblyPanel.Visible = isFrame

	local isMainEquipped = selectedUuid ~= nil and snapshot.loadout.main == selectedUuid
	local frameResolved = if isFrame and itemData then resolveWeaponFrame(itemData) else nil
	local tipResolved = if frameResolved and frameResolved.complete then frameResolved else nil

	detailTitle.Text = if isFrame and itemData
		then frameDisplayName(itemData, frameResolved)
		else (def and def.name or (defId or "?"))

	detailDesc.Text = ItemTooltip.Build({
		defId = defId,
		def = def,
		itemData = itemData,
		resolvedMain = tipResolved,
		isEquippedMain = isMainEquipped,
	})

	if isFrame and itemData and itemData.parts then
			for _, slotName in { "handle", "blade", "pommel" } do
				local partUuid = (itemData.parts :: any)[slotName]
				local partName = "(empty)"
				if partUuid then
					for _, pi in snapshot.items do
						if pi.uuid == partUuid then
							local pd = ItemDefs.Get(pi.defId)
							partName = pd and pd.name or pi.defId
							break
						end
					end
				end
				local btn = partButtons[slotName]
				if btn then
					btn.Text = string.upper(slotName) .. "\n" .. shortName(partName, 10)
					if pendingInstallSlot == slotName and assemblyFrameUuid == selectedUuid then
						btn.BackgroundColor3 = COL_PENDING
					else
						btn.BackgroundColor3 = COL_SLOT
					end
				end
			end
			local gemName = "(empty)"
			if itemData.gemUuid then
				for _, gi in snapshot.items do
					if gi.uuid == itemData.gemUuid then
						local gd = ItemDefs.Get(gi.defId)
						gemName = gd and gd.name or gi.defId
						break
					end
				end
			end
			gemBtn.Text = "GEM\n" .. shortName(gemName, 10)
			local oldGemBadge = gemBtn:FindFirstChild("GemBadge")
			if oldGemBadge then
				oldGemBadge:Destroy()
			end
			if okGemSymbol and GemSymbol and frameResolved and frameResolved.element and frameResolved.element ~= "Neutral" then
				GemSymbol.Mount({
					parent = gemBtn,
					element = frameResolved.element,
					size = UDim2.fromOffset(14, 14),
					position = UDim2.new(1, -4, 0, 4),
					zIndex = 4,
				})
			end
			if pendingInstallSlot then
				assemblyTitle.Text = `PICK {string.upper(pendingInstallSlot)} FROM BAG`
				assemblyTitle.TextColor3 = COL_PENDING
			else
				assemblyTitle.Text = "WEAPON ASSEMBLY"
				assemblyTitle.TextColor3 = COL_MUTED
			end
	elseif isFrame then
		assemblyTitle.Text = "WEAPON ASSEMBLY"
		assemblyTitle.TextColor3 = COL_MUTED
	end
	if itemData then
		mountItemIcon(detailIconHost, itemData, { zIndex = 2, yawDeg = 38, pitchDeg = -20, distanceMul = 1.7 })
	else
		ItemIcon.Clear(detailIconHost)
	end
end

refreshSkills = function()
	for i = 1, HotbarConfig.SlotCount do
		local btn = skillButtons[i]
		local id = snapshot.hotbar[i]
		local key = HotbarConfig.Labels[i]
		if id then
			btn.Text = key .. "\n" .. shortName(abilityName(id), 7)
			btn.BackgroundColor3 = COL_SLOT_EQ
		else
			btn.Text = key
			btn.BackgroundColor3 = if selectedAbility then COL_SLOT_SEL else COL_SLOT
		end
	end
	for _, child in abilityStrip:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local w = 0
	for i, a in snapshot.actives do
		local chip = Instance.new("TextButton")
		chip.Size = UDim2.fromOffset(100, 22)
		chip.BackgroundColor3 = if selectedAbility == a.abilityId then COL_SLOT_SEL else COL_SLOT
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.Gotham
		chip.TextSize = 10
		chip.TextColor3 = COL_TEXT
		chip.Text = shortName(a.name, 12)
		chip.LayoutOrder = i
		chip.Parent = abilityStrip
		corner(chip, 4)
		chip.MouseEnter:Connect(function()
			local title, body = AbilityTooltip.Build(a.abilityId, { name = a.name, desc = a.desc })
			HoverTooltip.show(title, body, chip)
		end)
		chip.MouseLeave:Connect(function()
			HoverTooltip.hide()
		end)
		chip.MouseButton1Click:Connect(function()
			selectedAbility = if selectedAbility == a.abilityId then nil else a.abilityId
			selectedUuid = nil
			refreshSkills()
			refreshInventory()
			refreshGear()
			refreshDetail()
		end)
		w += 104
	end
	abilityStrip.CanvasSize = UDim2.fromOffset(w, 0)
end

refreshInventory = function()
	for _, child in invGrid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local visible = {}
	for _, item in snapshot.items do
		if not item.installedIn and not isUuidInForge(item.uuid) and matchesInvFilter(item.defId) then
			table.insert(visible, item)
		end
	end

	local count = math.max(#visible, 16)
	for i = 1, count do
		local item = visible[i]
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = COL_SLOT
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = item ~= nil
		btn.LayoutOrder = i
		btn.Parent = invGrid
		corner(btn, 6)
		stroke(btn, Color3.fromRGB(70, 74, 82))
		if item then
			local def = ItemDefs.Get(item.defId)
			local resolved = if item.defId == "weapon_frame" then resolveWeaponFrame(item) else nil
			local name = frameDisplayName(item, resolved)
			local equipped = isEquipped(item.uuid)
			local selected = selectedUuid == item.uuid
			btn.BackgroundColor3 = if selected
				then COL_SLOT_SEL
				elseif equipped then COL_SLOT_EQ
				else COL_SLOT

			local iconHost = Instance.new("Frame")
			iconHost.Name = "IconHost"
			iconHost.Size = UDim2.new(1, -4, 1, -16)
			iconHost.Position = UDim2.fromOffset(2, 2)
			iconHost.BackgroundTransparency = 1
			iconHost.ZIndex = 2
			iconHost.Parent = btn
			mountItemIcon(iconHost, item, { zIndex = 2, yawDeg = 36, pitchDeg = -18 })

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -4, 0, 12)
			label.Position = UDim2.new(0, 2, 1, -13)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextSize = 8
			label.TextColor3 = COL_TEXT
			label.Text = shortName(name, 10)
			label.ZIndex = 4
			label.Parent = btn

			if okHoverTip and HoverTooltip and okTooltip and ItemTooltip then
				btn.MouseEnter:Connect(function()
					local frameRes = if item.defId == "weapon_frame" then resolveWeaponFrame(item) else nil
					local title = frameDisplayName(item, frameRes)
					local body = ItemTooltip.Build({
						defId = item.defId,
						def = def,
						itemData = item,
						resolvedMain = if frameRes and frameRes.complete then frameRes else nil,
					})
					HoverTooltip.show(title, body, btn)
				end)
				btn.MouseLeave:Connect(function()
					HoverTooltip.hide()
				end)
			end

			btn.MouseButton1Click:Connect(function()
				local frameUuid = assemblyFrameUuid or selectedUuid
				if pendingInstallSlot and frameUuid and item.defId ~= "weapon_frame" then
					if not matchesAssemblyPick(item.defId) then
						UiToast.Show("Incompatible part for this slot.", 2, "error")
						return
					end
					InstallWeaponPart:FireServer(frameUuid, item.uuid, pendingInstallSlot)
					clearAssemblyPick()
					invFilter = "All"
					selectedUuid = frameUuid
					refreshInventory()
					return
				end
				local gemDef = ItemDefs.Get(item.defId)
				if gemDef and gemDef.kind == "ElementGem" then
					if selectedUuid then
						for _, it in snapshot.items do
							if it.uuid == selectedUuid and it.defId == "weapon_frame" then
								SocketGem:FireServer(selectedUuid, item.uuid)
								return
							end
						end
					end
					if snapshot.loadout.main then
						SocketGem:FireServer(snapshot.loadout.main, item.uuid)
						return
					end
				end
				local newSelected = if selectedUuid == item.uuid then nil else item.uuid
				selectedUuid = newSelected
				if newSelected and newSelected ~= assemblyFrameUuid then
					clearAssemblyPick()
				end
				if newSelected and TradeUI.IsActive() then
					TradeUI.AddSelected(newSelected)
				end
				selectedAbility = nil
				refreshInventory()
				refreshGear()
				refreshSkills()
				refreshDetail()
			end)
		end
	end
	local rows = math.ceil(count / 4)
	invGrid.CanvasSize = UDim2.fromOffset(0, rows * 69 + 12)
	refreshFilterBar()
	refreshDetail()
end

refreshFilterBar = function()
	for id, btn in filterButtons do
		btn.BackgroundColor3 = if invFilter == id then COL_SLOT_SEL else COL_SLOT
	end
end

for idx, opt in FILTER_OPTIONS do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(52, 24)
	btn.BackgroundColor3 = COL_SLOT
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.TextColor3 = COL_TEXT
	btn.Text = opt.label
	btn.LayoutOrder = idx
	btn.Parent = filterBar
	corner(btn, 4)
	filterButtons[opt.id] = btn
	btn.MouseButton1Click:Connect(function()
		invFilter = opt.id
		refreshInventory()
	end)
end

local function applySnapshot(data: any)
	if typeof(data) ~= "table" then
		return
	end
	snapshot.items = data.items or {}
	snapshot.loadout = data.loadout or {}
	snapshot.hotbar = data.hotbar or {}
	snapshot.actives = data.actives or {}
	if typeof(data.stats) == "table" then
		snapshot.stats = data.stats
	end
	if typeof(data.derived) == "table" then
		snapshot.derived = data.derived
	end
	snapshot.resolvedMain = data.resolvedMain
	if typeof(data.premiumCurrency) == "number" then
		snapshot.premiumCurrency = data.premiumCurrency
	end
	if typeof(data.gemPreserveUnsocketCost) == "number" then
		snapshot.gemPreserveUnsocketCost = data.gemPreserveUnsocketCost
	end
	if typeof(data.xpProgress) == "table" then
		snapshot.xpProgress = data.xpProgress
	end
	if selectedUuid then
		local found = false
		for _, item in snapshot.items do
			if item.uuid == selectedUuid then
				found = true
				break
			end
		end
		if not found then
			selectedUuid = nil
		end
	end
	if forgeApi then
		forgeApi.pruneAfterSnapshot(findItemByUuid, function()
			if pendingForgeNeutral then
				UiToast.Show("Weapon forged (Neutral — no gem).", 3, "success")
				pendingForgeNeutral = false
			elseif pendingForgeResult and pendingForgeResult.gemSkipped then
				UiToast.Show("Weapon forged (Neutral — gem not applied).", 3, "warn")
			else
				UiToast.Show("Weapon forged!", 2, "success")
			end
			pendingForgeResult = nil
		end)
	end
	refreshStats()
	refreshForge()
	refreshInventory()
	refreshGear()
	refreshSkills()
	if open then
		refreshPreview()
	end
end

local function setOpen(state: boolean)
	open = state
	root.Visible = open
	if not open then
		setGlossaryOpen(false)
	end
	if open then
		refreshPreview()
		refreshStats()
		refreshForge()
		refreshInventory()
		refreshGear()
		refreshSkills()
	else
		clearPreview()
		selectedUuid = nil
		selectedAbility = nil
		clearForgeAttached()
	end
end

if loadCloseBtn then
	loadCloseBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end)
end

InventoryUpdated.OnClientEvent:Connect(applySnapshot)

ForgeResult.OnClientEvent:Connect(function(result: any)
	if typeof(result) ~= "table" then
		return
	end
	if result.ok ~= true then
		pendingForgeResult = nil
		pendingForgeNeutral = false
		UiToast.Show(forgeErrorMessage(result.code), 3, "error")
		return
	end
	pendingForgeResult = {
		ok = true,
		gemSkipped = result.gemSkipped,
	}
end)

task.spawn(function()
	local ok, data = pcall(function()
		return GetSnapshot:InvokeServer()
	end)
	if ok then
		applySnapshot(data)
	end
end)

player.CharacterAdded:Connect(function()
	if open then
		task.defer(refreshPreview)
	end
end)

UserInputService.InputBegan:Connect(function(input, _gp)
	if isTyping() then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		if player:GetAttribute("LoadoutLocked") == true then
			return
		end
		setOpen(not open)
		return
	end
	if input.KeyCode == Enum.KeyCode.G and open then
		glossaryBody.Text = GameGlossary.FormatAll()
		setGlossaryOpen(not glossaryOpen)
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape and open then
		if glossaryOpen then
			setGlossaryOpen(false)
			return
		end
		setOpen(false)
	end
end)

local quickGui = UiTheme.ScreenGui({
	name = "GearQuickBar",
	displayOrder = UiTheme.DisplayOrder.GearQuickBar,
	ignoreInset = false,
})
quickGui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "GearToggleBar"
bar.Size = UDim2.fromOffset(132, 36)
bar.Position = UDim2.new(0.5, -66, 1, -132)
bar.BackgroundColor3 = COL_BG
bar.BorderSizePixel = 0
bar.Parent = quickGui
corner(bar, 8)
stroke(bar)

local gearBtn = Instance.new("TextButton")
gearBtn.Size = UDim2.fromOffset(120, 28)
gearBtn.Position = UDim2.fromOffset(6, 4)
gearBtn.BackgroundColor3 = COL_SLOT
gearBtn.BorderSizePixel = 0
gearBtn.Font = Enum.Font.GothamBold
gearBtn.TextSize = 12
gearBtn.TextColor3 = COL_TEXT
gearBtn.Text = "Gear (I)"
gearBtn.Parent = bar
corner(gearBtn, 6)
gearBtn.MouseButton1Click:Connect(function()
	if player:GetAttribute("LoadoutLocked") == true then
		return
	end
	setOpen(not open)
end)

local lockBadge = Instance.new("TextLabel")
lockBadge.Name = "LoadoutLock"
lockBadge.Size = UDim2.new(1, -12, 0, 14)
lockBadge.Position = UDim2.fromOffset(6, -16)
lockBadge.BackgroundTransparency = 1
lockBadge.Font = Enum.Font.GothamBold
lockBadge.TextSize = 10
lockBadge.TextColor3 = COL_DANGER
lockBadge.Text = "Loadout locked"
lockBadge.Visible = false
lockBadge.Parent = bar

local function refreshLoadoutLock()
	local locked = player:GetAttribute("LoadoutLocked") == true
	lockBadge.Visible = locked
	if locked and open then
		setOpen(false)
	end
end

player:GetAttributeChangedSignal("LoadoutLocked"):Connect(refreshLoadoutLock)
refreshLoadoutLock()

print("[GearUI] Stats | Loadout | Inventory+Forge — I")
