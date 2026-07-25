--[[
	Item icons via ViewportFrame — 3/4 shot of WeaponMeshes templates.
	Weapon frames use blade mesh + optional element gem badge.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local WeaponMeshConfig = require(ReplicatedStorage.Shared.Config.WeaponMeshConfig)
local WeaponFamilyConfig = require(ReplicatedStorage.Shared.Config.WeaponFamilyConfig)
local AnimConfig = require(ReplicatedStorage.Shared.Config.AnimConfig)
local GemSymbol = require(ReplicatedStorage.Shared.UI.GemSymbol)

local ItemIcon = {}

local function isShieldKind(kind: string?): boolean
	return kind == "Shield"
end

local PART_COLORS = {
	WeaponHandle = Color3.fromRGB(139, 119, 90),
	WeaponBlade = Color3.fromRGB(180, 185, 195),
	WeaponPommel = Color3.fromRGB(110, 110, 120),
	ElementGem = Color3.fromRGB(255, 120, 80),
	WeaponFrame = Color3.fromRGB(70, 90, 120),
	LootBox = Color3.fromRGB(210, 175, 90),
}

local function bladeTemplateForDef(def: any): Model?
	if not def then
		return nil
	end
	if typeof(def.meshKey) == "string" and def.meshKey ~= "" then
		local byKey = WeaponMeshConfig.GetTemplateByMeshKey(def.meshKey)
		if byKey then
			return byKey
		end
	end
	if def.kind == "WeaponBlade" and def.family then
		local family = WeaponFamilyConfig.Resolve(def)
		return WeaponMeshConfig.GetTemplate(family.animPrefix, def.id)
	end
	return nil
end

function ItemIcon.ResolveTemplate(defId: string?): Model?
	if not defId then
		return nil
	end
	if defId == "weapon_frame" then
		return nil
	end
	local def = ItemDefs.Get(defId)
	if not def then
		return nil
	end
	if def.kind == "WeaponBlade" then
		return bladeTemplateForDef(def)
	end
	if PART_COLORS[def.kind] and def.kind ~= "WeaponBlade" then
		return nil
	end
	if isShieldKind(def.kind) then
		return WeaponMeshConfig.GetShieldTemplate(defId)
	end
	local family = WeaponFamilyConfig.Resolve(def)
	return WeaponMeshConfig.GetTemplate(family.animPrefix, defId)
end

local function prepareClone(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		elseif d:IsA("BaseScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
end

local function framingCFrame(model: Model): (CFrame, number)
	local ok, boxed = pcall(function()
		local cf, size = model:GetBoundingBox()
		return { cf = cf, size = size }
	end)
	if ok and typeof(boxed) == "table" and typeof(boxed.cf) == "CFrame" then
		local size = boxed.size :: Vector3
		local maxDim = math.max(size.X, size.Y, size.Z, 0.5)
		return boxed.cf, maxDim
	end
	local pp = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if pp then
		return pp.CFrame, math.max(pp.Size.X, pp.Size.Y, pp.Size.Z, 1)
	end
	return CFrame.new(), 3
end

local function clearGemBadge(parent: GuiObject)
	local badge = parent:FindFirstChild("GemBadge")
	if badge then
		badge:Destroy()
	end
end

--- Clear previous icon children (ViewportFrame / fallback / gem badge)
function ItemIcon.Clear(parent: GuiObject)
	for _, c in parent:GetChildren() do
		if c.Name == "ItemIconVp" or c.Name == "ItemIconFallback" or c.Name == "GemBadge" then
			c:Destroy()
		end
	end
	clearGemBadge(parent)
end

export type MountOpts = {
	zIndex: number?,
	bgTransparency: number?,
	yawDeg: number?,
	pitchDeg: number?,
	distanceMul: number?,
	element: string?,
	showGemBadge: boolean?,
}

export type FrameMountOpts = MountOpts & {
	bladeDefId: string?,
}

local function mountGemBadge(parent: GuiObject, element: string?, zIndex: number?)
	if not element or element == "Neutral" then
		return
	end
	GemSymbol.Mount({
		parent = parent,
		element = element,
		zIndex = (zIndex or 1) + 4,
	})
end

local function mountViewport(parent: GuiObject, template: Model, opts: MountOpts): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = "ItemIconVp"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = opts.bgTransparency or 1
	vp.BorderSizePixel = 0
	vp.ZIndex = opts.zIndex or 1
	vp.Ambient = Color3.fromRGB(180, 180, 190)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.4)
	vp.Parent = parent

	local world = Instance.new("WorldModel")
	world.Parent = vp

	local clone = template:Clone()
	prepareClone(clone)
	clone.Parent = world

	local cam = Instance.new("Camera")
	cam.Parent = vp
	vp.CurrentCamera = cam

	local pivot, maxDim = framingCFrame(clone)
	local dist = maxDim * (opts.distanceMul or 1.85)
	local yaw = math.rad(opts.yawDeg or 35)
	local pitch = math.rad(opts.pitchDeg or -22)
	local offset = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 0, dist)
	cam.CFrame = CFrame.new((pivot * offset).Position, pivot.Position)
	cam.FieldOfView = 30

	return vp
end

local function mountFallback(parent: GuiObject, defId: string?, opts: MountOpts)
	local def = defId and ItemDefs.Get(defId)
	local fb = Instance.new("Frame")
	fb.Name = "ItemIconFallback"
	fb.Size = UDim2.fromScale(1, 1)
	local partColor = def and PART_COLORS[def.kind]
	if def and def.kind == "LootBox" then
		if def.rarity == "Rare" then
			fb.BackgroundColor3 = Color3.fromRGB(120, 150, 230)
		elseif def.rarity == "BossExclusive" then
			fb.BackgroundColor3 = Color3.fromRGB(170, 100, 220)
		else
			fb.BackgroundColor3 = PART_COLORS.LootBox
		end
	else
		fb.BackgroundColor3 = partColor
			or AnimConfig.ElementColor[(def and def.element) or "Neutral"]
			or Color3.fromRGB(120, 120, 130)
	end
	fb.BackgroundTransparency = 0.55
	fb.BorderSizePixel = 0
	fb.ZIndex = opts.zIndex or 1
	fb.Parent = parent
end

--- Mount assembled weapon frame — blade preview + gem badge.
function ItemIcon.MountFrame(parent: GuiObject, opts: FrameMountOpts?): ViewportFrame?
	ItemIcon.Clear(parent)
	opts = opts or {}
	local bladeDefId = opts.bladeDefId
	local bladeDef = bladeDefId and ItemDefs.Get(bladeDefId)
	local template = bladeTemplateForDef(bladeDef)
	if template then
		mountViewport(parent, template, opts)
	elseif bladeDefId then
		mountFallback(parent, bladeDefId, opts)
	else
		mountFallback(parent, "weapon_frame", opts)
	end
	if opts.showGemBadge ~= false and opts.element and opts.element ~= "Neutral" then
		mountGemBadge(parent, opts.element, opts.zIndex)
	end
	return parent:FindFirstChild("ItemIconVp") :: ViewportFrame?
end

--- Mount 3/4 preview into parent. Returns ViewportFrame or nil.
function ItemIcon.Mount(parent: GuiObject, defId: string?, opts: MountOpts?): ViewportFrame?
	ItemIcon.Clear(parent)
	if not defId then
		return nil
	end
	opts = opts or {}
	local def = ItemDefs.Get(defId)
	local template = ItemIcon.ResolveTemplate(defId)
	if not template then
		mountFallback(parent, defId, opts)
		if opts.showGemBadge ~= false and def and def.kind == "ElementGem" and def.element then
			mountGemBadge(parent, def.element, opts.zIndex)
		end
		return nil
	end

	local vp = mountViewport(parent, template, opts)
	if opts.showGemBadge ~= false and def and def.kind == "ElementGem" and def.element then
		mountGemBadge(parent, def.element, opts.zIndex)
	end
	return vp
end

return ItemIcon
