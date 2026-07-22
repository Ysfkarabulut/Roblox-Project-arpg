--[[
	Map legacy monolithic w_{family}_{element} → modular part def ids.
]]

local ElementData = require(script.Parent.ElementData)
local BladeDefs = require(script.Parent.BladeDefs)
local PommelDefs = require(script.Parent.PommelDefs)

local LegacyWeaponConverter = {}

local FAMILY_TO_HANDLE = {
	dagger = "1H_Sword",
	sword_1h = "1H_Sword",
	axe_1h = "1H_AxeMace",
	mace_1h = "1H_AxeMace",
	wand = "1H_WandScepter",
	scepter = "1H_WandScepter",
	sword_2h = "2H_Sword",
	axe_2h = "2H_AxeMace",
	mace_2h = "2H_AxeMace",
	staff = "2H_Staff",
	bow = "2H_Bow",
	crossbow = "2H_Crossbow",
}

local HANDLE_ID = {
	["1H_Sword"] = "h_1h_sword",
	["1H_AxeMace"] = "h_1h_axemace",
	["1H_WandScepter"] = "h_1h_wandscepter",
	["2H_Sword"] = "h_2h_sword",
	["2H_AxeMace"] = "h_2h_axemace",
	["2H_Staff"] = "h_2h_staff",
	["2H_Bow"] = "h_2h_bow",
	["2H_Crossbow"] = "h_2h_crossbow",
}

function LegacyWeaponConverter.IsLegacyWeaponId(defId: string): boolean
	return string.sub(defId, 1, 2) == "w_" and not string.find(defId, "_frame", 1, true)
end

function LegacyWeaponConverter.ParseLegacyId(defId: string): (string?, string?)
	-- w_{familyKey}_{elementLower}
	local rest = string.sub(defId, 3)
	local lastUnderscore = nil
	for i = #rest, 1, -1 do
		if string.sub(rest, i, i) == "_" then
			lastUnderscore = i
			break
		end
	end
	if not lastUnderscore then
		return nil, nil
	end
	local familyKey = string.sub(rest, 1, lastUnderscore - 1)
	local elLower = string.sub(rest, lastUnderscore + 1)
	local element = nil
	for _, el in ElementData.List do
		if ElementData.Lower[el] == elLower then
			element = el
			break
		end
	end
	return familyKey, element
end

function LegacyWeaponConverter.ResolveParts(defId: string): { handleId: string, bladeId: string, pommelId: string, gemId: string }?
	local familyKey, element = LegacyWeaponConverter.ParseLegacyId(defId)
	if not familyKey or not element then
		return nil
	end
	local handleType = FAMILY_TO_HANDLE[familyKey]
	if not handleType then
		return nil
	end
	local handleId = HANDLE_ID[handleType]
	local bladeId = BladeDefs.ForLegacyFamily(familyKey)
	local pommelId = PommelDefs.BalancedFor(handleType)
	local gemId = `gem_{ElementData.Lower[element]}`
	if not handleId or not bladeId then
		return nil
	end
	return {
		handleId = handleId,
		bladeId = bladeId,
		pommelId = pommelId,
		gemId = gemId,
	}
end

return LegacyWeaponConverter
