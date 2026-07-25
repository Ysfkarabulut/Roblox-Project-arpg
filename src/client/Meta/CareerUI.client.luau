--[[
	Career / profile panel — lobby only (C toggle).
	Playtime, PvP K/D, MMR tiers, season boss stats, pending reward claim.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local BossEncounterConfig = require(ReplicatedStorage.Shared.Config.BossEncounterConfig)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local UiToast = require(script.Parent.Parent.UI.UiToast)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("CareerRemotes", 30)
if not remotes then
	return
end
local GetCareerSnapshot = remotes:WaitForChild("GetCareerSnapshot") :: RemoteFunction
local ClaimSeasonRewards = remotes:WaitForChild("ClaimSeasonRewards") :: RemoteFunction

local BRACKET_LABELS = { "1v1", "2v2", "3v3" }

local gui = UiTheme.ScreenGui({
	name = "CareerUI",
	displayOrder = UiTheme.DisplayOrder.Career,
	ignoreInset = false,
})
gui.Parent = playerGui

local panel = UiTheme.Panel({
	parent = gui,
	name = "Panel",
	size = UDim2.fromOffset(440, 520),
	position = UDim2.new(0.5, -220, 0.5, -260),
	visible = false,
	radius = UiTheme.Radius.Lg,
})
panel.AnchorPoint = Vector2.new(0.5, 0.5)

local title = UiTheme.Label({
	parent = panel,
	text = "Career (C)",
	size = UDim2.new(1, -24, 0, 28),
	position = UDim2.fromOffset(12, 10),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Title,
})

local closeBtn = UiTheme.Button({
	parent = panel,
	text = "×",
	size = UDim2.fromOffset(28, 28),
	position = UDim2.new(1, -36, 0, 8),
	variant = "muted",
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Title,
})

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Body"
scroll.Size = UDim2.new(1, -24, 1, -96)
scroll.Position = UDim2.fromOffset(12, 44)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 10)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = scroll

local claimBtn = UiTheme.Button({
	parent = panel,
	text = "Claim season rewards",
	size = UDim2.new(1, -24, 0, 36),
	position = UDim2.new(0, 12, 1, -48),
	variant = "success",
	font = UiTheme.Font.Body,
	textSize = UiTheme.TextSize.Body,
})
claimBtn.Visible = false

local function sectionLabel(text: string, order: number)
	local lbl = UiTheme.Label({
		parent = scroll,
		text = text,
		size = UDim2.new(1, -8, 0, 20),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Subtitle,
		color = C.Accent,
	})
	lbl.LayoutOrder = order
	return lbl
end

local function statLine(text: string, order: number, muted: boolean?)
	local lbl = UiTheme.Label({
		parent = scroll,
		text = text,
		size = UDim2.new(1, -8, 0, 18),
		textSize = UiTheme.TextSize.Body,
		color = if muted then C.TextMuted else C.Text,
	})
	lbl.LayoutOrder = order
	return lbl
end

local function clearBody()
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function bossDisplayName(bossId: string): string
	local def = BossEncounterConfig.Get(bossId)
	if def and def.displayName then
		return def.displayName
	end
	return bossId
end

local function renderSnapshot(snap: any)
	clearBody()
	if typeof(snap) ~= "table" then
		statLine("Could not load career data.", 1)
		return
	end

	local order = 0
	order += 1
	sectionLabel("Overview", order)
	order += 1
	statLine(`Playtime · {snap.playtimeText or "—"}`, order)
	order += 1
	statLine(
		`PvP · {snap.pvpKills or 0} kills / {snap.pvpDeaths or 0} deaths · K/D {snap.kdRatio or 0}`,
		order
	)

	order += 1
	sectionLabel("Ranked MMR", order)
	local mmr = snap.mmr
	if typeof(mmr) == "table" then
		for _, bracket in BRACKET_LABELS do
			local row = mmr[bracket]
			if typeof(row) == "table" then
				order += 1
				statLine(`{bracket} · {row.value or 0} ({row.tier or "—"})`, order)
			end
		end
	else
		order += 1
		statLine("No ranked data yet.", order, true)
	end

	local season = snap.season
	if typeof(season) == "table" then
		order += 1
		sectionLabel(`Season · {season.name or season.id or "Current"}`, order)
		order += 1
		statLine(`Season PvP · {season.pvpKills or 0}K / {season.pvpDeaths or 0}D`, order)

		local bossKills = season.bossKills
		if typeof(bossKills) == "table" then
			for bossId, kills in bossKills do
				if typeof(kills) == "number" and kills > 0 then
					order += 1
					statLine(`{bossDisplayName(bossId)} · {kills} kills`, order)
				end
			end
		end

		local bestClears = season.bossBestClears
		if typeof(bestClears) == "table" then
			for bossId, run in bestClears do
				if typeof(run) == "table" and typeof(run.clearTimeText) == "string" then
					local party = if typeof(run.partySize) == "number" then run.partySize else 1
					order += 1
					statLine(
						`Best clear · {bossDisplayName(bossId)} · {run.clearTimeText} ({party}p)`,
						order
					)
				end
			end
		end
	end

	local pending = snap.pendingRewardSeasons
	local hasPending = typeof(pending) == "table" and #pending > 0
	claimBtn.Visible = hasPending
	if hasPending then
		order += 1
		sectionLabel("Season rewards", order)
		for _, seasonId in pending do
			order += 1
			statLine(`Pending claim · {seasonId}`, order, true)
		end
	end
end

local open = false

local function setOpen(value: boolean)
	open = value
	panel.Visible = open
	if open then
		local snap = GetCareerSnapshot:InvokeServer()
		renderSnapshot(snap)
	end
end

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

claimBtn.MouseButton1Click:Connect(function()
	claimBtn.Text = "Claiming…"
	local result = ClaimSeasonRewards:InvokeServer()
	claimBtn.Text = "Claim season rewards"
	if typeof(result) ~= "table" then
		UiToast.Show("Claim failed.")
		return
	end
	if result.ok then
		local count = if typeof(result.rewards) == "table" then #result.rewards else 0
		UiToast.Show(if count > 0 then `Claimed {count} reward(s).` else "Nothing to claim.", nil, "success")
		local snap = GetCareerSnapshot:InvokeServer()
		renderSnapshot(snap)
	else
		local reason = if typeof(result.reason) == "string" then result.reason else "ClaimFailed"
		UiToast.Show(`Claim failed: {reason}`, nil, "error")
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.C then
		setOpen(not open)
	end
	if input.KeyCode == Enum.KeyCode.Escape and open then
		setOpen(false)
	end
end)

print("[CareerUI] Profile panel — C")
