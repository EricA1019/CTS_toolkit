extends GutTest

## ==============================================================================
## TEST SUITE DOCUMENTATION
## ==============================================================================
##
## TEST SUITE: TestProvingGrounds
## CLASS UNDER TEST: ProvingGrounds
##
## PURPOSE:
## Validates the functionality of the Proving Grounds test environment, including
## entity spawning, UI interactions, and state management.
##
## COVERAGE:
## - Initialization - Tests environment setup and signal connections
## - Entity Spawning - Tests spawning logic and factory integration
## - Clearing - Tests entity removal
## - UI Integration - Tests UI signal handling
##
## ==============================================================================

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------
const PROVING_GROUNDS_SCENE_PATH = "res://scenes/proving_grounds/ProvingGrounds.tscn"
const ENTITY_FACTORY_SCRIPT = preload("res://scenes/proving_grounds/scripts/entity_factory.gd")

# ------------------------------------------------------------------------------
# Test Variables
# ------------------------------------------------------------------------------
var _proving_grounds: ProvingGrounds
var _sender = InputSender.new(self)

# ------------------------------------------------------------------------------
# Setup & Teardown
# ------------------------------------------------------------------------------
func before_all():
	# Setup global environment if needed
	pass

func after_all():
	# Cleanup global environment
	pass

func before_each():
	# Instantiate the scene for each test to ensure clean state
	var scene = load(PROVING_GROUNDS_SCENE_PATH)
	_proving_grounds = scene.instantiate()
	add_child_autofree(_proving_grounds)
	
	# Wait for _ready
	await wait_frames(1)

func after_each():
	# Cleanup is handled by add_child_autofree
	_proving_grounds = null

# ------------------------------------------------------------------------------
# Test Cases
# ------------------------------------------------------------------------------

## Tests that the Proving Grounds initializes correctly with all required components
func test_initialization():
	assert_not_null(_proving_grounds, "Proving Grounds should be instantiated")
	assert_not_null(_proving_grounds.tile_map, "TileMap should be assigned")
	assert_not_null(_proving_grounds.entity_factory, "EntityFactory should be assigned")
	assert_not_null(_proving_grounds.ui, "UI should be assigned")
	assert_not_null(_proving_grounds.camera, "Camera should be assigned")

## Tests that the entity factory is correctly typed and assigned
func test_entity_factory_assignment():
	assert_is(_proving_grounds.entity_factory, ProvingGroundsEntityFactory, "EntityFactory should be of type ProvingGroundsEntityFactory")

## Tests the spawn_test_entity method directly
func test_spawn_test_entity():
	# Watch for the signal
	watch_signals(_proving_grounds)
	
	# Initial count
	var initial_child_count = _proving_grounds.get_child_count()
	
	# Trigger spawn
	_proving_grounds.spawn_test_entity()
	
	# Verify signal was emitted
	assert_signal_emitted(_proving_grounds, "entity_spawned", "entity_spawned signal should be emitted")
	
	# Verify entity was added to scene
	# Note: We can't strictly check child count + 1 because the factory might add children differently,
	# but we can check if the internal array was updated if we exposed it, or check the signal payload.
	
	# Get the emitted signal parameters
	var signal_params = get_signal_parameters(_proving_grounds, "entity_spawned")
	if signal_params != null:
		var spawned_entity = signal_params[0]
		assert_not_null(spawned_entity, "Spawned entity should not be null")
		assert_true(spawned_entity.is_inside_tree(), "Spawned entity should be in the tree")
		assert_true(spawned_entity.name.begins_with("Base_entity"), "Entity name should start with Base_entity")

## Tests the clear_entities method
func test_clear_entities():
	# Spawn a few entities
	_proving_grounds.spawn_test_entity()
	_proving_grounds.spawn_test_entity()
	_proving_grounds.spawn_test_entity()
	
	# Verify we have entities (internal array check via reflection or just assumption based on previous test)
	# Since _entities is private, we rely on behavior.
	
	# Trigger clear
	_proving_grounds.clear_entities()
	
	# Wait a frame for queue_free to process
	await wait_frames(2)
	
	# We can't easily check private _entities, but we can check if the children count dropped
	# or if the specific entities we saw spawned are now invalid/freed.
	
	# Let's try to spawn one, capture it, clear, and check validity
	watch_signals(_proving_grounds)
	_proving_grounds.spawn_test_entity()
	var params = get_signal_parameters(_proving_grounds, "entity_spawned")
	var entity = params[0]
	
	assert_true(is_instance_valid(entity), "Entity should be valid after spawn")
	
	_proving_grounds.clear_entities()
	await wait_frames(2)
	
	assert_false(is_instance_valid(entity), "Entity should be freed after clear_entities")

## Tests UI integration - Spawn Button
func test_ui_spawn_button_integration():
	# This tests that the UI signal correctly triggers the ProvingGrounds method
	
	# Mock the UI signal emission or simulate button press if possible
	# Since we have a reference to UI, we can emit the signal manually to test the connection
	
	watch_signals(_proving_grounds)
	
	# Emit signal from UI
	_proving_grounds.ui.spawn_requested.emit()
	
	# Verify ProvingGrounds responded
	assert_signal_emitted(_proving_grounds, "entity_spawned", "ProvingGrounds should respond to UI spawn_requested")

## Tests UI integration - Clear Button
func test_ui_clear_button_integration():
	# Spawn an entity first
	_proving_grounds.spawn_test_entity()
	watch_signals(_proving_grounds)
	var params = get_signal_parameters(_proving_grounds, "entity_spawned")
	var entity = params[0]
	
	# Emit clear signal from UI
	_proving_grounds.ui.clear_requested.emit()
	await wait_frames(2)
	
	assert_false(is_instance_valid(entity), "ProvingGrounds should respond to UI clear_requested")

## Tests EntityFactory fallback behavior (if scene is missing)
func test_entity_factory_fallback():
	# Create a factory instance without a scene assigned
	var factory = ProvingGroundsEntityFactory.new()
	add_child_autofree(factory)
	
	# Watch for signal
	watch_signals(factory)
	
	# Create entity
	var entity = factory.create_entity("test_fallback")
	
	# Verify fallback behavior (Sprite2D)
	assert_not_null(entity, "Factory should return a fallback entity")
	assert_is(entity, Sprite2D, "Fallback entity should be a Sprite2D")
	assert_signal_emitted(factory, "entity_created", "Factory should emit entity_created")
	
	entity.free()

