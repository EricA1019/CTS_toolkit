class_name DragPayload
extends Resource

## Data carrier for cross-page drag-drop operations
## Used by DragDropManager and UI components

var source_container: Node
var source_index: int = -1
var item_instance: Resource # ItemInstance
var quantity: int = 1
var visual_data: Dictionary = {} # Icon, size, etc.

func _init(p_source: Node = null, p_index: int = -1, p_item: Resource = null, p_qty: int = 1) -> void:
	source_container = p_source
	source_index = p_index
	item_instance = p_item
	quantity = p_qty

func is_valid() -> bool:
	return source_container != null and item_instance != null
