class_name CraftingManager
extends Node

## Handles crafting and deconstruction logic

signal craft_started(recipe: CtsRecipe)
signal craft_success(recipe: CtsRecipe, result: ItemInstance)
signal craft_failed(recipe: CtsRecipe, reason: String)
signal deconstruct_success(original_item: ItemInstance, yielded_materials: Array[ItemInstance])

## Attempt to craft a recipe using items from the given inventory
func craft(recipe: CtsRecipe, inventory: InventoryManager) -> bool:
	if not recipe or not inventory:
		craft_failed.emit(recipe, "Invalid parameters")
		return false
		
	# 1. Check requirements
	var summary = inventory.get_inventory_summary()
	if not recipe.can_craft(summary):
		craft_failed.emit(recipe, "Insufficient materials")
		return false
		
	craft_started.emit(recipe)
	
	# 2. Consume ingredients
	for ingredient in recipe.ingredients:
		if not inventory.remove_item(ingredient.item, ingredient.amount):
			# This shouldn't happen if can_craft passed, but safety first
			craft_failed.emit(recipe, "Critical error removing items")
			return false
			
	# 3. Create result
	var result_instance = ItemInstance.new(recipe.result_item, recipe.amount)
	
	# 4. Add to inventory
	if not inventory.add_item(result_instance):
		# Inventory full? Drop it? For now, fail but materials are gone (classic RPG punishment? or refund?)
		# Let's try to refund
		for ingredient in recipe.ingredients:
			var refund = ItemInstance.new(ingredient.item, ingredient.amount)
			inventory.add_item(refund)
		craft_failed.emit(recipe, "Inventory full")
		return false
		
	craft_success.emit(recipe, result_instance)
	return true

## Deconstruct an item into its base materials
func deconstruct(item: ItemInstance, inventory: InventoryManager) -> bool:
	if not item or not item.definition:
		return false
		
	var yields = item.definition.deconstruction_yield
	if yields.is_empty():
		return false # Cannot be deconstructed
		
	# 1. Remove the item
	# We assume the item passed is the one in the inventory. 
	# If it's a reference, we need to find it.
	# For simplicity, we assume the UI calls this then removes the item, 
	# OR we ask the inventory to remove this specific instance.
	# Let's try to remove 1 of this type.
	if not inventory.remove_item(item.definition, 1):
		return false
		
	# 2. Grant materials
	var yielded_instances: Array[ItemInstance] = []
	for ingredient in yields:
		var mat_instance = ItemInstance.new(ingredient.item, ingredient.amount)
		inventory.add_item(mat_instance) # What if full? Drop?
		yielded_instances.append(mat_instance)
		
	deconstruct_success.emit(item, yielded_instances)
	return true
