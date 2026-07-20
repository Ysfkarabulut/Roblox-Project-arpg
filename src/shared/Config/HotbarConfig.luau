-- GDD §13 — hotbar tuşları (max 6 aktif = loadout tavanı).

export type HotbarSlotIndex = number -- 1..6

local HotbarConfig = {
	SlotCount = 6,

	-- index → KeyCode name (client UserInputService)
	Keys = {
		[1] = Enum.KeyCode.Q,
		[2] = Enum.KeyCode.E,
		[3] = Enum.KeyCode.R,
		[4] = Enum.KeyCode.One,
		[5] = Enum.KeyCode.Two,
		[6] = Enum.KeyCode.Three,
	} :: { [number]: Enum.KeyCode },

	Labels = {
		[1] = "Q",
		[2] = "E",
		[3] = "R",
		[4] = "1",
		[5] = "2",
		[6] = "3",
	} :: { [number]: string },
}

function HotbarConfig.IsValidSlot(index: number): boolean
	return index >= 1 and index <= HotbarConfig.SlotCount
end

return HotbarConfig
