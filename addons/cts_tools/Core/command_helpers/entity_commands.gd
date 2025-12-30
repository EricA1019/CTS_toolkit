class_name EntityCommands
extends RefCounted

## Entity manipulation commands for CTS CLI Tools.
## Handles spawning, stats, and state management via signals.

# =============================================================================
# STATE
# =============================================================================

var _console: Node
var _event_bus: Node

# =============================================================================
# LIFECYCLE
# =============================================================================

func _init(console: Node) -> void:
	_console = console
	_event_bus = _console.get_node_or_null("/root/EventBus")
	
	if not _event_bus:
		_console.error("[EntityCommands] EventBus not found. Commands disabled.")
		return
		
	_register_commands()


func _register_commands() -> void:
	_console.register_command(cmd_entity_spawn, "entity spawn", "Spawn an entity: entity spawn <id> <type> [x] [y]")
	_console.register_command(cmd_entity_kill, "entity kill", "Despawn an entity: entity kill <id>")
	_console.register_command(cmd_entity_stat, "entity stat", "Modify entity stat: entity stat <id> <stat> <value>")
	
	# Autocomplete setup could go here if we had access to entity registries
	# _console.add_argument_autocomplete_source("entity spawn", 1, _get_entity_types)


# =============================================================================
# COMMANDS
# =============================================================================

func cmd_entity_spawn(id: String, type: String, x: String = "0", y: String = "0") -> void:
	var cts_entity = _console.get_node_or_null("/root/CTS_Entity")
	if cts_entity:
		# Try to load config based on type
		var config_path = "res://%s.tres" % type
		if type == "zombie": config_path = "res://test_zombie.tres" # Hardcoded for test
		
		if ResourceLoader.exists(config_path):
			var config = load(config_path)
			var parent = _console.get_tree().current_scene
			var pos = Vector2(x.to_float(), y.to_float())
			
			# Override ID if provided
			if not id.is_empty():
				config.entity_id = id
				config.is_unique = true
				
			cts_entity.spawn_at_position(config, pos, parent)
			_console.info("Spawned entity '%s' via CTS_Entity" % id)
			return
	
	# Fallback to EventBus signal if CTS_Entity not found or config missing
	if not _event_bus.has_signal("entity_spawned"):
		_console.error("Signal 'entity_spawned' not found on EventBus")
		return
		
	_event_bus.entity_spawned.emit(id, type)
	_console.info("Emitted entity_spawned signal for '%s' (No visual spawn)" % id)


func cmd_entity_kill(id: String) -> void:
	if not _event_bus.has_signal("entity_despawned"):
		_console.error("Signal 'entity_despawned' not found on EventBus")
		return
		
	_event_bus.entity_despawned.emit(id)
	_console.info("Despawned entity '%s'" % id)


func cmd_entity_stat(id: String, stat: String, value: String) -> void:
	# This assumes a generic stat change signal exists or maps to specific ones
	# Checking SIGNAL_CONTRACTS.md: entity_health_changed is there.
	
	var val_int := value.to_int()
	
	if stat == "health" or stat == "hp":
		if _event_bus.has_signal("entity_health_changed"):
			# Contract: entity_id, new_health, max_health
			# We don't know max_health here, so this is tricky without game state query.
			# For a CLI tool, we might need a 'debug_stat_changed' signal or similar.
			_console.warning("Direct health modification requires max_health context.")
			# _event_bus.entity_health_changed.emit(id, val_int, val_int) # Hacky
	
	# Generic stat signal (if available in project)
	if _event_bus.has_signal("stat_changed"):
		_event_bus.stat_changed.emit(id, stat, val_int)
		_console.info("Set stat '%s' of '%s' to %s" % [stat, id, value])
	else:
		_console.warning("Generic 'stat_changed' signal not found.")

# =============================================================================
# HELPERS
# =============================================================================

func _get_entity_types() -> Array:
	# Placeholder for autocomplete
	return ["player", "enemy", "npc", "item"]
