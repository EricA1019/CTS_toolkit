extends Control

## PIS Input Test Scene
## Tests if PIS can simulate keyboard and mouse inputs

var _test_results: Dictionary = {}
var _pis_manager: RefCounted = null

@onready var button1: Button = $VBoxContainer/Button1
@onready var button2: Button = $VBoxContainer/Button2
@onready var button3: Button = $VBoxContainer/Button3
@onready var mouse_button: Button = $VBoxContainer/MouseTest
@onready var results_label: Label = $VBoxContainer/ResultsLabel

func _ready() -> void:
	print("[PISTest] Scene ready")
	
	# Connect buttons
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	button3.pressed.connect(_on_button3_pressed)
	mouse_button.pressed.connect(_on_mouse_button_pressed)
	
	# Setup input actions
	_setup_input_actions()
	
	print("[PISTest] Waiting for PIS_Manager initialization...")
	results_label.text = "Waiting for PIS_Manager..."
	
	# Wait for CLI manager to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Debug: Show what autoloads exist
	print("[PISTest] Checking /root children:")
	for child in get_tree().root.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	# Get PIS manager (it's a RefCounted property, not a Node child)
	var cli_manager = get_node_or_null("/root/CTS_Tools")
	if not cli_manager:
		print("[PISTest] ERROR: CTS_Tools not found!")
		results_label.text = "ERROR: CTS_Tools not found!"
		return
	
	print("[PISTest] Found CTS_CLI_Manager!")
	_pis_manager = cli_manager.pis_manager
	if not _pis_manager:
		print("[PISTest] ERROR: PIS_Manager property not found!")
		results_label.text = "ERROR: PIS Manager property not found!"
		return
	
	print("[PISTest] Found PIS_Manager, starting test in 2 seconds...")
	results_label.text = "Starting test in 2 seconds..."
	
	# Start test after delay
	await get_tree().create_timer(2.0).timeout
	_start_pis_test()

func _setup_input_actions() -> void:
	# Add test input actions if they don't exist
	if not InputMap.has_action("test_button_a"):
		InputMap.add_action("test_button_a")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_A
		InputMap.action_add_event("test_button_a", event)
		print("[PISTest] Created action: test_button_a (A key)")
	
	if not InputMap.has_action("test_button_b"):
		InputMap.add_action("test_button_b")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_B
		InputMap.action_add_event("test_button_b", event)
		print("[PISTest] Created action: test_button_b (B key)")
	
	if not InputMap.has_action("test_button_c"):
		InputMap.add_action("test_button_c")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_C
		InputMap.action_add_event("test_button_c", event)
		print("[PISTest] Created action: test_button_c (C key)")

func _input(event: InputEvent) -> void:
	# Listen for our test actions
	if event.is_action_pressed("test_button_a"):
		print("[PISTest] Input detected: test_button_a")
		_trigger_button(1)
	elif event.is_action_pressed("test_button_b"):
		print("[PISTest] Input detected: test_button_b")
		_trigger_button(2)
	elif event.is_action_pressed("test_button_c"):
		print("[PISTest] Input detected: test_button_c")
		_trigger_button(3)

func _trigger_button(button_num: int) -> void:
	match button_num:
		1:
			button1.emit_signal("pressed")
		2:
			button2.emit_signal("pressed")
		3:
			button3.emit_signal("pressed")

func _on_button1_pressed() -> void:
	print("[PISTest] Button 1 PRESSED!")
	_test_results["button1"] = true
	button1.text = "Button 1 ✓ ACTIVATED"
	button1.modulate = Color.GREEN
	_update_results()

func _on_button2_pressed() -> void:
	print("[PISTest] Button 2 PRESSED!")
	_test_results["button2"] = true
	button2.text = "Button 2 ✓ ACTIVATED"
	button2.modulate = Color.GREEN
	_update_results()

func _on_button3_pressed() -> void:
	print("[PISTest] Button 3 PRESSED!")
	_test_results["button3"] = true
	button3.text = "Button 3 ✓ ACTIVATED"
	button3.modulate = Color.GREEN
	_update_results()

func _on_mouse_button_pressed() -> void:
	print("[PISTest] Mouse Button PRESSED!")
	_test_results["mouse_click"] = true
	mouse_button.text = "Mouse Click ✓ ACTIVATED"
	mouse_button.modulate = Color.GREEN
	_update_results()

func _update_results() -> void:
	var passed := _test_results.size()
	var total := 4
	results_label.text = "Results: %d/%d tests passed" % [passed, total]
	
	if passed == total:
		results_label.modulate = Color.GREEN
		print("[PISTest] ALL TESTS PASSED!")

func _start_pis_test() -> void:
	print("[PISTest] Starting PIS test...")
	results_label.text = "Running PIS test..."
	
	# Load and play test macro
	var test_file := "res://scenes/pis_test/pis_input_test.json"
	if not FileAccess.file_exists(test_file):
		print("[PISTest] ERROR: Test file not found: ", test_file)
		results_label.text = "ERROR: Test file not found!"
		return
	
	if _pis_manager.has_method("load_macro"):
		_pis_manager.load_macro(test_file)
		print("[PISTest] Loaded macro: ", test_file)
	
	if _pis_manager.has_method("play_macro"):
		_pis_manager.play_macro(test_file)
		print("[PISTest] Playing macro: ", test_file)
	else:
		print("[PISTest] ERROR: PIS_Manager doesn't have play_macro method!")
		results_label.text = "ERROR: PIS play_macro not available!"
