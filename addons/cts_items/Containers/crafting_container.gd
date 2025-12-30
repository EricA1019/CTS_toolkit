extends Node
class_name CraftingContainer

const RecipeBook = preload("res://addons/cts_items/Data/recipe_book.gd")

@export var recipe_book: RecipeBook
@export var entity_id: String = ""

func _ready() -> void:
	var bus := Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if bus:
		bus.emit_signal("crafting_container_registered", _resolve_entity_id(), self)

func _exit_tree() -> void:
	var bus := Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if bus:
		bus.emit_signal("crafting_container_unregistered", _resolve_entity_id())

func _get_recipe(recipe_id: String):
	return recipe_book.get_recipe(recipe_id) if recipe_book else null

func _resolve_entity_id() -> String:
	if not entity_id.is_empty():
		return entity_id
	var parent := get_parent()
	if parent and parent.has_method("get_entity_id"):
		return parent.get_entity_id()
	return name
