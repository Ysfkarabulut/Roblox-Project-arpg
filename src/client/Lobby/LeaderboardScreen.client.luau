--[[
	Lobby split leaderboard wall displays:
	- LeaderboardScreenPvE: merged kills + speed lists (player > boss > stat)
	- LeaderboardScreenPvP: 1v1 / 2v2 / 3v3 MMR columns
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local SeasonConfig = require(ReplicatedStorage.Shared.Config.SeasonConfig)
local LeaderboardPveMerge = require(ReplicatedStorage.Shared.Meta.LeaderboardPveMerge)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local DISPLAY_TAG = "LeaderboardDisplay"
local PIXELS_PER_STUD = 38
local REFRESH_SEC = 45
local ROWS_PER_BOARD = 10

local RANK_COLORS = {
	Color3.fromRGB(255, 210, 90),
	Color3.fromRGB(210, 220, 235),
	Color3.fromRGB(210, 150, 110),
}

type BoardDef = LeaderboardPveMerge.BoardDef

type PveList = {
	kind: string,
	list: Frame,
	setEntries: (entries: { LeaderboardPveMerge.MergedEntry }) -> (),
}

local remotes = ReplicatedStorage:WaitForChild("CareerRemotes", 30)
if not remotes then
	warn("[LeaderboardScreen] CareerRemotes missing")
	return
end

local GetLeaderboard = remotes:WaitForChild("GetLeaderboard") :: RemoteFunction
local GetLeaderboardCatalog = remotes:WaitForChild("GetLeaderboardCatalog") :: RemoteFunction

local catalogSeason: { id: string, name: string }? = nil
local catalogBoards: { BoardDef } = {}

local function findScreen(kind: string): BasePart?
	for _, inst in CollectionService:GetTagged(DISPLAY_TAG) do
		if inst:IsA("BasePart") and inst:GetAttribute("DisplayKind") == kind then
			return inst
		end
	end
	local displays = workspace:FindFirstChild("Lobby")
		and workspace.Lobby:FindFirstChild("Displays")
	if not displays then
		return nil
	end
	local name = if kind == "PvE" then "LeaderboardScreenPvE" else "LeaderboardScreenPvP"
	local part = displays:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function waitForScreen(kind: string): BasePart?
	local part = findScreen(kind)
	if part then
		return part
	end
	local lobby = workspace:WaitForChild("Lobby", 20)
	local displays = lobby and lobby:WaitForChild("Displays", 20)
	if not displays then
		return nil
	end
	local name = if kind == "PvE" then "LeaderboardScreenPvE" else "LeaderboardScreenPvP"
	part = displays:WaitForChild(name, 20)
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function formatScore(entry: any, kind: string): string
	if kind == "boss_kills" then
		return `{math.floor(entry.killCount or entry.score)}`
	end
	if kind == "boss_speed" then
		return entry.clearTimeText or "—"
	end
	return `{math.floor(entry.score)}`
end

local function formatDetail(entry: any, kind: string): string?
	if kind ~= "boss_speed" then
		return nil
	end
	if entry.memberNames and #entry.memberNames > 0 then
		return table.concat(entry.memberNames, ", ")
	end
	return nil
end

local function setPvpRow(row: Frame, visible: boolean, rank: number?, playerName: string?, score: string?, detail: string?)
	row.Visible = visible
	if not visible then
		return
	end
	local rankLabel = row:FindFirstChild("Rank") :: TextLabel
	local playerLabel = row:FindFirstChild("Player") :: TextLabel
	local scoreLabel = row:FindFirstChild("Score") :: TextLabel
	local detailLabel = row:FindFirstChild("Detail") :: TextLabel

	rankLabel.Text = if rank then tostring(rank) else "—"
	rankLabel.TextColor3 = RANK_COLORS[rank or 0] or C.TextMuted
	playerLabel.Text = playerName or "—"
	scoreLabel.Text = score or "—"

	if detail and detail ~= "" then
		playerLabel.Size = UDim2.new(1, -52, 0, 14)
		detailLabel.Visible = true
		detailLabel.Text = detail
	else
		playerLabel.Size = UDim2.new(1, -52, 1, 0)
		detailLabel.Visible = false
	end
end

local MEMBER_LINE = 11
local MEMBER_LINE_FIRST = 13

local function clearListRows(list: Frame)
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function renderKillRow(list: Frame, entry: LeaderboardPveMerge.MergedEntry)
	local row = UiTheme.Panel({
		parent = list,
		size = UDim2.new(1, 0, 0, 20),
		bg = C.BgElevated,
		transparency = 0.5,
		radius = UiTheme.Radius.Xs,
	})

	UiTheme.Label({
		parent = row,
		size = UDim2.fromOffset(22, 20),
		position = UDim2.fromOffset(4, 0),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Caption,
		color = RANK_COLORS[entry.rank] or C.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
		text = tostring(entry.rank),
	})

	UiTheme.Label({
		parent = row,
		size = UDim2.new(1, -30, 1, 0),
		position = UDim2.fromOffset(26, 0),
		font = UiTheme.Font.Body,
		textSize = UiTheme.TextSize.Caption,
		text = LeaderboardPveMerge.FormatRow(entry, "boss_kills"),
	})
end

local function renderSpeedGroupRow(list: Frame, group: LeaderboardPveMerge.PartyGroup)
	local memberCount = math.max(1, #group.members)
	local rowH = math.max(22, 6 + MEMBER_LINE_FIRST + math.max(0, memberCount - 1) * MEMBER_LINE)

	local row = UiTheme.Panel({
		parent = list,
		size = UDim2.new(1, 0, 0, rowH),
		bg = C.BgElevated,
		transparency = 0.5,
		radius = UiTheme.Radius.Xs,
	})

	UiTheme.Label({
		parent = row,
		name = "Rank",
		size = UDim2.fromOffset(22, rowH),
		position = UDim2.fromOffset(4, 0),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Caption,
		color = RANK_COLORS[group.rank] or C.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
		yAlign = Enum.TextYAlignment.Top,
		text = tostring(group.rank),
	})

	local membersHost = Instance.new("Frame")
	membersHost.Name = "Members"
	membersHost.BackgroundTransparency = 1
	membersHost.Size = UDim2.new(1, -108, 0, rowH - 4)
	membersHost.Position = UDim2.fromOffset(26, 2)
	membersHost.Parent = row

	for i, member in group.members do
		UiTheme.Label({
			parent = membersHost,
			size = UDim2.new(1, 0, 0, if i == 1 then MEMBER_LINE_FIRST else MEMBER_LINE),
			position = UDim2.fromOffset(0, if i == 1 then 0 else MEMBER_LINE_FIRST + (i - 2) * MEMBER_LINE),
			font = UiTheme.Font.Body,
			textSize = if i == 1 then UiTheme.TextSize.Caption else 10,
			color = if i == 1 then C.Text else C.TextDim,
			text = member.displayName,
		})
	end

	local timeText = group.clearTimeText or "—"
	UiTheme.Label({
		parent = row,
		size = UDim2.fromOffset(76, rowH),
		position = UDim2.new(1, -80, 0, 0),
		font = UiTheme.Font.Title,
		textSize = 10,
		color = C.TextBright,
		xAlign = Enum.TextXAlignment.Right,
		yAlign = Enum.TextYAlignment.Center,
		wrapped = true,
		text = `{group.bossName}\n{timeText}`,
	})
end

local function createPvpRow(parent: Frame, height: number): Frame
	local row = UiTheme.Panel({
		parent = parent,
		size = UDim2.new(1, 0, 0, height),
		bg = C.BgElevated,
		transparency = 0.5,
		radius = UiTheme.Radius.Xs,
		visible = false,
	})

	UiTheme.Label({
		parent = row,
		name = "Rank",
		size = UDim2.fromOffset(22, height),
		position = UDim2.fromOffset(4, 0),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Caption,
		color = C.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
	})

	UiTheme.Label({
		parent = row,
		name = "Player",
		size = UDim2.new(1, -52, 1, 0),
		position = UDim2.fromOffset(26, 0),
		font = UiTheme.Font.Body,
		textSize = UiTheme.TextSize.Caption,
		text = "—",
	})

	UiTheme.Label({
		parent = row,
		name = "Detail",
		size = UDim2.new(1, -52, 0, 11),
		position = UDim2.fromOffset(26, height - 12),
		font = UiTheme.Font.Body,
		textSize = 9,
		color = C.TextDim,
		visible = false,
	})

	UiTheme.Label({
		parent = row,
		name = "Score",
		size = UDim2.fromOffset(26, height),
		position = UDim2.new(1, -28, 0, 0),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Caption,
		color = C.TextBright,
		xAlign = Enum.TextXAlignment.Right,
		text = "—",
	})

	return row
end

local function createPveList(parent: Instance, kind: string): PveList
	local list = Instance.new("Frame")
	list.Name = `{kind}List`
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 1, 0)
	list.Parent = parent

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = list

	local pveList: PveList = {
		kind = kind,
		list = list,
		setEntries = function(_self, _entries: { LeaderboardPveMerge.MergedEntry }) end,
	}

	function pveList.setEntries(_self, entries: { LeaderboardPveMerge.MergedEntry })
		clearListRows(list)

		if #entries == 0 then
			local empty = UiTheme.Panel({
				parent = list,
				size = UDim2.new(1, 0, 0, 20),
				bg = C.BgElevated,
				transparency = 0.5,
				radius = UiTheme.Radius.Xs,
			})
			UiTheme.Label({
				parent = empty,
				size = UDim2.new(1, -8, 1, 0),
				position = UDim2.fromOffset(4, 0),
				font = UiTheme.Font.Body,
				textSize = UiTheme.TextSize.Caption,
				color = C.TextDim,
				text = "No entries yet — be the first!",
			})
			return
		end

		if kind == "boss_speed" then
			for _, group in LeaderboardPveMerge.GroupByPartyRank(entries) do
				renderSpeedGroupRow(list, group)
			end
		else
			for _, entry in entries do
				renderKillRow(list, entry)
			end
		end
	end

	return pveList
end

local function createMiniBoard(parent: Instance, layoutOrder: number, title: string, subtitle: string, boardId: string, kind: string)
	local wrap = UiTheme.Panel({
		parent = parent,
		name = boardId,
		size = UDim2.new(1, 0, 1, 0),
		bg = C.Panel,
		transparency = 0.2,
		radius = UiTheme.Radius.Sm,
		stroke = true,
	})
	wrap.LayoutOrder = layoutOrder
	UiTheme.Padding(wrap, UiTheme.Spacing.Xs)

	UiTheme.Label({
		parent = wrap,
		text = title,
		size = UDim2.new(1, 0, 0, 18),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Subtitle,
		color = C.TextBright,
		xAlign = Enum.TextXAlignment.Center,
	})

	UiTheme.Label({
		parent = wrap,
		text = subtitle,
		size = UDim2.new(1, 0, 0, 14),
		position = UDim2.fromOffset(0, 18),
		textSize = UiTheme.TextSize.Caption,
		color = C.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
	})

	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 1, -36)
	list.Position = UDim2.fromOffset(0, 34)
	list.Parent = wrap

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = list

	local rowHeight = 22
	local rows: { Frame } = {}
	for _ = 1, ROWS_PER_BOARD do
		table.insert(rows, createPvpRow(list, rowHeight))
	end

	local mini = {
		boardId = boardId,
		kind = kind,
		rows = rows,
		setEntries = function(_self, entries: { any }) end,
	}

	function mini.setEntries(_self, entries: { any })
		if #entries == 0 then
			setPvpRow(rows[1], true, nil, "No entries", "", nil)
			for i = 2, #rows do
				setPvpRow(rows[i], false, nil, nil, nil, nil)
			end
			return
		end
		for i, row in rows do
			local entry = entries[i]
			if entry then
				setPvpRow(
					row,
					true,
					entry.rank,
					entry.displayName,
					formatScore(entry, kind),
					formatDetail(entry, kind)
				)
			else
				setPvpRow(row, false, nil, nil, nil, nil)
			end
		end
	end

	return mini
end

local function createSectionHeader(parent: Instance, text: string, y: number, accent: Color3)
	UiTheme.Label({
		parent = parent,
		text = text,
		size = UDim2.new(1, 0, 0, 22),
		position = UDim2.fromOffset(0, y),
		font = UiTheme.Font.Title,
		textSize = UiTheme.TextSize.Title,
		color = accent,
		xAlign = Enum.TextXAlignment.Center,
	})
end

local function mountSurface(screen: BasePart, accentColor: Color3): Frame
	local surface = Instance.new("SurfaceGui")
	surface.Name = "LeaderboardSurface"
	surface.Adornee = screen
	surface.Face = Enum.NormalId.Front
	surface.LightInfluence = 0
	surface.Brightness = 1.15
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = PIXELS_PER_STUD
	surface.ClipsDescendants = true
	surface.Parent = screen

	local root = UiTheme.Panel({
		parent = surface,
		size = UDim2.fromScale(1, 1),
		bg = C.Bg,
		radius = 0,
	})
	UiTheme.Padding(root, UiTheme.Spacing.Sm)

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(1, 0, 0, 3)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = root

	return root
end

local pveLists: { PveList } = {}
local pvpBoards: { any } = {}

local function buildPveDisplay(screen: BasePart)
	local root = mountSurface(screen, Color3.fromRGB(90, 170, 120))

	UiTheme.Label({
		parent = root,
		text = "PvE LEADERBOARDS",
		size = UDim2.new(1, 0, 0, 32),
		position = UDim2.fromOffset(0, 6),
		font = UiTheme.Font.Display,
		textSize = 24,
		color = C.TextBright,
		xAlign = Enum.TextXAlignment.Center,
	})

	local seasonLabel = UiTheme.Label({
		parent = root,
		name = "Season",
		size = UDim2.new(1, 0, 0, 16),
		position = UDim2.fromOffset(0, 36),
		textSize = UiTheme.TextSize.Caption,
		color = C.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
	})

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 1, -72)
	body.Position = UDim2.fromOffset(0, 56)
	body.Parent = root

	local killsHalf = UiTheme.Panel({
		parent = body,
		name = "KillsHalf",
		size = UDim2.new(0.5, -4, 1, 0),
		bg = C.BgElevated,
		transparency = 0.15,
		radius = UiTheme.Radius.Md,
	})
	createSectionHeader(killsHalf, "MOST KILLS", 6, Color3.fromRGB(120, 200, 140))

	local killsListHost = Instance.new("Frame")
	killsListHost.Name = "KillsListHost"
	killsListHost.BackgroundTransparency = 1
	killsListHost.Size = UDim2.new(1, -8, 1, -32)
	killsListHost.Position = UDim2.fromOffset(4, 30)
	killsListHost.Parent = killsHalf
	table.insert(pveLists, createPveList(killsListHost, "boss_kills"))

	local speedHalf = UiTheme.Panel({
		parent = body,
		name = "SpeedHalf",
		size = UDim2.new(0.5, -4, 1, 0),
		position = UDim2.new(0.5, 4, 0, 0),
		bg = C.BgElevated,
		transparency = 0.15,
		radius = UiTheme.Radius.Md,
	})
	createSectionHeader(speedHalf, "FASTEST CLEAR", 6, Color3.fromRGB(100, 170, 230))

	local speedListHost = Instance.new("Frame")
	speedListHost.Name = "SpeedListHost"
	speedListHost.BackgroundTransparency = 1
	speedListHost.Size = UDim2.new(1, -8, 1, -32)
	speedListHost.Position = UDim2.fromOffset(4, 30)
	speedListHost.Parent = speedHalf
	table.insert(pveLists, createPveList(speedListHost, "boss_speed"))

	local status = UiTheme.Label({
		parent = root,
		name = "Status",
		size = UDim2.new(1, 0, 0, 14),
		position = UDim2.new(0, 0, 1, -16),
		textSize = 10,
		color = C.TextDim,
		xAlign = Enum.TextXAlignment.Center,
	})

	return function(seasonText: string, statusText: string)
		seasonLabel.Text = seasonText
		status.Text = statusText
	end
end

local function buildPvpDisplay(screen: BasePart)
	local root = mountSurface(screen, Color3.fromRGB(255, 200, 90))

	UiTheme.Label({
		parent = root,
		text = "PvP RANKED",
		size = UDim2.new(1, 0, 0, 32),
		position = UDim2.fromOffset(0, 6),
		font = UiTheme.Font.Display,
		textSize = 24,
		color = C.TextBright,
		xAlign = Enum.TextXAlignment.Center,
	})

	local seasonLabel = UiTheme.Label({
		parent = root,
		name = "Season",
		size = UDim2.new(1, 0, 0, 16),
		position = UDim2.fromOffset(0, 36),
		textSize = UiTheme.TextSize.Caption,
		color = C.TextMuted,
		xAlign = Enum.TextXAlignment.Center,
	})

	local grid = Instance.new("Frame")
	grid.Name = "BracketGrid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 1, -72)
	grid.Position = UDim2.fromOffset(0, 56)
	grid.Parent = root

	local gridLayout = Instance.new("UIListLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.Padding = UDim.new(0, 6)
	gridLayout.Parent = grid

	local pvpDefs = {
		{ id = "mmr_1v1", title = "1v1", subtitle = "MMR" },
		{ id = "mmr_2v2", title = "2v2", subtitle = "MMR" },
		{ id = "mmr_3v3", title = "3v3", subtitle = "MMR" },
	}

	for i, def in pvpDefs do
		local col = Instance.new("Frame")
		col.Name = def.id
		col.BackgroundTransparency = 1
		col.Size = UDim2.new(1 / 3, -4, 1, 0)
		col.LayoutOrder = i
		col.Parent = grid

		local board = createMiniBoard(col, 1, def.title, def.subtitle, def.id, "mmr")
		table.insert(pvpBoards, board)
	end

	local status = UiTheme.Label({
		parent = root,
		name = "Status",
		size = UDim2.new(1, 0, 0, 14),
		position = UDim2.new(0, 0, 1, -16),
		textSize = 10,
		color = C.TextDim,
		xAlign = Enum.TextXAlignment.Center,
	})

	return function(seasonText: string, statusText: string)
		seasonLabel.Text = seasonText
		status.Text = statusText
	end
end

local function loadCatalog(): boolean
	local ok, catalog = pcall(function()
		return GetLeaderboardCatalog:InvokeServer()
	end)
	if not ok or typeof(catalog) ~= "table" then
		return false
	end
	catalogSeason = catalog.season
	table.clear(catalogBoards)
	for _, board in catalog.boards or {} do
		table.insert(catalogBoards, board)
	end
	return catalogSeason ~= nil
end

local function fetchBoard(boardId: string, limit: number): { any }
	if not catalogSeason then
		return {}
	end
	local ok, result = pcall(function()
		return GetLeaderboard:InvokeServer(catalogSeason.id, boardId, limit)
	end)
	if ok and typeof(result) == "table" and result.ok == true then
		return result.entries or {}
	end
	return {}
end

local function fetchMergedPve(kind: string, partyRankLimit: number): { LeaderboardPveMerge.MergedEntry }
	local boards = LeaderboardPveMerge.FilterBoards(catalogBoards, kind)
	local fetchLimit = math.max(partyRankLimit, ROWS_PER_BOARD)
	local byBoard: { [string]: { any } } = {}
	for _, board in boards do
		byBoard[board.id] = fetchBoard(board.id, fetchLimit)
	end
	return LeaderboardPveMerge.Merge(boards, byBoard, kind, partyRankLimit, nil)
end

local function refreshAll(setPveStatus: (string, string) -> (), setPvpStatus: (string, string) -> ())
	if not catalogSeason then
		setPveStatus("", "Leaderboard unavailable")
		setPvpStatus("", "Leaderboard unavailable")
		return
	end

	local seasonText = `{catalogSeason.name} ({catalogSeason.id})`
	setPveStatus(seasonText, "Updating…")
	setPvpStatus(seasonText, "Updating…")

	for _, list in pveLists do
		list:setEntries(fetchMergedPve(list.kind, ROWS_PER_BOARD))
	end
	for _, board in pvpBoards do
		board:setEntries(fetchBoard(board.boardId, ROWS_PER_BOARD))
	end

	local statusText = `Refreshes every {REFRESH_SEC}s`
	setPveStatus(seasonText, statusText)
	setPvpStatus(seasonText, statusText)
end

local pveScreen = waitForScreen("PvE")
local pvpScreen = waitForScreen("PvP")

if not pveScreen or not pvpScreen then
	warn("[LeaderboardScreen] PvE or PvP screen part not found")
	return
end

local setPveStatus = buildPveDisplay(pveScreen)
local setPvpStatus = buildPvpDisplay(pvpScreen)

if not loadCatalog() then
	setPveStatus("", "Catalog unavailable")
	setPvpStatus("", "Catalog unavailable")
	return
end

refreshAll(setPveStatus, setPvpStatus)

task.spawn(function()
	while pveScreen.Parent and pvpScreen.Parent do
		task.wait(REFRESH_SEC)
		refreshAll(setPveStatus, setPvpStatus)
	end
end)

print("[LeaderboardScreen] PvE + PvP split wall displays ready")
