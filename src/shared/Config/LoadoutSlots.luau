local LoadoutSlots = {
	Order = { "main", "off", "head", "chest", "hands", "feets" } :: { string },

	Labels = {
		main = "Main Hand",
		off = "Off Hand",
		head = "Head",
		chest = "Chest",
		hands = "Hand",
		feets = "Feets",
	} :: { [string]: string },
}

return LoadoutSlots
