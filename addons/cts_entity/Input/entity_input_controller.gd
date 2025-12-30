extends Node
class_name EntityInputController

## Centralized input handler for entity context menus.
## Listens for selection signals and routes E / 1-9 to the selected entity.

var _selected_entity: Node = null
var _selected_id: String = ""
@onready var _signals: Node = EntitySignalRegistry

func _ready() -> void:
	print("[EntityInputController] Ready; signals present=", _signals != null)
	if _signals:
		_signals.entity_selected.connect(_on_entity_selected)
		_signals.entity_deselected.connect(_on_entity_deselected)
	
	set_process_input(true)
	set_process_unhandled_input(true)

func _exit_tree() -> void:
	if _signals:
		if _signals.entity_selected.is_connected(_on_entity_selected):
			_signals.entity_selected.disconnect(_on_entity_selected)
		if _signals.entity_deselected.is_connected(_on_entity_deselected):
			_signals.entity_deselected.disconnect(_on_entity_deselected)

func _unhandled_input(event: InputEvent) -> void:
	_handle_input(event)

func _handle_input(event: InputEvent) -> void:
	# Avoid logging mouse motion which floods logs. Only log meaningful events.
	if event is InputEventMouseMotion:
		# keep minimal trace-level info if needed in future
		return

	# Debug for other types only when an entity is selected
	if not _selected_entity:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode
		if key == KEY_E:
			print("[EntityInputController] E pressed - show menu on selected entity: ", _selected_id)
			_show_menu()
			get_viewport().set_input_as_handled()
			return

		if key >= KEY_1 and key <= KEY_9:
			var idx := key - KEY_1
			print("[EntityInputController] Number key pressed: ", idx + 1, " triggering menu index on ", _selected_id)
			_trigger_menu_index(idx)
			get_viewport().set_input_as_handled()
			return

	# Allow other events to pass through (e.g., mouse buttons handled by Area2D)
func _show_menu() -> void:
	if _selected_entity and _selected_entity.has_method("show_context_menu"):
		_selected_entity.show_context_menu()

func _trigger_menu_index(index: int) -> void:
	if _selected_entity and _selected_entity.has_method("trigger_context_option"):
		_selected_entity.trigger_context_option(index)

func _on_entity_selected(entity_id: String, entity_node: Node) -> void:
	_selected_entity = entity_node
	_selected_id = entity_id

func _on_entity_deselected(entity_id: String) -> void:
	if entity_id == _selected_id:
		_selected_entity = null
		_selected_id = ""
