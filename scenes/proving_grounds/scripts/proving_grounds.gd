class_name ProvingGrounds
extends Node2D

## ProvingGrounds
##
## Dedicated test space for testing entities, procgen, and systems.
## Orchestrates the test environment, UI, and entity spawning.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal test_started
signal entity_spawned(entity: Node)

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------
enum TestState {
	IDLE,
	SPAWNING,
	RUNNING
}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_group("References")
@export var tile_map: TileMapLayer
@export var entity_factory: TestEntitySpawner
@export var ui: UnifiedUI
@export var camera: Camera2D

# ------------------------------------------------------------------------------
# Internal Variables
# ------------------------------------------------------------------------------
var _current_state: TestState = TestState.IDLE
var _entities: Array[Node] = []

# ------------------------------------------------------------------------------
# Lifecycle Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_initialize_environment()
	_connect_signals()
	
	if ui:
		ui.update_status("Proving Grounds Ready")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func spawn_test_entity() -> void:
	if not entity_factory:
		push_error("TestEntitySpawner not assigned!")
		return
		
	_current_state = TestState.SPAWNING
	var entity = entity_factory.create_entity("base_entity")
	if entity:
		add_child(entity)
		_entities.append(entity)
		# Position randomly or at center
		entity.position = _get_spawn_position()
		entity_spawned.emit(entity)
		if ui:
			ui.log_message("Spawned entity: " + entity.name)
	
	_current_state = TestState.RUNNING

func clear_entities() -> void:
	for entity in _entities:
		if is_instance_valid(entity):
			entity.queue_free()
	_entities.clear()
	if ui:
		ui.log_message("Cleared all entities")

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _initialize_environment() -> void:
	# Setup basic tilemap if needed
	pass

func _connect_signals() -> void:
	if ui:
		ui.spawn_requested.connect(spawn_test_entity)
		ui.clear_requested.connect(clear_entities)

func _get_spawn_position() -> Vector2:
	# Simple random position near center for now
	var center = get_viewport_rect().size / 2
	return center + Vector2(randf_range(-100, 100), randf_range(-100, 100))
