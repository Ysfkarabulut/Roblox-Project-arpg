--[[
	HotbarService — aktif yetenek bağları (abilityId + sourceUuid → slot 1..6).
]]

local HotbarConfig = require(game.ReplicatedStorage.Shared.Config.HotbarConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local WeaponAssemblyService = require(script.Parent.Parent.Inventory.WeaponAssemblyService)
local LoadoutSlots = require(game.ReplicatedStorage.Shared.Config.LoadoutSlots)

export type HotbarBinds = { [number]: string? }
export type HotbarSources = { [number]: string? }

local HotbarService = {}

local bindsByUser: { [number]: HotbarBinds } = {}
local sourcesByUser: { [number]: HotbarSources } = {}

local function emptyBinds(): HotbarBinds
	local b: HotbarBinds = {}
	for i = 1, HotbarConfig.SlotCount do
		b[i] = nil
	end
	return b
end

local function emptySources(): HotbarSources
	local s: HotbarSources = {}
	for i = 1, HotbarConfig.SlotCount do
		s[i] = nil
	end
	return s
end

local function ensure(userId: number): HotbarBinds
	if not bindsByUser[userId] then
		bindsByUser[userId] = emptyBinds()
	end
	return bindsByUser[userId]
end

local function ensureSources(userId: number): HotbarSources
	if not sourcesByUser[userId] then
		sourcesByUser[userId] = emptySources()
	end
	return sourcesByUser[userId]
end

function HotbarService.GetAvailableActives(userId: number): { { abilityId: string, name: string, desc: string, sourceUuid: string, defId: string } }
	local out = {}
	local loadout = LoadoutService.Get(userId)

	if loadout.main then
		local resolved = WeaponAssemblyService.ToResolved(userId, loadout.main)
		if resolved and resolved.complete and resolved.abilities then
			for _, ab in resolved.abilities do
				if ab.slotType == "Active" then
					table.insert(out, {
						abilityId = ab.id,
						name = ab.name,
						desc = ab.desc,
						sourceUuid = loadout.main,
						defId = "weapon_frame",
					})
				end
			end
		end
	end

	for _, slotId in LoadoutSlots.Order do
		if slotId == "main" then
			continue
		end
		local uuid = (loadout :: any)[slotId] :: string?
		if not uuid then
			continue
		end
		local inst = InventoryService.Find(userId, uuid)
		if not inst then
			continue
		end
		if inst.defId == "weapon_frame" then
			local resolved = WeaponAssemblyService.ToResolved(userId, uuid)
			if resolved and resolved.complete and resolved.abilities then
				for _, ab in resolved.abilities do
					if ab.slotType == "Active" then
						table.insert(out, {
							abilityId = ab.id,
							name = ab.name,
							desc = ab.desc,
							sourceUuid = uuid,
							defId = "weapon_frame",
						})
					end
				end
			end
			continue
		end
		local def = ItemDefs.Get(inst.defId)
		if def and def.abilities then
			for _, ab in def.abilities do
				if ab.slotType == "Active" then
					table.insert(out, {
						abilityId = ab.id,
						name = ab.name,
						desc = ab.desc,
						sourceUuid = uuid,
						defId = inst.defId,
					})
				end
			end
		end
	end
	return out
end

local function findActiveSource(userId: number, abilityId: string, sourceUuid: string?): string?
	for _, a in HotbarService.GetAvailableActives(userId) do
		if a.abilityId == abilityId and (not sourceUuid or a.sourceUuid == sourceUuid) then
			return a.sourceUuid
		end
	end
	return nil
end

local function isBindValid(userId: number, abilityId: string, sourceUuid: string?): boolean
	return findActiveSource(userId, abilityId, sourceUuid) ~= nil
end

function HotbarService.GetBinds(userId: number): HotbarBinds
	local b = ensure(userId)
	local copy: HotbarBinds = {}
	for i = 1, HotbarConfig.SlotCount do
		copy[i] = b[i]
	end
	return copy
end

function HotbarService.GetBindSources(userId: number): HotbarSources
	local s = ensureSources(userId)
	local copy: HotbarSources = {}
	for i = 1, HotbarConfig.SlotCount do
		copy[i] = s[i]
	end
	return copy
end

function HotbarService.GetBindForSlot(userId: number, slotIndex: number): (string?, string?)
	if not HotbarConfig.IsValidSlot(slotIndex) then
		return nil, nil
	end
	return ensure(userId)[slotIndex], ensureSources(userId)[slotIndex]
end

function HotbarService.Prune(userId: number)
	local b = ensure(userId)
	local s = ensureSources(userId)
	for i = 1, HotbarConfig.SlotCount do
		local id = b[i]
		if id and not isBindValid(userId, id, s[i]) then
			b[i] = nil
			s[i] = nil
		elseif id then
			s[i] = findActiveSource(userId, id, s[i])
		end
	end
end

function HotbarService.Bind(userId: number, abilityId: string, slotIndex: number, sourceUuid: string?): (boolean, string?)
	if not HotbarConfig.IsValidSlot(slotIndex) then
		return false, "BadSlot"
	end
	local resolvedSource = findActiveSource(userId, abilityId, sourceUuid)
	if not resolvedSource then
		return false, "NotAvailable"
	end
	local b = ensure(userId)
	local s = ensureSources(userId)
	for i = 1, HotbarConfig.SlotCount do
		if b[i] == abilityId and s[i] == resolvedSource then
			b[i] = nil
			s[i] = nil
		end
	end
	b[slotIndex] = abilityId
	s[slotIndex] = resolvedSource
	return true, nil
end

function HotbarService.Unbind(userId: number, slotIndex: number): (boolean, string?)
	if not HotbarConfig.IsValidSlot(slotIndex) then
		return false, "BadSlot"
	end
	ensure(userId)[slotIndex] = nil
	ensureSources(userId)[slotIndex] = nil
	return true, nil
end

function HotbarService.AutoFill(userId: number): number
	HotbarService.Prune(userId)
	local b = ensure(userId)
	local s = ensureSources(userId)
	local filled = 0
	local used: { [string]: boolean } = {}
	for i = 1, HotbarConfig.SlotCount do
		if b[i] and s[i] then
			used[`{b[i]}@{s[i]}`] = true
		end
	end
	for _, a in HotbarService.GetAvailableActives(userId) do
		local key = `{a.abilityId}@{a.sourceUuid}`
		if not used[key] then
			for i = 1, HotbarConfig.SlotCount do
				if b[i] == nil then
					b[i] = a.abilityId
					s[i] = a.sourceUuid
					used[key] = true
					filled += 1
					break
				end
			end
		end
	end
	return filled
end

function HotbarService.GetAbilityInSlot(userId: number, slotIndex: number): string?
	return ensure(userId)[slotIndex]
end

function HotbarService.ImportBinds(userId: number, binds: HotbarBinds, sources: HotbarSources?)
	local b = emptyBinds()
	local s = emptySources()
	for i = 1, HotbarConfig.SlotCount do
		b[i] = binds[i]
		if sources then
			s[i] = sources[i]
		end
	end
	bindsByUser[userId] = b
	sourcesByUser[userId] = s
end

function HotbarService.Clear(userId: number)
	bindsByUser[userId] = nil
	sourcesByUser[userId] = nil
end

return HotbarService
