--[[
	Forge panel — Attach handle/blade/pommel/gem then Forge into a weapon frame.
	Split from GearUI to stay under Luau's 200-local register limit.
]]

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)

local GearForgePanel = {}

export type ForgeApi = {
	attached: { handle: string?, blade: string?, pommel: string?, gem: string? },
	isUuidInForge: (uuid: string) -> boolean,
	clear: () -> (),
	refresh: () -> (),
	pruneAfterSnapshot: (findItem: (uuid: string?) -> any, onForged: (() -> ())?) -> (),
}

export type MountDeps = {
	parent: Frame,
	colors: {
		slot: Color3,
		slotEq: Color3,
		text: Color3,
		muted: Color3,
	},
	corner: (parent: Instance, r: number?) -> (),
	stroke: (parent: Instance, color: Color3?, t: number?) -> (),
	shortName: (name: string, maxLen: number) -> string,
	toast: (msg: string, dur: number?, kind: string?) -> (),
	getSelectedUuid: () -> string?,
	setSelectedUuid: (uuid: string?) -> (),
	findItemByUuid: (uuid: string?) -> any,
	refreshInventory: () -> (),
	refreshDetail: () -> (),
	forgeRemote: RemoteEvent,
}

local FORGE_SLOT_ORDER = { "handle", "blade", "pommel", "gem" }
local FORGE_SLOT_KIND = {
	handle = "WeaponHandle",
	blade = "WeaponBlade",
	pommel = "WeaponPommel",
	gem = "ElementGem",
}

function GearForgePanel.Mount(deps: MountDeps): ForgeApi
	local attached = {
		handle = nil :: string?,
		blade = nil :: string?,
		pommel = nil :: string?,
		gem = nil :: string?,
	}

	local forgePanel = Instance.new("Frame")
	forgePanel.Name = "ForgePanel"
	forgePanel.Size = UDim2.new(1, -20, 0, 100)
	forgePanel.Position = UDim2.new(0, 10, 0.36, 0)
	forgePanel.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
	forgePanel.BorderSizePixel = 0
	forgePanel.Parent = deps.parent
	deps.corner(forgePanel, 8)
	deps.stroke(forgePanel, Color3.fromRGB(90, 110, 70))

	local forgeTitle = Instance.new("TextLabel")
	forgeTitle.Size = UDim2.new(1, -110, 0, 18)
	forgeTitle.Position = UDim2.fromOffset(8, 4)
	forgeTitle.BackgroundTransparency = 1
	forgeTitle.Font = Enum.Font.GothamBold
	forgeTitle.TextSize = 11
	forgeTitle.TextColor3 = Color3.fromRGB(170, 200, 120)
	forgeTitle.TextXAlignment = Enum.TextXAlignment.Left
	forgeTitle.Text = "FORGE  ·  select part → Attach slot"
	forgeTitle.Parent = forgePanel

	local forgeHint = Instance.new("TextLabel")
	forgeHint.Size = UDim2.new(1, -16, 0, 14)
	forgeHint.Position = UDim2.fromOffset(8, 82)
	forgeHint.BackgroundTransparency = 1
	forgeHint.Font = Enum.Font.Gotham
	forgeHint.TextSize = 10
	forgeHint.TextColor3 = deps.colors.muted
	forgeHint.TextXAlignment = Enum.TextXAlignment.Left
	forgeHint.Text = "Empty slot click = detach · needs Handle + Blade + Pommel"
	forgeHint.Parent = forgePanel

	local forgeButtons: { [string]: TextButton } = {}
	local forgeLabels: { [string]: TextLabel } = {}

	local forgeBtn = Instance.new("TextButton")
	forgeBtn.Size = UDim2.fromOffset(88, 52)
	forgeBtn.Position = UDim2.new(1, -96, 0, 22)
	forgeBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
	forgeBtn.BorderSizePixel = 0
	forgeBtn.Font = Enum.Font.GothamBold
	forgeBtn.TextSize = 14
	forgeBtn.TextColor3 = deps.colors.text
	forgeBtn.Text = "FORGE"
	forgeBtn.Parent = forgePanel
	deps.corner(forgeBtn, 6)

	local function clear()
		attached.handle = nil
		attached.blade = nil
		attached.pommel = nil
		attached.gem = nil
	end

	local function isUuidInForge(uuid: string): boolean
		return attached.handle == uuid
			or attached.blade == uuid
			or attached.pommel == uuid
			or attached.gem == uuid
	end

	local function forgeCompatOk(slotName: string, defId: string): (boolean, string?)
		local def = ItemDefs.Get(defId)
		if not def then
			return false, "Unknown"
		end
		local needKind = FORGE_SLOT_KIND[slotName]
		if def.kind ~= needKind then
			return false, "WrongPart"
		end
		if slotName == "blade" or slotName == "pommel" then
			local handleUuid = attached.handle
			if handleUuid then
				local hItem = deps.findItemByUuid(handleUuid)
				local hDef = hItem and ItemDefs.Get(hItem.defId)
				local ht = hDef and hDef.handleType
				if slotName == "blade" and ht and def.handleType and def.handleType ~= ht then
					return false, "IncompatibleHandle"
				end
				if slotName == "pommel" then
					local role = (def :: any).pommelRole or "Pommel"
					local ranged = ht == "2H_Bow" or ht == "2H_Crossbow"
					if ranged and role ~= "String" then
						return false, "NeedString"
					end
					if not ranged and role ~= "Pommel" then
						return false, "NeedPommel"
					end
				end
			end
		elseif slotName == "handle" then
			local bladeUuid = attached.blade
			if bladeUuid then
				local bItem = deps.findItemByUuid(bladeUuid)
				local bDef = bItem and ItemDefs.Get(bItem.defId)
				if bDef and bDef.handleType and def.handleType and bDef.handleType ~= def.handleType then
					return false, "IncompatibleBlade"
				end
			end
		end
		return true, nil
	end

	local function refresh()
		local ready = attached.handle ~= nil and attached.blade ~= nil and attached.pommel ~= nil
		forgeBtn.BackgroundColor3 = if ready then Color3.fromRGB(80, 150, 80) else Color3.fromRGB(55, 70, 55)
		for _, slotName in FORGE_SLOT_ORDER do
			local uuid = attached[slotName]
			local btn = forgeButtons[slotName]
			local label = forgeLabels[slotName]
			if uuid then
				local item = deps.findItemByUuid(uuid)
				local def = item and ItemDefs.Get(item.defId)
				label.Text = deps.shortName(def and def.name or "?", 9)
				btn.BackgroundColor3 = deps.colors.slotEq
			else
				label.Text = "Attach"
				btn.BackgroundColor3 = deps.colors.slot
			end
		end
	end

	for i, slotName in FORGE_SLOT_ORDER do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(64, 52)
		btn.Position = UDim2.fromOffset(8 + (i - 1) * 70, 22)
		btn.BackgroundColor3 = deps.colors.slot
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 9
		btn.TextColor3 = deps.colors.text
		btn.Text = ""
		btn.Parent = forgePanel
		deps.corner(btn, 6)
		deps.stroke(btn)

		local cap = Instance.new("TextLabel")
		cap.Size = UDim2.new(1, -4, 0, 12)
		cap.Position = UDim2.fromOffset(2, 2)
		cap.BackgroundTransparency = 1
		cap.Font = Enum.Font.Gotham
		cap.TextSize = 9
		cap.TextColor3 = deps.colors.muted
		cap.Text = string.upper(slotName)
		cap.ZIndex = 2
		cap.Parent = btn

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -4, 0, 28)
		name.Position = UDim2.fromOffset(2, 18)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 9
		name.TextColor3 = deps.colors.text
		name.TextWrapped = true
		name.Text = "Attach"
		name.ZIndex = 2
		name.Parent = btn

		forgeButtons[slotName] = btn
		forgeLabels[slotName] = name

		btn.MouseButton1Click:Connect(function()
			local selectedUuid = deps.getSelectedUuid()
			if selectedUuid then
				local item = deps.findItemByUuid(selectedUuid)
				if not item or item.installedIn then
					deps.toast("Pick a free part from inventory.", 2, "warn")
					return
				end
				if isUuidInForge(selectedUuid) then
					deps.toast("Already attached in forge.", 2, "warn")
					return
				end
				local ok, err = forgeCompatOk(slotName, item.defId)
				if not ok then
					deps.toast(err or "Cannot attach.", 2, "error")
					return
				end
				for _, s in FORGE_SLOT_ORDER do
					if attached[s] == selectedUuid then
						attached[s] = nil
					end
				end
				attached[slotName] = selectedUuid
				deps.setSelectedUuid(nil)
				refresh()
				deps.refreshInventory()
				deps.refreshDetail()
			else
				if attached[slotName] then
					attached[slotName] = nil
					refresh()
					deps.refreshInventory()
				end
			end
		end)
	end

	forgeBtn.MouseButton1Click:Connect(function()
		if not attached.handle or not attached.blade or not attached.pommel then
			deps.toast("Attach Handle + Blade + Pommel first.", 2.5, "warn")
			return
		end
		deps.forgeRemote:FireServer(attached.handle, attached.blade, attached.pommel, attached.gem)
		deps.toast("Forging…", 1.5, "info")
	end)

	local function pruneAfterSnapshot(findItem: (uuid: string?) -> any, onForged: (() -> ())?)
		local forged = false
		for _, slotName in FORGE_SLOT_ORDER do
			local uuid = attached[slotName]
			if uuid then
				local item = findItem(uuid)
				if item and item.installedIn then
					forged = true
					break
				end
			end
		end
		if forged then
			clear()
			if onForged then
				onForged()
			end
		end
	end

	return {
		attached = attached,
		isUuidInForge = isUuidInForge,
		clear = clear,
		refresh = refresh,
		pruneAfterSnapshot = pruneAfterSnapshot,
	}
end

return GearForgePanel
