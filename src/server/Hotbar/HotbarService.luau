--[[
	HotbarService — aktif yetenek bağları (abilityId → slot 1..6).
	Pasifler burada yok. Bind'ler oturum içi; DataStore sonra.
]]

local Players = game:GetService("Players")

local HotbarConfig = require(game.ReplicatedStorage.Shared.Config.HotbarConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local LoadoutSlots = require(game.ReplicatedStorage.Shared.Config.LoadoutSlots)

export type HotbarBinds = { [number]: string? } -- slot → abilityId

local HotbarService = {}

local bindsByUser: { [number]: HotbarBinds } = {}

local function emptyBinds(): HotbarBinds
	local b: HotbarBinds = {}
	for i = 1, HotbarConfig.SlotCount do
		b[i] = nil
	end
	return b
end

local function ensure(userId: number): HotbarBinds
	if not bindsByUser[userId] then
		bindsByUser[userId] = emptyBinds()
	end
	return bindsByUser[userId]
end

-- Loadout'taki tüm Active ability id'leri (kaynak item uuid ile)
function HotbarService.GetAvailableActives(userId: number): { { abilityId: string, name: string, desc: string, sourceUuid: string, defId: string } }
	local out = {}
	local loadout = LoadoutService.Get(userId)
	for _, slotId in LoadoutSlots.Order do
		local uuid = (loadout :: any)[slotId] :: string?
		if uuid then
			local inst = InventoryService.Find(userId, uuid)
			local def = inst and ItemDefs.Get(inst.defId)
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
	end
	return out
end

local function isAvailable(userId: number, abilityId: string): boolean
	for _, a in HotbarService.GetAvailableActives(userId) do
		if a.abilityId == abilityId then
			return true
		end
	end
	return false
end

function HotbarService.GetBinds(userId: number): HotbarBinds
	local b = ensure(userId)
	local copy: HotbarBinds = {}
	for i = 1, HotbarConfig.SlotCount do
		copy[i] = b[i]
	end
	return copy
end

-- Loadout değişince geçersiz bind'leri temizle
function HotbarService.Prune(userId: number)
	local b = ensure(userId)
	for i = 1, HotbarConfig.SlotCount do
		local id = b[i]
		if id and not isAvailable(userId, id) then
			b[i] = nil
		end
	end
end

function HotbarService.Bind(userId: number, abilityId: string, slotIndex: number): (boolean, string?)
	if not HotbarConfig.IsValidSlot(slotIndex) then
		return false, "BadSlot"
	end
	if not isAvailable(userId, abilityId) then
		return false, "NotAvailable"
	end
	local b = ensure(userId)
	-- Aynı ability başka slottan düşsün
	for i = 1, HotbarConfig.SlotCount do
		if b[i] == abilityId then
			b[i] = nil
		end
	end
	b[slotIndex] = abilityId
	return true, nil
end

function HotbarService.Unbind(userId: number, slotIndex: number): (boolean, string?)
	if not HotbarConfig.IsValidSlot(slotIndex) then
		return false, "BadSlot"
	end
	ensure(userId)[slotIndex] = nil
	return true, nil
end

--- Boş hotbar slotlarına loadout Actives'i sırayla doldur (proto QoL)
function HotbarService.AutoFill(userId: number): number
	HotbarService.Prune(userId)
	local b = ensure(userId)
	local filled = 0
	local used: { [string]: boolean } = {}
	for i = 1, HotbarConfig.SlotCount do
		if b[i] then
			used[b[i] :: string] = true
		end
	end
	for _, a in HotbarService.GetAvailableActives(userId) do
		if not used[a.abilityId] then
			for i = 1, HotbarConfig.SlotCount do
				if b[i] == nil then
					b[i] = a.abilityId
					used[a.abilityId] = true
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

Players.PlayerRemoving:Connect(function(player)
	bindsByUser[player.UserId] = nil
end)

return HotbarService
