--[[
	Combat VFX data — profiles, element palettes, reaction styles, asset hook paths.

	Studio asset layout (optional — code falls back to procedural):
	  ReplicatedStorage/CombatVfxAssets/
	    Particles/SparkBurst, SmokePuff, HealMotes  (ParticleEmitter templates)
	    Meshes/SlashImpact, BoltStreak, ReactionBurst  (MeshPart or Model)
	    Reactions/Vaporize, ChainShock, ...  (per-reaction Model)
]]

local AnimConfig = require(script.Parent.AnimConfig)

export type ParticlePreset = {
	textureKey: string,
	lightEmission: number?,
	sizeStart: number?,
	sizeEnd: number?,
	life: number?,
	speed: number?,
	spread: number?,
	rate: number?,
	accelY: number?,
}

export type Profile = {
	lifeMult: number?,
	lightBrightness: number?,
	lightRange: number?,
	particleMult: number?,
	impactRing: boolean?,
	supportTint: number?, -- 0-1 lerp to green
	fillTransparency: number?,
	edgeTransparency: number?,
}

local VfxConfig = {}

VfxConfig.AssetRootName = "CombatVfxAssets"

-- Keys map to VfxAssets.GetTexture / template folder names
VfxConfig.Textures = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Soft = "rbxasset://textures/particles/sparkles_main.dds",
	Beam = "rbxasset://textures/particles/sparkles_main.dds",
}

VfxConfig.ComboStep = {
	[1] = { lifeMult = 0.9, particleMult = 0.82, lightMult = 0.88, impact = false },
	[2] = { lifeMult = 1.0, particleMult = 1.0, lightMult = 1.0, impact = false },
	[3] = { lifeMult = 1.28, particleMult = 1.38, lightMult = 1.3, impact = true, cameraKick = 0.18 },
}

-- Per animPrefix overrides (merged into BuildContext)
VfxConfig.FamilyTuning = {
	Dagger = { particleMult = 0.82, lightMult = 0.9, cameraKick = 0.12, impactScale = 0.75 },
	Sword1H = { particleMult = 1.0, lightMult = 1.0, cameraKick = 0.16, impactScale = 1.0 },
	Sword2H = { particleMult = 1.08, lightMult = 1.08, cameraKick = 0.2, impactScale = 1.12 },
	Axe1H = { particleMult = 1.1, lightMult = 1.05, cameraKick = 0.22, impactScale = 1.15 },
	Axe2H = { particleMult = 1.18, lightMult = 1.1, cameraKick = 0.26, impactScale = 1.22 },
	Mace1H = { particleMult = 1.15, lightMult = 1.12, cameraKick = 0.28, impactScale = 1.28 },
	Mace2H = { particleMult = 1.25, lightMult = 1.18, cameraKick = 0.32, impactScale = 1.38 },
	Wand = { particleMult = 0.95, lightMult = 1.05, cameraKick = 0.14, impactScale = 0.9 },
	Scepter = { particleMult = 1.05, lightMult = 1.08, cameraKick = 0.15, impactScale = 0.95 },
	Staff = { particleMult = 1.12, lightMult = 1.1, cameraKick = 0.2, impactScale = 1.1 },
	Bow = { particleMult = 0.92, lightMult = 0.98, cameraKick = 0.14, impactScale = 0.88 },
	Crossbow = { particleMult = 1.0, lightMult = 1.02, cameraKick = 0.18, impactScale = 1.0 },
}

VfxConfig.Profiles = {
	Slash = { lifeMult = 1, lightBrightness = 2.8, lightRange = 11, particleMult = 1, impactRing = true },
	Bolt = { lifeMult = 1, lightBrightness = 3.2, lightRange = 14, particleMult = 1, impactRing = true },
	Cone = { lifeMult = 1, lightBrightness = 3, lightRange = 12, particleMult = 1.1, impactRing = false },
	Burst = { lifeMult = 1, lightBrightness = 5, lightRange = 16, particleMult = 1.2, impactRing = true },
	Dash = { lifeMult = 1, lightBrightness = 2, lightRange = 10, particleMult = 1, impactRing = false },
	Aura = { lifeMult = 1, lightBrightness = 2.5, lightRange = 12, particleMult = 1, impactRing = false },
	Support = { lifeMult = 1.05, lightBrightness = 2.8, lightRange = 14, particleMult = 1.1, supportTint = 0.52 },
	Telegraph = {
		lifeMult = 1,
		fillTransparency = 0.58,
		edgeTransparency = 0.1,
		lightBrightness = 2.2,
		lightRange = 12,
	},
} :: { [string]: Profile }

VfxConfig.Particles = {
	SparkBurst = {
		textureKey = "Spark",
		lightEmission = 0.75,
		sizeStart = 0.55,
		sizeEnd = 0.04,
		life = 0.35,
		speed = 10,
		spread = 28,
	} :: ParticlePreset,
	SmokePuff = {
		textureKey = "Smoke",
		lightEmission = 0.12,
		sizeStart = 1.3,
		sizeEnd = 2.4,
		life = 0.65,
		speed = 3,
		spread = 38,
	} :: ParticlePreset,
	ImpactFlash = {
		textureKey = "Spark",
		lightEmission = 0.9,
		sizeStart = 0.9,
		sizeEnd = 0.05,
		life = 0.28,
		speed = 14,
		spread = 180,
		rate = 40,
	} :: ParticlePreset,
	HealMotes = {
		textureKey = "Soft",
		lightEmission = 0.85,
		sizeStart = 0.5,
		sizeEnd = 0.08,
		life = 0.8,
		speed = 2.5,
		spread = 180,
		accelY = 5,
	} :: ParticlePreset,
	MuzzleFlash = {
		textureKey = "Spark",
		lightEmission = 0.8,
		sizeStart = 0.38,
		sizeEnd = 0.05,
		life = 0.2,
		speed = 8,
		spread = 42,
		rate = 18,
	} :: ParticlePreset,
}

-- Asset hook paths (relative to CombatVfxAssets)
VfxConfig.AssetHooks = {
	SlashImpact = "Meshes/SlashImpact",
	BoltStreak = "Meshes/BoltStreak",
	ReactionBurst = "Meshes/ReactionBurst",
	ParticleSpark = "Particles/SparkBurst",
	ParticleSmoke = "Particles/SmokePuff",
	ParticleHeal = "Particles/HealMotes",
}

export type VfxContext = {
	element: string,
	primary: Color3,
	accent: Color3,
	glow: Color3,
	profile: Profile,
	profileKey: string,
	step: number,
	stepScale: {
		lifeMult: number,
		particleMult: number,
		lightMult: number,
		impact: boolean,
		cameraKick: number?,
		impactScale: number?,
	},
	isSupport: boolean,
	vfx: string,
	shape: string?,
}

local SUPPORT_SHAPES = { AllyCone = true, AllySphere = true, AllySingle = true }

function VfxConfig.ElementColors(element: string?): (Color3, Color3, Color3)
	local base = AnimConfig.ElementColor[element or "Neutral"] or AnimConfig.ElementColor.Neutral
	local accent = base:Lerp(Color3.new(1, 1, 1), 0.35)
	local glow = base:Lerp(Color3.new(1, 1, 1), 0.15)
	return base, accent, glow
end

function VfxConfig.ReactionColor(reactionId: string): Color3
	return AnimConfig.ReactionColor[reactionId] or Color3.fromRGB(255, 248, 200)
end

function VfxConfig.ResolveProfile(fx: any): (string, Profile)
	local vfx = if typeof(fx.vfx) == "string" then fx.vfx else "Slash"
	local shape = fx.shape
	if shape == "AllyCone" or shape == "AllySphere" or shape == "AllySingle" then
		return "Support", VfxConfig.Profiles.Support
	end
	if vfx == "Aura" and (shape == "AllyCone" or shape == "AllySphere" or shape == "AllySingle") then
		return "Support", VfxConfig.Profiles.Support
	end
	local key = vfx
	if vfx == "Cone" then
		key = "Cone"
	elseif vfx == "Burst" then
		key = "Burst"
	elseif vfx == "Bolt" then
		key = "Bolt"
	elseif vfx == "Dash" then
		key = "Dash"
	elseif vfx == "Aura" then
		key = "Aura"
	else
		key = "Slash"
	end
	return key, VfxConfig.Profiles[key] or VfxConfig.Profiles.Slash
end

function VfxConfig.BuildContext(fx: any): VfxContext
	local element = fx.element or "Neutral"
	local primary, accent, glow = VfxConfig.ElementColors(element)
	local profileKey, profile = VfxConfig.ResolveProfile(fx)
	local step = math.clamp(fx.comboStep or 1, 1, 3)
	local stepScale = VfxConfig.ComboStep[step] or VfxConfig.ComboStep[2]
	local shape = fx.shape
	local isSupport = SUPPORT_SHAPES[shape] == true
	if isSupport then
		primary = primary:Lerp(Color3.fromRGB(70, 220, 120), profile.supportTint or 0.5)
		accent = accent:Lerp(Color3.fromRGB(120, 255, 170), 0.4)
	end

	local family = if typeof(fx.family) == "string" then fx.family else nil
	local famTune = if family then VfxConfig.FamilyTuning[family] else nil
	if famTune then
		profile = table.clone(profile)
		if famTune.particleMult then
			profile.particleMult = (profile.particleMult or 1) * famTune.particleMult
		end
		if famTune.lightMult then
			profile.lightBrightness = (profile.lightBrightness or 2.8) * famTune.lightMult
		end
		stepScale = table.clone(stepScale)
		if famTune.cameraKick then
			stepScale.cameraKick = famTune.cameraKick
		end
		if famTune.impactScale then
			stepScale.impactScale = famTune.impactScale
		end
	end

	return {
		element = element,
		primary = primary,
		accent = accent,
		glow = glow,
		profile = profile,
		profileKey = profileKey,
		step = step,
		stepScale = stepScale,
		isSupport = isSupport,
		vfx = fx.vfx or "Slash",
		shape = shape,
	}
end

-- Per-reaction burst tuning (PlayReaction)
VfxConfig.Reactions = {
	Vaporize = { scale = 1.45, ring = 10, flash = 56, label = true, kind = "fire" },
	ChainShock = { scale = 1.15, ring = 7, flash = 38, label = true, kind = "chain" },
	Chilled = { scale = 1.0, ring = 6, flash = 28, label = true, kind = "ice" },
	Thaw = { scale = 1.1, ring = 7, flash = 32, label = true, kind = "fire" },
	Cauterize = { scale = 1.2, ring = 8, flash = 40, label = true, kind = "hybrid" },
	Blight = { scale = 1.15, ring = 7, flash = 34, label = true, kind = "poison" },
	Grounded = { scale = 1.25, ring = 9, flash = 30, label = true, kind = "earth" },
	Contamination = { scale = 1.1, ring = 7, flash = 36, label = true, kind = "poison" },
	WildFire = { scale = 1.35, ring = 9, flash = 48, label = true, kind = "fire" },
	CausticBurn = { scale = 1.3, ring = 8, flash = 44, label = true, kind = "acid" },
}

VfxConfig.DefaultReaction = { scale = 1.0, ring = 8, flash = 42, label = true, kind = "neutral" }

function VfxConfig.ReactionStyle(reactionId: string)
	return VfxConfig.Reactions[reactionId] or VfxConfig.DefaultReaction
end

return VfxConfig
