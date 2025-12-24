class_name ItemEnums
extends RefCounted

## Item Rarity Tiers
enum ItemRarity {
	TRASH,      ## Tier 0: Complete trash
	COMMON,     ## Tier 1: Standard items
	UNCOMMON,   ## Tier 2: Slightly better
	RARE,       ## Tier 3: Hard to find
	LEGENDARY,  ## Tier 4: Powerful gear
	MYTHIC,     ## Tier 5: Very powerful
	RELIC       ## Tier 6: Unique/Special
}

## Item classification type
enum ItemType {
	MISC,       ## Generic item, no special behavior
	GEAR,       ## Equippable item (weapon, armor)
	CONSUMABLE, ## Usable item (potions, food)
	AMMO,       ## Ammunition for ranged weapons
	QUEST,      ## Quest-related item
	KEY,        ## Key item, typically non-removable
	MATERIAL    ## Crafting material
}

## Equipment slot this item can be equipped to
enum EquipmentSlot {
	NONE,        ## Not equippable (bag item)
	HEAD,        ## Hats, helmets
	TORSO,       ## Jackets, armor
	LEFT_ARM,    ## Bracers, watches
	RIGHT_ARM,   ## Bracers, gloves
	HANDS,       ## Gloves
	LEGS,        ## Pants, leg armor
	FEET,        ## Boots, shoes
	WEAPON_MAIN, ## Primary weapon slot
	WEAPON_OFF,  ## Secondary weapon/shield slot
	ACCESSORY    ## Rings, amulets
}

## Rarity Colors for UI
const RARITY_COLORS = {
	ItemRarity.TRASH: Color(0.5, 0.5, 0.5),      # Grey
	ItemRarity.COMMON: Color(1.0, 1.0, 1.0),     # White
	ItemRarity.UNCOMMON: Color(0.2, 1.0, 0.2),   # Green
	ItemRarity.RARE: Color(0.2, 0.2, 1.0),       # Blue
	ItemRarity.LEGENDARY: Color(1.0, 0.6, 0.0),  # Orange
	ItemRarity.MYTHIC: Color(0.8, 0.0, 0.8),     # Purple
	ItemRarity.RELIC: Color(1.0, 0.0, 0.0)       # Red
}

static func get_rarity_color(rarity: ItemRarity) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

static func get_rarity_name(rarity: ItemRarity) -> String:
	return ItemRarity.keys()[rarity].capitalize()
