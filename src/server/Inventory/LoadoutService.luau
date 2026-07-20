--[[
	LoadoutService — slot → item uuid.
	Kurallar: GDD §5 (2H/Bow/Staff → Knot/Quiver off uyumu basit kontrol).
]]

local Players = game:GetService("Players")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutSlots = require(game.ReplicatedStorage.Shared.Config.LoadoutSlots)
local InventoryService = require(script.Parent.InventoryService)

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
	local def = ItemDefs.Get(inst.defId)
	return def and def.kind or nil
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
	-- 1H: shield, 1H weapon, focus, wand, scepter
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
	if not ItemDefs.CanEquipInSlot(inst.defId, slotId) then
		return false, "WrongSlot"
	end

	local def = ItemDefs.Get(inst.defId)
	if not def then
		return false, "UnknownDef"
	end

	local lo = ensure(userId)

	-- Aynı uuid başka slotta ise önce oradan çıkar
	for _, s in LoadoutSlots.Order do
		if (lo :: any)[s] == uuid then
			(lo :: any)[s] = nil
		end
	end

	if slotId == "main" then
		local offUuid = lo.off
		local offKind = offUuid and kindOfUuid(userId, offUuid) or nil
		if not offCompatible(def.kind, offKind) then
			lo.off = nil -- uyumsuz off otomatik düşer
		end
	elseif slotId == "off" then
		local mainUuid = lo.main
		local mainKind = mainUuid and kindOfUuid(userId, mainUuid) or nil
		if not offCompatible(mainKind, def.kind) then
			return false, "OffIncompatible"
		end
	end

	(lo :: any)[slotId] = uuid
	return true, nil
end

Players.PlayerRemoving:Connect(function(player)
	loadouts[player.UserId] = nil
end)

return LoadoutService
