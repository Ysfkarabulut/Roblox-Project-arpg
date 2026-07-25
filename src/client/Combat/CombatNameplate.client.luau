--[[
	Combat nameplates — Boss / PvP / Training / Players (MMORPG overhead UI).
	Status: symbol icon + duration strip · HP bar with themed chrome.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NameplateConfig = require(game.ReplicatedStorage.Shared.Config.NameplateConfig)
local ReactionTable = require(game.ReplicatedStorage.Shared.Config.ReactionTable)
local StatusIconArt = require(script.Parent.StatusIconArt)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)

local C = UiTheme.Colors
local N = UiTheme.Nameplate

local localPlayer = Players.LocalPlayer

type PlateParts = {
	bb: BillboardGui,
	statusRow: Frame,
	nameLabel: TextLabel,
	barBg: Frame,
	barFill: Frame,
	barText: TextLabel,
	statusSlots: { Frame },
	kind: string,
}

local plates: { [Model]: PlateParts } = {}

local function getAdornee(model: Model): BasePart?
	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return model:FindFirstChildWhichIsA("BasePart")
end

local function resolveKind(model: Model): string?
	local kind = model:GetAttribute("NameplateKind")
	if typeof(kind) == "string" and kind ~= "" then
		return kind
	end
	if model:GetAttribute("IsBoss") then
		return "Boss"
	end
	if model:GetAttribute("IsBossAdd") then
		return "BossAdd"
	end
	if model:GetAttribute("IsPvpOpponent") then
		return "Pvp"
	end
	if model:GetAttribute("IsCombatDummy") then
		return "Training"
	end
	local plr = Players:GetPlayerFromCharacter(model)
	if plr then
		if plr:GetAttribute("PvpTeam") or model:GetAttribute("NameplateKind") == "Pvp" then
			return "Pvp"
		end
		return "Player"
	end
	return nil
end

local function shouldShow(model: Model): boolean
	local kind = resolveKind(model)
	if not kind then
		return false
	end
	if kind == "Training" or kind == "Boss" or kind == "BossAdd" then
		return true
	end
	if kind == "Player" then
		local plr = Players:GetPlayerFromCharacter(model)
		if not plr or plr == localPlayer then
			return false
		end
		local myTeam = localPlayer:GetAttribute("PvpTeam")
		local theirTeam = plr:GetAttribute("PvpTeam")
		if myTeam and theirTeam and myTeam == theirTeam then
			return false
		end
		return true
	end
	local plr = Players:GetPlayerFromCharacter(model)
	if not plr then
		return kind == "Pvp"
	end
	if plr == localPlayer then
		return false
	end
	local myTeam = localPlayer:GetAttribute("PvpTeam")
	local theirTeam = plr:GetAttribute("PvpTeam")
	if not myTeam and not theirTeam then
		return false
	end
	if myTeam and theirTeam and myTeam == theirTeam then
		return false
	end
	return true
end

local function parseStatuses(raw: any): { any }
	if typeof(raw) ~= "string" or raw == "" then
		return {}
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or typeof(data) ~= "table" then
		return {}
	end
	return data
end

local function makeText(parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = UiTheme.Font.Title
	t.TextStrokeTransparency = 0.4
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = parent
	return t
end

local function buildStatusSlot(parent: Frame): Frame
	local slot = Instance.new("Frame")
	slot.Size = UDim2.fromOffset(28, 32)
	slot.BackgroundTransparency = 1
	slot.Parent = parent

	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(26, 26)
	icon.Position = UDim2.new(0.5, -13, 0, 0)
	icon.BorderSizePixel = 0
	icon.Parent = slot
	UiTheme.Corner(icon, UiTheme.Radius.Sm)
	UiTheme.Stroke(icon, { color = C.StrokeSoft, thickness = 1.5 })

	local artHost = Instance.new("Frame")
	artHost.Name = "ArtHost"
	artHost.Size = UDim2.new(1, 0, 1, -11)
	artHost.Position = UDim2.fromOffset(0, 0)
	artHost.BackgroundTransparency = 1
	artHost.ClipsDescendants = true
	artHost.Parent = icon

	local timeStrip = Instance.new("Frame")
	timeStrip.Name = "TimeStrip"
	timeStrip.Size = UDim2.new(1, 0, 0, 11)
	timeStrip.Position = UDim2.new(0, 0, 1, -11)
	timeStrip.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	timeStrip.BackgroundTransparency = 0.35
	timeStrip.BorderSizePixel = 0
	timeStrip.Parent = icon
	UiTheme.Corner(timeStrip, UiTheme.Radius.Xs)

	local timeLbl = makeText(timeStrip, {
		Name = "Time",
		Size = UDim2.fromScale(1, 1),
		TextSize = 9,
		TextColor3 = N.TextOnBar,
		Text = "",
		Font = UiTheme.Font.Title,
	})

	return slot
end

local function createPlate(model: Model, kind: string): PlateParts?
	local adornee = getAdornee(model)
	if not adornee then
		return nil
	end
	local style = NameplateConfig.StyleForKind(kind)
	local chromePad = if style.showChrome then 4 else 0
	local totalH = style.statusRowH + style.nameH + style.barH + 6 + chromePad

	local bb = Instance.new("BillboardGui")
	bb.Name = "CombatNameplate"
	bb.Size = UDim2.fromOffset(style.width, totalH)
	bb.StudsOffset = style.studsOffset
	bb.AlwaysOnTop = false
	bb.MaxDistance = style.maxDistance or if kind == "Boss" then 400 else 120
	bb.Adornee = adornee
	bb.Parent = adornee

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = bb

	local statusRow = Instance.new("Frame")
	statusRow.Name = "StatusRow"
	statusRow.Size = UDim2.new(1, 0, 0, style.statusRowH)
	statusRow.BackgroundTransparency = 1
	statusRow.Parent = root
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = statusRow

	local statusSlots: { Frame } = {}
	for i = 1, NameplateConfig.MaxStatusSlots do
		local slot = buildStatusSlot(statusRow)
		slot.LayoutOrder = i
		slot.Visible = false
		statusSlots[i] = slot
	end

	local bodyY = style.statusRowH
	local bodyParent: Instance = root

	if style.showChrome then
		local chrome = Instance.new("Frame")
		chrome.Name = "Chrome"
		chrome.Size = UDim2.new(1, -2, 0, style.nameH + style.barH + chromePad + 4)
		chrome.Position = UDim2.fromOffset(1, bodyY)
		chrome.BackgroundColor3 = N.ChromeBg
		chrome.BackgroundTransparency = N.ChromeTransparency
		chrome.BorderSizePixel = 0
		chrome.Parent = root
		UiTheme.Corner(chrome, UiTheme.Radius.Sm)
		UiTheme.Stroke(chrome, { color = C.StrokeSoft, thickness = 1 })
		bodyParent = chrome
		bodyY = 2
	end

	local nameLabel = makeText(bodyParent, {
		Name = "Name",
		Size = UDim2.new(1, -8, 0, style.nameH),
		Position = UDim2.fromOffset(4, bodyY),
		TextSize = if kind == "Boss" then UiTheme.TextSize.Subtitle + 2 else UiTheme.TextSize.Subtitle,
		TextColor3 = style.nameColor,
		Text = "",
		Font = UiTheme.Font.Title,
	})

	local barBg = Instance.new("Frame")
	barBg.Name = "HpBar"
	barBg.Size = UDim2.new(1, -10, 0, style.barH)
	barBg.Position = UDim2.new(0, 5, 0, bodyY + style.nameH + 2)
	barBg.BackgroundColor3 = style.hpBg
	barBg.BorderSizePixel = 0
	barBg.Parent = bodyParent
	UiTheme.Corner(barBg, UiTheme.Radius.Xs)
	UiTheme.Stroke(barBg, { color = C.StrokeLight, thickness = 1 })

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = style.hpFill
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	UiTheme.Corner(barFill, UiTheme.Radius.Xs)

	local barText = makeText(barBg, {
		Name = "HpText",
		Size = UDim2.fromScale(1, 1),
		TextSize = if kind == "Boss" then UiTheme.TextSize.Body else UiTheme.TextSize.Caption,
		TextColor3 = N.TextOnBar,
		Text = "",
		ZIndex = 2,
		Font = UiTheme.Font.Title,
	})

	if kind == "Player" then
		local plr = Players:GetPlayerFromCharacter(model)
		if plr then
			nameLabel.Text = plr.DisplayName
		end
	end

	return {
		bb = bb,
		statusRow = statusRow,
		nameLabel = nameLabel,
		barBg = barBg,
		barFill = barFill,
		barText = barText,
		statusSlots = statusSlots,
		kind = kind,
	}
end

local function readHp(model: Model): (number, number)
	local attrHp = tonumber(model:GetAttribute("NameplateHp"))
	local attrMax = tonumber(model:GetAttribute("NameplateMaxHp"))
	if attrHp and attrMax and attrMax > 0 then
		return attrHp, attrMax
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum.Health, math.max(1, hum.MaxHealth)
	end
	return 0, 1
end

local function formatHpText(kind: string, hp: number, maxHp: number, pct: number): string
	local style = NameplateConfig.StyleForKind(kind)
	if style.showAbsHp and style.showPctInBar then
		return `{math.floor(pct + 0.5)}%  ({math.floor(hp)}/{math.floor(maxHp)})`
	end
	if style.showAbsHp then
		return `{math.floor(hp)} / {math.floor(maxHp)}`
	end
	if style.showPctInBar then
		return `{math.floor(pct + 0.5)}%`
	end
	return ""
end

local function resolvePartyVisual(plr: Player): (Color3, Color3, string)
	local myPartyId = localPlayer:GetAttribute("PartyId")
	local theirPartyId = plr:GetAttribute("PartyId")
	local grouped = plr:GetAttribute("PartyGrouped") == true
	if typeof(myPartyId) == "string" and myPartyId ~= "" and myPartyId == theirPartyId and grouped then
		local isLeader = plr:GetAttribute("PartyIsLeader") == true
		local prefix = if isLeader then "★ " else "◆ "
		local nameColor = if isLeader then N.PartyLeaderName else N.PartyMemberName
		return nameColor, N.PartyMemberHp, prefix
	end
	return NameplateConfig.StyleForKind("Player").nameColor, NameplateConfig.StyleForKind("Player").hpFill, ""
end

local function updatePlate(model: Model, parts: PlateParts)
	local kind = resolveKind(model) or parts.kind
	local style = NameplateConfig.StyleForKind(kind)

	if kind == "Player" then
		local plr = Players:GetPlayerFromCharacter(model)
		if plr then
			local nameColor, hpFill, prefix = resolvePartyVisual(plr)
			parts.nameLabel.TextColor3 = nameColor
			local display = plr.DisplayName
			if display == "" then
				display = plr.Name
			end
			parts.nameLabel.Text = prefix .. display
			local hp, maxHp = readHp(model)
			local pct = math.clamp(hp / maxHp, 0, 1) * 100
			parts.barFill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
			parts.barText.Text = formatHpText(kind, hp, maxHp, pct)
			parts.barFill.BackgroundColor3 = UiTheme.HpTierColor(pct, hpFill)
			local hum = model:FindFirstChildOfClass("Humanoid")
			parts.barBg.Visible = hum ~= nil
		end
	else
		local name = model:GetAttribute("NameplateName")
		if typeof(name) ~= "string" or name == "" then
			name = model.Name
		end
		if kind == "Boss" then
			local phase = model:GetAttribute("NameplatePhase")
			if typeof(phase) == "number" then
				name = `{name}  ·  P{math.floor(phase)}`
			end
		end
		parts.nameLabel.Text = name

		local hp, maxHp = readHp(model)
		local pct = math.clamp(hp / maxHp, 0, 1) * 100
		parts.barFill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
		parts.barText.Text = formatHpText(kind, hp, maxHp, pct)
		parts.barFill.BackgroundColor3 = UiTheme.HpTierColor(pct, style.hpFill)
		parts.barBg.Visible = true
	end

	local statuses = parseStatuses(model:GetAttribute("NameplateStatuses"))
	for i, slot in parts.statusSlots do
		local entry = statuses[i]
		if entry then
			slot.Visible = true
			local statusId = if typeof(entry.id) == "string" then entry.id else "?"
			local vis = NameplateConfig.StatusVisual(statusId)
			local icon = slot:FindFirstChild("Icon") :: Frame?
			if icon then
				icon.BackgroundColor3 = Color3.fromRGB(entry.r or 180, entry.g or 180, entry.b or 190)
				local stroke = icon:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = if entry.debuff then N.DebuffBorder else N.BuffBorder
					stroke.Thickness = if entry.debuff then 1.8 else 1.4
				end
				local artHost = icon:FindFirstChild("ArtHost") :: Frame?
				if artHost then
					local mergeA, mergeB = ReactionTable.OutputParents(statusId)
					if mergeA and mergeB then
						local visA = NameplateConfig.StatusVisual(mergeA)
						local visB = NameplateConfig.StatusVisual(mergeB)
						icon.BackgroundColor3 = visA.color:Lerp(visB.color, 0.5):Lerp(Color3.fromRGB(20, 22, 28), 0.55)
					else
						icon.BackgroundColor3 = vis.color:Lerp(Color3.fromRGB(18, 20, 26), 0.45)
					end
					StatusIconArt.MountForStatus(artHost, statusId)
				end
				local timeStrip = icon:FindFirstChild("TimeStrip")
				local timeLbl = timeStrip and timeStrip:FindFirstChild("Time") :: TextLabel?
				if timeLbl then
					if typeof(entry.remaining) == "number" then
						local sec = math.ceil(entry.remaining)
						timeLbl.Text = if sec >= 10 then tostring(sec) else string.format("%.1f", entry.remaining)
					else
						timeLbl.Text = "∞"
					end
				end
			end
		else
			slot.Visible = false
		end
	end
end

local function removePlate(model: Model)
	local parts = plates[model]
	if parts then
		if parts.bb and parts.bb.Parent then
			parts.bb:Destroy()
		end
		plates[model] = nil
	end
end

local function tryTrack(model: Model)
	if not model:IsA("Model") or plates[model] then
		return
	end
	local kind = resolveKind(model)
	if not kind then
		return
	end
	local parts = createPlate(model, kind)
	if parts then
		plates[model] = parts
		updatePlate(model, parts)
	end
end

local function scanWorkspace()
	for _, inst in workspace:GetDescendants() do
		if inst:IsA("Model") then
			tryTrack(inst)
		end
	end
end

workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("Model") then
		task.defer(tryTrack, inst)
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		task.defer(tryTrack, char)
	end)
end)

for _, plr in Players:GetPlayers() do
	if plr.Character then
		tryTrack(plr.Character)
	end
	plr.CharacterAdded:Connect(function(char)
		task.defer(tryTrack, char)
	end)
end

scanWorkspace()

RunService.Heartbeat:Connect(function()
	for model, parts in plates do
		if not model.Parent then
			removePlate(model)
			continue
		end
		local kind = resolveKind(model)
		if kind and kind ~= parts.kind then
			removePlate(model)
			tryTrack(model)
			continue
		end
		if shouldShow(model) then
			parts.bb.Enabled = true
			updatePlate(model, parts)
		else
			parts.bb.Enabled = false
		end
	end
end)
