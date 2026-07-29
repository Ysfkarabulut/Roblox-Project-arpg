--[[
	WeaponAssemblyService — install/remove parts and gems on WeaponFrame.
]]

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local WeaponResolver = require(game.ReplicatedStorage.Shared.Combat.WeaponResolver)
local InventoryService = require(script.Parent.InventoryService)
local LoadoutService = require(script.Parent.LoadoutService)
local CurrencyService = require(script.Parent.CurrencyService)

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

	for _, slotName in PART_SLOTS do
		local existing = (frame.parts :: any)[slotName]
		if existing == partUuid then
			return false, "DuplicatePart"
		end
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
	local resolved = WeaponResolver.ResolveFrame(userId, frame, function(uid, partUuid)
		return InventoryService.Find(uid, partUuid)
	end)
	local equipSlot = LoadoutService.GetSlotOf(userId, frameUuid)
	if equipSlot and not resolved.complete then
		LoadoutService.Unequip(userId, equipSlot)
	end
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
	if not gemDef or gemDef.kind ~= "ElementGem" or gemDef.element == "Neutral" then
		return false, "NotGem"
	end
	if gemInst.installedIn and gemInst.installedIn ~= frameUuid then
		return false, "GemInUse"
	end

	-- Replacing socketed gem destroys the old gem (GDD: gems break on removal)
	if frame.gemUuid then
		InventoryService.RemoveItem(userId, frame.gemUuid)
		frame.gemUuid = nil
	end

	frame.gemUuid = gemUuid
	gemInst.installedIn = frameUuid
	return true, nil
end

--- @param preserve false = gem destroyed (default) · true = spend premium currency, gem returns to bag
function WeaponAssemblyService.UnsocketGem(userId: number, frameUuid: string, preserve: boolean?): (boolean, string?)
	local frame = getRawFrame(userId, frameUuid)
	if not frame then
		return false, "NotFrame"
	end
	if not frame.gemUuid then
		return false, "NoGem"
	end

	local gemUuid = frame.gemUuid
	frame.gemUuid = nil

	if preserve == true then
		local spend = CurrencyService.TrySpendForGemPreserveUnsocket(userId)
		if not spend.ok then
			frame.gemUuid = gemUuid
			return false, spend.reason or "InsufficientPremium"
		end
		local gemInst = InventoryService.FindRaw(userId, gemUuid)
		if gemInst then
			gemInst.installedIn = nil
		end
		return true, "Preserved"
	end

	InventoryService.RemoveItem(userId, gemUuid)
	return true, "Destroyed"
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

--- Build a new weapon from free bag parts (handle + blade + pommel, optional gem).
--- Gem issues never abort forge — weapon completes as Neutral (no socketed gem).
--- Returns frameUuid, hard error, optional gemSkipped reason.
function WeaponAssemblyService.ForgeFromParts(
	userId: number,
	handleUuid: string,
	bladeUuid: string,
	pommelUuid: string,
	gemUuid: string?
): (string?, string?, string?)
	if typeof(handleUuid) ~= "string" or typeof(bladeUuid) ~= "string" or typeof(pommelUuid) ~= "string" then
		return nil, "BadParts", nil
	end
	if handleUuid == bladeUuid or handleUuid == pommelUuid or bladeUuid == pommelUuid then
		return nil, "DuplicateParts", nil
	end
	if gemUuid and (gemUuid == handleUuid or gemUuid == bladeUuid or gemUuid == pommelUuid) then
		return nil, "DuplicateParts", nil
	end

	local handleInst = InventoryService.FindRaw(userId, handleUuid)
	local bladeInst = InventoryService.FindRaw(userId, bladeUuid)
	local pommelInst = InventoryService.FindRaw(userId, pommelUuid)
	if not handleInst or not bladeInst or not pommelInst then
		return nil, "NotOwned", nil
	end
	if handleInst.installedIn or bladeInst.installedIn or pommelInst.installedIn then
		return nil, "AlreadyInstalled", nil
	end

	local handleDef = ItemDefs.Get(handleInst.defId)
	local bladeDef = ItemDefs.Get(bladeInst.defId)
	local pommelDef = ItemDefs.Get(pommelInst.defId)
	if not handleDef or handleDef.kind ~= "WeaponHandle" then
		return nil, "NeedHandle", nil
	end
	if not bladeDef or bladeDef.kind ~= "WeaponBlade" then
		return nil, "NeedBlade", nil
	end
	if not pommelDef or pommelDef.kind ~= "WeaponPommel" then
		return nil, "NeedPommel", nil
	end

	local handleType = handleDef.handleType
	local okBlade, errBlade = WeaponAssemblyService.ValidatePart(handleType, bladeDef, "blade")
	if not okBlade then
		return nil, errBlade, nil
	end
	local okPommel, errPommel = WeaponAssemblyService.ValidatePart(handleType, pommelDef, "pommel")
	if not okPommel then
		return nil, errPommel, nil
	end

	local gemInst = nil
	local gemSkipped: string? = nil
	if typeof(gemUuid) == "string" and gemUuid ~= "" then
		gemInst = InventoryService.FindRaw(userId, gemUuid)
		if not gemInst then
			gemSkipped = "GemNotOwned"
		elseif gemInst.installedIn then
			gemSkipped = "GemAlreadyInstalled"
		else
			local gemDef = ItemDefs.Get(gemInst.defId)
			if not gemDef or gemDef.kind ~= "ElementGem" or gemDef.element == "Neutral" then
				gemSkipped = "InvalidGem"
			end
		end
	end

	local frame = WeaponAssemblyService.CreateFrame(userId)
	if not frame then
		return nil, "FrameFailed", nil
	end

	local okH, errH = WeaponAssemblyService.InstallPart(userId, frame.uuid, handleUuid, "handle")
	if not okH then
		InventoryService.RemoveItem(userId, frame.uuid)
		return nil, errH or "InstallHandleFailed", nil
	end
	local okB, errB = WeaponAssemblyService.InstallPart(userId, frame.uuid, bladeUuid, "blade")
	if not okB then
		WeaponAssemblyService.RemovePart(userId, frame.uuid, "handle")
		InventoryService.RemoveItem(userId, frame.uuid)
		return nil, errB or "InstallBladeFailed", nil
	end
	local okP, errP = WeaponAssemblyService.InstallPart(userId, frame.uuid, pommelUuid, "pommel")
	if not okP then
		WeaponAssemblyService.RemovePart(userId, frame.uuid, "blade")
		WeaponAssemblyService.RemovePart(userId, frame.uuid, "handle")
		InventoryService.RemoveItem(userId, frame.uuid)
		return nil, errP or "InstallPommelFailed", nil
	end

	if gemInst and not gemSkipped then
		local okG, errG = WeaponAssemblyService.SocketGem(userId, frame.uuid, gemUuid :: string)
		if not okG then
			gemSkipped = errG or "GemSocketFailed"
		end
	end

	return frame.uuid, nil, gemSkipped
end

return WeaponAssemblyService
