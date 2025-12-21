@tool
extends TooltipControlInterface
## A default implementation of a tooltip control.

@export_group("Base Components")
@export var full_container: Control
@export var text_label: RichTextLabel

@export_group("Lock Progress")
@export var lock_icon: TextureRect
@export var lock_progress_bar: TextureProgressBar

const REQUIRED_MINIMUM_WIDTH: int = 30

var _lock_progress: float = 0.0
var _unlock_progress: float = 0.0


func _ready() -> void:
	if text_label:
		text_label.meta_clicked.connect(_on_label_meta_clicked)
		text_label.gui_input.connect(_on_label_gui_input)


func _on_label_meta_clicked(meta: Variant) -> void:
	if meta is String:
		link_clicked.emit(get_global_mouse_position(), meta)


func _on_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Handle tooltip click
			pass


## Update the lock/unlock progress display.
func _update_locking_display() -> void:
	if not lock_progress_bar or not lock_icon:
		return
	
	var show_lock := _lock_progress > 0.0 or _unlock_progress > 0.0
	lock_progress_bar.visible = show_lock
	lock_icon.visible = show_lock
	
	if _lock_progress > 0.0:
		lock_progress_bar.value = _lock_progress
	else:
		lock_progress_bar.value = 1.0 - _unlock_progress


# Override properties
func _set(property: StringName, value: Variant) -> bool:
	match property:
		"minimum_width":
			if full_container:
				var size := full_container.custom_minimum_size
				size.x = max(REQUIRED_MINIMUM_WIDTH, value as float)
				full_container.custom_minimum_size = size
			return true
		"content_text":
			if text_label:
				text_label.text = value as String
			return true
		"wrap_text":
			if text_label:
				text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if value else TextServer.AUTOWRAP_OFF
			return true
		"lock_progress":
			_lock_progress = clampf(value as float, 0.0, 1.0)
			_update_locking_display()
			return true
		"unlock_progress":
			_unlock_progress = clampf(value as float, 0.0, 1.0)
			_update_locking_display()
			return true
	return false


func _get(property: StringName) -> Variant:
	match property:
		"minimum_width":
			return full_container.custom_minimum_size.x if full_container else 0.0
		"content_text":
			return text_label.text if text_label else ""
		"wrap_text":
			return text_label.autowrap_mode != TextServer.AUTOWRAP_OFF if text_label else true
		"lock_progress":
			return _lock_progress
		"unlock_progress":
			return _unlock_progress
	return null
