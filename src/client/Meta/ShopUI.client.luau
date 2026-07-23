--[[
	Premium shop UI — lobby only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local PlaceRuntime = require(ReplicatedStorage.Shared.Config.PlaceRuntime)
if not PlaceRuntime.IsLobby() then
	return
end

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiToast = require(script.Parent.Parent.UI.UiToast)
local UiTheme = require(script.Parent.Parent.UI.UiTheme)
local C = UiTheme.Colors

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local meta = ReplicatedStorage:WaitForChild("MetaRemotes", 15)
if not meta then
	return
end
local ShopPurchase = meta:WaitForChild("ShopPurchase") :: RemoteEvent
local ShopPurchaseResult = meta:WaitForChild("ShopPurchaseResult", 10) :: RemoteEvent?

local SHOP_ERRORS = {
	NotEnoughPremium = "Not enough premium currency.",
	UnknownOffer = "Unknown shop offer.",
	LootBoxNotSold = "Lootboxes are not sold in the shop.",
}

local gui = UiTheme.ScreenGui({
	name = "ShopUI",
	displayOrder = UiTheme.DisplayOrder.Shop,
	ignoreInset = false,
})
gui.Parent = playerGui

local panel = UiTheme.Panel({
	parent = gui,
	name = "Panel",
	size = UDim2.fromOffset(280, 200),
	position = UDim2.new(1, -292, 0, 70),
	visible = false,
	radius = UiTheme.Radius.Md,
})

UiTheme.Label({
	parent = panel,
	text = "Shop (B)",
	size = UDim2.new(1, -12, 0, 24),
	position = UDim2.fromOffset(8, 6),
	font = UiTheme.Font.Title,
	textSize = UiTheme.TextSize.Title,
})

local status = UiTheme.Label({
	parent = panel,
	size = UDim2.new(1, -16, 0, 16),
	position = UDim2.new(0, 8, 1, -22),
	textSize = UiTheme.TextSize.Caption,
	color = C.TextMuted,
})

local y = 34
for _, offer in ShopConfig.Offers do
	local btn = UiTheme.Button({
		parent = panel,
		text = offer.label or offer.id,
		size = UDim2.new(1, -16, 0, 30),
		position = UDim2.fromOffset(8, y),
		variant = "button",
		font = UiTheme.Font.Body,
		textSize = UiTheme.TextSize.Body,
	})
	btn.MouseButton1Click:Connect(function()
		status.Text = "Purchasing…"
		status.TextColor3 = C.TextMuted
		ShopPurchase:FireServer(offer.id)
	end)
	y += 36
end
panel.Size = UDim2.fromOffset(280, y + 28)

if ShopPurchaseResult then
	ShopPurchaseResult.OnClientEvent:Connect(function(result: any)
		if typeof(result) ~= "table" then
			return
		end
		if result.ok then
			local label = "Purchase successful!"
			for _, offer in ShopConfig.Offers do
				if offer.id == result.offerId then
					label = `Purchased: {offer.label or offer.id}`
					break
				end
			end
			status.Text = label
			status.TextColor3 = C.SuccessBright
			UiToast.Show(label, 2.5, "success")
		else
			local reason = if typeof(result.reason) == "string" then result.reason else "Error"
			local msg = SHOP_ERRORS[reason] or reason
			status.Text = msg
			status.TextColor3 = C.DangerBright
			UiToast.Show(msg, 2.5, "error")
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		panel.Visible = not panel.Visible
		if panel.Visible then
			status.Text = ""
		end
	end
end)
