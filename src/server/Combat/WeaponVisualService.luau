--[[
	Gear visuals — prefers ReplicatedStorage.WeaponMeshes (Studio AI models),
	falls back to proportional placeholder parts. Same grip attach points.
]]

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local AnimConfig = require(game.ReplicatedStorage.Shared.Config.AnimConfig)
local WeaponFamilyConfig = require(game.ReplicatedStorage.Shared.Config.WeaponFamilyConfig)
local WeaponMeshConfig = require(game.ReplicatedStorage.Shared.Config.WeaponMeshConfig)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local WeaponAssemblyService = require(script.Parent.Parent.Inventory.WeaponAssemblyService)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)

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

--- R15 grip attachment in hand local space (blade should follow grip +Y, not hand -X)
local function gripC0(hand: BasePart): CFrame
	local attName = if string.find(hand.Name, "Left") then "LeftGripAttachment" else "RightGripAttachment"
	local att = hand:FindFirstChild(attName)
	if att and att:IsA("Attachment") then
		return hand.CFrame:ToObjectSpace(att.WorldCFrame)
	end
	return CFrame.new()
end

local function weldGrip(part: BasePart, hand: BasePart, folder: Folder, offset: CFrame)
	weld(part, hand, folder, gripC0(hand) * offset)
end

--- Grip tip align: blade along grip +Y (forearm / forward), not tip into floor.
--- Equivalent to classic Xm90 then sağa Z+90 × sola Y−90.
local function tipAlign(): CFrame
	return CFrame.Angles(0, math.rad(-90), 0)
end

--- Melee/ranged hafts: part +Y tip along grip up
local function weldWeapon(part: BasePart, hand: BasePart, folder: Folder, offset: CFrame)
	weldGrip(part, hand, folder, tipAlign() * offset)
end

--- Weld without reparenting (mesh Handle stays inside Model)
local function weldInPlace(part: BasePart, hand: BasePart, c0: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	local w = Instance.new("Weld")
	w.Part0 = hand
	w.Part1 = part
	w.C0 = c0
	w.Parent = part
end

--- Rotation that maps `from` direction → `to` direction
local function rotateFromTo(from: Vector3, to: Vector3): CFrame
	from = from.Unit
	to = to.Unit
	local dot = from:Dot(to)
	if dot > 0.9999 then
		return CFrame.new()
	end
	if dot < -0.9999 then
		local ortho = from:Cross(Vector3.xAxis)
		if ortho.Magnitude < 0.1 then
			ortho = from:Cross(Vector3.yAxis)
		end
		return CFrame.fromAxisAngle(ortho.Unit, math.pi)
	end
	local axis = from:Cross(to)
	return CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(dot, -1, 1)))
end

--- Prefer blade/tip/head/crystal centroid vs pommel/base when names exist
local function namedTipDir(model: Model, handle: BasePart): Vector3?
	local tipSum = Vector3.zero
	local tipN = 0
	local pomSum = Vector3.zero
	local pomN = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= handle then
			local n = string.lower(d.Name)
			local rel = handle.CFrame:ToObjectSpace(d.CFrame).Position
			if
				string.find(n, "pommel", 1, true)
				or string.find(n, "butt", 1, true)
				or string.find(n, "basecap", 1, true)
				or string.find(n, "base_cap", 1, true)
				or (string.find(n, "base", 1, true) and string.find(n, "shaft", 1, true))
			then
				pomSum += rel
				pomN += 1
			elseif
				string.find(n, "blade", 1, true)
				or string.find(n, "tip", 1, true)
				or string.find(n, "head", 1, true)
				or string.find(n, "spike", 1, true)
				or string.find(n, "limb", 1, true)
				or string.find(n, "crystal", 1, true)
				or string.find(n, "orb", 1, true)
				or string.find(n, "gem", 1, true)
				or string.find(n, "claw", 1, true)
			then
				-- note: do NOT match "prod" (crossbow limb bar — not muzzle tip)
				tipSum += rel
				tipN += 1
			end
		end
	end
	if tipN > 0 and pomN > 0 then
		local delta = tipSum / tipN - pomSum / pomN
		if delta.Magnitude > 0.05 then
			return delta.Unit
		end
	elseif tipN > 0 then
		local delta = tipSum / tipN
		if delta.Magnitude > 0.05 then
			return delta.Unit
		end
	end
	return nil
end

--- Pack meshes: tip/longest axis → `toDir` (placeholder blades use +Y)
local function autoBladeOrient(model: Model, handle: BasePart, toDir: Vector3?, forceTip: Vector3?): CFrame
	local target = (toDir or Vector3.yAxis).Unit
	if forceTip and forceTip.Magnitude > 0.01 then
		return rotateFromTo(forceTip.Unit, target)
	end
	local named = namedTipDir(model, handle)
	if named then
		return rotateFromTo(named, target)
	end
	local minV = Vector3.new(1e9, 1e9, 1e9)
	local maxV = Vector3.new(-1e9, -1e9, -1e9)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = handle.CFrame:ToObjectSpace(d.CFrame).Position
			local half = d.Size * 0.5
			for _, corner in {
				rel + half,
				rel - half,
				rel + Vector3.new(half.X, -half.Y, -half.Z),
				rel + Vector3.new(-half.X, half.Y, half.Z),
			} do
				minV = Vector3.new(math.min(minV.X, corner.X), math.min(minV.Y, corner.Y), math.min(minV.Z, corner.Z))
				maxV = Vector3.new(math.max(maxV.X, corner.X), math.max(maxV.Y, corner.Y), math.max(maxV.Z, corner.Z))
			end
		end
	end
	local ext = maxV - minV
	local fromDir: Vector3
	if ext.Y >= ext.X and ext.Y >= ext.Z then
		fromDir = if math.abs(maxV.Y) >= math.abs(minV.Y) then Vector3.yAxis else -Vector3.yAxis
	elseif ext.Z >= ext.X then
		fromDir = if math.abs(maxV.Z) >= math.abs(minV.Z) then Vector3.zAxis else -Vector3.zAxis
	else
		fromDir = if math.abs(maxV.X) >= math.abs(minV.X) then Vector3.xAxis else -Vector3.xAxis
	end
	return rotateFromTo(fromDir, target)
end

--- Uniform scale. Prefer targetSize (studs). Falls back to manual weld-safe scale if ScaleTo fails.
local function scaleModel(model: Model, visual: any)
	local handle = model.PrimaryPart or model:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		model.PrimaryPart = handle
	else
		return
	end

	local factor = 1
	if typeof(visual) == "table" and typeof(visual.targetSize) == "number" and visual.targetSize > 0 then
		local e = model:GetExtentsSize()
		local longest = math.max(e.X, e.Y, e.Z)
		if longest > 0.05 then
			factor = visual.targetSize / longest
		end
	elseif typeof(visual) == "table" and typeof(visual.scale) == "number" then
		factor = visual.scale
	elseif typeof(visual) == "number" then
		factor = visual
	end
	if math.abs(factor - 1) < 0.03 or factor <= 0.05 then
		return
	end

	local ok = pcall(function()
		model:ScaleTo(factor)
	end)
	local got = 1
	pcall(function()
		got = model:GetScale()
	end)
	if ok and math.abs(got - factor) <= 0.08 then
		return
	end

	-- Manual fallback: keep parts welded to Handle with scaled local offsets
	warn("[WeaponVisual] ScaleTo fallback", model.Name, "factor", factor, "got", got)
	local rel: { [BasePart]: CFrame } = {}
	local sizes: { [BasePart]: Vector3 } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			sizes[d] = d.Size
			if d ~= handle then
				rel[d] = handle.CFrame:ToObjectSpace(d.CFrame)
			end
		elseif d:IsA("WeldConstraint") or d:IsA("Weld") or d:IsA("Motor6D") or d:IsA("RigidConstraint") then
			d:Destroy()
		end
	end
	handle.Size = sizes[handle] * factor
	for part, cf in rel do
		local s = sizes[part]
		if s then
			part.Size = s * factor
		end
		local pos = cf.Position * factor
		part.CFrame = handle.CFrame * CFrame.new(pos) * (cf - cf.Position)
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = part
		w.Parent = handle
	end
end

--- Grip hold: hand along shaft (frac from butt→tip).
local function gripHoldOffset(model: Model, handle: BasePart, tipOrient: CFrame, holdFrac: number?): CFrame
	local minY, maxY = 1e9, -1e9
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local rel = handle.CFrame:ToObjectSpace(d.CFrame).Position
			local oriented = tipOrient:VectorToObjectSpace(rel)
			local hy = math.max(d.Size.X, d.Size.Y, d.Size.Z) * 0.12
			minY = math.min(minY, oriented.Y - hy)
			maxY = math.max(maxY, oriented.Y + hy)
		end
	end
	if maxY < minY then
		return CFrame.new()
	end
	local frac = holdFrac or 0.22
	local span = maxY - minY
	local holdY = minY + span * frac
	local lim = math.clamp(span * 0.4, 0.8, 2.2)
	holdY = math.clamp(holdY, -lim, lim)
	return CFrame.new(0, -holdY, 0)
end

--- Pull grip onto a named part: "center" = part origin, "surface" = closest point on part to Handle.
--- nestle: extra studs past the collision surface toward part center (MeshPart hull ≠ visual).
local function centerOnPart(model: Model, handle: BasePart, nameHint: string?, mode: string?, nestle: number?): CFrame
	if not nameHint or nameHint == "" then
		return CFrame.new()
	end
	local hint = string.lower(nameHint)
	local best: BasePart? = nil
	local bestVol = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= handle then
			if string.find(string.lower(d.Name), hint, 1, true) then
				local vol = d.Size.X * d.Size.Y * d.Size.Z
				if vol > bestVol then
					bestVol = vol
					best = d
				end
			end
		end
	end
	if not best then
		return CFrame.new()
	end
	local rel: Vector3
	if mode == "surface" then
		local closest = best:GetClosestPointOnSurface(handle.Position)
		local pull = nestle or 0
		if pull > 0 then
			local inward = best.Position - closest
			if inward.Magnitude > 0.01 then
				closest = closest + inward.Unit * math.min(pull, inward.Magnitude * 0.85)
			end
		end
		rel = handle.CFrame:PointToObjectSpace(closest)
	else
		rel = handle.CFrame:ToObjectSpace(best.CFrame).Position
	end
	return CFrame.new(-rel.X, -rel.Y, -rel.Z)
end

local function resolveMeshGrip(model: Model, handle: BasePart, animPrefix: string?): CFrame
	local visual = WeaponMeshConfig.GetVisual(animPrefix)
	local stored = model:FindFirstChild("ToolGripCF")
	if stored and stored:IsA("CFrameValue") then
		local g = stored.Value
		local isIdentity = g == CFrame.new()
			or (g.Position.Magnitude < 0.05 and (g.LookVector - Vector3.new(0, 0, -1)).Magnitude < 0.05)
		if not isIdentity then
			return g
		end
	end
	local nudge = visual.gripOffset or CFrame.new()

	-- Authored full orient (bow): skip tipAlign — grip +Y is forward, bow long axis needs world up
	if visual.gripOrient then
		local hold = if visual.centerOn
			then centerOnPart(model, handle, visual.centerOn, visual.centerMode, visual.nestle)
			else CFrame.new()
		-- hold in handle space after orient (do not pre-multiply gripOffset — that reopens gaps)
		return visual.gripOrient * hold * nudge
	end

	local tipOrient = autoBladeOrient(model, handle, Vector3.yAxis, visual.forceTip)
	local extra = visual.gripExtra or CFrame.new()
	local orient = tipAlign() * tipOrient * extra
	if visual.centerOn then
		return orient * centerOnPart(model, handle, visual.centerOn, visual.centerMode, visual.nestle) * nudge
	end
	local hold = gripHoldOffset(model, handle, tipOrient, visual.holdFrac)
	return orient * hold * nudge
end

--- Clone cleaned marketplace mesh onto hand. Returns true if used.
local function tryAttachMeshWeapon(animPrefix: string, defId: string?, folder: Folder, hand: BasePart): boolean
	local template = WeaponMeshConfig.GetTemplate(animPrefix, defId)
	if not template then
		return false
	end
	local model = template:Clone()
	local handle = model.PrimaryPart or model:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		model:Destroy()
		return false
	end
	model.PrimaryPart = handle
	model.Name = "MeshWeapon"
	model.Parent = folder

	local visual = WeaponMeshConfig.GetVisual(animPrefix)
	scaleModel(model, visual)
	handle = model.PrimaryPart or model:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		model:Destroy()
		return false
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end

	local gripCf = resolveMeshGrip(model, handle, animPrefix)
	weldInPlace(handle, hand, gripC0(hand) * gripCf)
	return true
end

local function tryAttachMeshShield(defId: string?, folder: Folder, hand: BasePart): boolean
	local template = WeaponMeshConfig.GetShieldTemplate(defId)
	if not template then
		return false
	end
	local model = template:Clone()
	local handle = model.PrimaryPart or model:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		model:Destroy()
		return false
	end
	local sv = WeaponMeshConfig.ShieldVisual
	model.PrimaryPart = handle
	model.Name = "MeshShield"
	model.Parent = folder
	scaleModel(model, sv)
	handle = model.PrimaryPart or model:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		model:Destroy()
		return false
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end

	local stored = model:FindFirstChild("ToolGripCF")
	local gripCf = if stored and stored:IsA("CFrameValue") then stored.Value else CFrame.new()
	local isIdentity = gripCf == CFrame.new()
		or (gripCf.Position.Magnitude < 0.05 and (gripCf.LookVector - Vector3.new(0, 0, -1)).Magnitude < 0.05)
	if isIdentity then
		gripCf = sv.grip
	end
	weldInPlace(handle, hand, gripC0(hand) * gripCf)
	return true
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
	weldWeapon(gem, hand, folder, offset)
end

-- Offsets are relative to R15 *GripAttachment (+Y = tip / forward along grip)
local function buildWeapon(familyKey: string, element: string?, folder: Folder, hand: BasePart, defId: string?)
	if tryAttachMeshWeapon(familyKey, defId, folder, hand) then
		return
	end

	local bladeCol = metalBase(element)
	local accent = accentTone(element)
	local wood = Color3.fromRGB(90, 70, 50)

	if familyKey == "Sword1H" or familyKey == "Sword" then
		local blade = makePart("Blade", Vector3.new(0.22, 3.0, 0.55), bladeCol, Enum.Material.Metal)
		weldWeapon(blade, hand, folder, CFrame.new(0, -1.35, 0))
		local guard = makePart("Guard", Vector3.new(0.9, 0.18, 0.35), accent, Enum.Material.Metal)
		weldWeapon(guard, hand, folder, CFrame.new(0, -0.35, 0))
		local hilt = makePart("Hilt", Vector3.new(0.28, 0.7, 0.28), wood)
		weldWeapon(hilt, hand, folder, CFrame.new(0, 0.05, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.7, 0), element, 0.35)
	elseif familyKey == "Sword2H" then
		local blade = makePart("Blade", Vector3.new(0.28, 4.4, 0.7), bladeCol, Enum.Material.Metal)
		weldWeapon(blade, hand, folder, CFrame.new(0, -2.0, 0))
		local guard = makePart("Guard", Vector3.new(1.2, 0.22, 0.4), accent, Enum.Material.Metal)
		weldWeapon(guard, hand, folder, CFrame.new(0, -0.4, 0))
		local hilt = makePart("Hilt", Vector3.new(0.32, 1.1, 0.32), wood)
		weldWeapon(hilt, hand, folder, CFrame.new(0, 0.2, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -4.0, 0), element, 0.4)
	elseif familyKey == "Axe1H" or familyKey == "Axe" then
		local haft = makePart("Haft", Vector3.new(0.22, 2.3, 0.22), wood)
		weldWeapon(haft, hand, folder, CFrame.new(0, -0.95, 0))
		local head = makePart("AxeHead", Vector3.new(1.35, 0.75, 0.32), bladeCol, Enum.Material.Metal)
		weldWeapon(head, hand, folder, CFrame.new(0.45, -1.95, 0))
		addAccentOrb(folder, hand, CFrame.new(0.9, -1.95, 0), element, 0.3)
	elseif familyKey == "Axe2H" then
		local haft = makePart("Haft", Vector3.new(0.28, 3.4, 0.28), wood)
		weldWeapon(haft, hand, folder, CFrame.new(0, -1.45, 0))
		local head = makePart("AxeHead", Vector3.new(1.9, 1.0, 0.4), bladeCol, Enum.Material.Metal)
		weldWeapon(head, hand, folder, CFrame.new(0.55, -2.95, 0))
		addAccentOrb(folder, hand, CFrame.new(1.2, -2.95, 0), element, 0.4)
	elseif familyKey == "Mace1H" or familyKey == "Mace" then
		local haft = makePart("Haft", Vector3.new(0.26, 2.1, 0.26), wood)
		weldWeapon(haft, hand, folder, CFrame.new(0, -0.85, 0))
		local head = makePart("MaceHead", Vector3.new(1.05, 1.05, 1.05), bladeCol, Enum.Material.Metal)
		head.Shape = Enum.PartType.Ball
		weldWeapon(head, hand, folder, CFrame.new(0, -2.1, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.1, 0.55), element, 0.28)
	elseif familyKey == "Mace2H" then
		local haft = makePart("Haft", Vector3.new(0.3, 3.1, 0.3), wood)
		weldWeapon(haft, hand, folder, CFrame.new(0, -1.35, 0))
		local head = makePart("MaceHead", Vector3.new(1.45, 1.45, 1.45), bladeCol, Enum.Material.Metal)
		weldWeapon(head, hand, folder, CFrame.new(0, -2.95, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.95, 0.7), element, 0.35)
	elseif familyKey == "Dagger" then
		local blade = makePart("Blade", Vector3.new(0.18, 1.5, 0.4), bladeCol, Enum.Material.Metal)
		weldWeapon(blade, hand, folder, CFrame.new(0, -0.65, 0))
		local hilt = makePart("Hilt", Vector3.new(0.22, 0.45, 0.22), wood)
		weldWeapon(hilt, hand, folder, CFrame.new(0, 0.05, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -1.35, 0), element, 0.22)
	elseif familyKey == "Wand" then
		local rod = makePart("Rod", Vector3.new(0.18, 1.9, 0.18), wood)
		weldWeapon(rod, hand, folder, CFrame.new(0, -0.75, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -1.75, 0), element, 0.5)
	elseif familyKey == "Scepter" then
		local rod = makePart("Rod", Vector3.new(0.22, 2.5, 0.22), wood)
		weldWeapon(rod, hand, folder, CFrame.new(0, -1.05, 0))
		local gem = makePart("Gem", Vector3.new(0.75, 0.75, 0.75), accent, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		weldWeapon(gem, hand, folder, CFrame.new(0, -2.4, 0))
	elseif familyKey == "Staff" then
		local rod = makePart("Rod", Vector3.new(0.26, 4.0, 0.26), wood)
		weldWeapon(rod, hand, folder, CFrame.new(0, -1.7, 0))
		local gem = makePart("Gem", Vector3.new(0.95, 0.95, 0.95), accent, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		weldWeapon(gem, hand, folder, CFrame.new(0, -3.85, 0))
	elseif familyKey == "Bow" then
		local upper = makePart("UpperLimb", Vector3.new(0.18, 1.7, 0.18), bladeCol)
		weldWeapon(upper, hand, folder, CFrame.new(0, 0.7, -0.45) * CFrame.Angles(0, 0, math.rad(18)))
		local lower = makePart("LowerLimb", Vector3.new(0.18, 1.7, 0.18), bladeCol)
		weldWeapon(lower, hand, folder, CFrame.new(0, -0.7, -0.45) * CFrame.Angles(0, 0, math.rad(-18)))
		local grip = makePart("Grip", Vector3.new(0.22, 0.5, 0.22), wood)
		weldWeapon(grip, hand, folder, CFrame.new(0, 0, -0.35))
		addAccentOrb(folder, hand, CFrame.new(0, 0, -0.7), element, 0.3)
	elseif familyKey == "Crossbow" then
		local body = makePart("Body", Vector3.new(0.35, 0.4, 2.0), wood)
		weldWeapon(body, hand, folder, CFrame.new(0, -0.15, -0.75))
		local limbs = makePart("Limbs", Vector3.new(2.1, 0.22, 0.22), bladeCol, Enum.Material.Metal)
		weldWeapon(limbs, hand, folder, CFrame.new(0, -0.15, -1.55))
		addAccentOrb(folder, hand, CFrame.new(0, -0.15, -1.9), element, 0.32)
	else
		local blade = makePart("Blade", Vector3.new(0.22, 2.8, 0.5), bladeCol, Enum.Material.Metal)
		weldWeapon(blade, hand, folder, CFrame.new(0, -1.2, 0))
		addAccentOrb(folder, hand, CFrame.new(0, -2.5, 0), element, 0.3)
	end
end

--- 3-part modular placeholder: handle + blade + pommel (tint by archetype) + gem orb
local function buildModularComposite(resolved: any, folder: Folder, hand: BasePart)
	local bladeCol = metalBase(resolved.element)
	local handleCol = Color3.fromRGB(139, 119, 90)
	local pommelDef = resolved.pommelDefId and ItemDefs.Get(resolved.pommelDefId)
	local pommelCol = Color3.fromRGB(130, 130, 140)
	if pommelDef and pommelDef.archetype == "Heavy" then
		pommelCol = Color3.fromRGB(95, 95, 105)
	elseif pommelDef and pommelDef.archetype == "Lightweight" then
		pommelCol = Color3.fromRGB(175, 185, 200)
	end

	local bladeLen = 2.0
	local handleLen = 0.85
	if resolved.kind == "Weapon2H" or resolved.kind == "Staff" then
		bladeLen = 3.2
		handleLen = 1.1
	elseif resolved.kind == "Bow" then
		bladeLen = 1.4
		handleLen = 1.0
	elseif resolved.kind == "Crossbow" then
		bladeLen = 1.0
		handleLen = 0.9
	elseif resolved.subFamily == "Dagger" then
		bladeLen = 1.15
		handleLen = 0.7
	elseif resolved.kind == "Wand" or resolved.kind == "Scepter" then
		bladeLen = 0.55
		handleLen = 1.0
	end

	local grip = makePart("ModHandle", Vector3.new(0.24, handleLen, 0.24), handleCol, Enum.Material.Wood)
	weldWeapon(grip, hand, folder, CFrame.new(0, -0.12, 0))

	local blade = makePart("ModBlade", Vector3.new(0.2, bladeLen, 0.42), bladeCol, Enum.Material.Metal)
	weldWeapon(blade, hand, folder, CFrame.new(0, -(handleLen * 0.45 + bladeLen * 0.5), 0))

	local pommelSize = if pommelDef and pommelDef.archetype == "Heavy"
		then 0.42
		elseif pommelDef and pommelDef.archetype == "Lightweight" then 0.28
		else 0.34
	local pommel = makePart("ModPommel", Vector3.new(pommelSize, pommelSize, pommelSize), pommelCol, Enum.Material.Metal)
	if pommelDef and pommelDef.archetype == "Heavy" then
		pommel.Shape = Enum.PartType.Ball
	end
	weldWeapon(pommel, hand, folder, CFrame.new(0, handleLen * 0.42, 0))

	addAccentOrb(folder, hand, CFrame.new(0, -0.32, 0.18), resolved.element, 0.28)
end

local function buildShield(defId: string, element: string?, folder: Folder, hand: BasePart)
	if tryAttachMeshShield(defId, folder, hand) then
		return
	end

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
	-- Face outward from left grip (+Z of grip = shield front) — no weapon align
	local shield = makePart("Shield", size, col, Enum.Material.Metal)
	weldGrip(shield, hand, folder, CFrame.new(0, -0.15, 0.55) * CFrame.Angles(0, math.rad(90), 0))
	local boss = makePart("ShieldBoss", Vector3.new(0.2, 0.55, 0.55), trim, Enum.Material.Neon)
	boss.Shape = Enum.PartType.Cylinder
	weldGrip(boss, hand, folder, CFrame.new(0, -0.15, 0.75) * CFrame.Angles(0, math.rad(90), math.rad(90)))
	if defId == "o_spiked" then
		local spike = makePart("Spike", Vector3.new(0.25, 0.7, 0.25), trim, Enum.Material.Metal)
		weldGrip(spike, hand, folder, CFrame.new(0, -0.15, 1.0) * CFrame.Angles(0, math.rad(90), 0))
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
		local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
		if resolved and resolved.complete then
			local def = WeaponResolver.AsItemDef(resolved)
			local fam = WeaponFamilyConfig.Resolve(def)
			local hand = if fam.hand == "Left" and left then left else right
			buildModularComposite(resolved, weaponFolder, hand)
		end
	end

	if loadout.off then
		local inst = InventoryService.Find(userId, loadout.off)
		local def = inst and ItemDefs.Get(inst.defId)
		if def and def.kind == "Shield" and left then
			buildShield(inst.defId, def.element, weaponFolder, left)
		elseif def and (def.kind == "Weapon1H" or def.kind == "Wand" or def.kind == "Scepter") and left then
			local fam = WeaponFamilyConfig.Resolve(def)
			buildWeapon(fam.animPrefix, def.element, weaponFolder, left, inst.defId)
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
