class_name PISRecorder
extends Node

## Records input events for PIS playback.
## Captures input events and serializes them to JSON.

# =============================================================================
# SIGNALS
# =============================================================================

signal recording_started
signal recording_stopped(event_count: int)
signal screenshot_requested(frame_info: Dictionary)

# =============================================================================
# STATE
# =============================================================================

var _is_recording: bool = false
var _recorded_events: Array[Dictionary] = []
var _start_time: int = 0
var _frame_count: int = 0

# =============================================================================
# PUBLIC API
# =============================================================================

func start_recording() -> void:
	_is_recording = true
	_recorded_events.clear()
	_start_time = Time.get_ticks_msec()
	_frame_count = 0
	
	# Ensure we are processing input
	set_process_input(true)
	set_process(true)
	
	recording_started.emit()
	print("[PISRecorder] Recording started")


func stop_recording() -> void:
	if not _is_recording: return
	
	_is_recording = false
	set_process_input(false)
	set_process(false)
	
	recording_stopped.emit(_recorded_events.size())
	print("[PISRecorder] Recording stopped. Captured %d events." % _recorded_events.size())


func save_recording(path: String) -> void:
	if _recorded_events.is_empty():
		push_warning("[PISRecorder] No events to save")
		return
		
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[PISRecorder] Failed to open file for saving: %s" % path)
		return
		
	var data := {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"events": _recorded_events
	}
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[PISRecorder] Saved recording to %s" % path)


func mark_screenshot() -> void:
	if not _is_recording: return
	
	var event := {
		"frame": _frame_count,
		"time": Time.get_ticks_msec() - _start_time,
		"type": "screenshot",
		"screenshot": true
	}
	_recorded_events.append(event)
	screenshot_requested.emit(event)
	print("[PISRecorder] Screenshot marker added at frame %d" % _frame_count)

# =============================================================================
# ENGINE CALLBACKS
# =============================================================================

func _ready() -> void:
	set_process_input(false)
	set_process(false)


func _process(_delta: float) -> void:
	if _is_recording:
		_frame_count += 1


func _input(event: InputEvent) -> void:
	if not _is_recording: return
	
	var event_data: Dictionary = {}
	var capture: bool = false
	
	if event is InputEventKey:
		capture = true
		event_data = {
			"type": "key",
			"keycode": event.keycode,
			"physical_keycode": event.physical_keycode,
			"pressed": event.pressed,
			"echo": event.echo
		}
	elif event is InputEventMouseButton:
		capture = true
		event_data = {
			"type": "mouse_button",
			"button_index": event.button_index,
			"pressed": event.pressed,
			"position_x": event.position.x,
			"position_y": event.position.y
		}
	elif event is InputEventAction:
		capture = true
		event_data = {
			"type": "action",
			"action": event.action,
			"pressed": event.pressed,
			"strength": event.strength
		}
		
	if capture:
		event_data["frame"] = _frame_count
		event_data["time"] = Time.get_ticks_msec() - _start_time
		_recorded_events.append(event_data)
