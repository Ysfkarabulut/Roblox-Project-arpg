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
	| "WeaponHandle"
	| "WeaponBlade"
	| "WeaponPommel"
	| "ElementGem"
	| "WeaponFrame"
	| "LootBox"

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

export type HandleType =
	"1H_Sword"
	| "1H_AxeMace"
	| "1H_WandScepter"
	| "2H_Sword"
	| "2H_AxeMace"
	| "2H_Staff"
	| "2H_Bow"
	| "2H_Crossbow"

export type PommelArchetype = "Heavy" | "Balanced" | "Lightweight"
export type PommelRole = "Pommel" | "String"

export type WeaponPartSlot = "handle" | "blade" | "pommel"

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
	lootBoxPoolId: string?, -- LootBox only
	bossId: string?, -- boss lootbox linkage
	tradeable: boolean?, -- default false except LootBox
	abilities: { AbilitySlot }?,
	desc: string?,
	-- Modular part fields
	handleType: HandleType?,
	subFamily: string?,
	bladeDamageMult: number?,
	archetype: PommelArchetype?,
	pommelRole: PommelRole?,
	damageMult: number?,
	attackSpeedMult: number?,
	socketCount: number?,
	meshKey: string?,
}

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
