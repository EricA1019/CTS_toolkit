extends GutTest

## ==============================================================================
## TEST SUITE DOCUMENTATION
## ==============================================================================
##
## TEST SUITE: TestProvingGrounds
## CLASS UNDER TEST: ProvingGrounds
##
## PURPOSE:
## Tests the functionality of the Proving Grounds scene, including entity spawning,
## clearing, and UI integration.
##
## COVERAGE:
## - Initialization - Verifies scene setup and dependencies
## - Spawning - Tests entity creation and positioning
## - Clearing - Tests entity removal
## - Signals - Verifies signal emissions
##
## ==============================================================================

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------
const PROVING_GROUNDS_SCENE_PATH = "res://scenes/proving_grounds/ProvingGrounds.tscn"
const BASE_ENTITY_SCENE_PATH = "res://scenes/proving_grounds/entities/BaseEntity.tscn"

# ------------------------------------------------------------------------------
# Test Variables
# ------------------------------------------------------------------------------
var _proving_grounds: ProvingGrounds
var _sender = InputSender.new(self)

# ------------------------------------------------------------------------------
# Lifecycle Methods
# ------------------------------------------------------------------------------
func before_each():
	# Load the scene instance
	var scene = load(PROVING_GROUNDS_SCENE_PATH)
	_proving_grounds = scene.instantiate()
	add_child_autofree(_proving_grounds)
	
	# Ensure it's ready
	await wait_frames(1)

func after_each():
	_proving_grounds.queue_free()
	_sender.release_all()

# ------------------------------------------------------------------------------
# Test Methods
# ------------------------------------------------------------------------------

func test_initialization():
	assert_not_null(_proving_grounds, "Proving Grounds scene should instantiate")
	assert_not_null(_proving_grounds.entity_factory, "EntityFactory should be assigned")
	assert_not_null(_proving_grounds.ui, "UnifiedUI should be assigned")
	assert_not_null(_proving_grounds.tile_map, "TileMapLayer should be assigned")
	assert_not_null(_proving_grounds.camera, "Camera2D should be assigned")

func test_spawn_entity():
	# Watch for signal
	watch_signals(_proving_grounds)
	
	# Trigger spawn
	_proving_grounds.spawn_test_entity()
	
	# Verify signal
	assert_signal_emitted(_proving_grounds, "entity_spawned", "Should emit entity_spawned signal")
	
	# Verify entity count
	var entities = _proving_grounds._entities
	assert_eq(entities.size(), 1, "Should have 1 entity tracked")
	
	# Verify child added
	var spawned_entity = entities[0]
	assert_not_null(spawned_entity.get_parent(), "Entity should be in scene tree")
	assert_true(spawned_entity.name.begins_with("BaseEntity"), "Entity name should start with BaseEntity")

func test_clear_entities():
	# Spawn a few entities
	_proving_grounds.spawn_test_entity()
	_proving_grounds.spawn_test_entity()
	_proving_grounds.spawn_test_entity()
	
	assert_eq(_proving_grounds._entities.size(), 3, "Should have 3 entities")
	
	# Clear them
	_proving_grounds.clear_entities()
	
	# Verify list cleared
	assert_eq(_proving_grounds._entities.size(), 0, "Entity list should be empty")
	
	# Verify nodes freed (might need to wait a frame for queue_free)
	await wait_frames(1)
	# Note: We can't easily check if freed objects are gone from memory, 
	# but we can check if the list is empty and trust queue_free

func test_ui_spawn_integration():
	# Watch for signal
	watch_signals(_proving_grounds)
	
	# Simulate UI button press via signal emission from UI
	# We can't easily click the button in unit test without complex input simulation,
	# but we can verify the signal connection
	
	_proving_grounds.ui.spawn_requested.emit()
	
	# Verify ProvingGrounds responded
	assert_signal_emitted(_proving_grounds, "entity_spawned", "UI spawn request should trigger entity spawn")
	assert_eq(_proving_grounds._entities.size(), 1, "Should have 1 entity after UI request")

func test_ui_clear_integration():
	# Spawn one
	_proving_grounds.spawn_test_entity()
	assert_eq(_proving_grounds._entities.size(), 1)
	
	# Simulate UI clear request
	_proving_grounds.ui.clear_requested.emit()
	
	# Verify cleared
	assert_eq(_proving_grounds._entities.size(), 0, "UI clear request should clear entities")

func test_entity_factory_fallback():
	# Test what happens if factory has no scene assigned (if we were to modify it)
	# This is a bit of a white-box test on the factory itself via the main scene
	
	# Temporarily remove the scene from factory
	var original_scene = _proving_grounds.entity_factory.base_entity_scene
	_proving_grounds.entity_factory.base_entity_scene = null
	
	# Trigger spawn
	_proving_grounds.spawn_test_entity()
	
	# Should still spawn a placeholder
	assert_eq(_proving_grounds._entities.size(), 1, "Should spawn placeholder even without scene")
	var entity = _proving_grounds._entities[0]
	assert_true(entity is Sprite2D, "Fallback entity should be a Sprite2D")
	
	# Restore
	_proving_grounds.entity_factory.base_entity_scene = original_scene
