@tool
class_name ItemSlot
extends TextureRect

## Inventory slot component with drag-drop support
## Displays item icon, quantity, and rarity border

signal slot_clicked(index: int, button: int)
signal slot_hovered(index: int)
signal slot_unhovered(index: int)
signal slot_context_requested(index: int, position: Vector2)

@export var slot_index: int = -1
@export var show_background: bool = true

var _item_instance: Resource # ItemInstance
var _quantity_label: Label
var _border: ReferenceRect

func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	_build_ui()
	
	mouse_entered.connect(func(): slot_hovered.emit(slot_index))
	mouse_exited.connect(func(): slot_unhovered.emit(slot_index))

func _build_ui() -> void:
	if not _border:
		_border = ReferenceRect.new()
		_border.name = "Border"
		_border.anchors_preset = Control.PRESET_FULL_RECT
		_border.border_width = 2.0
		_border.editor_only = false
		_border.visible = false
		add_child(_border)
		
	if not _quantity_label:
		_quantity_label = Label.new()
		_quantity_label.name = "Quantity"
		_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_quantity_label.anchors_preset = Control.PRESET_FULL_RECT
		_quantity_label.add_theme_font_size_override("font_size", 10)
		add_child(_quantity_label)

func set_item(item: Resource) -> void:
	_item_instance = item
	if not item:
		texture = null
		_quantity_label.text = ""
		_border.visible = false
		tooltip_text = ""
		return
		
	# Assuming ItemInstance has 'item_data' property with 'icon'
	# and 'quantity' property
	var data = item.get("item_data")
	if data and data.get("icon"):
		texture = data.get("icon")
	
	var qty = item.get("quantity")
	if qty > 1:
		_quantity_label.text = str(qty)
	else:
		_quantity_label.text = ""
		
	# Rarity border logic here if needed
	_border.visible = true
	_border.border_color = Color.WHITE # Default

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			slot_context_requested.emit(slot_index, get_global_mouse_position())
		else:
			slot_clicked.emit(slot_index, event.button_index)

# Drag & Drop Implementation
func _get_drag_data(_at_position: Vector2) -> Variant:
	if not _item_instance:
		return null
		
	var payload = DragPayload.new(get_parent(), slot_index, _item_instance, _item_instance.get("quantity"))
	DragDropManager.start_drag(payload)
	
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	set_drag_preview(preview)
	
	return payload

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is DragPayload and data.is_valid()

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is DragPayload:
		DragDropManager.complete_drop(self)
