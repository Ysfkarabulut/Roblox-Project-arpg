--[[
	WeaponAssemblyService — install/remove parts and gems on WeaponFrame.
]]

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)
local InventoryService = require(script.Parent.InventoryService)

local WeaponAssemblyService = {}

local PART_SLOTS = { "handle", "blade", "pommel" }

local KIND_FOR_SLOT = {
	handle = "WeaponHandle",
	blade = "WeaponBlade",
	pommel = "WeaponPommel",
}

local function getRawFrame(userId: number, frameUuid: string)
	local inst = InventoryService.FindRaw(userId, frameUuid)
	if not inst or inst.defId ~= "weapon_frame" then
		return nil
	end
	if not inst.parts then
		inst.parts = { handle = nil, blade = nil, pommel = nil }
	end
	return inst
end

function WeaponAssemblyService.ValidatePart(handleType: string?, partDef: any, slot: string): (boolean, string?)
	if not partDef then
		return false, "UnknownPart"
	end
	local expectedKind = KIND_FOR_SLOT[slot]
	if partDef.kind ~= expectedKind then
		return false, "WrongPartKind"
	end
	if slot ~= "pommel" and partDef.handleType and handleType and partDef.handleType ~= handleType then
		return false, "IncompatibleHandle"
	end
	if slot == "pommel" then
		local PommelDefs = require(game.ReplicatedStorage.Shared.Config.PommelDefs)
		local role = partDef.pommelRole or "Pommel"
		local handleTypeResolved = handleType or ""
		if PommelDefs.IsRangedHandle(handleTypeResolved) then
			if role ~= "String" then
				return false, "NeedString"
			end
		elseif role ~= "Pommel" then
			return false, "NeedPommel"
		end
	end
	return true, nil
end

function WeaponAssemblyService.GetHandleType(userId: number, frameUuid: string): string?
	local frame = getRawFrame(userId, frameUuid)
	if not frame or not frame.parts or not frame.parts.handle then
		return nil
	end
	local handleInst = InventoryService.FindRaw(userId, frame.parts.handle)
	local handleDef = handleInst and ItemDefs.Get(handleInst.defId)
	return handleDef and handleDef.handleType
end

function WeaponAssemblyService.InstallPart(userId: number, frameUuid: string, partUuid: string, slot: string): (boolean, string?)
	if not table.find(PART_SLOTS, slot) then
		return false, "BadSlot"
	end
	local frame = getRawFrame(userId, frameUuid)
	if not frame or not frame.parts then
		return false, "NotFrame"
	end
	local partInst = InventoryService.FindRaw(userId, partUuid)
	if not partInst then
		return false, "NotOwned"
	end
	if partInst.installedIn and partInst.installedIn ~= frameUuid then
		return false, "AlreadyInstalled"
	end
	if partInst.defId == "weapon_frame" then
		return false, "CannotInstallFrame"
	end

	local partDef = ItemDefs.Get(partInst.defId)
	local handleType = WeaponAssemblyService.GetHandleType(userId, frameUuid)

	if slot == "handle" then
		handleType = partDef and partDef.handleType
	elseif not handleType then
		return false, "InstallHandleFirst"
	end

	local ok, err = WeaponAssemblyService.ValidatePart(handleType, partDef, slot)
	if not ok then
		return false, err
	end

	-- Remove existing part in slot
	local existingUuid = (frame.parts :: any)[slot]
	if existingUuid then
		WeaponAssemblyService.RemovePart(userId, frameUuid, slot)
	end

	(frame.parts :: any)[slot] = partUuid
	partInst.installedIn = frameUuid
	return true, nil
end

function WeaponAssemblyService.RemovePart(userId: number, frameUuid: string, slot: string): (boolean, string?)
	if not table.find(PART_SLOTS, slot) then
		return false, "BadSlot"
	end
	local frame = getRawFrame(userId, frameUuid)
	if not frame or not frame.parts then
		return false, "NotFrame"
	end
	local partUuid = (frame.parts :: any)[slot]
	if not partUuid then
		return false, "EmptySlot"
	end
	local partInst = InventoryService.FindRaw(userId, partUuid)
	if partInst then
		partInst.installedIn = nil
	end
	(frame.parts :: any)[slot] = nil
	return true, nil
end

function WeaponAssemblyService.SocketGem(userId: number, frameUuid: string, gemUuid: string): (boolean, string?)
	local frame = getRawFrame(userId, frameUuid)
	if not frame then
		return false, "NotFrame"
	end
	local gemInst = InventoryService.FindRaw(userId, gemUuid)
	if not gemInst then
		return false, "NotOwned"
	end
	local gemDef = ItemDefs.Get(gemInst.defId)
	if not gemDef or gemDef.kind ~= "ElementGem" then
		return false, "NotGem"
	end
	if gemInst.installedIn and gemInst.installedIn ~= frameUuid then
		return false, "GemInUse"
	end

	-- Return existing gem to bag (do not destroy)
	if frame.gemUuid then
		local oldGem = InventoryService.FindRaw(userId, frame.gemUuid)
		if oldGem then
			oldGem.installedIn = nil
		end
		frame.gemUuid = nil
	end

	frame.gemUuid = gemUuid
	gemInst.installedIn = frameUuid
	return true, nil
end

function WeaponAssemblyService.UnsocketGem(userId: number, frameUuid: string): (boolean, string?)
	local frame = getRawFrame(userId, frameUuid)
	if not frame then
		return false, "NotFrame"
	end
	if not frame.gemUuid then
		return false, "NoGem"
	end
	local gemInst = InventoryService.FindRaw(userId, frame.gemUuid)
	if gemInst then
		gemInst.installedIn = nil
	end
	frame.gemUuid = nil
	return true, nil
end

function WeaponAssemblyService.ToResolved(userId: number, frameUuid: string)
	local frame = InventoryService.Find(userId, frameUuid)
	if not frame then
		return WeaponResolver.ResolveFrame(userId, nil, InventoryService.Find)
	end
	return WeaponResolver.ResolveFrame(userId, frame, function(uid, uuid)
		return InventoryService.Find(uid, uuid)
	end)
end

function WeaponAssemblyService.CreateFrame(userId: number)
	return InventoryService.AddItem(userId, "weapon_frame", {
		parts = { handle = nil, blade = nil, pommel = nil },
	})
end

return WeaponAssemblyService
