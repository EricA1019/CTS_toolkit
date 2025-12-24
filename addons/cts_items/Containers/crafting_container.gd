extends Node
class_name CraftingContainer

const RecipeBook = preload("res://addons/cts_items/Data/recipe_book.gd")
const RecipeData = preload("res://addons/cts_items/Data/recipe_data.gd")
const StackOperations = preload("res://addons/cts_items/Core/stack_operations.gd")

@export var recipe_book: RecipeBook

func can_craft(recipe_id: String) -> bool:
	var recipe := _get_recipe(recipe_id)
	if recipe == null:
		return false
	var inv: InventoryContainer = _get_inventory()
	if inv == null:
		return false
	return _ingredients_available(inv, recipe)

func craft(recipe_id: String) -> bool:
	var recipe := _get_recipe(recipe_id)
	if recipe == null:
		return false
	var inv: InventoryContainer = _get_inventory()
	if inv == null:
		return false
	if not _ingredients_available(inv, recipe):
		return false
	_consume_ingredients(inv, recipe)
	_emit_craft_started(recipe)
	_grant_outputs(inv, recipe)
	_emit_craft_completed(recipe)
	return true

func _get_recipe(recipe_id: String) -> RecipeData:
	return recipe_book.get_recipe(recipe_id) if recipe_book else null

func _ingredients_available(inv, recipe: RecipeData) -> bool:
	for entry in recipe.ingredients:
		if not entry.has("item_id") or not entry.has("count"):
			continue
		if not _has_item(inv, entry["item_id"], int(entry["count"])):
			return false
	return true

func _consume_ingredients(inv, recipe: RecipeData) -> void:
	for entry in recipe.ingredients:
		if not entry.has("item_id") or not entry.has("count"):
			continue
		_remove_items(inv, entry["item_id"], int(entry["count"]))

func _grant_outputs(inv, recipe: RecipeData) -> void:
	for entry in recipe.outputs:
		if not entry.has("item_id") or not entry.has("count"):
			continue
		# TODO: hook into ItemFactory once implemented
		var item := preload("res://addons/cts_items/Data/item_instance.gd").new()
		item.stack_size = int(entry["count"])
		item.ensure_instance_id()
		inv.add_item(item)

func _has_item(inv, item_id: String, count: int) -> bool:
	var total := 0
	for item in inv.get_items():
		if item and item.item_data and item.item_data.item_id == item_id:
			total += item.stack_size
		if total >= count:
			return true
	return false

func _remove_items(inv, item_id: String, count: int) -> void:
	var remaining := count
	for item in inv.get_items():
		if remaining <= 0:
			break
		if item and item.item_data and item.item_data.item_id == item_id:
			var take := min(item.stack_size, remaining)
			item.stack_size -= take
			remaining -= take
			if item.stack_size <= 0:
				inv.remove_item(item)

func _get_inventory():
	var parent := get_parent()
	if parent and parent.has_method("get_container"):
		return parent.get_container("InventoryContainer")
	return null

func _emit_craft_started(recipe: RecipeData) -> void:
	var bus := _signal_bus()
	if bus:
		bus.emit_signal("craft_started", _resolve_entity_id(), recipe)

func _emit_craft_completed(recipe: RecipeData) -> void:
	var bus := _signal_bus()
	if bus:
		bus.emit_signal("craft_completed", _resolve_entity_id(), recipe)

func _signal_bus() -> Node:
	return Engine.get_singleton("CTS_Items") if Engine.has_singleton("CTS_Items") else null

func _resolve_entity_id() -> String:
	var parent := get_parent()
	if parent and parent.has_method("get_entity_id"):
		return parent.get_entity_id()
	return name
