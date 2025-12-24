extends Node
class_name InventoryContainer

const InventoryBlock = preload("res://addons/cts_items/Data/inventory_block.gd")
const ItemInstance = preload("res://addons/cts_items/Data/item_instance.gd")
const StackOperations = preload("res://addons/cts_items/Core/stack_operations.gd")

@export var inventory_block: InventoryBlock
@export var inventory_id: String = ""

var _items: Array[ItemInstance] = []

func _ready() -> void:
	_load_block()

func add_item(item: ItemInstance) -> bool:
	if item == null:
		return false
	item.ensure_instance_id()

	# try merge first
	for existing in _items:
		if StackOperations.merge(existing, item):
			_emit_item_stacked(existing, item)
			if item.stack_size <= 0:
				_emit_item_added(existing)
				return true
	if _is_full():
		return false
	_items.append(item)
	_emit_item_added(item)
	return true

func remove_item(item: ItemInstance) -> bool:
	var idx := _items.find(item)
	if idx == -1:
		return false
	_items.remove_at(idx)
	_emit_item_removed(item)
	return true

func has_item(item: ItemInstance) -> bool:
	return _items.has(item)

func get_items() -> Array[ItemInstance]:
	return _items.duplicate()

func get_item_count() -> int:
	return _items.size()

func _is_full() -> bool:
	if inventory_block and inventory_block.capacity > 0:
		return _items.size() >= inventory_block.capacity
	return false

func _load_block() -> void:
	_items.clear()
	if inventory_block == null:
		return
	for inst in inventory_block.starting_items:
		if inst:
			add_item(inst.duplicate())

func _emit_item_added(item: ItemInstance) -> void:
	var bus := _signal_bus()
	if bus:
		bus.emit_signal("item_added", _resolve_inventory_id(), item)

func _emit_item_removed(item: ItemInstance) -> void:
	var bus := _signal_bus()
	if bus:
		bus.emit_signal("item_removed", _resolve_inventory_id(), item)

func _emit_item_stacked(dst: ItemInstance, src: ItemInstance) -> void:
	var bus := _signal_bus()
	if bus:
		bus.emit_signal("item_stacked", _resolve_inventory_id(), dst, src)

func _signal_bus() -> Node:
	return Engine.get_singleton("CTS_Items") if Engine.has_singleton("CTS_Items") else null

func _resolve_inventory_id() -> String:
	if not inventory_id.is_empty():
		return inventory_id
	var parent := get_parent()
	if parent and parent.has_method("get_entity_id"):
		return "%s_inventory" % parent.get_entity_id()
	return name
