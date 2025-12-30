extends Node
## ItemsSignalRegistry - Autoload singleton for CTS Items signals
## Access via: ItemsSignalRegistry (autoload name)

# Lifecycle signals
signal inventory_container_registered(entity_id: String, container: Node)
signal inventory_container_unregistered(entity_id: String)
signal equipment_container_registered(entity_id: String, container: Node)
signal equipment_container_unregistered(entity_id: String)
signal crafting_container_registered(entity_id: String, container: Node)
signal crafting_container_unregistered(entity_id: String)

# Inventory operation signals
signal item_add_requested(entity_id: String, item: Node) # Node should be ItemInstance
signal item_place_requested(entity_id: String, slot_index: int, item: Node)
signal item_added(entity_id: String, item: Node, slot_index: int)
signal item_remove_requested(entity_id: String, item_id: String, amount: int)
signal item_removed(entity_id: String, item: Node, slot_index: int)
signal item_stacked(entity_id: String, dst: Node, src: Node)

# Equipment operation signals
signal item_equip_requested(entity_id: String, slot: int, item: Node)
signal item_equipped(entity_id: String, slot: int, item: Node, previous: Node)
signal item_unequip_requested(entity_id: String, slot: int)
signal item_unequipped(entity_id: String, slot: int, item: Node)

# Crafting operation signals
signal craft_requested(entity_id: String, recipe_id: String)
signal craft_started(entity_id: String, recipe: Node)
signal craft_completed(entity_id: String, recipe: Node, result: Node)
signal craft_failed(entity_id: String, recipe_id: String, reason: String)

func _ready() -> void:
	# Simple autoload initializer
	print("ItemsSignalRegistry ready")
