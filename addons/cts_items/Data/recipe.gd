class_name CtsRecipe
extends Resource

## Unique identifier for this recipe
@export var id: StringName

## The item created by this recipe
@export var result_item: CtsItemDefinition

## Amount of result item created
@export var amount: int = 1

## Required ingredients
@export var ingredients: Array[Ingredient] = []

## Required crafting station type (optional string tag)
@export var station_type: String = ""

## Check if an inventory (dictionary of item_id -> amount) has requirements
func can_craft(inventory_items: Dictionary) -> bool:
	for ingredient in ingredients:
		if not ingredient.item:
			continue
			
		var required_id = ingredient.item.item_id
		var required_amount = ingredient.amount
		
		if not inventory_items.has(required_id):
			return false
			
		if inventory_items[required_id] < required_amount:
			return false
			
	return true
