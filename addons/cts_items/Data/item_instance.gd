class_name ItemInstance
extends Resource

## The static definition of this item
@export var definition: CtsItemDefinition

## Current stack size
@export_range(1, 9999) var amount: int = 1

## Unique ID for this specific instance (for tracking unique items)
@export var instance_id: String = ""

## Current durability (if applicable)
@export var durability: float = 100.0

## Attached affixes
@export var attached_affixes: Array[AffixInstance] = []

## Properties overridden by affixes or gameplay
@export var overridden_properties: Dictionary = {}

func _init(p_definition: CtsItemDefinition = null, p_amount: int = 1):
	definition = p_definition
	amount = p_amount
	if definition:
		instance_id = str(ResourceUID.create_id()) # Simple unique ID generation

func get_display_name() -> String:
	if definition:
		return definition.display_name
	return "Unknown Item"

func get_rarity_color() -> Color:
	if definition:
		return definition.get_rarity_color()
	return Color.WHITE
