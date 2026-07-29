local LoadoutSlots = {
	Order = { "main", "off", "head", "chest", "hands", "feets" } :: { string },

	Labels = {
		main = "Main Hand",
		off = "Off Hand",
		head = "Head",
		chest = "Chest",
		hands = "Hands",
		feets = "Boots",
	} :: { [string]: string },

	--- Dual-wield off-hand: complete 1H modular frames only (Weapon1H / Wand / Scepter).
	OneHandWeaponKinds = {
		Weapon1H = true,
		Wand = true,
		Scepter = true,
	} :: { [string]: boolean },
}

function LoadoutSlots.IsOneHandWeaponKind(kind: string?): boolean
	return kind ~= nil and LoadoutSlots.OneHandWeaponKinds[kind] == true
end

return LoadoutSlots
