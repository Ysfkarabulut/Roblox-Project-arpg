--[[
	InventoryService — UUID instance bag with modular weapon state.
]]

local HttpService = game:GetService("HttpService")

local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LegacyWeaponConverter = require(game.ReplicatedStorage.Shared.Config.LegacyWeaponConverter)

export type WeaponFrameParts = {
	handle: string?,
	blade: string?,
	pommel: string?,
}

export type ItemInstance = {
	uuid: string,
	defId: string,
	parts: WeaponFrameParts?,
	gemUuid: string?,
	installedIn: string?,
	upgradeLevel: number?,
}

local InventoryService = {}

local bags: { [number]: { ItemInstance } } = {}

local function cloneInstance(item: ItemInstance): ItemInstance
	local copy: ItemInstance = {
		uuid = item.uuid,
		defId = item.defId,
	}
	if item.parts then
		copy.parts = {
			handle = item.parts.handle,
			blade = item.parts.blade,
			pommel = item.parts.pommel,
		}
	end
	if item.gemUuid then
		copy.gemUuid = item.gemUuid
	end
	if item.installedIn then
		copy.installedIn = item.installedIn
	end
	if typeof((item :: any).upgradeLevel) == "number" then
		copy.upgradeLevel = (item :: any).upgradeLevel
	end
	return copy
end

local function ensureBag(userId: number): { ItemInstance }
	if not bags[userId] then
		bags[userId] = {}
	end
	return bags[userId]
end

function InventoryService.GetItems(userId: number): { ItemInstance }
	local bag = ensureBag(userId)
	local copy = table.create(#bag)
	for i, item in bag do
		copy[i] = cloneInstance(item)
	end
	return copy
end

function InventoryService.Find(userId: number, uuid: string): ItemInstance?
	for _, item in ensureBag(userId) do
		if item.uuid == uuid then
			return cloneInstance(item)
		end
	end
	return nil
end

function InventoryService.FindRaw(userId: number, uuid: string): ItemInstance?
	for _, item in ensureBag(userId) do
		if item.uuid == uuid then
			return item
		end
	end
	return nil
end

function InventoryService.AddItem(userId: number, defId: string, extra: { parts: WeaponFrameParts?, gemUuid: string? }?): ItemInstance?
	if not ItemDefs.Get(defId) then
		warn("[Inventory] Unknown defId", defId)
		return nil
	end
	local instance: ItemInstance = {
		uuid = HttpService:GenerateGUID(false),
		defId = defId,
	}
	if extra then
		if extra.parts then
			instance.parts = {
				handle = extra.parts.handle,
				blade = extra.parts.blade,
				pommel = extra.parts.pommel,
			}
		end
		if extra.gemUuid then
			instance.gemUuid = extra.gemUuid
		end
	end
	table.insert(ensureBag(userId), instance)
	return cloneInstance(instance)
end

function InventoryService.ReplaceBag(userId: number, items: { ItemInstance })
	bags[userId] = {}
	local skipped = 0
	for _, item in items do
		if ItemDefs.Get(item.defId) then
			table.insert(ensureBag(userId), cloneInstance(item))
		else
			skipped += 1
		end
	end
	if skipped > 0 then
		warn(`[Inventory] ReplaceBag skipped {skipped} unknown defId(s) for user {userId}`)
	end
end

function InventoryService.Clear(userId: number)
	bags[userId] = nil
end

function InventoryService.ReleaseFrameParts(userId: number, frameUuid: string)
	local frame = InventoryService.FindRaw(userId, frameUuid)
	if not frame or frame.defId ~= "weapon_frame" then
		return
	end
	local parts = frame.parts
	if parts then
		for _, partUuid in { parts.handle, parts.blade, parts.pommel } do
			if partUuid then
				local part = InventoryService.FindRaw(userId, partUuid)
				if part then
					part.installedIn = nil
				end
			end
		end
	end
	if frame.gemUuid then
		local gem = InventoryService.FindRaw(userId, frame.gemUuid)
		if gem then
			gem.installedIn = nil
		end
	end
end

function InventoryService.RemoveItem(userId: number, uuid: string): boolean
	local bag = ensureBag(userId)
	for i, item in bag do
		if item.uuid == uuid then
			table.remove(bag, i)
			return true
		end
	end
	return false
end

function InventoryService.TransferItem(fromUserId: number, toUserId: number, uuid: string): boolean
	local raw = InventoryService.FindRaw(fromUserId, uuid)
	if not raw then
		return false
	end
	if not InventoryService.RemoveItem(fromUserId, uuid) then
		return false
	end
	table.insert(ensureBag(toUserId), cloneInstance(raw))
	return true
end

function InventoryService.SetInstalledIn(userId: number, partUuid: string, frameUuid: string?)
	local item = InventoryService.FindRaw(userId, partUuid)
	if not item then
		return false
	end
	item.installedIn = frameUuid
	return true
end

function InventoryService.IsInstalled(userId: number, uuid: string): boolean
	local item = InventoryService.FindRaw(userId, uuid)
	return item ~= nil and item.installedIn ~= nil
end

--- Create assembled WeaponFrame from part def ids (creates part instances + frame)
function InventoryService.CreateAssembledFrame(userId: number, handleId: string, bladeId: string, pommelId: string, gemId: string?): ItemInstance?
	local handleInst = InventoryService.AddItem(userId, handleId)
	local bladeInst = InventoryService.AddItem(userId, bladeId)
	local pommelInst = InventoryService.AddItem(userId, pommelId)
	if not handleInst or not bladeInst or not pommelInst then
		return nil
	end

	local gemUuid: string? = nil
	if gemId then
		local gemInst = InventoryService.AddItem(userId, gemId)
		gemUuid = gemInst and gemInst.uuid
	end

	local frame = InventoryService.AddItem(userId, "weapon_frame", {
		parts = {
			handle = handleInst.uuid,
			blade = bladeInst.uuid,
			pommel = pommelInst.uuid,
		},
		gemUuid = gemUuid,
	})
	if not frame then
		return nil
	end

	InventoryService.SetInstalledIn(userId, handleInst.uuid, frame.uuid)
	InventoryService.SetInstalledIn(userId, bladeInst.uuid, frame.uuid)
	InventoryService.SetInstalledIn(userId, pommelInst.uuid, frame.uuid)
	if gemUuid then
		InventoryService.SetInstalledIn(userId, gemUuid, frame.uuid)
	end

	local raw = InventoryService.FindRaw(userId, frame.uuid)
	if raw then
		raw.parts = { handle = handleInst.uuid, blade = bladeInst.uuid, pommel = pommelInst.uuid }
		raw.gemUuid = gemUuid
	end
	return cloneInstance(raw :: ItemInstance)
end

function InventoryService.ConvertLegacyWeapon(userId: number, legacyDefId: string): ItemInstance?
	local parts = LegacyWeaponConverter.ResolveParts(legacyDefId)
	if not parts then
		return nil
	end
	return InventoryService.CreateAssembledFrame(userId, parts.handleId, parts.bladeId, parts.pommelId, parts.gemId)
end

function InventoryService.MigrateLegacyItems(userId: number)
	local LoadoutService = require(script.Parent.LoadoutService)
	local bag = ensureBag(userId)
	local toConvert: { { index: number, defId: string, uuid: string } } = {}
	for i, item in bag do
		if LegacyWeaponConverter.IsLegacyWeaponId(item.defId) then
			table.insert(toConvert, { index = i, defId = item.defId, uuid = item.uuid })
		end
	end
	-- Reverse order so indices stay valid
	for i = #toConvert, 1, -1 do
		local entry = toConvert[i]
		local slot = LoadoutService.GetSlotOf(userId, entry.uuid)
		local frame = InventoryService.ConvertLegacyWeapon(userId, entry.defId)
		if frame then
			if slot then
				LoadoutService.Equip(userId, frame.uuid, slot)
			end
			table.remove(bag, entry.index)
		end
	end
end

function InventoryService.GrantStarter(userId: number)
	local bag = ensureBag(userId)
	InventoryService.MigrateLegacyItems(userId)

	local have: { [string]: boolean } = {}
	for _, inst in bag do
		if typeof(inst) == "table" and typeof(inst.defId) == "string" then
			have[inst.defId] = true
		end
	end

	-- Minimal off-hand options for stance tests
	local offhandStarter = { "o_kite", "o_quiver", "o_knot" }
	for _, defId in offhandStarter do
		if not have[defId] then
			InventoryService.AddItem(userId, defId)
			have[defId] = true
		end
	end

	-- Steel tank armor set (playtest default)
	local armorSet = {
		"a_head_steel",
		"a_chest_steel",
		"a_hands_steel",
		"a_feets_steel",
	}
	for _, defId in armorSet do
		if not have[defId] then
			InventoryService.AddItem(userId, defId)
			have[defId] = true
		end
	end

	-- One ready Sword frame for combat (no loose part spam — meshes come from Studio placeholders)
	local hasCompleteFrame = false
	for _, inst in ensureBag(userId) do
		if inst.defId == "weapon_frame" and inst.parts and inst.parts.handle and inst.parts.blade and inst.parts.pommel then
			hasCompleteFrame = true
			break
		end
	end
	if not hasCompleteFrame then
		InventoryService.CreateAssembledFrame(userId, "h_1h_sword", "b_sword_st", "p_balanced", "gem_steel")
	end

	-- Loose forge kit so players can Attach → Forge a second weapon (scepter playtest)
	local forgeKit = { "h_1h_wandscepter", "b_scepter_st", "p_balanced" }
	for _, defId in forgeKit do
		if not have[defId] then
			InventoryService.AddItem(userId, defId)
			have[defId] = true
		end
	end
end

return InventoryService
