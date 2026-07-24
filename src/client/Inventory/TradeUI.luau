--[[
	Bilateral trade UI — invite by player name, then lootbox exchange.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiToast = require(script.Parent.Parent.UI.UiToast)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local tradeFolder = ReplicatedStorage:WaitForChild("TradeRemotes", 20)
if not tradeFolder then
	warn("[TradeUI] TradeRemotes missing")
end

local function getRemote(name: string): RemoteEvent?
	if not tradeFolder then
		return nil
	end
	local r = tradeFolder:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then
		return r
	end
	return nil
end

local TradeInviteByName = getRemote("TradeInviteByName")
local TradeRespondInvite = getRemote("TradeRespondInvite")
local TradeAddOffer = getRemote("TradeAddOffer")
local TradeRemoveOffer = getRemote("TradeRemoveOffer")
local TradeSetReady = getRemote("TradeSetReady")
local TradeCancel = getRemote("TradeCancel")
local TradeExecute = getRemote("TradeExecute")
local TradeUpdated = getRemote("TradeUpdated")
local TradeInviteReceived = getRemote("TradeInviteReceived")

local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local COL_BG = C.Bg
local COL_PANEL = C.Panel
local COL_TEXT = C.Text
local COL_MUTED = C.TextMuted
local COL_ACCENT = C.Accent

local gui = UiTheme.ScreenGui({
	name = "TradeUI",
	displayOrder = UiTheme.DisplayOrder.Trade,
	ignoreInset = false,
	enabled = false,
})
gui.Parent = playerGui

local panel = UiTheme.Panel({
	parent = gui,
	size = UDim2.fromOffset(440, 340),
	position = UDim2.new(0.5, -220, 0.5, -170),
	visible = false,
})

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.fromOffset(8, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = COL_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Trade"
title.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 18)
status.Position = UDim2.fromOffset(8, 36)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = COL_MUTED
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = ""
status.Parent = panel

local invitePanel = Instance.new("Frame")
invitePanel.Size = UDim2.new(1, -16, 1, -56)
invitePanel.Position = UDim2.fromOffset(8, 56)
invitePanel.BackgroundTransparency = 1
invitePanel.Visible = false
invitePanel.Parent = panel

local inviteHint = Instance.new("TextLabel")
inviteHint.Size = UDim2.new(1, 0, 0, 36)
inviteHint.BackgroundTransparency = 1
inviteHint.Font = Enum.Font.Gotham
inviteHint.TextSize = 13
inviteHint.TextColor3 = COL_MUTED
inviteHint.TextWrapped = true
inviteHint.TextXAlignment = Enum.TextXAlignment.Left
inviteHint.Text = "Enter the player's username to send a trade invite."
inviteHint.Parent = invitePanel

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, 0, 0, 34)
nameBox.Position = UDim2.fromOffset(0, 44)
nameBox.BackgroundColor3 = COL_PANEL
nameBox.BorderSizePixel = 0
nameBox.ClearTextOnFocus = false
nameBox.Font = Enum.Font.Gotham
nameBox.PlaceholderText = "Player name"
nameBox.Text = ""
nameBox.TextColor3 = COL_TEXT
nameBox.TextSize = 14
nameBox.Parent = invitePanel
local nameCorner = Instance.new("UICorner")
nameCorner.CornerRadius = UDim.new(0, 6)
nameCorner.Parent = nameBox

local function makeBtn(parent: Instance, text: string, x: number, y: number, color: Color3, w: number?): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(w or 120, 32)
	btn.Position = UDim2.fromOffset(x, y)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = COL_TEXT
	btn.Text = text
	btn.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	return btn
end

local inviteSendBtn = makeBtn(invitePanel, "Send invite", 0, 90, COL_ACCENT)
local inviteCloseBtn = makeBtn(invitePanel, "Close", 128, 90, C.ButtonMuted)

local tradePanel = Instance.new("Frame")
tradePanel.Size = UDim2.new(1, -16, 1, -56)
tradePanel.Position = UDim2.fromOffset(8, 56)
tradePanel.BackgroundTransparency = 1
tradePanel.Visible = false
tradePanel.Parent = panel

local function makeOfferScroll(parent: Instance, xScale: number, xOffset: number, titleText: string): (ScrollingFrame, Frame)
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(0.48, -8, 0, 16)
	header.Position = UDim2.new(xScale, xOffset, 0, 0)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 11
	header.TextColor3 = COL_MUTED
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = titleText
	header.Parent = parent

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(0.48, -8, 0, 148)
	scroll.Position = UDim2.new(xScale, xOffset, 0, 20)
	scroll.BackgroundColor3 = COL_PANEL
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.Parent = parent
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 6)
	sc.Parent = scroll

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, -8, 0, 0)
	list.Position = UDim2.fromOffset(4, 4)
	list.BackgroundTransparency = 1
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end)

	return scroll, list
end

local _, myOfferList = makeOfferScroll(tradePanel, 0, 0, "Your offers")
local _, theirOfferList = makeOfferScroll(tradePanel, 0.52, 0, "Their offers")

local readyBtn = makeBtn(tradePanel, "Ready", 0, 178, C.Success)
local confirmBtn = makeBtn(tradePanel, "Confirm", 108, 178, C.AccentMuted)
local cancelBtn = makeBtn(tradePanel, "Cancel", 216, 178, C.Danger)

local incomingGui = UiTheme.ScreenGui({
	name = "TradeInvitePopup",
	displayOrder = UiTheme.DisplayOrder.Trade + 1,
	ignoreInset = false,
})
incomingGui.Parent = playerGui

local incoming = UiTheme.Panel({
	parent = incomingGui,
	size = UDim2.fromOffset(360, 120),
	position = UDim2.new(0.5, -180, 0, 72),
	visible = false,
})

local incomingText = Instance.new("TextLabel")
incomingText.Size = UDim2.new(1, -16, 0, 48)
incomingText.Position = UDim2.fromOffset(8, 10)
incomingText.BackgroundTransparency = 1
incomingText.Font = Enum.Font.Gotham
incomingText.TextSize = 14
incomingText.TextColor3 = COL_TEXT
incomingText.TextWrapped = true
incomingText.Text = ""
incomingText.Parent = incoming

local acceptBtn = makeBtn(incoming, "Accept", 8, 68, C.Success)
local declineBtn = makeBtn(incoming, "Decline", 136, 68, C.Danger)

local pendingStarterUuid: string? = nil
local pendingInviteFrom: number? = nil
local myReadyCached = false

local REASON_TEXT = {
	PlayerNotFound = "Player not found in this server.",
	InviteSent = "Invite sent — waiting for response…",
	InviteDeclined = "Trade invite declined.",
	InviteExpired = "Trade invite expired.",
	Busy = "That player is already in a trade.",
	InvitePending = "They already have a pending invite.",
	Self = "You cannot trade with yourself.",
	TooFar = "Move closer to confirm the trade.",
	NotReady = "Both players must be ready.",
	NoItem = "Item no longer in inventory.",
	NotTradeable = "That item cannot be traded.",
	Installed = "Remove installed parts before trading.",
	Equipped = "Unequip the item before trading.",
	Full = "Trade offer list is full.",
	Offline = "Partner left the server.",
	NoInvite = "Trade invite is no longer valid.",
	TransferFailed = "Trade failed — try again.",
	InvalidOffer = "An offer became invalid.",
	Completed = "Trade completed.",
	Cancelled = "Trade cancelled.",
}

local function reasonText(reason: string?): string
	if not reason then
		return ""
	end
	return REASON_TEXT[reason] or reason
end

local function clearOfferList(list: Frame)
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function rebuildOfferList(list: Frame, lines: { any }?, removable: boolean)
	clearOfferList(list)
	if not lines or #lines == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 20)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 11
		empty.TextColor3 = COL_MUTED
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.Text = "—"
		empty.Parent = list
		return
	end
	for i, line in lines do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i
		row.Parent = list

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, if removable then -28 else 0, 1, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.Gotham
		nameLbl.TextSize = 11
		nameLbl.TextColor3 = COL_TEXT
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Text = if typeof(line.name) == "string" then line.name else "?"
		nameLbl.Parent = row

		if removable and typeof(line.uuid) == "string" then
			local rm = Instance.new("TextButton")
			rm.Size = UDim2.fromOffset(22, 22)
			rm.Position = UDim2.new(1, -24, 0, 1)
			rm.BackgroundColor3 = C.DangerDark
			rm.BorderSizePixel = 0
			rm.Font = Enum.Font.GothamBold
			rm.TextSize = 12
			rm.TextColor3 = COL_TEXT
			rm.Text = "×"
			rm.Parent = row
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0, 4)
			rc.Parent = rm
			local uuid = line.uuid
			rm.MouseButton1Click:Connect(function()
				if TradeRemoveOffer then
					TradeRemoveOffer:FireServer(uuid)
				end
			end)
		end
	end
end

local function showInviteMode()
	panel.Visible = true
	invitePanel.Visible = true
	tradePanel.Visible = false
	title.Text = "Trade invite"
end

local function showTradeMode(partnerName: string?)
	panel.Visible = true
	invitePanel.Visible = false
	tradePanel.Visible = true
	title.Text = if partnerName then `Trade · {partnerName}` else "Trade"
end

local function hideMainPanel()
	panel.Visible = false
	invitePanel.Visible = false
	tradePanel.Visible = false
end

local function render(snapshot: any)
	if typeof(snapshot) ~= "table" then
		return
	end

	local reason = snapshot.reason
	if reason == "Completed" then
		UiToast.Show("Trade completed!", 2.5, "success")
		gui.Enabled = false
		hideMainPanel()
		incoming.Visible = false
		return
	end
	if reason == "Cancelled" then
		UiToast.Show("Trade cancelled.", 2, "warn")
		gui.Enabled = false
		hideMainPanel()
		incoming.Visible = false
		return
	end

	if reason == "InviteSent" then
		gui.Enabled = true
		showInviteMode()
		local partner = snapshot.partnerUserId and Players:GetPlayerByUserId(snapshot.partnerUserId)
		status.Text = if partner then `Waiting for {partner.DisplayName}…` else reasonText(reason)
		return
	end

	if reason and reason ~= "NoSession" then
		status.Text = reasonText(reason)
		if not snapshot.ok and reason ~= "InviteSent" then
			UiToast.Show(reasonText(reason), 2.5, "error")
		end
		if reason == "InviteDeclined" or reason == "PlayerNotFound" or reason == "Busy" or reason == "InvitePending" or reason == "Self" then
			gui.Enabled = true
			showInviteMode()
		end
	end

	if not snapshot.ok then
		if reason == "NoSession" and not incoming.Visible then
			if invitePanel.Visible or tradePanel.Visible then
				gui.Enabled = true
			else
				gui.Enabled = false
				hideMainPanel()
			end
		end
		return
	end

	gui.Enabled = true
	local partner = snapshot.partnerUserId and Players:GetPlayerByUserId(snapshot.partnerUserId)
	showTradeMode(partner and partner.DisplayName or nil)
	myReadyCached = snapshot.myReady == true
	readyBtn.Text = if myReadyCached then "Not ready" else "Ready"
	readyBtn.BackgroundColor3 = if myReadyCached then C.ButtonMuted else C.Success
	status.Text = if snapshot.myReady and snapshot.partnerReady
		then "Both ready — press Confirm"
		elseif snapshot.myReady then "Waiting for partner…"
		else "Add offers from Gear, then Ready"
	rebuildOfferList(myOfferList, snapshot.myOfferLines, true)
	rebuildOfferList(theirOfferList, snapshot.partnerOfferLines, false)
end

inviteSendBtn.MouseButton1Click:Connect(function()
	local name = nameBox.Text
	if name == "" then
		status.Text = "Enter a player name."
		return
	end
	if TradeInviteByName then
		TradeInviteByName:FireServer(name, pendingStarterUuid)
	end
end)

inviteCloseBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
	hideMainPanel()
	pendingStarterUuid = nil
end)

readyBtn.MouseButton1Click:Connect(function()
	if TradeSetReady then
		TradeSetReady:FireServer(not myReadyCached)
	end
end)

confirmBtn.MouseButton1Click:Connect(function()
	if TradeExecute then
		TradeExecute:FireServer()
	end
end)

cancelBtn.MouseButton1Click:Connect(function()
	if TradeCancel then
		TradeCancel:FireServer()
	end
	gui.Enabled = false
	hideMainPanel()
end)

acceptBtn.MouseButton1Click:Connect(function()
	if pendingInviteFrom and TradeRespondInvite then
		TradeRespondInvite:FireServer(pendingInviteFrom, true)
	end
	incoming.Visible = false
	pendingInviteFrom = nil
end)

declineBtn.MouseButton1Click:Connect(function()
	if pendingInviteFrom and TradeRespondInvite then
		TradeRespondInvite:FireServer(pendingInviteFrom, false)
	end
	incoming.Visible = false
	pendingInviteFrom = nil
	if not panel.Visible then
		gui.Enabled = false
	end
end)

if TradeUpdated then
	TradeUpdated.OnClientEvent:Connect(render)
end

if TradeInviteReceived then
	TradeInviteReceived.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" or typeof(payload.fromUserId) ~= "number" then
			return
		end
		pendingInviteFrom = payload.fromUserId
		local fromName = if typeof(payload.fromName) == "string" then payload.fromName else "A player"
		incomingText.Text = `{fromName} wants to trade with you.`
		incoming.Visible = true
	end)
end

local TradeUI = {}

function TradeUI.IsActive(): boolean
	return tradePanel.Visible and gui.Enabled
end

function TradeUI.OpenInvite(selectedUuid: string?)
	if not TradeInviteByName then
		UiToast.Show("Trade system not ready.", 2, "error")
		return
	end
	pendingStarterUuid = selectedUuid
	gui.Enabled = true
	showInviteMode()
	status.Text = if selectedUuid then "Selected item will be offered when they accept." else ""
	nameBox:CaptureFocus()
end

function TradeUI.AddSelected(uuid: string)
	if TradeUI.IsActive() and TradeAddOffer then
		TradeAddOffer:FireServer(uuid)
	end
end

return TradeUI
