@tool
class_name EquipmentPage
extends BookPage

## Page displaying equipment slots

var _slots_container: GridContainer
var _equipment_container: Node # EquipmentContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	if get_child_count() > 0: return
	
	_slots_container = GridContainer.new()
	_slots_container.columns = 2
	_slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_slots_container)

func setup(event_bus: Node, data_provider: Node) -> void:
	super.setup(event_bus, data_provider)
	
	if data_provider.has_method("get_equipment_container"):
		_equipment_container = data_provider.get_equipment_container()
		_rebuild_slots()

func _rebuild_slots() -> void:
	for child in _slots_container.get_children():
		child.queue_free()
		
	if not _equipment_container:
		return
		
	var block = _equipment_container.equipment_block
	if not block:
		return
		
	for slot_idx in block.available_slots:
		var slot = ItemSlot.new()
		slot.slot_index = slot_idx
		# Set item if equipped
		var equipped = _equipment_container.get_equipped()
		if equipped.has(slot_idx):
			slot.set_item(equipped[slot_idx])
		else:
			slot.set_item(null)
			
		_slots_container.add_child(slot)
