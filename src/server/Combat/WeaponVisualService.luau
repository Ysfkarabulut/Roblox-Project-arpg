--[[
	Placeholder gear visuals — type-proportional weapon parts + simple armor shells.
	Element tint + neon accent. Swap for mesh models later (same attach points).
]]

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local AnimConfig = require(game.ReplicatedStorage.Shared.Config.AnimConfig)
local WeaponFamilyConfig = require(game.ReplicatedStorage.Shared.Config.WeaponFamilyConfig)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local WeaponVisualService = {}

local function elementColor(element: string?): Color3
	return AnimConfig.ElementColor[element or "Neutral"] or Color3.fromRGB(200, 200, 210)
end

--- Armor: muted element tone (readable silhouette, not neon wash)
local function armorTone(element: string?): Color3
	local el = elementColor(element)
	return el:Lerp(Color3.fromRGB(40, 42, 48), 0.45)
end

local function accentTone(element: string?): Color3
	return elementColor(element)
end

local function metalBase(element: string?): Color3
	local el = elementColor(element)
	return el:Lerp(Color3.fromRGB(170, 175, 185), 0.35)
end

local function clearFolder(char: Model)
	local old = char:FindFirstChild("GearVisuals")
	if old then
		old:Destroy()
	end
end

local function weld(part: BasePart, parent: BasePart, folder: Folder, c0: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.CastShadow = true
	part.Parent = folder
	local w = Instance.new("Weld")
	w.Part0 = parent
	w.Part1 = part
	w.C0 = c0
	w.Parent = part
end

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function addAccentOrb(folder: Folder, hand: BasePart, offset: CFrame, element: string?, scale: number?)
	local s = scale or 0.45
	local gem = makePart("ElementAccent", Vector3.new(s, s, s), accentTone(element), Enum.Material.Neon)
	gem.Shape = Enum.PartType.Ball
	weld(gem, hand, folder, offset)
end

-- Proportional placeholder weapons by family (stud sizes tuned for R15 hand)
local function buildWeapon(familyKey: string, element: string?, folder: Folder, hand: BasePart)
	local bladeCol = metalBase(element)
	local accent = accentTone(element)
	local wood = Color3.fromRGB(90, 70, 50)

	if familyKey == "Sword1H" or familyKey == "Sword" then
		-- blade ~3.0 long, narrow
		local blade = makePart("Blade", Vector3.new(0.22, 3.0, 0.55), bladeCol, Enum.Material.Metal)
		weld(blade, hand, folder, CFrame.new(0, -1.35, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local guard = makePart("Guard", Vector3.new(0.9, 0.18, 0.35), accent, Enum.Material.Metal)
		weld(guard, hand, folder, CFrame.new(0, -0.35, 0))
		local hilt = makePart("Hilt", Vector3.new(0.28, 0.7, 0.28), wood)
		weld(hilt, hand, folder, CFrame.new(0, 0.05, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.7, 0), element, 0.35)
	elseif familyKey == "Sword2H" then
		local blade = makePart("Blade", Vector3.new(0.28, 4.4, 0.7), bladeCol, Enum.Material.Metal)
		weld(blade, hand, folder, CFrame.new(0, -2.0, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local guard = makePart("Guard", Vector3.new(1.2, 0.22, 0.4), accent, Enum.Material.Metal)
		weld(guard, hand, folder, CFrame.new(0, -0.4, 0))
		local hilt = makePart("Hilt", Vector3.new(0.32, 1.1, 0.32), wood)
		weld(hilt, hand, folder, CFrame.new(0, 0.2, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -4.0, 0), element, 0.4)
	elseif familyKey == "Axe1H" or familyKey == "Axe" then
		local haft = makePart("Haft", Vector3.new(0.22, 2.3, 0.22), wood)
		weld(haft, hand, folder, CFrame.new(0, -0.95, 0))
		local head = makePart("AxeHead", Vector3.new(1.35, 0.75, 0.32), bladeCol, Enum.Material.Metal)
		weld(head, hand, folder, CFrame.new(0.45, -1.95, 0))
		addAccentOrb(folder, hand, CFrame.new(0.9, -1.95, 0), element, 0.3)
	elseif familyKey == "Axe2H" then
		local haft = makePart("Haft", Vector3.new(0.28, 3.4, 0.28), wood)
		weld(haft, hand, folder, CFrame.new(0, -1.45, 0))
		local head = makePart("AxeHead", Vector3.new(1.9, 1.0, 0.4), bladeCol, Enum.Material.Metal)
		weld(head, hand, folder, CFrame.new(0.55, -2.95, 0))
		addAccentOrb(folder, hand, CFrame.new(1.2, -2.95, 0), element, 0.4)
	elseif familyKey == "Mace1H" or familyKey == "Mace" then
		local haft = makePart("Haft", Vector3.new(0.26, 2.1, 0.26), wood)
		weld(haft, hand, folder, CFrame.new(0, -0.85, 0))
		local head = makePart("MaceHead", Vector3.new(1.05, 1.05, 1.05), bladeCol, Enum.Material.Metal)
		head.Shape = Enum.PartType.Ball
		weld(head, hand, folder, CFrame.new(0, -2.1, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.1, 0.55), element, 0.28)
	elseif familyKey == "Mace2H" then
		local haft = makePart("Haft", Vector3.new(0.3, 3.1, 0.3), wood)
		weld(haft, hand, folder, CFrame.new(0, -1.35, 0))
		local head = makePart("MaceHead", Vector3.new(1.45, 1.45, 1.45), bladeCol, Enum.Material.Metal)
		weld(head, hand, folder, CFrame.new(0, -2.95, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.95, 0.7), element, 0.35)
	elseif familyKey == "Dagger" then
		local blade = makePart("Blade", Vector3.new(0.18, 1.5, 0.4), bladeCol, Enum.Material.Metal)
		weld(blade, hand, folder, CFrame.new(0, -0.65, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local hilt = makePart("Hilt", Vector3.new(0.22, 0.45, 0.22), wood)
		weld(hilt, hand, folder, CFrame.new(0, 0.05, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -1.35, 0), element, 0.22)
	elseif familyKey == "Wand" then
		local rod = makePart("Rod", Vector3.new(0.18, 1.9, 0.18), wood)
		weld(rod, hand, folder, CFrame.new(0, -0.75, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -1.75, 0), element, 0.5)
	elseif familyKey == "Scepter" then
		local rod = makePart("Rod", Vector3.new(0.22, 2.5, 0.22), wood)
		weld(rod, hand, folder, CFrame.new(0, -1.05, 0))
		local gem = makePart("Gem", Vector3.new(0.75, 0.75, 0.75), accent, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		weld(gem, hand, folder, CFrame.new(0, -2.4, 0))
	elseif familyKey == "Staff" then
		local rod = makePart("Rod", Vector3.new(0.26, 4.0, 0.26), wood)
		weld(rod, hand, folder, CFrame.new(0, -1.7, 0))
		local gem = makePart("Gem", Vector3.new(0.95, 0.95, 0.95), accent, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		weld(gem, hand, folder, CFrame.new(0, -3.85, 0))
	elseif familyKey == "Bow" then
		local upper = makePart("UpperLimb", Vector3.new(0.18, 1.7, 0.18), bladeCol)
		weld(upper, hand, folder, CFrame.new(0, 0.7, -0.45) * CFrame.Angles(0, 0, math.rad(18)))
		local lower = makePart("LowerLimb", Vector3.new(0.18, 1.7, 0.18), bladeCol)
		weld(lower, hand, folder, CFrame.new(0, -0.7, -0.45) * CFrame.Angles(0, 0, math.rad(-18)))
		local grip = makePart("Grip", Vector3.new(0.22, 0.5, 0.22), wood)
		weld(grip, hand, folder, CFrame.new(0, 0, -0.35))
		addAccentOrb(folder, hand, CFrame.new(0, 0, -0.7), element, 0.3)
	elseif familyKey == "Crossbow" then
		local body = makePart("Body", Vector3.new(0.35, 0.4, 2.0), wood)
		weld(body, hand, folder, CFrame.new(0, -0.15, -0.75))
		local limbs = makePart("Limbs", Vector3.new(2.1, 0.22, 0.22), bladeCol, Enum.Material.Metal)
		weld(limbs, hand, folder, CFrame.new(0, -0.15, -1.55))
		addAccentOrb(folder, hand, CFrame.new(0, -0.15, -1.9), element, 0.32)
	else
		local blade = makePart("Blade", Vector3.new(0.22, 2.8, 0.5), bladeCol, Enum.Material.Metal)
		weld(blade, hand, folder, CFrame.new(0, -1.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
		addAccentOrb(folder, hand, CFrame.new(0, -2.5, 0), element, 0.3)
	end
end

local function buildShield(defId: string, element: string?, folder: Folder, hand: BasePart)
	local col = armorTone(element)
	local trim = accentTone(element)
	local size = Vector3.new(0.32, 2.1, 1.5) -- kite default
	if defId == "o_buckler" then
		size = Vector3.new(0.28, 1.35, 1.35)
	elseif defId == "o_tower" then
		size = Vector3.new(0.38, 3.1, 1.75)
	elseif defId == "o_round" then
		size = Vector3.new(0.3, 1.7, 1.7)
	elseif defId == "o_spiked" then
		size = Vector3.new(0.34, 1.95, 1.45)
	end
	local shield = makePart("Shield", size, col, Enum.Material.Metal)
	weld(shield, hand, folder, CFrame.new(0, -0.15, 0.65))
	local boss = makePart("ShieldBoss", Vector3.new(0.2, 0.55, 0.55), trim, Enum.Material.Neon)
	boss.Shape = Enum.PartType.Cylinder
	weld(boss, hand, folder, CFrame.new(0.2, -0.15, 0.65) * CFrame.Angles(0, 0, math.rad(90)))
	if defId == "o_spiked" then
		local spike = makePart("Spike", Vector3.new(0.25, 0.7, 0.25), trim, Enum.Material.Metal)
		weld(spike, hand, folder, CFrame.new(0.45, -0.15, 0.65))
	end
end

local function findPart(char: Model, names: { string }): BasePart?
	for _, n in names do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

local function buildArmorPiece(slot: string, element: string?, folder: Folder, char: Model)
	local tone = armorTone(element)
	local trim = accentTone(element)

	if slot == "head" then
		local head = findPart(char, { "Head" })
		if not head then
			return
		end
		-- Simple helm shell slightly larger than head
		local helm = makePart("Helm", Vector3.new(1.35, 1.0, 1.35), tone, Enum.Material.SmoothPlastic)
		weld(helm, head, folder, CFrame.new(0, 0.15, 0))
		local visor = makePart("Visor", Vector3.new(1.1, 0.22, 0.35), trim, Enum.Material.Neon)
		weld(visor, head, folder, CFrame.new(0, 0.05, -0.55))
	elseif slot == "chest" then
		local torso = findPart(char, { "UpperTorso", "Torso" })
		if not torso then
			return
		end
		local plate = makePart("ChestPlate", Vector3.new(2.0, 1.6, 1.15), tone, Enum.Material.Metal)
		weld(plate, torso, folder, CFrame.new(0, 0.1, -0.15))
		local emblem = makePart("ChestEmblem", Vector3.new(0.55, 0.55, 0.2), trim, Enum.Material.Neon)
		weld(emblem, torso, folder, CFrame.new(0, 0.25, -0.7))
	elseif slot == "hands" then
		for _, side in { "Left", "Right" } do
			local hand = findPart(char, { side .. "Hand", side .. " Arm" })
			if hand then
				local cuff = makePart(side .. "Gauntlet", Vector3.new(0.85, 0.55, 0.85), tone, Enum.Material.Metal)
				weld(cuff, hand, folder, CFrame.new(0, 0.05, 0))
				local ring = makePart(side .. "Trim", Vector3.new(0.9, 0.12, 0.9), trim, Enum.Material.Neon)
				weld(ring, hand, folder, CFrame.new(0, 0.28, 0))
			end
		end
	elseif slot == "feets" then
		for _, side in { "Left", "Right" } do
			local foot = findPart(char, { side .. "Foot", side .. " Leg" })
			if foot then
				local boot = makePart(side .. "Boot", Vector3.new(0.95, 0.7, 1.15), tone, Enum.Material.SmoothPlastic)
				weld(boot, foot, folder, CFrame.new(0, -0.15, 0.1))
				local sole = makePart(side .. "Sole", Vector3.new(0.9, 0.12, 1.1), trim, Enum.Material.Neon)
				weld(sole, foot, folder, CFrame.new(0, -0.45, 0.1))
			end
		end
	end
end

function WeaponVisualService.Refresh(player: Player)
	local char = player.Character
	if not char then
		return
	end
	clearFolder(char)
	local root = Instance.new("Folder")
	root.Name = "GearVisuals"
	root.Parent = char

	local weaponFolder = Instance.new("Folder")
	weaponFolder.Name = "Weapons"
	weaponFolder.Parent = root

	local armorFolder = Instance.new("Folder")
	armorFolder.Name = "Armor"
	armorFolder.Parent = root

	local right = findPart(char, { "RightHand", "Right Arm" })
	local left = findPart(char, { "LeftHand", "Left Arm" })
	if not right then
		return
	end

	local userId = player.UserId
	local loadout = LoadoutService.Get(userId)

	if loadout.main then
		local inst = InventoryService.Find(userId, loadout.main)
		local def = inst and ItemDefs.Get(inst.defId)
		if def then
			local fam = WeaponFamilyConfig.Resolve(def)
			local hand = if fam.hand == "Left" and left then left else right
			buildWeapon(fam.animPrefix, def.element, weaponFolder, hand)
		end
	end

	if loadout.off then
		local inst = InventoryService.Find(userId, loadout.off)
		local def = inst and ItemDefs.Get(inst.defId)
		if def and def.kind == "Shield" and left then
			buildShield(inst.defId, def.element, weaponFolder, left)
		elseif def and (def.kind == "Weapon1H" or def.kind == "Wand" or def.kind == "Scepter") and left then
			local fam = WeaponFamilyConfig.Resolve(def)
			buildWeapon(fam.animPrefix, def.element, weaponFolder, left)
		end
	end

	for _, slot in { "head", "chest", "hands", "feets" } do
		local uuid = (loadout :: any)[slot]
		if uuid then
			local inst = InventoryService.Find(userId, uuid)
			local def = inst and ItemDefs.Get(inst.defId)
			if def then
				buildArmorPiece(slot, def.element, armorFolder, char)
			end
		end
	end
end

return WeaponVisualService
