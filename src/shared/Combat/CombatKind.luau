--[[
	Inventory kind (WeaponBlade) vs combat kind (Weapon1H, Bow, Staff, …).
]]

local CombatKind = {}

function CombatKind.FromHandleAndFamily(handleType: string?, family: string?): string?
	if not handleType then
		return nil
	end
	if handleType == "2H_Bow" then
		return "Bow"
	end
	if handleType == "2H_Crossbow" then
		return "Crossbow"
	end
	if handleType == "2H_Staff" then
		return "Staff"
	end
	if handleType == "2H_Sword" or handleType == "2H_AxeMace" then
		return "Weapon2H"
	end
	if handleType == "1H_WandScepter" then
		if family == "Scepter" then
			return "Scepter"
		end
		return "Wand"
	end
	if handleType == "1H_Sword" or handleType == "1H_AxeMace" then
		return "Weapon1H"
	end
	return nil
end

--- Prefer explicit combatKind on blade defs; fall back to handle + family.
function CombatKind.Resolve(handleType: string?, family: string?, explicit: string?): string?
	if explicit and explicit ~= "WeaponBlade" and explicit ~= "WeaponHandle" then
		return explicit
	end
	local derived = CombatKind.FromHandleAndFamily(handleType, family)
	if derived then
		return derived
	end
	return explicit
end

return CombatKind
