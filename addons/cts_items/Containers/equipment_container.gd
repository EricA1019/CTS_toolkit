extends Node
class_name EquipmentContainer

const EquipmentBlock = preload("res://addons/cts_items/Data/equipment_block.gd")

@export var equipment_block: EquipmentBlock
@export var entity_id: String = ""

var equipped: Dictionary = {}

func _ready() -> void:
	_load_block()
	var bus := Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if bus:
		bus.emit_signal("equipment_container_registered", _resolve_entity_id(), self)

func _exit_tree() -> void:
	var bus := Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if bus:
		bus.emit_signal("equipment_container_unregistered", _resolve_entity_id())

func _load_block() -> void:
	equipped.clear()
	if equipment_block == null:
		return
	for slot_key in equipment_block.starting_equipment.keys():
		var item = equipment_block.starting_equipment[slot_key]
		if item:
			equipped[int(slot_key)] = item.duplicate()

func _resolve_entity_id() -> String:
	if not entity_id.is_empty():
		return entity_id
	var parent := get_parent()
	if parent and parent.has_method("get_entity_id"):
		return parent.get_entity_id()
	return name
