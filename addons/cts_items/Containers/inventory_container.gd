extends Node
class_name InventoryContainer

const InventoryBlock = preload("res://addons/cts_items/Data/inventory_block.gd")
const ItemInstance = preload("res://addons/cts_items/Data/item_instance.gd")
const StackOperations = preload("res://addons/cts_items/Core/stack_operations.gd")

@export var inventory_block: InventoryBlock
@export var entity_id: String = ""

var slots: Array = []

func _ready() -> void:
	_init_slots()
	# Register with ItemsSignalRegistry
	var bus := Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if bus:
		bus.emit_signal("inventory_container_registered", _resolve_entity_id(), self)

func _exit_tree() -> void:
	var bus := Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if bus:
		bus.emit_signal("inventory_container_unregistered", _resolve_entity_id())

func _init_slots() -> void:
	slots.clear()
	var capacity := 16
	if inventory_block and inventory_block.capacity > 0:
		capacity = inventory_block.capacity
	slots.resize(capacity)
	slots.fill(null)
	# Populate starting items
	if inventory_block:
		for inst in inventory_block.starting_items:
			if inst:
				var clone = inst.duplicate()
				StackOperations.add_item_to_slots(slots, clone)

func _resolve_entity_id() -> String:
	if not entity_id.is_empty():
		return entity_id
	var parent := get_parent()
	if parent and parent.has_method("get_entity_id"):
		return "%s_inventory" % parent.get_entity_id()
	return name

## Returns all items in the inventory as an array (skips empty slots)
## Used by UI components for data binding
func get_items() -> Array:
	var items: Array = []
	for slot in slots:
		if slot:
			items.append(slot)
	return items
