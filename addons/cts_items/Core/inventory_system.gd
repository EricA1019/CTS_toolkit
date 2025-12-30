extends Node
class_name InventorySystem

const StackOperations = preload("res://addons/cts_items/Core/stack_operations.gd")

var _inventories: Dictionary = {}
var _registry: Node = null

func _ready() -> void:
	_registry = Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if _registry:
		_registry.connect("inventory_container_registered", Callable(self, "_on_inventory_registered"))
		_registry.connect("inventory_container_unregistered", Callable(self, "_on_inventory_unregistered"))
		_registry.connect("item_add_requested", Callable(self, "_on_item_add_requested"))
		_registry.connect("item_place_requested", Callable(self, "_on_item_place_requested"))
		_registry.connect("item_remove_requested", Callable(self, "_on_item_remove_requested"))

func _on_inventory_registered(entity_id: String, container: Node) -> void:
	_inventories[entity_id] = container

func _on_inventory_unregistered(entity_id: String) -> void:
	_inventories.erase(entity_id)

func _on_item_add_requested(entity_id: String, item) -> void:
	var container = _inventories.get(entity_id, null)
	if container == null:
		return
	if not container.has("slots"):
		# fallback to old-style _items
		if container.has_method("add_item"):
			if container.add_item(item):
				_emit_item_added(entity_id, item, -1)
			return
	var slot_idx = StackOperations.add_item_to_slots(container.slots, item)
	if slot_idx >= 0:
		_emit_item_added(entity_id, item, slot_idx)

func _on_item_place_requested(entity_id: String, slot_index: int, item) -> void:
	var container = _inventories.get(entity_id, null)
	if container == null:
		return
	if not container.has("slots"):
		return
	if StackOperations.place_at_slot(container.slots, slot_index, item):
		_emit_item_added(entity_id, item, slot_index)

func _on_item_remove_requested(entity_id: String, item_id: String, amount: int) -> void:
	var container = _inventories.get(entity_id, null)
	if container == null:
		return
	# operate on container.slots if present, else fallback
	if not container.has("slots"):
		if container.has_method("remove_item"):
			# Attempt best-effort: remove item instances by searching
			# This is legacy fallback - not atomic
			# No guarantee on slot index
			# Notifying via registry is responsibility of manager
			return
	# Remove across slots
	var remaining := amount
	for i in range(container.slots.size()):
		if remaining <= 0:
			break
		var slot = container.slots[i]
		if slot and slot.definition and slot.definition.item_id == item_id:
			var take = min(remaining, int(slot.amount))
			slot.amount -= take
			remaining -= take
			if slot.amount <= 0:
				# clear slot
				container.slots[i] = null
				_emit_item_removed(entity_id, slot, i)
			else:
				_emit_item_changed(entity_id, slot, i)

func _emit_item_added(entity_id: String, item, slot_index: int) -> void:
	if _registry:
		_registry.emit_signal("item_added", entity_id, item, slot_index)

func _emit_item_removed(entity_id: String, item, slot_index: int) -> void:
	if _registry:
		_registry.emit_signal("item_removed", entity_id, item, slot_index)

func _emit_item_changed(entity_id: String, item, slot_index: int) -> void:
	if _registry:
		_registry.emit_signal("item_changed", entity_id, item, slot_index)
