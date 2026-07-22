--[[
	Item icons via ViewportFrame — 3/4 shot of WeaponMeshes templates.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefs = require(ReplicatedStorage.Shared.Config.ItemDefs)
local WeaponMeshConfig = require(ReplicatedStorage.Shared.Config.WeaponMeshConfig)
local WeaponFamilyConfig = require(ReplicatedStorage.Shared.Config.WeaponFamilyConfig)
local AnimConfig = require(ReplicatedStorage.Shared.Config.AnimConfig)

local ItemIcon = {}

local function isShieldKind(kind: string?): boolean
	return kind == "Shield"
end

function ItemIcon.ResolveTemplate(defId: string?): Model?
	if not defId then
		return nil
	end
	local def = ItemDefs.Get(defId)
	if not def then
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

--- Clear previous icon children (ViewportFrame / fallback)
function ItemIcon.Clear(parent: GuiObject)
	for _, c in parent:GetChildren() do
		if c.Name == "ItemIconVp" or c.Name == "ItemIconFallback" then
			c:Destroy()
		end
	end
end

export type MountOpts = {
	zIndex: number?,
	bgTransparency: number?,
	yawDeg: number?,
	pitchDeg: number?,
	distanceMul: number?,
}

--- Mount 3/4 preview into parent. Returns ViewportFrame or nil.
function ItemIcon.Mount(parent: GuiObject, defId: string?, opts: MountOpts?): ViewportFrame?
	ItemIcon.Clear(parent)
	if not defId then
		return nil
	end
	opts = opts or {}
	local template = ItemIcon.ResolveTemplate(defId)
	if not template then
		-- Armor / missing mesh: tinted fallback tile
		local def = ItemDefs.Get(defId)
		local fb = Instance.new("Frame")
		fb.Name = "ItemIconFallback"
		fb.Size = UDim2.fromScale(1, 1)
		fb.BackgroundColor3 = AnimConfig.ElementColor[(def and def.element) or "Neutral"]
			or Color3.fromRGB(120, 120, 130)
		fb.BackgroundTransparency = 0.55
		fb.BorderSizePixel = 0
		fb.ZIndex = opts.zIndex or 1
		fb.Parent = parent
		return nil
	end

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

return ItemIcon
