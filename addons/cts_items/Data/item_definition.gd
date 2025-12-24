class_name CtsItemDefinition
extends Resource

# =============================================================================
# IDENTIFICATION
# =============================================================================

## Unique identifier for this item. Must match filename stem.
@export var item_id: StringName = &""

## Display name shown in UI
@export var display_name: String = ""

## Tooltip description text
@export_multiline var description: String = ""

## Item icon texture for inventory display
@export var image: Texture2D

# =============================================================================
# CLASSIFICATION
# =============================================================================

## Item type classification
@export var item_type: ItemEnums.ItemType = ItemEnums.ItemType.MISC

## Equipment slot (NONE for non-equippable)
@export var slot: ItemEnums.EquipmentSlot = ItemEnums.EquipmentSlot.NONE

## Item Rarity Tier
@export var rarity: ItemEnums.ItemRarity = ItemEnums.ItemRarity.COMMON

# =============================================================================
# STACKING & PHYSICAL
# =============================================================================

## Current stack size (initial quantity)
@export var stack_size: int = 1

## Maximum items per stack
@export var max_stack_size: int = 1

## Weight per unit in inventory
@export var weight: float = 1.0

## Base value in currency
@export var value: int = 0

# =============================================================================
# CRAFTING & DECONSTRUCTION
# =============================================================================

## Materials yielded when this item is deconstructed
@export var deconstruction_yield: Array[Ingredient] = []

## Number of affix slots available on this item
@export var affix_slots: int = 0

# =============================================================================
# HELPERS
# =============================================================================

func get_rarity_color() -> Color:
	return ItemEnums.get_rarity_color(rarity)

func is_stackable() -> bool:
	return max_stack_size > 1
