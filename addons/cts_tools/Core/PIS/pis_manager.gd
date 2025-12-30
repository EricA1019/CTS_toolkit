class_name PISManager
extends RefCounted

## Player Input Simulation (PIS) Manager
## Handles deterministic input simulation for automated testing and AI agents.

# =============================================================================
# STATE
# =============================================================================

signal event_executed(event_type: String, event_data: Dictionary)
signal playback_started(total_events: int)
signal playback_complete(success: bool, events_executed: int)
signal playback_failed(reason: String)

var _console: Node
var _playback_speed: float = 1.0
var _verbose_logging: bool = true
var _validate_events: bool = true
var _screenshot_callback: Callable = Callable()

# Statistics
var _total_events_executed: int = 0
var _failed_events: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _init(console: Node, default_speed: float = 1.0) -> void:
	_console = console
	_playback_speed = default_speed

# =============================================================================
# INPUT SIMULATION
# =============================================================================

## Simulate pressing a key or action
func press_button(action_or_key: Variant) -> void:
	var event := _create_input_event(action_or_key, true)
	if event:
		Input.parse_input_event(event)
		_log_input("Pressed", action_or_key)

## Simulate releasing a key or action
func release_button(action_or_key: Variant) -> void:
	var event := _create_input_event(action_or_key, false)
	if event:
		Input.parse_input_event(event)
		_log_input("Released", action_or_key)

## Simulate a tap (press + release)
func tap_button(action_or_key: Variant) -> void:
	press_button(action_or_key)
	# In a real frame-perfect sim, we might want to wait a frame here
	# For now, immediate release simulates a quick tap
	release_button(action_or_key)

## Simulate typing a string
func type_string(text: String) -> void:
	for char in text:
		var keycode := OS.find_keycode_from_string(char)
		if keycode == KEY_NONE:
			# Handle special cases or uppercase
			if char == " ": keycode = KEY_SPACE
			elif char == "_": keycode = KEY_UNDERSCORE
			# Add more mappings as needed
		
		if keycode != KEY_NONE:
			tap_button(keycode)

## Simulate mouse movement
func move_mouse(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position # Assuming window coordinates
	Input.parse_input_event(event)
	# _log_input("Moved Mouse", position) # Spammy, maybe skip logging

## Simulate mouse scroll
func scroll(delta: Vector2) -> void:
	var event := InputEventMouseButton.new()
	if delta.y > 0:
		event.button_index = MOUSE_BUTTON_WHEEL_UP
	elif delta.y < 0:
		event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	elif delta.x > 0:
		event.button_index = MOUSE_BUTTON_WHEEL_RIGHT
	elif delta.x < 0:
		event.button_index = MOUSE_BUTTON_WHEEL_LEFT
	else:
		return
		
	event.pressed = true
	Input.parse_input_event(event)
	event.pressed = false
	Input.parse_input_event(event)
	_log_input("Scrolled", delta)

## Wait for a number of frames (blocking - use in coroutines)
func wait_frames(count: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree: return
	
	for i in range(count):
		await tree.process_frame

# =============================================================================
# HELPERS
# =============================================================================

func _create_input_event(action_or_key: Variant, pressed: bool) -> InputEvent:
	var event: InputEvent
	
	if typeof(action_or_key) == TYPE_STRING:
		# Assume Action
		if InputMap.has_action(action_or_key):
			event = InputEventAction.new()
			event.action = action_or_key
			event.pressed = pressed
		else:
			# Try to parse as key string (e.g. "Space", "Escape")
			var key_code := OS.find_keycode_from_string(action_or_key)
			if key_code != KEY_NONE:
				event = InputEventKey.new()
				event.keycode = key_code
				event.pressed = pressed
				event.physical_keycode = key_code # Good practice
	elif typeof(action_or_key) == TYPE_INT:
		# Assume KeyCode
		event = InputEventKey.new()
		event.keycode = action_or_key
		event.pressed = pressed
		event.physical_keycode = action_or_key
		
	return event

func _log_input(type: String, target: Variant) -> void:
	if not _verbose_logging:
		return
	# Print concise info depending on type
	match typeof(target):
		TYPE_INT:
			print("[PIS] %s key %d" % [type, int(target)])
		TYPE_STRING:
			print("[PIS] %s action '%s'" % [type, str(target)])
		TYPE_VECTOR2:
			print("[PIS] %s mouse %s" % [type, str(target)])
		_:
			print("[PIS] %s %s" % [type, str(target)])

func set_playback_speed(speed: float) -> void:
	_playback_speed = speed

# =============================================================================
# PLAYBACK
# =============================================================================

func play_macro(path: String) -> void:
	reset_statistics()
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[PISManager] Could not open macro: %s" % path)
		emit_signal("playback_failed", "file_not_found")
		return
		
	var content := file.get_as_text()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("[PISManager] JSON parse error: %s" % json.get_error_message())
		emit_signal("playback_failed", "json_parse_error")
		return
		
	var data: Dictionary = json.get_data()
	var events: Array = data.get("events", [])
	# Emit start
	emit_signal("playback_started", events.size())
	# Run async
	_play_events(events)

func _play_events(events: Array) -> void:
	var current_frame: int = 0
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		emit_signal("playback_failed", "no_scene_tree")
		return
	
	print("[PIS] Starting playback of %d events" % events.size())
	_total_events_executed = 0
	_failed_events = 0
	
	for event in events:
		var target_frame: int = int(event.get("frame", 0))
		var frames_to_wait: int = target_frame - current_frame
		if frames_to_wait > 0:
			var wait: int = int(frames_to_wait / _playback_speed)
			if wait > 0:
				for i in range(wait):
					await tree.process_frame
			current_frame = target_frame
			
		# Execute and catch failures per event
		var ok := true
		var reason := ""
		match true:
			_:
				# Try execution (await because some events may be async)
				var res = await _execute_event(event)
				if res == false:
					ok = false
					reason = "event_failed"
					_failed_events += 1
				else:
					_total_events_executed += 1
			
		if _verbose_logging:
			print("[PIS] Progress: %d/%d executed, %d failed" % [_total_events_executed, events.size(), _failed_events])
	
	# Emit completion signal
	var success := _failed_events == 0
	emit_signal("playback_complete", success, _total_events_executed)
	print("[PIS] Playback complete. Executed: %d Failed: %d" % [_total_events_executed, _failed_events])


func _execute_event(data: Dictionary) -> bool:
	# Asynchronous event executor: returns true on success, false on failure
	var type := str(data.get("type", ""))
	var comment := str(data.get("comment", ""))
	if _verbose_logging:
		print("[PIS] Executing event type='%s' frame=%s %s" % [type, str(data.get("frame", "?")), ("- %s" % comment) if comment != "" else ""]) 
	
	var res: bool = false
	match type:
		"key":
			res = _execute_key_event(data)
		"mouse_button":
			res = _execute_mouse_button_event(data)
		"mouse_move":
			res = _execute_mouse_move_event(data)
		"action":
			res = _execute_action_event(data)
		"screenshot":
			_execute_screenshot_event(data)
			res = true
		"wait":
			await _execute_wait_event(data)
			res = true
		"validate":
			_execute_validation_event(data)
			res = true
		_:
			print("[PIS] WARNING: Unknown event type '%s'" % type)
			_failed_events += 1
			res = false
	
	if res:
		event_executed.emit(type, data)
	return res

# ---------------------
# Per-event executors
# ---------------------
func _execute_key_event(data: Dictionary) -> bool:
	var keycode: int = int(data.get("keycode", 0))
	var pressed: bool = data.get("pressed", false)
	if keycode == 0:
		print("[PIS] ERROR: Invalid keycode: 0")
		_return_false()
		return false
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = int(data.get("physical_keycode", keycode))
	event.unicode = int(data.get("unicode", 0))
	event.pressed = pressed
	event.echo = data.get("echo", false)
	Input.parse_input_event(event)
	if _verbose_logging:
		print("[PIS]   -> Key %d %s" % [keycode, "pressed" if pressed else "released"])
	return true

func _execute_mouse_button_event(data: Dictionary) -> bool:
	var button = int(data.get("button", int(data.get("button_index", 0))))
	var pressed = data.get("pressed", false)
	var pos_dict = data.get("position", null)
	var position = Vector2(0,0)
	if pos_dict:
		position = Vector2(pos_dict.get("x",0), pos_dict.get("y",0))
	elif data.has("position_x"):
		position = Vector2(data.get("position_x",0), data.get("position_y",0))
	if button == 0:
		print("[PIS] ERROR: Invalid mouse button: 0 (NONE). Event ignored.")
		_failed_events += 1
		return false
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	event.global_position = position
	Input.parse_input_event(event)
	if _verbose_logging:
		print("[PIS]   -> Mouse %s at %s" % [ _get_button_name(button), str(position) ])
	return true

func _execute_mouse_move_event(data: Dictionary) -> bool:
	var pos_dict = data.get("position", {"x":0, "y":0})
	var position := Vector2(pos_dict.get("x",0), pos_dict.get("y",0))
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = Vector2.ZERO
	Input.parse_input_event(event)
	if _verbose_logging:
		print("[PIS]   -> Mouse move to %s" % str(position))
	return true

func _execute_action_event(data: Dictionary) -> bool:
	var action := str(data.get("action", ""))
	if not InputMap.has_action(action):
		print("[PIS] ERROR: Action '%s' not found" % action)
		_failed_events += 1
		return false
	var event := InputEventAction.new()
	event.action = action
	event.pressed = data.get("pressed", false)
	event.strength = float(data.get("strength", 1.0))
	Input.parse_input_event(event)
	if _verbose_logging:
		print("[PIS]   -> Action %s %s" % [action, "pressed" if event.pressed else "released"])
	return true

func _execute_screenshot_event(data: Dictionary) -> void:
	print("[PIS] SCREENSHOT MARKER at frame %s" % str(data.get("frame", "?")))
	if _screenshot_callback.is_valid():
		_screenshot_callback.call(data)

func _execute_validation_event(data: Dictionary) -> void:
	var check_type := str(data.get("check", ""))
	var expected := data.get("expected", null)
	print("[PIS] VALIDATION: %s -> %s" % [check_type, str(expected)])
	match check_type:
		"node_exists":
			var tree := Engine.get_main_loop() as SceneTree
			if tree and tree.root:
				var node = tree.root.get_node_or_null(str(expected))
				if node:
					print("[PIS]   ✓ Node exists: %s" % str(expected))
				else:
					print("[PIS]   ✗ Node NOT found: %s" % str(expected))
					_failed_events += 1
			# add more validators here
		_:
			print("[PIS] WARNING: Unknown validation type '%s'" % check_type)

func _execute_wait_event(data: Dictionary) -> void:
	var frames := int(data.get("frames", 1))
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		if _verbose_logging:
			print("[PIS]   -> Waiting %d frames" % frames)
		for i in range(frames):
			await tree.process_frame

# ---------------------
# Helpers
# ---------------------
func _get_button_name(button: int) -> String:
	match button:
		MOUSE_BUTTON_LEFT: return "LEFT"
		MOUSE_BUTTON_RIGHT: return "RIGHT"
		MOUSE_BUTTON_MIDDLE: return "MIDDLE"
		MOUSE_BUTTON_WHEEL_UP: return "WHEEL_UP"
		MOUSE_BUTTON_WHEEL_DOWN: return "WHEEL_DOWN"
		_: return "BUTTON_%d" % button

func set_verbose_logging(enabled: bool) -> void:
	_verbose_logging = enabled

func get_statistics() -> Dictionary:
	return {"total_executed": _total_events_executed, "failed": _failed_events, "success_rate": (float(_total_events_executed - _failed_events) / max(1, _total_events_executed)) * 100.0}

func reset_statistics() -> void:
	_total_events_executed = 0
	_failed_events = 0

func _return_false():
	# small helper to increase future compatibility
	return false
