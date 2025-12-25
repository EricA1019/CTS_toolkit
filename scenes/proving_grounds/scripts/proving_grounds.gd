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
	print("[ProvingGrounds] Ready.")
	
	# Fallback for exports
	if not ui:
		print("[ProvingGrounds] UI export null, attempting fallback...")
		ui = get_node_or_null("UnifiedUI")
		
	if not entity_factory:
		print("[ProvingGrounds] EntityFactory export null, attempting fallback...")
		entity_factory = get_node_or_null("EntityFactory")
		
	if not camera:
		camera = get_node_or_null("Camera2D")
	
	_initialize_environment()
	_connect_signals()
	
	if ui:
		ui.update_status("Proving Grounds Ready")
	else:
		push_error("[ProvingGrounds] UI not found!")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func spawn_test_entity() -> void:
	print("[ProvingGrounds] Spawn requested.")
	if not entity_factory:
		push_error("[ProvingGrounds] TestEntitySpawner not assigned!")
		return
		
	_current_state = TestState.SPAWNING
	print("[ProvingGrounds] Calling factory.create_entity...")
	var entity = entity_factory.create_entity("base_entity")
	
	if entity:
		print("[ProvingGrounds] Entity created successfully: ", entity.name)
		add_child(entity)
		_entities.append(entity)
		# Position randomly or at center
		var pos = _get_spawn_position()
		entity.position = pos
		print("[ProvingGrounds] Entity positioned at: ", pos)
		
		entity_spawned.emit(entity)
		if ui:
			ui.log_message("Spawned entity: " + entity.name)
	else:
		push_error("[ProvingGrounds] Factory returned null entity!")
	
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
	# Spawn around the camera position (or 0,0 if no camera)
	var base_pos = camera.position if camera else Vector2.ZERO
	return base_pos + Vector2(randf_range(-200, 200), randf_range(-200, 200))
