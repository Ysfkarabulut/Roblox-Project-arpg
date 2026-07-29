--[[
	LoadoutService — slot → item uuid.
	Main / off: WeaponFrame (modular). Off-hand 1H frames enable dual wield.
]]

local Players = game:GetService("Players")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutSlots = require(game.ReplicatedStorage.Shared.Config.LoadoutSlots)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)
local InventoryService = require(script.Parent.InventoryService)
local WeaponAssemblyService = require(script.Parent.WeaponAssemblyService)

export type LoadoutMap = {
	main: string?,
	off: string?,
	head: string?,
	chest: string?,
	hands: string?,
	feets: string?,
}

local LoadoutService = {}

local loadouts: { [number]: LoadoutMap } = {}

local function emptyLoadout(): LoadoutMap
	return {
		main = nil,
		off = nil,
		head = nil,
		chest = nil,
		hands = nil,
		feets = nil,
	}
end

local function ensure(userId: number): LoadoutMap
	if not loadouts[userId] then
		loadouts[userId] = emptyLoadout()
	end
	return loadouts[userId]
end

function LoadoutService.Get(userId: number): LoadoutMap
	local lo = ensure(userId)
	return {
		main = lo.main,
		off = lo.off,
		head = lo.head,
		chest = lo.chest,
		hands = lo.hands,
		feets = lo.feets,
	}
end

function LoadoutService.IsEquipped(userId: number, uuid: string): boolean
	local lo = ensure(userId)
	for _, slot in LoadoutSlots.Order do
		if (lo :: any)[slot] == uuid then
			return true
		end
	end
	return false
end

function LoadoutService.GetSlotOf(userId: number, uuid: string): string?
	local lo = ensure(userId)
	for _, slot in LoadoutSlots.Order do
		if (lo :: any)[slot] == uuid then
			return slot
		end
	end
	return nil
end

local function kindOfUuid(userId: number, uuid: string): string?
	local inst = InventoryService.Find(userId, uuid)
	if not inst then
		return nil
	end
	if inst.defId == "weapon_frame" then
		local resolved = WeaponAssemblyService.ToResolved(userId, uuid)
		return resolved.kind
	end
	local def = ItemDefs.Get(inst.defId)
	return def and def.kind or nil
end

function LoadoutService.GetResolvedMain(userId: number)
	local lo = ensure(userId)
	if not lo.main then
		return nil
	end
	return WeaponAssemblyService.ToResolved(userId, lo.main)
end

function LoadoutService.GetResolvedOff(userId: number)
	local lo = ensure(userId)
	if not lo.off then
		return nil
	end
	local inst = InventoryService.Find(userId, lo.off)
	if not inst or inst.defId ~= "weapon_frame" then
		return nil
	end
	return WeaponAssemblyService.ToResolved(userId, lo.off)
end

--- StanceConfig input for off slot (frame → resolved pseudo-def, else catalog def).
function LoadoutService.GetOffHandDef(userId: number): any?
	local lo = ensure(userId)
	if not lo.off then
		return nil
	end
	local inst = InventoryService.Find(userId, lo.off)
	if not inst then
		return nil
	end
	if inst.defId == "weapon_frame" then
		local resolved = WeaponAssemblyService.ToResolved(userId, lo.off)
		if resolved and resolved.complete then
			return WeaponResolver.AsItemDef(resolved)
		end
		return nil
	end
	return ItemDefs.Get(inst.defId)
end

-- 2H / Bow / Crossbow / Staff main → off Knot veya Quiver (türe göre)
local function offCompatible(mainKind: string?, offKind: string?): boolean
	if not mainKind then
		return true
	end
	if mainKind == "Weapon2H" or mainKind == "Staff" then
		return offKind == nil or offKind == "Knot"
	end
	if mainKind == "Bow" or mainKind == "Crossbow" then
		return offKind == nil or offKind == "Quiver"
	end
	-- 1H: shield, 1H weapon / frame, focus, wand, scepter
	if offKind == "Quiver" or offKind == "Knot" then
		return false
	end
	return true
end

function LoadoutService.Unequip(userId: number, slotId: string): (boolean, string?)
	local lo = ensure(userId)
	if not table.find(LoadoutSlots.Order, slotId) then
		return false, "BadSlot"
	end
	(lo :: any)[slotId] = nil
	return true, nil
end

function LoadoutService.Equip(userId: number, uuid: string, slotId: string): (boolean, string?)
	if not table.find(LoadoutSlots.Order, slotId) then
		return false, "BadSlot"
	end

	local inst = InventoryService.Find(userId, uuid)
	if not inst then
		return false, "NotOwned"
	end
	if InventoryService.IsInstalled(userId, uuid) and inst.defId ~= "weapon_frame" then
		return false, "PartInstalled"
	end

	local def = ItemDefs.Get(inst.defId)
	if not def then
		return false, "UnknownDef"
	end

	local lo = ensure(userId)

	if slotId == "main" then
		if def.kind ~= "WeaponFrame" then
			return false, "MainRequiresFrame"
		end
		local resolvedMain = WeaponAssemblyService.ToResolved(userId, uuid)
		if not resolvedMain.complete then
			return false, "FrameIncomplete"
		end
	elseif inst.defId == "weapon_frame" then
		if slotId ~= "off" then
			return false, "WrongSlot"
		end
		local resolved = WeaponAssemblyService.ToResolved(userId, uuid)
		if not resolved.complete then
			return false, "FrameIncomplete"
		end
		if not LoadoutSlots.IsOneHandWeaponKind(resolved.kind) then
			return false, "OffRequires1H"
		end
		local mainKind = lo.main and kindOfUuid(userId, lo.main) or nil
		if mainKind and not LoadoutSlots.IsOneHandWeaponKind(mainKind) then
			return false, "MainRequires1H"
		end
	elseif not ItemDefs.CanEquipInSlot(inst.defId, slotId) then
		return false, "WrongSlot"
	end

	for _, s in LoadoutSlots.Order do
		if (lo :: any)[s] == uuid then
			(lo :: any)[s] = nil
		end
	end

	if slotId == "main" then
		local offUuid = lo.off
		local offKind = offUuid and kindOfUuid(userId, offUuid) or nil
		local mainKind = kindOfUuid(userId, uuid)
		if not offCompatible(mainKind, offKind) then
			lo.off = nil
		end
	elseif slotId == "off" then
		local mainUuid = lo.main
		local mainKind = mainUuid and kindOfUuid(userId, mainUuid) or nil
		local offKind = if inst.defId == "weapon_frame"
			then (WeaponAssemblyService.ToResolved(userId, uuid).kind)
			else def.kind
		if not offCompatible(mainKind, offKind) then
			return false, "OffIncompatible"
		end
	end

	(lo :: any)[slotId] = uuid
	return true, nil
end

function LoadoutService.Import(userId: number, loadout: { [string]: string? })
	local seen: { [string]: boolean } = {}
	local lo = emptyLoadout()
	for _, slotId in LoadoutSlots.Order do
		local uuid = loadout[slotId]
		if uuid and not seen[uuid] then
			(lo :: any)[slotId] = uuid
			seen[uuid] = true
		end
	end
	loadouts[userId] = lo
end

function LoadoutService.Clear(userId: number)
	loadouts[userId] = nil
end

return LoadoutService
