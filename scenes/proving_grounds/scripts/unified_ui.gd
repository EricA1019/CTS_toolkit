class_name UnifiedUI
extends CanvasLayer

## UnifiedUI
##
## Central UI for the Proving Grounds.
## Provides controls for spawning, debugging, and status display.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal spawn_requested
signal clear_requested

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var status_label: Label
@export var log_container: VBoxContainer
@export var spawn_button: Button
@export var clear_button: Button

# ------------------------------------------------------------------------------
# Lifecycle Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	print("[UnifiedUI] UI Ready.")
	
	# Fallback assignments if exports fail
	if not spawn_button:
		print("[UnifiedUI] Spawn button export null, attempting fallback search...")
		spawn_button = get_node_or_null("Control/VBoxContainer/Buttons/SpawnButton")
		
	if not clear_button:
		print("[UnifiedUI] Clear button export null, attempting fallback search...")
		clear_button = get_node_or_null("Control/VBoxContainer/Buttons/ClearButton")
		
	if not status_label:
		status_label = get_node_or_null("Control/VBoxContainer/StatusLabel")
		
	if not log_container:
		log_container = get_node_or_null("Control/VBoxContainer/LogContainer")

	# Button connections (ensure these remain and are connected properly)
	if spawn_button:
		spawn_button.pressed.connect(func(): 
			print("[UnifiedUI] Spawn button pressed.")
			spawn_requested.emit()
		)
		# Add shortcut for PIS testing
		var shortcut = Shortcut.new()
		var event = InputEventKey.new()
		event.keycode = KEY_S
		shortcut.events.append(event)
		spawn_button.shortcut = shortcut
	else:
		push_error("[UnifiedUI] Spawn button not assigned and fallback failed!")
		
	if clear_button:
		clear_button.pressed.connect(func(): 
			print("[UnifiedUI] Clear button pressed.")
			clear_requested.emit()
		)
	else:
		push_error("[UnifiedUI] Clear button not assigned and fallback failed!")
		log_container.get_child(0).queue_free()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func update_status(message: String) -> void:
	if status_label:
		status_label.text = message
		print("[UnifiedUI] Status updated: ", message)
	else:
		push_warning("[UnifiedUI] Cannot update status - status_label not assigned")

func log_message(message: String) -> void:
	print("[UnifiedUI] Log: ", message)
	if log_container:
		var label := Label.new()
		label.text = message
		log_container.add_child(label)
	else:
		push_warning("[UnifiedUI] Cannot log message - log_container not assigned")
