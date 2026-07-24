--[[

	Full leaderboard browser — top 100 (L toggle, lobby).

	PvE: merged player > boss > stat lists. PvP: per-bracket MMR.

]]



local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local UserInputService = game:GetService("UserInputService")



local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)

if not PlaceRuntime.IsLobby() then

	return

end



local SeasonConfig = require(ReplicatedStorage.Shared.Config.SeasonConfig)

local LeaderboardPveMerge = require(ReplicatedStorage.Shared.Meta.LeaderboardPveMerge)

local UiTheme = require(script.Parent.Parent.UI.UiTheme)

local C = UiTheme.Colors



local LIST_LIMIT = SeasonConfig.LeaderboardUiMax

local ROW_HEIGHT = 28

local PVE_KILLS_ID = "pve_kills"

local PVE_SPEED_ID = "pve_speed"



local RANK_COLORS = {

	Color3.fromRGB(255, 210, 90),

	Color3.fromRGB(210, 220, 235),

	Color3.fromRGB(210, 150, 110),

}



type BoardDef = LeaderboardPveMerge.BoardDef & {

	virtual: boolean?,

}



local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")



local remotes = ReplicatedStorage:WaitForChild("CareerRemotes", 30)

if not remotes then

	return

end



local GetLeaderboard = remotes:WaitForChild("GetLeaderboard") :: RemoteFunction

local GetLeaderboardCatalog = remotes:WaitForChild("GetLeaderboardCatalog") :: RemoteFunction



local open = false

local loading = false

local uiBoards: { BoardDef } = {}

local catalogBoards: { BoardDef } = {}

local boardById: { [string]: BoardDef } = {}

local selectedBoardId: string? = nil

local seasonInfo: { id: string, name: string }? = nil



local gui = UiTheme.ScreenGui({

	name = "LeaderboardUI",

	displayOrder = UiTheme.DisplayOrder.Leaderboard,

	ignoreInset = false,

})

gui.Parent = playerGui



local panel = UiTheme.Panel({

	parent = gui,

	name = "Panel",

	size = UDim2.fromOffset(580, 580),

	position = UDim2.new(0.5, -290, 0.5, -290),

	visible = false,

	radius = UiTheme.Radius.Lg,

	stroke = true,

})



UiTheme.Label({

	parent = panel,

	text = "Leaderboards  (L)",

	size = UDim2.new(1, -16, 0, 28),

	position = UDim2.fromOffset(12, 10),

	font = UiTheme.Font.Title,

	textSize = UiTheme.TextSize.Heading,

})



local seasonLabel = UiTheme.Label({

	parent = panel,

	size = UDim2.new(1, -16, 0, 16),

	position = UDim2.fromOffset(12, 36),

	textSize = UiTheme.TextSize.Caption,

	color = C.TextMuted,

})



local boardScroll = UiTheme.ScrollFrame({

	parent = panel,

	name = "BoardList",

	size = UDim2.fromOffset(168, 470),

	position = UDim2.fromOffset(10, 58),

	bgTransparency = 0.35,

})

boardScroll.BackgroundColor3 = C.BgElevated

UiTheme.Corner(boardScroll, UiTheme.Radius.Sm)

UiTheme.Padding(boardScroll, UiTheme.Spacing.Xs)



local boardLayout = Instance.new("UIListLayout")

boardLayout.Padding = UDim.new(0, 4)

boardLayout.Parent = boardScroll



local listPanel = UiTheme.Panel({

	parent = panel,

	name = "Entries",

	size = UDim2.new(1, -196, 0, 446),

	position = UDim2.fromOffset(186, 58),

	bg = C.BgElevated,

	transparency = 0.1,

	radius = UiTheme.Radius.Md,

	stroke = true,

})



local boardTitle = UiTheme.Label({

	parent = listPanel,

	name = "BoardTitle",

	size = UDim2.new(1, -12, 0, 22),

	position = UDim2.fromOffset(8, 6),

	font = UiTheme.Font.Title,

	textSize = UiTheme.TextSize.Subtitle,

	color = C.Accent,

})



local columnHeader = UiTheme.Label({

	parent = listPanel,

	name = "Columns",

	size = UDim2.new(1, -12, 0, 16),

	position = UDim2.fromOffset(8, 30),

	font = UiTheme.Font.Title,

	textSize = UiTheme.TextSize.Caption,

	color = C.TextDim,

	text = "#    PLAYER > BOSS > SCORE",

})



local entryScroll = UiTheme.ScrollFrame({

	parent = listPanel,

	name = "EntryScroll",

	size = UDim2.new(1, -12, 1, -58),

	position = UDim2.fromOffset(6, 48),

})

UiTheme.Padding(entryScroll, 2)



local entryLayout = Instance.new("UIListLayout")

entryLayout.Padding = UDim.new(0, 2)

entryLayout.Parent = entryScroll



local footer = UiTheme.Label({

	parent = panel,

	size = UDim2.new(1, -20, 0, 18),

	position = UDim2.new(0, 10, 1, -42),

	textSize = UiTheme.TextSize.Subtitle,

	color = C.TextMuted,

	rich = true,

	xAlign = Enum.TextXAlignment.Center,

})



local status = UiTheme.Label({

	parent = panel,

	size = UDim2.new(1, -20, 0, 14),

	position = UDim2.new(0, 10, 1, -22),

	textSize = UiTheme.TextSize.Caption,

	color = C.TextDim,

	xAlign = Enum.TextXAlignment.Center,

})



local boardButtons: { [string]: TextButton } = {}



local function isPveVirtual(boardId: string): boolean

	return boardId == PVE_KILLS_ID or boardId == PVE_SPEED_ID

end



local function pveKindForVirtual(boardId: string): string

	return if boardId == PVE_KILLS_ID then "boss_kills" else "boss_speed"

end



local function fetchBoardEntries(boardId: string, limit: number): { any }

	if not seasonInfo then

		return {}

	end

	local ok, result = pcall(function()

		return GetLeaderboard:InvokeServer(seasonInfo.id, boardId, limit)

	end)

	if ok and typeof(result) == "table" and result.ok == true then

		return result.entries or {}

	end

	return {}

end



local function fetchMergedPve(kind: string): { LeaderboardPveMerge.MergedEntry }

	local boards = LeaderboardPveMerge.FilterBoards(catalogBoards, kind)

	local byBoard: { [string]: { any } } = {}

	for _, board in boards do

		byBoard[board.id] = fetchBoardEntries(board.id, LIST_LIMIT)

	end

	return LeaderboardPveMerge.Merge(boards, byBoard, kind, LIST_LIMIT, nil)

end



local function clearEntries()

	for _, child in entryScroll:GetChildren() do

		if child:IsA("Frame") then

			child:Destroy()

		end

	end

end



local function createLineRow(rank: number, lineText: string, detail: string?)

	local rowH = if detail and detail ~= "" then ROW_HEIGHT + 12 else ROW_HEIGHT

	local row = UiTheme.Panel({

		parent = entryScroll,

		size = UDim2.new(1, -4, 0, rowH),

		bg = if rank % 2 == 0 then C.Panel else C.BgElevated,

		transparency = 0.35,

		radius = UiTheme.Radius.Xs,

	})



	UiTheme.Label({

		parent = row,

		size = UDim2.fromOffset(28, rowH),

		position = UDim2.fromOffset(6, 0),

		font = UiTheme.Font.Title,

		textSize = UiTheme.TextSize.Body,

		color = RANK_COLORS[rank] or C.TextMuted,

		xAlign = Enum.TextXAlignment.Center,

		text = if rank > 0 then tostring(rank) else "—",

	})



	local textH = if detail and detail ~= "" then 16 else rowH

	UiTheme.Label({

		parent = row,

		size = UDim2.new(1, -40, 0, textH),

		position = UDim2.fromOffset(36, 0),

		font = UiTheme.Font.Body,

		textSize = UiTheme.TextSize.Body,

		text = lineText,

	})



	if detail and detail ~= "" then

		UiTheme.Label({

			parent = row,

			size = UDim2.new(1, -40, 0, 12),

			position = UDim2.fromOffset(36, 16),

			font = UiTheme.Font.Body,

			textSize = UiTheme.TextSize.Caption,

			color = C.TextDim,

			text = detail,

		})

	end



	return rowH + 2

end



local function createMmrRow(rank: number, playerName: string, score: string)

	local row = UiTheme.Panel({

		parent = entryScroll,

		size = UDim2.new(1, -4, 0, ROW_HEIGHT),

		bg = if rank % 2 == 0 then C.Panel else C.BgElevated,

		transparency = 0.35,

		radius = UiTheme.Radius.Xs,

	})



	UiTheme.Label({

		parent = row,

		size = UDim2.fromOffset(28, ROW_HEIGHT),

		position = UDim2.fromOffset(6, 0),

		font = UiTheme.Font.Title,

		textSize = UiTheme.TextSize.Body,

		color = RANK_COLORS[rank] or C.TextMuted,

		xAlign = Enum.TextXAlignment.Center,

		text = tostring(rank),

	})



	UiTheme.Label({

		parent = row,

		size = UDim2.new(1, -120, 0, ROW_HEIGHT),

		position = UDim2.fromOffset(36, 0),

		font = UiTheme.Font.Body,

		textSize = UiTheme.TextSize.Body,

		text = playerName,

	})



	UiTheme.Label({

		parent = row,

		size = UDim2.fromOffset(80, ROW_HEIGHT),

		position = UDim2.new(1, -86, 0, 0),

		font = UiTheme.Font.Title,

		textSize = UiTheme.TextSize.Body,

		color = C.TextBright,

		xAlign = Enum.TextXAlignment.Right,

		text = score,

	})



	return ROW_HEIGHT + 2

end



local function renderPveMerged(entries: { LeaderboardPveMerge.MergedEntry }, kind: string)

	clearEntries()

	if #entries == 0 then

		createLineRow(0, "No entries yet — be the first!", nil)

		entryScroll.CanvasSize = UDim2.fromOffset(0, ROW_HEIGHT + 4)

		return

	end



	local totalH = 0

	for _, entry in entries do

		totalH += createLineRow(entry.rank, LeaderboardPveMerge.FormatRow(entry, kind), nil)

	end

	entryScroll.CanvasSize = UDim2.fromOffset(0, totalH)

	entryScroll.CanvasPosition = Vector2.zero

end



local function renderMmr(entries: { any })

	clearEntries()

	if #entries == 0 then

		createLineRow(0, "No entries yet — be the first!", nil)

		entryScroll.CanvasSize = UDim2.fromOffset(0, ROW_HEIGHT + 4)

		return

	end



	local totalH = 0

	for _, entry in entries do

		totalH += createMmrRow(entry.rank, entry.displayName, `{math.floor(entry.score)} MMR`)

	end

	entryScroll.CanvasSize = UDim2.fromOffset(0, totalH)

	entryScroll.CanvasPosition = Vector2.zero

end



local function updateBoardButtons()

	for id, btn in boardButtons do

		local selected = id == selectedBoardId

		btn.BackgroundColor3 = if selected then C.AccentMuted else C.Button

		btn.TextColor3 = if selected then C.TextBright else C.TextMuted

	end

end



local function refreshBoard()

	if loading or not selectedBoardId or not seasonInfo then

		return

	end

	local board = boardById[selectedBoardId]

	if not board then

		return

	end



	loading = true

	status.Text = "Loading…"

	boardTitle.Text = board.displayName



	if isPveVirtual(selectedBoardId) then

		local kind = pveKindForVirtual(selectedBoardId)

		columnHeader.Text = "#    PLAYER > BOSS > SCORE"

		local entries = fetchMergedPve(kind)

		loading = false

		renderPveMerged(entries, kind)

		local myRank: number? = nil

		for _, entry in entries do

			if entry.userId == player.UserId then

				myRank = entry.rank

				break

			end

		end

		local rankText = if myRank then `<font color="#E8C85A">#{myRank}</font>` else "unranked"

		footer.Text = `Your rank: {rankText}  ·  Top {LIST_LIMIT}`

		status.Text = "Wall screens show top 10"

		return

	end



	columnHeader.Text = "#    PLAYER                              MMR"

	local ok, result = pcall(function()

		return GetLeaderboard:InvokeServer(seasonInfo.id, selectedBoardId, LIST_LIMIT)

	end)

	loading = false



	if not ok or typeof(result) ~= "table" or result.ok ~= true then

		status.Text = "Could not load leaderboard"

		renderMmr({})

		footer.Text = ""

		return

	end



	renderMmr(result.entries or {})

	local rankText = if result.viewerRank

		then `<font color="#E8C85A">#{result.viewerRank}</font>`

		else "unranked"

	footer.Text = `Your rank: {rankText}  ·  Top {LIST_LIMIT}`

	status.Text = "Wall screens show top 10"

end



local function selectBoard(boardId: string)

	if selectedBoardId == boardId then

		return

	end

	selectedBoardId = boardId

	updateBoardButtons()

	refreshBoard()

end



local function rebuildBoardList()

	for _, child in boardScroll:GetChildren() do

		if child:IsA("TextButton") then

			child:Destroy()

		end

	end

	table.clear(boardButtons)



	for i, board in uiBoards do

		local btn = UiTheme.Button({

			parent = boardScroll,

			name = board.id,

			text = board.displayName,

			size = UDim2.new(1, -4, 0, 34),

			variant = "button",

			font = UiTheme.Font.Body,

			textSize = UiTheme.TextSize.Caption,

			autoButtonColor = false,

		})

		btn.LayoutOrder = i

		btn.TextWrapped = true

		boardButtons[board.id] = btn

		btn.MouseButton1Click:Connect(function()

			selectBoard(board.id)

		end)

	end



	boardScroll.CanvasSize = UDim2.fromOffset(0, #uiBoards * 38)

	updateBoardButtons()

end



local function buildUiBoards()

	table.clear(uiBoards)

	table.clear(boardById)



	local hasKills = #LeaderboardPveMerge.FilterBoards(catalogBoards, "boss_kills") > 0

	local hasSpeed = #LeaderboardPveMerge.FilterBoards(catalogBoards, "boss_speed") > 0



	if hasKills then

		local killsBoard: BoardDef = {

			id = PVE_KILLS_ID,

			displayName = "PvE — Most Kills",

			kind = "boss_kills",

			virtual = true,

		}

		table.insert(uiBoards, killsBoard)

		boardById[PVE_KILLS_ID] = killsBoard

	end



	if hasSpeed then

		local speedBoard: BoardDef = {

			id = PVE_SPEED_ID,

			displayName = "PvE — Fastest Clear",

			kind = "boss_speed",

			virtual = true,

		}

		table.insert(uiBoards, speedBoard)

		boardById[PVE_SPEED_ID] = speedBoard

	end



	for _, board in catalogBoards do

		if board.kind == "mmr" then

			table.insert(uiBoards, board)

			boardById[board.id] = board

		end

	end

end



local function loadCatalog(): boolean

	local ok, catalog = pcall(function()

		return GetLeaderboardCatalog:InvokeServer()

	end)

	if not ok or typeof(catalog) ~= "table" then

		return false

	end



	seasonInfo = catalog.season

	table.clear(catalogBoards)

	for _, board in catalog.boards or {} do

		table.insert(catalogBoards, board)

	end



	if seasonInfo then

		seasonLabel.Text = `{seasonInfo.name} ({seasonInfo.id})  ·  ranks 1–{LIST_LIMIT}`

	end



	buildUiBoards()

	rebuildBoardList()

	if not selectedBoardId and uiBoards[1] then

		selectedBoardId = uiBoards[1].id

	end

	updateBoardButtons()

	return #uiBoards > 0

end



local function setOpen(value: boolean)

	open = value

	panel.Visible = open

	if open then

		if #uiBoards == 0 then

			if not loadCatalog() then

				status.Text = "Leaderboard unavailable"

				return

			end

		end

		refreshBoard()

	end

end



UserInputService.InputBegan:Connect(function(input, processed)

	if processed then

		return

	end

	if input.KeyCode == Enum.KeyCode.L then

		setOpen(not open)

	end

end)



print(`[LeaderboardUI] Press L for full leaderboard (top {LIST_LIMIT})`)


