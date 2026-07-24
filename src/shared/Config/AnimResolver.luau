--[[
	Resolves CombatAnimDefs clip ids → playable AnimationId.
	Priority: CombatAnims folder (clipName) → catalog animId → fallbackId chain.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatAnimDefs = require(script.Parent.CombatAnimDefs)

local AnimResolver = {}

export type ResolvedClip = {
	id: string,
	animId: string,
	dedicated: boolean,
	def: CombatAnimDefs.AnimClipDef,
	speed: number?,
	weight: number?,
	fadeIn: number?,
	fadeOut: number?,
	sanitizeTranslation: boolean?,
	lean: number?,
}

local function clipNames(def: CombatAnimDefs.AnimClipDef): { string }
	local names: { string } = {}
	if typeof(def.clipName) == "string" then
		table.insert(names, def.clipName)
	end
	if typeof(def.clipNameAlts) == "table" then
		for _, n in def.clipNameAlts do
			if typeof(n) == "string" then
				table.insert(names, n)
			end
		end
	end
	return names
end

function AnimResolver.FindFolderAnimation(def: CombatAnimDefs.AnimClipDef): string?
	local folder = ReplicatedStorage:FindFirstChild("CombatAnims")
	if not folder then
		return nil
	end
	for _, name in clipNames(def) do
		local inst = folder:FindFirstChild(name)
		if inst and inst:IsA("Animation") and inst.AnimationId ~= "" then
			return inst.AnimationId
		end
	end
	return nil
end

function AnimResolver.ResolveById(clipId: string, visited: { [string]: boolean }?): ResolvedClip?
	local def = CombatAnimDefs.Get(clipId)
	if not def then
		return nil
	end

	visited = visited or {}
	if visited[clipId] then
		return nil
	end
	visited[clipId] = true

	local folderId = AnimResolver.FindFolderAnimation(def)
	if folderId then
		return {
			id = clipId,
			animId = folderId,
			dedicated = true,
			def = def,
			speed = def.speed,
			weight = def.weight,
			fadeIn = def.fadeIn,
			fadeOut = def.fadeOut,
			sanitizeTranslation = def.sanitizeTranslation,
			lean = def.lean,
		}
	end

	if typeof(def.animId) == "string" and string.sub(def.animId, 1, 13) == "rbxassetid://" then
		return {
			id = clipId,
			animId = def.animId,
			dedicated = true,
			def = def,
			speed = def.speed,
			weight = def.weight,
			fadeIn = def.fadeIn,
			fadeOut = def.fadeOut,
			sanitizeTranslation = def.sanitizeTranslation,
			lean = def.lean,
		}
	end

	if typeof(def.fallbackId) == "string" then
		local fb = AnimResolver.ResolveById(def.fallbackId, visited)
		if fb then
			return {
				id = clipId,
				animId = fb.animId,
				dedicated = false,
				def = def,
				speed = def.speed or fb.speed,
				weight = def.weight or fb.weight,
				fadeIn = def.fadeIn or fb.fadeIn,
				fadeOut = def.fadeOut or fb.fadeOut,
				sanitizeTranslation = def.sanitizeTranslation or fb.sanitizeTranslation,
				lean = def.lean or fb.lean,
			}
		end
	end

	return nil
end

function AnimResolver.ResolveLegacyName(legacyName: string): ResolvedClip?
	local clipId = CombatAnimDefs.IdFromLegacyName(legacyName)
	if not clipId then
		return nil
	end
	return AnimResolver.ResolveById(clipId)
end

function AnimResolver.ResolveSprint(stanceId: string): ResolvedClip?
	local clipId = CombatAnimDefs.SprintClipId(stanceId)
	if not clipId then
		return AnimResolver.ResolveById(CombatAnimDefs.SprintFallbackId())
	end
	return AnimResolver.ResolveById(clipId)
end

function AnimResolver.ResolveLa(familyAnimPrefix: string, step: number): ResolvedClip?
	return AnimResolver.ResolveById(CombatAnimDefs.LaClipId(familyAnimPrefix, step))
end

return AnimResolver
