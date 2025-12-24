class_name PlayerBook
extends TabContainer

## Central UI hub for the player.
## Manages multiple BookPages and handles visibility/input.

signal book_opened
signal book_closed

func _ready() -> void:
	# Hide by default
	visible = false
	
	# Set layout mode to full rect to cover screen usually
	set_anchors_preset(Control.PRESET_FULL_RECT)

func setup(event_bus: Node, data_provider: Node) -> void:
	for child in get_children():
		if child is BookPage:
			child.setup(event_bus, data_provider)

func toggle() -> void:
	visible = not visible
	if visible:
		book_opened.emit()
		# Focus the current tab
		var current = get_current_tab_control()
		if current:
			current.grab_focus()
	else:
		book_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		toggle()
		get_viewport().set_input_as_handled()
