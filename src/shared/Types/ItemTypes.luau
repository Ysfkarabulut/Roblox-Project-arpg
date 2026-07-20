-- Eşya instance: her kopya ayrı UUID (aynı defId birden fazla olabilir).

export type SlotId = "main" | "off" | "head" | "chest" | "hands" | "feets"

export type ItemKind =
	"Weapon1H"
	| "Weapon2H"
	| "Bow"
	| "Crossbow"
	| "Staff"
	| "Wand"
	| "Scepter"
	| "Shield"
	| "Quiver"
	| "Knot"
	| "Focus"
	| "Head"
	| "Chest"
	| "Hands"
	| "Feets"

export type ElementTag =
	"Fire"
	| "Water"
	| "Lightning"
	| "Wind"
	| "Poison"
	| "Steel"
	| "Rock"
	| "Neutral"
	| nil

export type AbilitySlot = {
	id: string,
	name: string,
	slotType: "Active" | "Passive",
	cooldownSec: number?, -- Active; stam her zaman 0
	desc: string,
}

export type ItemDef = {
	id: string,
	name: string,
	kind: ItemKind,
	family: string?, -- Sword, Axe, Dagger, ...
	slotHints: { SlotId },
	element: ElementTag,
	scaling: ("STR" | "DEX" | "INT")?,
	asTier: string?,
	baseDamage: number?,
	defence: number?,
	resist: number?,
	requires: { [string]: number }?,
	familyPerk: string?,
	onHitAffix: string?, -- nil = yok
	rarity: ("Common" | "Rare" | "BossExclusive")?,
	abilities: { AbilitySlot }?,
	desc: string?,
}

export type ItemInstance = {
	uuid: string,
	defId: string,
}

export type LoadoutMap = {
	main: string?,
	off: string?,
	head: string?,
	chest: string?,
	hands: string?,
	feets: string?,
}

export type InventorySnapshot = {
	items: { ItemInstance },
	loadout: LoadoutMap,
}

return {}
