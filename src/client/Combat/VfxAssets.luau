--[[
	Optional Studio VFX assets — clone templates from ReplicatedStorage.CombatVfxAssets.
	Falls back silently when folder or child is missing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VfxConfig = require(game.ReplicatedStorage.Shared.Config.VfxConfig)

local VfxAssets = {}

local root: Folder? = nil
local textureCache: { [string]: string } = {}
local warned: { [string]: boolean } = {}

local function getRoot(): Folder?
	if root ~= nil then
		return root
	end
	local inst = ReplicatedStorage:FindFirstChild(VfxConfig.AssetRootName)
	if inst and inst:IsA("Folder") then
		root = inst
		return root
	end
	return nil
end

function VfxAssets.GetTexture(textureKey: string): string
	if textureCache[textureKey] then
		return textureCache[textureKey]
	end
	local fallback = VfxConfig.Textures[textureKey] or VfxConfig.Textures.Spark
	local r = getRoot()
	if r then
		local particles = r:FindFirstChild("Particles")
		local named = if particles then particles:FindFirstChild(textureKey) else nil
		if named and named:IsA("ParticleEmitter") and named.Texture ~= "" then
			textureCache[textureKey] = named.Texture
			return named.Texture
		end
	end
	textureCache[textureKey] = fallback
	return fallback
end

local function findAt(path: string): Instance?
	local r = getRoot()
	if not r then
		return nil
	end
	local node: Instance = r
	for segment in string.split(path, "/") do
		if segment == "" then
			continue
		end
		local child = node:FindFirstChild(segment)
		if not child then
			return nil
		end
		node = child
	end
	return node
end

--- Clone optional mesh/model at CFrame; returns instances parented to `parent`
function VfxAssets.TrySpawn(path: string, cf: CFrame, parent: Instance, life: number?): Instance?
	local src = findAt(path)
	if not src then
		return nil
	end
	local clone = src:Clone()
	if clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.CFrame = cf
		clone.Parent = parent
	elseif clone:IsA("Model") then
		clone:PivotTo(cf)
		clone.Parent = parent
		for _, d in clone:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
	else
		clone:Destroy()
		return nil
	end
	if life and life > 0 then
		Debris:AddItem(clone, life)
	end
	return clone
end

--- Emit using a ParticleEmitter template (copies properties, one-shot emit)
function VfxAssets.TryEmitTemplate(path: string, parent: Attachment, emitCount: number?): ParticleEmitter?
	local src = findAt(path)
	if not src or not src:IsA("ParticleEmitter") then
		return nil
	end
	local pe = src:Clone()
	pe.Rate = 0
	pe.Enabled = true
	pe.Parent = parent
	pe:Emit(emitCount or src:GetAttribute("EmitCount") or 24)
	Debris:AddItem(pe, 2)
	return pe
end

function VfxAssets.TryReactionModel(reactionId: string, cf: CFrame, parent: Instance, life: number): Instance?
	local path = `Reactions/{reactionId}`
	local inst = VfxAssets.TrySpawn(path, cf, parent, life)
	if not inst and not warned[reactionId] then
		warned[reactionId] = true
		-- single warn per reaction id in session
	end
	return inst
end

return VfxAssets
