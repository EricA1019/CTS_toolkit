extends Node
class_name EquipmentSystem

var _equipment_containers: Dictionary = {}
var _registry: Node = null

func _ready() -> void:
	_registry = Engine.get_singleton("ItemsSignalRegistry") if Engine.has_singleton("ItemsSignalRegistry") else null
	if _registry:
		_registry.connect("equipment_container_registered", Callable(self, "_on_equipment_registered"))
		_registry.connect("equipment_container_unregistered", Callable(self, "_on_equipment_unregistered"))
		_registry.connect("item_equip_requested", Callable(self, "_on_item_equip_requested"))
		_registry.connect("item_unequip_requested", Callable(self, "_on_item_unequip_requested"))

func _on_equipment_registered(entity_id: String, container: Node) -> void:
	_equipment_containers[entity_id] = container

func _on_equipment_unregistered(entity_id: String) -> void:
	_equipment_containers.erase(entity_id)

func _on_item_equip_requested(entity_id: String, slot: int, item) -> void:
	var container = _equipment_containers.get(entity_id, null)
	if container == null:
		return
	# Validate slot allowed if block provided
	if container.has("equipment_block") and container.equipment_block:
		if container.equipment_block.available_slots.size() > 0 and not slot in container.equipment_block.available_slots:
			# invalid slot
			if _registry:
				_registry.emit_signal("item_equip_failed", entity_id, slot, item, "invalid_slot")
			return
	var previous = null
	if container.equipped.has(slot):
		previous = container.equipped[slot]
	container.equipped[slot] = item
	if _registry:
		_registry.emit_signal("item_equipped", entity_id, slot, item, previous)

func _on_item_unequip_requested(entity_id: String, slot: int) -> void:
	var container = _equipment_containers.get(entity_id, null)
	if container == null:
		return
	if not container.equipped.has(slot):
		return
	var item = container.equipped[slot]
	container.equipped.erase(slot)
	if _registry:
		_registry.emit_signal("item_unequipped", entity_id, slot, item)
