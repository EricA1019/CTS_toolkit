extends Node
class_name CraftingSystem

const ItemInstance = preload("res://addons/cts_items/Data/item_instance.gd")

var _crafting_containers: Dictionary = {}
var _inventory_containers: Dictionary = {}
var _registry: Node = null

func _ready() -> void:
	_registry = Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if _registry:
		_registry.connect("crafting_container_registered", Callable(self, "_on_crafting_registered"))
		_registry.connect("crafting_container_unregistered", Callable(self, "_on_crafting_unregistered"))
		_registry.connect("inventory_container_registered", Callable(self, "_on_inventory_registered"))
		_registry.connect("inventory_container_unregistered", Callable(self, "_on_inventory_unregistered"))
		_registry.connect("craft_requested", Callable(self, "_on_craft_requested"))

func _on_crafting_registered(entity_id: String, container: Node) -> void:
	_crafting_containers[entity_id] = container

func _on_crafting_unregistered(entity_id: String) -> void:
	_crafting_containers.erase(entity_id)

func _on_inventory_registered(entity_id: String, container: Node) -> void:
	_inventory_containers[entity_id] = container

func _on_inventory_unregistered(entity_id: String) -> void:
	_inventory_containers.erase(entity_id)

func _on_craft_requested(entity_id: String, recipe_id: String) -> void:
	var craft_cont = _crafting_containers.get(entity_id, null)
	if craft_cont == null:
		_emit_craft_failed(entity_id, recipe_id, "no_crafting_container")
		return
	var recipe = craft_cont.recipe_book.get_recipe(recipe_id) if craft_cont.recipe_book else null
	if recipe == null:
		_emit_craft_failed(entity_id, recipe_id, "unknown_recipe")
		return
	var inv = _inventory_containers.get(entity_id, null)
	if inv == null:
		_emit_craft_failed(entity_id, recipe_id, "no_inventory")
		return
	# Validation: check ingredients
	for entry in recipe.ingredients:
		if not entry.has("item_id") or not entry.has("count"):
			continue
		var needed = int(entry["count"])
		var total = 0
		for slot in inv.slots:
			if slot and slot.definition and slot.definition.item_id == entry["item_id"]:
				total += int(slot.amount)
			if total >= needed:
				break
		if total < needed:
			_emit_craft_failed(entity_id, recipe_id, "insufficient_materials")
			return
	# Execution: remove ingredients and grant outputs
	_emit_craft_started(entity_id, recipe)
	for entry in recipe.ingredients:
		if not entry.has("item_id") or not entry.has("count"):
			continue
		_registry.emit_signal("item_remove_requested", entity_id, entry["item_id"], int(entry["count"]))
	# Grant outputs
	for entry in recipe.outputs:
		if not entry.has("item_id") or not entry.has("count"):
			continue
		var item := ItemInstance.new()
		# Try to set amount / instance id; definition lookup is TODO (ItemFactory)
		item.amount = int(entry["count"])
		item.instance_id = str(ResourceUID.create_id())
		_registry.emit_signal("item_add_requested", entity_id, item)
	_emit_craft_completed(entity_id, recipe, null)

func _emit_craft_started(entity_id: String, recipe):
	if _registry:
		_registry.emit_signal("craft_started", entity_id, recipe)

func _emit_craft_completed(entity_id: String, recipe, result):
	if _registry:
		_registry.emit_signal("craft_completed", entity_id, recipe, result)

func _emit_craft_failed(entity_id: String, recipe_id: String, reason: String) -> void:
	if _registry:
		_registry.emit_signal("craft_failed", entity_id, recipe_id, reason)
