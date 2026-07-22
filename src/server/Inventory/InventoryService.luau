--[[
	InventoryService — UUID instance bag with modular weapon state.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

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
	local bag = ensureBag(userId)
	local toConvert: { { index: number, defId: string } } = {}
	for i, item in bag do
		if LegacyWeaponConverter.IsLegacyWeaponId(item.defId) then
			table.insert(toConvert, { index = i, defId = item.defId })
		end
	end
	-- Reverse order so indices stay valid
	for i = #toConvert, 1, -1 do
		local entry = toConvert[i]
		local frame = InventoryService.ConvertLegacyWeapon(userId, entry.defId)
		if frame then
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

	if not have["weapon_frame"] then
		InventoryService.AddItem(userId, "weapon_frame")
		have["weapon_frame"] = true
	end

	local offhandStarter = {
		"o_kite",
		"o_buckler",
		"o_tower",
		"o_round",
		"o_spiked",
		"o_quiver",
		"o_knot",
	}
	for _, defId in offhandStarter do
		if not have[defId] then
			InventoryService.AddItem(userId, defId)
			have[defId] = true
		end
	end

	local looseParts = {
		"h_1h_sword",
		"h_1h_axemace",
		"h_1h_wandscepter",
		"h_2h_sword",
		"h_2h_axemace",
		"h_2h_staff",
		"h_2h_bow",
		"h_2h_crossbow",
		"p_heavy",
		"p_balanced",
		"p_lightweight",
		"p_string_heavy",
		"p_string_balanced",
		"p_string_lightweight",
		"gem_fire",
		"gem_water",
		"gem_lightning",
		"gem_rock",
		"gem_wind",
		"gem_steel",
		"gem_poison",
		"gem_neutral",
		-- ST common blade per family (assembly testing)
		"b_dagger_st",
		"b_sword_st",
		"b_axe_st",
		"b_mace_st",
		"b_wand_st",
		"b_scepter_st",
		"b_greatblade_st",
		"b_greataxe_st",
		"b_greathammer_st",
		"b_staff_st",
		"b_bow_st",
		"b_crossbow_st",
	}
	for _, defId in looseParts do
		if not have[defId] then
			InventoryService.AddItem(userId, defId)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	bags[player.UserId] = nil
end)

Players.PlayerAdded:Connect(function(player)
	InventoryService.GrantStarter(player.UserId)
end)

for _, player in Players:GetPlayers() do
	InventoryService.GrantStarter(player.UserId)
end

return InventoryService
