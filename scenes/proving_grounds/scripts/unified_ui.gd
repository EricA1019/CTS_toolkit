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
	
	if spawn_button:
		spawn_button.pressed.connect(func(): 
			print("[UnifiedUI] Spawn button pressed.")
			spawn_requested.emit()
		)
	else:
		push_error("[UnifiedUI] Spawn button not assigned and fallback failed!")
		
	if clear_button:
		clear_button.pressed.connect(func(): 
			print("[UnifiedUI] Clear button pressed.")
			clear_requested.emit()
		)
	else:
		push_error("[UnifiedUI] Clear button not assigned and fallback failed!")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func update_status(text: String) -> void:
	if status_label:
		status_label.text = text

func log_message(text: String) -> void:
	if not log_container:
		print("UI Log: ", text)
		return
		
	var label = Label.new()
	label.text = "[%s] %s" % [Time.get_time_string_from_system(), text]
	log_container.add_child(label)
	
	# Keep log size manageable
	if log_container.get_child_count() > 10:
		log_container.get_child(0).queue_free()
