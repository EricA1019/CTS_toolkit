@tool
class_name InventoryGrid
extends GridContainer

## Grid-based inventory display
## Binds to an InventoryContainer and manages ItemSlots

signal slot_clicked(index: int, item: Resource, button: int)
signal slot_context_requested(index: int, item: Resource, position: Vector2)

@export var columns_count: int = 5:
	set(value):
		columns_count = value
		columns = value

var _inventory_container: Node # InventoryContainer
var _binding: ReactiveBinding
var _slots: Array[ItemSlot] = []

func _ready() -> void:
	columns = columns_count
	_binding = ReactiveBinding.new(self)

func bind_to_inventory(inventory: Node) -> void:
	_inventory_container = inventory
	if not _inventory_container:
		_clear_slots()
		return
		
	_rebuild_grid()
	
	if Engine.has_singleton("CTS_Items"):
		var bus = Engine.get_singleton("CTS_Items")
		_binding.bind_signal(bus, "item_added", _on_item_added)
		_binding.bind_signal(bus, "item_removed", _on_item_removed)

func _clear_slots() -> void:
	for child in get_children():
		child.queue_free()
	_slots.clear()

func _rebuild_grid() -> void:
	_clear_slots()
	
	if not _inventory_container:
		return
		
	var items = _inventory_container.get_items() # Array[ItemInstance]
	if not items:
		return
		
	for i in range(items.size()):
		var item = items[i]
		var slot = ItemSlot.new()
		slot.slot_index = i
		slot.set_item(item)
		
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_context_requested.connect(_on_slot_context_requested)
		
		add_child(slot)
		_slots.append(slot)

func _on_item_added(inv_id: String, _item: Resource) -> void:
	_check_update(inv_id)

func _on_item_removed(inv_id: String, _item: Resource) -> void:
	_check_update(inv_id)

func _check_update(inv_id: String) -> void:
	if not _inventory_container: return
	
	# Try to match ID
	var my_id = _inventory_container.inventory_id
	if my_id.is_empty() and _inventory_container.has_method("_resolve_inventory_id"):
		my_id = _inventory_container.call("_resolve_inventory_id")
		
	if inv_id == my_id:
		_rebuild_grid()

func _on_slot_clicked(index: int, button: int) -> void:
	var item = _get_item_at(index)
	slot_clicked.emit(index, item, button)

func _on_slot_context_requested(index: int, pos: Vector2) -> void:
	var item = _get_item_at(index)
	if item:
		slot_context_requested.emit(index, item, pos)

func _get_item_at(index: int) -> Resource:
	if _inventory_container:
		var items = _inventory_container.get_items()
		if items and index >= 0 and index < items.size():
			return items[index]
	return null
