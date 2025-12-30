class_name PISCommands
extends RefCounted

## CLI Adapter for Player Input Simulation (PIS).
## Exposes PIS functionality to the debug console.

# =============================================================================
# STATE
# =============================================================================

var _console: Node
var _manager: PISManager
var _recorder: PISRecorder

# =============================================================================
# LIFECYCLE
# =============================================================================

func _init(console: Node, manager: PISManager, recorder: PISRecorder) -> void:
	_console = console
	_manager = manager
	_recorder = recorder
	
	_register_commands()


func _register_commands() -> void:
	_console.register_command(cmd_record, "pis record", "Start recording input: pis record [filename]")
	_console.register_command(cmd_stop, "pis stop", "Stop recording and save")
	_console.register_command(cmd_play, "pis play", "Play recording: pis play <filename> [speed]")
	_console.register_command(cmd_mark, "pis mark", "Mark screenshot point in recording")
	_console.register_command(cmd_tap, "pis tap", "Tap a key/action: pis tap <action_or_key>")
	_console.register_command(cmd_move, "pis move", "Move mouse: pis move <x> <y>")

# =============================================================================
# COMMANDS
# =============================================================================

var _current_record_path: String = ""

func cmd_record(filename: String = "") -> void:
	if filename.is_empty():
		filename = "pis_recording_%s.json" % Time.get_datetime_string_from_system().replace(":", "-")
	
	if not filename.ends_with(".json"):
		filename += ".json"
		
	# Ensure user:// path if not specified
	if not filename.contains("://"):
		filename = "user://" + filename
		
	_current_record_path = filename
	_recorder.start_recording()
	_console.info("Started recording to %s" % filename)


func cmd_stop() -> void:
	_recorder.stop_recording()
	if not _current_record_path.is_empty():
		_recorder.save_recording(_current_record_path)
		_console.info("Saved recording to %s" % _current_record_path)
		_current_record_path = ""
	else:
		_console.warning("Recording stopped but no filename was set.")


func cmd_play(filename: String, speed: String = "1.0") -> void:
	# Ensure user:// path if not specified
	if not filename.contains("://"):
		filename = "user://" + filename
		
	if not FileAccess.file_exists(filename):
		_console.error("File not found: %s" % filename)
		return
		
	var speed_val := speed.to_float()
	if speed_val <= 0: speed_val = 1.0
	
	_manager.set_playback_speed(speed_val)
	_console.info("Playing %s at %.1fx speed..." % [filename, speed_val])
	
	_manager.play_macro(filename)


func cmd_mark() -> void:
	_recorder.mark_screenshot()
	_console.info("Screenshot marker added")


func cmd_tap(action_or_key: String) -> void:
	_manager.tap_button(action_or_key)
	_console.info("Tapped %s" % action_or_key)


func cmd_move(x: String, y: String) -> void:
	var pos := Vector2(x.to_float(), y.to_float())
	_manager.move_mouse(pos)
	_console.info("Moved mouse to %s" % pos)
