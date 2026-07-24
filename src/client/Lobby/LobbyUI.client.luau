--[[

	Lobby UI — party invite, ready, kick/promote, queue (J toggle).

]]



local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local UserInputService = game:GetService("UserInputService")



local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)

if not PlaceRuntime.IsLobby() then

	return

end



local UiTheme = require(script.Parent.Parent.UI.UiTheme)

local UiToast = require(script.Parent.Parent.UI.UiToast)

local BossQueueConfig = require(ReplicatedStorage.Shared.Config.BossQueueConfig)

local C = UiTheme.Colors



local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")



local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes", 30)
if not remotes then
	warn("[LobbyUI] LobbyRemotes missing — LobbyBootstrap failed")
	return
end

local PartyInviteByName = remotes:WaitForChild("PartyInviteByName") :: RemoteEvent

local PartyRespondInvite = remotes:WaitForChild("PartyRespondInvite") :: RemoteEvent

local PartyInviteReceived = remotes:WaitForChild("PartyInviteReceived") :: RemoteEvent

local PartyKick = remotes:WaitForChild("PartyKick") :: RemoteEvent

local PartyPromote = remotes:WaitForChild("PartyPromote") :: RemoteEvent

local PartyReady = remotes:WaitForChild("PartyReady") :: RemoteEvent

local PartyLeave = remotes:WaitForChild("PartyLeave") :: RemoteEvent

local QueueStart = remotes:WaitForChild("QueueStart") :: RemoteEvent

local QueueCancel = remotes:WaitForChild("QueueCancel") :: RemoteEvent

local LobbyUpdated = remotes:WaitForChild("LobbyUpdated") :: RemoteEvent

local GetLobbyState = remotes:WaitForChild("GetLobbyState") :: RemoteFunction

local LobbyNotify = remotes:WaitForChild("LobbyNotify") :: RemoteEvent



local MAX_PARTY = 3



local open = false

local state: any = nil

local pendingInviteFrom: number? = nil

local queueTab: "pvp" | "pve" = "pvp"

local tabPvpBtn: TextButton? = nil

local tabPveBtn: TextButton? = nil



local gui = UiTheme.ScreenGui({

	name = "LobbyUI",

	displayOrder = UiTheme.DisplayOrder.Lobby,

	ignoreInset = false,

})

gui.Parent = playerGui



local panel = UiTheme.Panel({

	parent = gui,

	name = "Panel",

	size = UDim2.fromOffset(340, 520),

	position = UDim2.new(0, 12, 0.5, -260),

	visible = false,

})



UiTheme.Label({

	parent = panel,

	text = "Lobby  (J)",

	size = UDim2.new(1, -16, 0, 28),

	position = UDim2.fromOffset(8, 8),

	font = UiTheme.Font.Title,

	textSize = UiTheme.TextSize.Heading,

})



local partyHeader = UiTheme.Label({

	parent = panel,

	text = "Party",

	size = UDim2.new(1, -16, 0, 18),

	position = UDim2.fromOffset(8, 38),

	textSize = UiTheme.TextSize.Caption,

	color = C.TextMuted,

})



local partyScroll = UiTheme.ScrollFrame({

	parent = panel,

	size = UDim2.new(1, -16, 0, 96),

	position = UDim2.fromOffset(8, 56),

})

local partyList = Instance.new("UIListLayout")

partyList.Padding = UDim.new(0, 4)

partyList.SortOrder = Enum.SortOrder.LayoutOrder

partyList.Parent = partyScroll



local inviteRow = Instance.new("Frame")

inviteRow.Name = "InviteRow"

inviteRow.Size = UDim2.new(1, -16, 0, 34)

inviteRow.Position = UDim2.fromOffset(8, 156)

inviteRow.BackgroundTransparency = 1

inviteRow.Visible = false

inviteRow.Parent = panel



local inviteBox = UiTheme.TextBox({

	parent = inviteRow,

	size = UDim2.new(1, -88, 1, 0),

	position = UDim2.fromOffset(0, 0),

	placeholder = "Player name",

})



local inviteBtn = UiTheme.Button({

	parent = inviteRow,

	text = "Invite",

	size = UDim2.fromOffset(80, 34),

	position = UDim2.new(1, -80, 0, 0),

	variant = "accent",

	textSize = UiTheme.TextSize.Body,

})



local readyBtn = UiTheme.Button({

	parent = panel,

	text = "Ready",

	size = UDim2.new(0.5, -12, 0, 32),

	position = UDim2.fromOffset(8, 196),

	variant = "success",

})



local leaveBtn = UiTheme.Button({

	parent = panel,

	text = "Leave Party",

	size = UDim2.new(0.5, -12, 0, 32),

	position = UDim2.new(0.5, 4, 0, 196),

	variant = "danger",

})



local cancelBtn = UiTheme.Button({

	parent = panel,

	text = "Cancel Queue",

	size = UDim2.new(1, -16, 0, 28),

	position = UDim2.fromOffset(8, 234),

	variant = "muted",

	textSize = UiTheme.TextSize.Body,

})



local tabRow = Instance.new("Frame")

tabRow.Name = "TabRow"

tabRow.Size = UDim2.new(1, -16, 0, 32)

tabRow.Position = UDim2.fromOffset(8, 266)

tabRow.BackgroundTransparency = 1

tabRow.Parent = panel



local tabLayout = Instance.new("UIListLayout")

tabLayout.FillDirection = Enum.FillDirection.Horizontal

tabLayout.Padding = UDim.new(0, 6)

tabLayout.Parent = tabRow



tabPvpBtn = UiTheme.Button({

	parent = tabRow,

	text = "PvP",

	size = UDim2.new(0.5, -3, 1, 0),

	variant = "accent",

	textSize = UiTheme.TextSize.Body,

})



tabPveBtn = UiTheme.Button({

	parent = tabRow,

	text = "PvE",

	size = UDim2.new(0.5, -3, 1, 0),

	variant = "panel",

	textSize = UiTheme.TextSize.Body,

})



local function refreshQueueTabs()

	if tabPvpBtn then

		tabPvpBtn.BackgroundColor3 = if queueTab == "pvp" then C.Accent else C.Panel

		tabPvpBtn.TextColor3 = if queueTab == "pvp" then C.Text else C.TextMuted

	end

	if tabPveBtn then

		tabPveBtn.BackgroundColor3 = if queueTab == "pve" then C.Accent else C.Panel

		tabPveBtn.TextColor3 = if queueTab == "pve" then C.Text else C.TextMuted

	end

end



tabPvpBtn.MouseButton1Click:Connect(function()

	queueTab = "pvp"

	refreshQueueTabs()

	render()

end)



tabPveBtn.MouseButton1Click:Connect(function()

	queueTab = "pve"

	refreshQueueTabs()

	render()

end)



local queueScroll = UiTheme.ScrollFrame({

	parent = panel,

	size = UDim2.new(1, -16, 1, -348),

	position = UDim2.fromOffset(8, 306),

})

local queueList = Instance.new("UIListLayout")

queueList.Padding = UDim.new(0, 6)

queueList.SortOrder = Enum.SortOrder.LayoutOrder

queueList.Parent = queueScroll



local status = UiTheme.Label({

	parent = panel,

	size = UDim2.new(1, -16, 0, 20),

	position = UDim2.new(0, 8, 1, -28),

	textSize = UiTheme.TextSize.Caption,

	color = C.TextMuted,

})



local invitePopupGui = UiTheme.ScreenGui({

	name = "PartyInvitePopup",

	displayOrder = UiTheme.DisplayOrder.Modal,

	ignoreInset = false,

})

invitePopupGui.Parent = playerGui



local invitePopup = UiTheme.Panel({

	parent = invitePopupGui,

	size = UDim2.fromOffset(360, 120),

	position = UDim2.new(0.5, -180, 0, 72),

	visible = false,

})



local invitePopupText = UiTheme.Label({

	parent = invitePopup,

	text = "",

	size = UDim2.new(1, -16, 0, 48),

	position = UDim2.fromOffset(8, 10),

	textSize = UiTheme.TextSize.Subtitle,

	wrapped = true,

})



local acceptBtn = UiTheme.Button({

	parent = invitePopup,

	text = "Accept",

	size = UDim2.fromOffset(120, 32),

	position = UDim2.fromOffset(8, 72),

	variant = "success",

})



local declineBtn = UiTheme.Button({

	parent = invitePopup,

	text = "Decline",

	size = UDim2.fromOffset(120, 32),

	position = UDim2.fromOffset(136, 72),

	variant = "danger",

})



local NOTIFY_TEXT = {

	QueueBusy = "Already in queue.",

	NotReady = "Party not ready.",

	NotLeader = "Only party leader can do that.",

	InvalidQueue = "Invalid queue.",

	PartyFull = "Party is full.",

	PlayerNotFound = "Player not found in this server.",

	InviteSent = "Party invite sent.",

	InvitePending = "They already have a pending invite.",

	InviteDeclined = "Party invite declined.",

	InviteAccepted = "Player joined your party.",

	JoinedParty = "You joined the party.",

	AlreadyInParty = "That player is already in a party.",

	Self = "You cannot invite yourself.",

	NoInvite = "Invite is no longer valid.",

	Kicked = "Player removed from party.",

	Promoted = "Party leader updated.",

	NotInParty = "Player is not in your party.",

	CantKickSelf = "You cannot kick yourself.",

	Left = "You left the party.",

	MembersNotReady = "All party members must be ready.",

	WrongPartySize = "Party size does not fit this queue.",

	UnknownQueue = "Unknown queue.",

	InvalidBoss = "Pick a boss or Random.",

	AlreadyQueued = "Already in queue.",

	NoParty = "You are not in a party.",

	TargetOffline = "That player is offline.",

	PartyNotFound = "Party not found.",

}



local function clearPartyRows()

	for _, child in partyScroll:GetChildren() do

		if child:IsA("GuiObject") and child ~= partyList then

			child:Destroy()

		end

	end

end



local function makeMemberRow(member: any, isLeader: boolean, canManage: boolean)

	local row = Instance.new("Frame")

	row.Size = UDim2.new(1, -4, 0, 28)

	row.BackgroundColor3 = C.Panel

	row.BackgroundTransparency = 0.2

	row.BorderSizePixel = 0

	row.Parent = partyScroll

	UiTheme.Corner(row, UiTheme.Radius.Sm)



	local tag = ""

	if member.isLeader then

		tag ..= "[L] "

	end

	if member.ready then

		tag ..= "✓ "

	end

	if member.isYou then

		tag ..= "(you) "

	end



	local nameLbl = UiTheme.Label({

		parent = row,

		text = `{tag}{member.name}`,

		size = UDim2.new(1, if canManage and not member.isYou then -72 else -8, 1, 0),

		position = UDim2.fromOffset(6, 0),

		textSize = UiTheme.TextSize.Body,

		bg = C.Panel,

		color = if member.isLeader then C.WarningBright else C.Text,

	})



	if canManage and not member.isYou then

		local uid = member.userId

		local promoteBtn = UiTheme.Button({

			parent = row,

			text = "★",

			size = UDim2.fromOffset(28, 22),

			position = UDim2.new(1, -62, 0.5, -11),

			variant = "muted",

			textSize = UiTheme.TextSize.Caption,

		})

		promoteBtn.MouseButton1Click:Connect(function()

			PartyPromote:FireServer(uid)

		end)



		local kickBtn = UiTheme.Button({

			parent = row,

			text = "×",

			size = UDim2.fromOffset(28, 22),

			position = UDim2.new(1, -30, 0.5, -11),

			variant = "danger",

			textSize = UiTheme.TextSize.Body,

		})

		kickBtn.MouseButton1Click:Connect(function()

			PartyKick:FireServer(uid)

		end)

	end

end



local function render()

	if typeof(state) ~= "table" then

		return

	end



	clearPartyRows()



	local party = state.party

	local isLeader = party and party.isLeader == true

	local memberCount = if party and party.members then #party.members else 0

	local grouped = memberCount > 1



	if party and party.members then

		for i, m in party.members do

			makeMemberRow(m, isLeader, isLeader and grouped)

		end

		partyHeader.Text = if grouped then `Party ({memberCount}/{MAX_PARTY})` else "Party — solo"

		readyBtn.Visible = grouped

		leaveBtn.Visible = grouped

		inviteRow.Visible = isLeader and memberCount < MAX_PARTY

	else

		partyHeader.Text = "Party — solo"

		readyBtn.Visible = false

		leaveBtn.Visible = false

		inviteRow.Visible = false

	end



	partyScroll.CanvasSize = UDim2.fromOffset(0, partyList.AbsoluteContentSize.Y + 4)



	refreshQueueTabs()



	for _, child in queueScroll:GetChildren() do

		if child:IsA("GuiObject") and child ~= queueList then

			child:Destroy()

		end

	end



	local order = 0

	local function addSectionHeader(text: string)

		order += 1

		local lbl = UiTheme.Label({

			parent = queueScroll,

			text = text,

			size = UDim2.new(1, -4, 0, 22),

			textSize = UiTheme.TextSize.Caption,

			color = C.TextMuted,

			bg = C.Panel,

		})

		lbl.LayoutOrder = order

	end



	local function addQueueButton(label: string, onClick: () -> (), ranked: boolean?)

		order += 1

		local btn = UiTheme.Button({

			parent = queueScroll,

			text = label,

			size = UDim2.new(1, -4, 0, 36),

			variant = if ranked then "accent" else "panel",

			font = UiTheme.Font.Body,

			textSize = UiTheme.TextSize.Body,

		})

		btn.LayoutOrder = order

		btn.MouseButton1Click:Connect(onClick)

	end



	local function partySize(): number

		if party and party.members then

			return #party.members

		end

		return 1

	end



	if queueTab == "pvp" then

		local sections = if typeof(state.pvpSections) == "table" then state.pvpSections else {}

		for _, section in sections do

			if typeof(section.title) == "string" then

				addSectionHeader(section.title)

			end

			local ranked = section.title == "Ranked"

			local queues = if typeof(section.queues) == "table" then section.queues else {}

			for _, entry in queues do

				local qid = entry.queueId

				local bracket = entry.label or qid

				local label = `{bracket} · {section.title or "PvP"}`

				addQueueButton(label, function()

					QueueStart:FireServer(qid)

					status.Text = `Queued: {label}`

					status.TextColor3 = C.TextMuted

				end, ranked)

			end

		end

	else

		local pveQueues = if typeof(state.pveQueues) == "table" then state.pveQueues else {}

		local size = partySize()

		local qid = pveQueues[size]



		local function queueBoss(bossPref: string, label: string)

			if typeof(qid) ~= "string" then

				status.Text = "Boss queue needs 1–3 players in party."

				status.TextColor3 = C.DangerBright

				return

			end

			QueueStart:FireServer(qid, bossPref)

			status.Text = `Queued: {label} · {size}p`

			status.TextColor3 = C.TextMuted

		end



		local wildcard = state.pveWildcard

		if typeof(wildcard) == "table" then

			addQueueButton(wildcard.label or "Random", function()

				queueBoss(wildcard.id, wildcard.label or "Random")

			end)

		end



		local bosses = if typeof(state.pveBosses) == "table" then state.pveBosses else BossQueueConfig.GetBossList()

		for _, boss in bosses do

			local pref = boss.id

			local label = boss.label or pref

			addQueueButton(label, function()

				queueBoss(pref, label)

			end)

		end

	end

	queueScroll.CanvasSize = UDim2.fromOffset(0, queueList.AbsoluteContentSize.Y + 8)

end



local function pull()

	local ok, s = pcall(function()

		return GetLobbyState:InvokeServer()

	end)

	if ok and s then

		state = s

		render()

	end

end



local function sendInvite()
	local name = inviteBox.Text
	if name == "" then
		status.Text = "Enter a player name."
		status.TextColor3 = C.DangerBright
		return
	end
	PartyInviteByName:FireServer(name)
end

inviteBtn.MouseButton1Click:Connect(sendInvite)

inviteBox.FocusLost:Connect(function(enter)
	if enter then
		sendInvite()
	end
end)



readyBtn.MouseButton1Click:Connect(function()

	local ready = true

	if state and state.party then

		for _, m in state.party.members do

			if m.isYou then

				ready = not m.ready

				break

			end

		end

	end

	PartyReady:FireServer(ready)

end)



leaveBtn.MouseButton1Click:Connect(function()

	PartyLeave:FireServer()

end)



cancelBtn.MouseButton1Click:Connect(function()

	QueueCancel:FireServer()

	status.Text = "Queue cancelled"

	status.TextColor3 = C.TextMuted

end)



acceptBtn.MouseButton1Click:Connect(function()

	if pendingInviteFrom then

		PartyRespondInvite:FireServer(pendingInviteFrom, true)

	end

	invitePopup.Visible = false

	pendingInviteFrom = nil

end)



declineBtn.MouseButton1Click:Connect(function()

	if pendingInviteFrom then

		PartyRespondInvite:FireServer(pendingInviteFrom, false)

	end

	invitePopup.Visible = false

	pendingInviteFrom = nil

end)



PartyInviteReceived.OnClientEvent:Connect(function(payload: any)

	if typeof(payload) ~= "table" or typeof(payload.fromUserId) ~= "number" then

		return

	end

	pendingInviteFrom = payload.fromUserId

	local fromName = if typeof(payload.fromName) == "string" then payload.fromName else "A player"

	invitePopupText.Text = `{fromName} invited you to their party.`

	invitePopup.Visible = true

	UiToast.Show(`Party invite from {fromName}`, 3, "accent")

end)



LobbyUpdated.OnClientEvent:Connect(function(payload)

	state = payload

	render()

end)



LobbyNotify.OnClientEvent:Connect(function(payload)

	if typeof(payload) ~= "table" then

		return

	end

	local code = if typeof(payload.code) == "string" then payload.code else "Error"

	if payload.ok == true then

		if code == "InviteSent" or code == "JoinedParty" or code == "InviteAccepted" or code == "Kicked" or code == "Promoted" then

			status.Text = NOTIFY_TEXT[code] or code

			status.TextColor3 = C.SuccessBright

		end

		return

	end

	status.Text = NOTIFY_TEXT[code] or code

	status.TextColor3 = C.DangerBright

end)



UserInputService.InputBegan:Connect(function(input, processed)

	if processed then

		return

	end

	if input.KeyCode == Enum.KeyCode.J then

		open = not open

		panel.Visible = open

		if open then

			pull()

		end

	end

end)



pull()

