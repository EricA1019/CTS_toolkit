extends Node

## Main manager for CTS CLI Tools.
## Coordinates command registration, persistence, and LimboConsole integration.

# =============================================================================
# SIGNALS
# =============================================================================

signal command_registered(cmd_name: String, category: String)
signal command_executed(cmd_name: String, args: Array, result: Variant)
signal preset_loaded(preset_name: String, command_count: int)
signal config_changed(config: CLIConfigResource)

# =============================================================================
# CONSTANTS
# =============================================================================

const CONFIG_PATH: String = "res://cli_config.tres"

# =============================================================================
# STATE
# =============================================================================

var _config: CLIConfigResource
var _persistence: CLIPersistenceHelper
var _custom_commands: Dictionary = {} # name -> {signal, description, handler}
var _is_initialized: bool = false

# Command Helpers
var _entity_commands: RefCounted
var _pis_commands: RefCounted
var pis_manager: RefCounted
var pis_recorder: Node

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	if not OS.has_feature("debug"):
		print("[CTS_CLI_Manager] Disabled in release build")
		return
	
	if DisplayServer.get_name() == "headless":
		print("[CTS_CLI_Manager] Skipping in headless mode")
		return
	
	_persistence = CLIPersistenceHelper.new()
	_load_config()
	
	# Defer initialization to ensure LimboConsole is ready
	call_deferred("_initialize_console")


func _initialize_console() -> void:
	var console := get_node_or_null("/root/LimboConsole")
	if not console:
		push_warning("[CTS_CLI_Manager] LimboConsole not found. CLI tools disabled.")
		return
	
	_register_core_commands(console)
	
	if _config.enable_entity_commands:
		_register_entity_commands(console)
	
	if _config.enable_pis:
		_register_pis_commands(console)
	
	if _config.enable_custom_commands and _config.persistence_enabled:
		_load_custom_commands(console)
	
	_is_initialized = true
	print("[CTS_CLI_Manager] Initialized")


func _load_config() -> void:
	if ResourceLoader.exists(CONFIG_PATH):
		_config = load(CONFIG_PATH)
	else:
		_config = CLIConfigResource.new()
	
	config_changed.emit(_config)

# =============================================================================
# CORE COMMANDS
# =============================================================================

func _register_core_commands(console: Node) -> void:
	console.register_command(cmd_create_custom, "cmd create", "Create a custom signal command")
	console.register_command(cmd_list_custom, "cmd list", "List custom commands")
	console.register_command(cmd_remove_custom, "cmd remove", "Remove a custom command")
	
	command_registered.emit("cmd create", "core")
	command_registered.emit("cmd list", "core")
	command_registered.emit("cmd remove", "core")


func cmd_create_custom(cmd_name: String, signal_name: String, description: String = "") -> void:
	var console := get_node_or_null("/root/LimboConsole")
	if not console: return
	
	if _custom_commands.has(cmd_name):
		console.info("Command '%s' already exists" % cmd_name)
		return
	
	var handler: Callable = func(args: Array = []) -> void:
		_execute_custom_command(cmd_name, args)
	
	_custom_commands[cmd_name] = {
		"signal": signal_name,
		"description": description if not description.is_empty() else "Emits %s" % signal_name,
		"handler": handler
	}
	
	console.register_command(handler, "custom %s" % cmd_name, _custom_commands[cmd_name]["description"])
	console.info("Created command: custom %s -> %s" % [cmd_name, signal_name])
	
	if _config.persistence_enabled:
		_save_custom_commands()
	
	command_registered.emit("custom %s" % cmd_name, "custom")


func cmd_list_custom() -> void:
	var console := get_node_or_null("/root/LimboConsole")
	if not console: return
	
	if _custom_commands.is_empty():
		console.info("No custom commands. Use 'cmd create <name> <signal>'")
		return
	
	console.info("Custom commands (%d):" % _custom_commands.size())
	for cmd_name: String in _custom_commands.keys():
		var data: Dictionary = _custom_commands[cmd_name]
		console.info("  %s -> %s (%s)" % [cmd_name, data.signal, data.description])
	
	command_executed.emit("cmd list", [], null)


func cmd_remove_custom(cmd_name: String) -> void:
	var console := get_node_or_null("/root/LimboConsole")
	if not console: return
	
	if not _custom_commands.has(cmd_name):
		console.error("Command '%s' not found" % cmd_name)
		return
	
	console.unregister_command("custom %s" % cmd_name)
	_custom_commands.erase(cmd_name)
	console.info("Removed command: %s" % cmd_name)
	
	if _config.persistence_enabled:
		_save_custom_commands()
	
	command_executed.emit("cmd remove", [cmd_name], null)

# =============================================================================
# ENTITY COMMANDS
# =============================================================================

func _register_entity_commands(console: Node) -> void:
	# Load the helper script dynamically to avoid hard dependency
	var script_path := "res://addons/cts_tools/Core/command_helpers/entity_commands.gd"
	if not ResourceLoader.exists(script_path):
		push_warning("[CTS_CLI_Manager] Entity commands script not found at %s" % script_path)
		return
		
	var EntityCommandsClass = load(script_path)
	_entity_commands = EntityCommandsClass.new(console)
	
	# The helper registers its own commands in _init, but we can track them here if needed
	print("[CTS_CLI_Manager] Entity commands registered")

# =============================================================================
# PIS COMMANDS
# =============================================================================

func _register_pis_commands(console: Node) -> void:
	var manager_script := "res://addons/cts_tools/Core/PIS/pis_manager.gd"
	var recorder_script := "res://addons/cts_tools/Core/PIS/pis_recorder.gd"
	var commands_script := "res://addons/cts_tools/Core/PIS/pis_commands.gd"
	
	if not ResourceLoader.exists(manager_script) or not ResourceLoader.exists(recorder_script):
		push_warning("[CTS_CLI_Manager] PIS scripts not found")
		return
		
	var ManagerClass = load(manager_script)
	var RecorderClass = load(recorder_script)
	var CommandsClass = load(commands_script)
	
	pis_manager = ManagerClass.new(console, _config.pis_default_speed)
	pis_recorder = RecorderClass.new()
	add_child(pis_recorder) # Recorder needs to be in tree for _input
	
	if _config.pis_screenshot_integration:
		pis_recorder.screenshot_requested.connect(func(info):
			console.info("📸 Screenshot requested at frame %s. Use Godot MCP: take_screenshot()" % info.frame)
		)
	
	_pis_commands = CommandsClass.new(console, pis_manager, pis_recorder)
	print("[CTS_CLI_Manager] PIS commands registered")

# =============================================================================
# CUSTOM COMMAND EXECUTION
# =============================================================================

func _execute_custom_command(cmd_name: String, args: Array) -> void:
	var console := get_node_or_null("/root/LimboConsole")
	if not _custom_commands.has(cmd_name):
		return
		
	var data: Dictionary = _custom_commands[cmd_name]
	var signal_name: String = data.signal
	
	# Try to find EventBus
	var event_bus := get_node_or_null("/root/EventBus")
	if not event_bus:
		if console: console.error("EventBus not found")
		return
	
	if not event_bus.has_signal(signal_name):
		if console: console.error("Signal '%s' not found on EventBus" % signal_name)
		return
	
	# Emit the signal with provided args
	# Note: This assumes the signal takes an Array or variable arguments matching input
	# For more complex mapping, we'd need a schema
	if args.is_empty():
		event_bus.emit_signal(signal_name)
	else:
		# Basic support for 1 argument (often a Dictionary or ID)
		event_bus.emit_signal(signal_name, args[0])
	
	if console: console.info("Emitted %s" % signal_name)
	command_executed.emit("custom %s" % cmd_name, args, null)

# =============================================================================
# PERSISTENCE
# =============================================================================

func _save_custom_commands() -> void:
	if _persistence:
		_persistence.save_commands(_custom_commands, _config.custom_commands_path)


func _load_custom_commands(console: Node) -> void:
	if not _persistence:
		return
	
	var loaded_cmds: Array[Dictionary] = _persistence.load_commands(_config.custom_commands_path)
	
	for cmd_data: Dictionary in loaded_cmds:
		var cmd_name: String = cmd_data.get("name", "")
		var sig: String = cmd_data.get("signal", "")
		var desc: String = cmd_data.get("description", "")
		
		var handler: Callable = func(args: Array = []) -> void:
			_execute_custom_command(cmd_name, args)
		
		_custom_commands[cmd_name] = {"signal": sig, "description": desc, "handler": handler}
		console.register_command(handler, "custom %s" % cmd_name, desc)
		command_registered.emit("custom %s" % cmd_name, "custom")
	
	if not loaded_cmds.is_empty():
		preset_loaded.emit("custom", loaded_cmds.size())
