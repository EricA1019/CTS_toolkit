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
	if spawn_button:
		spawn_button.pressed.connect(func(): spawn_requested.emit())
	if clear_button:
		clear_button.pressed.connect(func(): clear_requested.emit())

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
