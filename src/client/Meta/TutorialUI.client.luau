--[[
	Tutorial overlay — shows next onboarding step in lobby.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local meta = ReplicatedStorage:WaitForChild("MetaRemotes", 15)
if not meta then
	return
end
local GetTutorialState = meta:WaitForChild("GetTutorialState") :: RemoteFunction
local CompleteTutorialStep = meta:WaitForChild("CompleteTutorialStep") :: RemoteEvent

local hints: { [string]: string } = {
	open_gear = "Press I to open Gear / Inventory",
	equip_weapon = "Install a complete weapon frame in Main slot",
	light_attack = "Left-click to light attack the Training Dummy",
	queue_pvp = "Press J → queue PvP Practice or Boss",
	allocate_stat = "Spend stat points in Gear UI Stats panel",
}

local gui = UiTheme.ScreenGui({
	name = "TutorialUI",
	displayOrder = UiTheme.DisplayOrder.Tutorial,
	ignoreInset = false,
})
gui.Parent = playerGui

local label = UiTheme.Label({
	parent = gui,
	size = UDim2.fromOffset(360, 48),
	position = UDim2.new(1, -372, 0, 12),
	bg = C.BgElevated,
	textSize = UiTheme.TextSize.Subtitle,
	color = C.Text,
	wrapped = true,
	radius = UiTheme.Radius.Md,
})
label.BackgroundTransparency = 0.2

local function refresh()
	local ok, state = pcall(function()
		return GetTutorialState:InvokeServer()
	end)
	if not ok or typeof(state) ~= "table" then
		label.Visible = false
		return
	end
	local step = state.nextStep
	if not step then
		label.Visible = false
		return
	end
	label.Visible = true
	label.Text = `Tutorial: {hints[step] or step}`
end

task.spawn(function()
	while true do
		refresh()
		task.wait(3)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		CompleteTutorialStep:FireServer("open_gear")
	end
end)
