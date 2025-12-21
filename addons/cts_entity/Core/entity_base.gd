extends Node2D
class_name EntityBase

## Base entity container - lifecycle management and component orchestration
## Entities are pure containers. All gameplay logic (stats, movement, abilities)
## lives in separate plugins that attach to entity containers.
##
## Usage:
##   # Factory-spawned (recommended):
##   var entity = CTS_Entity.create_entity(config)
##   
##   # Scene-instanced (fallback):
##   var entity = preload("res://my_entity.tscn").instantiate()

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted after entity fully initialized in scene tree
signal entity_ready(entity_id: String)

## Emitted after entity_config processed
signal entity_config_loaded(entity_id: String, config: EntityConfig)

## Emitted for each container after validation
signal container_ready(entity_id: String, container_name: String)

## Emitted before entity cleanup begins (death, removal, etc.)
signal entity_despawning(entity_id: String, reason: String)

## Emitted after despawn delay, before queue_free
signal entity_cleanup_started(entity_id: String)

# =============================================================================
# EXPORTS
# =============================================================================

## Entity configuration (assigned by factory or in inspector)
@export var entity_config: EntityConfig = null

# =============================================================================
# STATE
# =============================================================================

## Unique instance identifier (set by factory or generated)
var _instance_id: String = ""

## Despawn state guard
var _is_despawning: bool = false

# =============================================================================
# CONTAINER REFERENCES
# =============================================================================

## Container for stats components (HP, stamina, etc.)
@onready var stats_container: Node = $StatsContainer

## Container for inventory system
@onready var inventory_container: Node = $InventoryContainer

## Container for abilities/skills
@onready var abilities_container: Node = $AbilitiesContainer

## Container for misc components (AI, movement, etc.)
@onready var components_container: Node = $ComponentsContainer

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Dual-path initialization: factory-spawned vs scene-instanced
	var factory_id: String = str(get_meta("instance_id", ""))
	if not factory_id.is_empty():
		# Factory-spawned: ID already assigned
		_instance_id = factory_id
	else:
		# Scene-instanced fallback: generate ID
		_instance_id = _generate_fallback_id()
		set_meta("instance_id", _instance_id)
	
	# Initialize entity
	_initialize()

## Internal initialization after ID assigned
func _initialize() -> void:
	# Emit container ready signals for plugins to attach components
	_emit_container_signals()
	
	# Load config if provided
	if entity_config:
		if entity_config._validate():
			entity_config_loaded.emit(_instance_id, entity_config)
		else:
			push_error("[EntityBase] EntityConfig validation failed for %s" % _instance_id)
	
	# Entity ready for plugins to use
	entity_ready.emit(_instance_id)

## Emit container ready signals
func _emit_container_signals() -> void:
	var containers := [
		stats_container,
		inventory_container,
		abilities_container,
		components_container
	]
	
	for container in containers:
		if container:
			container_ready.emit(_instance_id, container.name)

# =============================================================================
# DESPAWN & CLEANUP
# =============================================================================

## Despawn entity with reason (death, manual removal, area exit, etc.)
## Handles death sprite replacement, signal emission, and cleanup
func despawn(reason: String = "manual") -> void:
	if _is_despawning:
		return
	
	_is_despawning = true
	
	# Emit despawn signal (plugins can respond: loot drops, death VFX, etc.)
	entity_despawning.emit(_instance_id, reason)
	
	# Handle death sprite replacement if applicable
	if reason == "death":
		await _handle_death_sprite()
	
	# Wait for signal handlers to complete
	await get_tree().process_frame
	
	# Cleanup and remove
	_cleanup()
	queue_free()

## Handle death sprite replacement
## Emits despawn signal, waits brief moment for sprite swap
func _handle_death_sprite() -> void:
	# Other plugins (cts_vfx) can connect to entity_despawning
	# and swap sprite here. Wait for swap to complete.
	await get_tree().create_timer(0.1).timeout

## Internal cleanup before queue_free
func _cleanup() -> void:
	entity_cleanup_started.emit(_instance_id)
	
	# Notify EntityManager to unregister
	var manager := get_node_or_null("/root/CTS_Entity")
	if manager and manager.has_method("unregister_entity"):
		manager.unregister_entity(_instance_id)
	
	# Plugins disconnect signals, cleanup components

# =============================================================================
# PUBLIC API
# =============================================================================

## Get unique instance identifier
func get_instance_id() -> String:
	return _instance_id

## Get container by name
func get_container(container_name: String) -> Node:
	match container_name:
		"StatsContainer":
			return stats_container
		"InventoryContainer":
			return inventory_container
		"AbilitiesContainer":
			return abilities_container
		"ComponentsContainer":
			return components_container
		_:
			push_error("[EntityBase] Unknown container: %s" % container_name)
			return null

## Check if entity has specific container
func has_container(container_name: String) -> bool:
	return get_container(container_name) != null

## Get all containers as dictionary
func get_all_containers() -> Dictionary:
	return {
		"StatsContainer": stats_container,
		"InventoryContainer": inventory_container,
		"AbilitiesContainer": abilities_container,
		"ComponentsContainer": components_container
	}

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

## Generate fallback ID for scene-instanced entities
func _generate_fallback_id() -> String:
	if entity_config and not entity_config.entity_id.is_empty():
		return "%s_scene_%d" % [entity_config.entity_id, get_instance_id()]
	return "entity_%d" % get_instance_id()
