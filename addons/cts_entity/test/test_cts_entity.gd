extends GutTest

## cts_entity Plugin Tests (25+ comprehensive tests)
## Tests EntityConfig, EntityBase, EntityFactory, EntityManager

const EntityConfig = preload("res://addons/cts_entity/Data/entity_config.gd")
const EntityBase = preload("res://addons/cts_entity/Core/entity_base.gd")
const EntityFactory = preload("res://addons/cts_entity/Core/entity_factory.gd")

var _manager: Node
var _factory: EntityFactory
var _test_parent: Node

# ============================================================
# SETUP / TEARDOWN
# ============================================================

func before_each() -> void:
	_manager = get_node_or_null("/root/CTS_Entity")
	assert_not_null(_manager, "CTS_Entity autoload not found")
	
	_factory = _manager.get_node_or_null("EntityFactory")
	assert_not_null(_factory, "EntityFactory not found in CTS_Entity")
	
	_test_parent = Node.new()
	add_child(_test_parent)

func after_each() -> void:
	if _test_parent:
		_test_parent.queue_free()
	
	# Clean up any remaining entities
	for entity_id in _manager._entity_registry.keys():
		var entity = _manager.get_entity(entity_id)
		if entity:
			entity.queue_free()
	
	_manager._entity_registry.clear()
	_manager._entities_by_type.clear()

# ============================================================
# ENTITYCONFIG VALIDATION TESTS (5 tests)
# ============================================================

func test_entity_config_validates_empty_id() -> void:
	var config = EntityConfig.new()
	config.entity_id = ""
	
	assert_false(config._validate(), "Empty entity_id should fail validation")

func test_entity_config_validates_invalid_characters() -> void:
	var config = EntityConfig.new()
	config.entity_id = "invalid-id-with-dashes!"
	
	assert_false(config._validate(), "Invalid characters should fail validation")

func test_entity_config_validates_alphanumeric_id() -> void:
	var config = EntityConfig.new()
	config.entity_id = "valid_entity_123"
	
	assert_true(config._validate(), "Valid alphanumeric ID should pass")

func test_entity_config_accepts_unique_flag() -> void:
	var config = EntityConfig.new()
	config.entity_id = "detective"
	config.is_unique = true
	
	assert_true(config._validate())
	assert_true(config.is_unique)

func test_entity_config_custom_data_stored() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_npc"
	config.custom_data = {"stats_path": "res://data/stats/bandit_stats.tres"}
	
	assert_eq(config.get_stats_path(), "res://data/stats/bandit_stats.tres")

# ============================================================
# ENTITYBASE LIFECYCLE TESTS (6 tests)
# ============================================================

func test_entity_base_initializes_with_instance_id() -> void:
	var entity = EntityBase.new()
	entity.set_meta("instance_id", "test_entity_001")
	_test_parent.add_child(entity)
	
	await get_tree().process_frame
	
	assert_eq(entity._instance_id, "test_entity_001")
	assert_true(entity._is_initialized)

func test_entity_base_emits_entity_ready_signal() -> void:
	var entity = EntityBase.new()
	entity.set_meta("instance_id", "test_entity_002")
	
	watch_signals(entity)
	_test_parent.add_child(entity)
	
	await get_tree().process_frame
	
	assert_signal_emitted(entity, "entity_ready")
	assert_signal_emit_count(entity, "entity_ready", 1)

func test_entity_base_has_required_containers() -> void:
	var entity = EntityBase.new()
	entity.set_meta("instance_id", "test_entity_003")
	_test_parent.add_child(entity)
	
	await get_tree().process_frame
	
	assert_not_null(entity.stats_container)
	assert_not_null(entity.inventory_container)
	assert_not_null(entity.abilities_container)
	assert_not_null(entity.components_container)

func test_entity_base_despawn_emits_signal() -> void:
	var entity = EntityBase.new()
	entity.set_meta("instance_id", "test_entity_004")
	_test_parent.add_child(entity)
	
	await get_tree().process_frame
	
	watch_signals(entity)
	entity.despawn("test_reason")
	
	await get_tree().process_frame
	
	assert_signal_emitted(entity, "entity_despawning")

func test_entity_base_despawn_prevents_duplicate_calls() -> void:
	var entity = EntityBase.new()
	entity.set_meta("instance_id", "test_entity_005")
	_test_parent.add_child(entity)
	
	await get_tree().process_frame
	
	watch_signals(entity)
	entity.despawn("test")
	entity.despawn("duplicate")
	
	await get_tree().process_frame
	
	assert_signal_emit_count(entity, "entity_despawning", 1)

func test_entity_base_cleanup_unregisters_from_manager() -> void:
	var entity = EntityBase.new()
	entity.set_meta("instance_id", "test_entity_006")
	entity.set_meta("factory_created", true)
	_test_parent.add_child(entity)
	
	await get_tree().process_frame
	
	# Manual registration for test
	_manager._entity_registry["test_entity_006"] = entity
	_manager._entities_by_type["test"] = ["test_entity_006"]
	
	entity._cleanup()
	
	assert_false(_manager._entity_registry.has("test_entity_006"))

# ============================================================
# ENTITYFACTORY CREATION TESTS (8 tests)
# ============================================================

func test_factory_creates_entity_from_base_template() -> void:
	var config = EntityConfig.new()
	config.entity_id = "bandit"
	config.is_unique = false
	
	var entity = _factory.create_entity(config, _test_parent)
	
	await get_tree().process_frame
	
	assert_not_null(entity)
	assert_true(entity.has_meta("instance_id"))

func test_factory_generates_unique_instance_id() -> void:
	var config = EntityConfig.new()
	config.entity_id = "detective"
	config.is_unique = true
	
	var entity = _factory.create_entity(config, _test_parent)
	
	assert_eq(entity.get_meta("instance_id"), "detective")

func test_factory_generates_auto_increment_id() -> void:
	var config = EntityConfig.new()
	config.entity_id = "bandit"
	config.is_unique = false
	
	var entity1 = _factory.create_entity(config, _test_parent)
	var entity2 = _factory.create_entity(config, _test_parent)
	
	var id1 = entity1.get_meta("instance_id")
	var id2 = entity2.get_meta("instance_id")
	
	assert_true(id1.begins_with("bandit_"))
	assert_true(id2.begins_with("bandit_"))
	assert_ne(id1, id2)

func test_factory_emits_entity_spawned_signal() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_spawn"
	
	watch_signals(_factory)
	var entity = _factory.create_entity(config, _test_parent)
	
	assert_signal_emitted(_factory, "entity_spawned")

func test_factory_validates_entity_config() -> void:
	var config = EntityConfig.new()
	config.entity_id = ""  # Invalid
	
	var entity = _factory.create_entity(config, _test_parent)
	
	assert_null(entity, "Should return null for invalid config")

func test_factory_attaches_to_parent() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_parent"
	
	var entity = _factory.create_entity(config, _test_parent)
	
	assert_eq(entity.get_parent(), _test_parent)

func test_factory_sets_factory_created_metadata() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_meta"
	
	var entity = _factory.create_entity(config, _test_parent)
	
	assert_true(entity.has_meta("factory_created"))
	assert_true(entity.get_meta("factory_created"))

func test_factory_passes_config_to_entity() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_config"
	config.custom_data = {"test_key": "test_value"}
	
	var entity = _factory.create_entity(config, _test_parent)
	
	assert_true(entity.has_meta("entity_config"))

# ============================================================
# ENTITYMANAGER REGISTRY TESTS (6 tests)
# ============================================================

func test_manager_registers_entity() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_register"
	
	var entity = _factory.create_entity(config, _test_parent)
	
	await get_tree().process_frame
	
	var instance_id = entity.get_meta("instance_id")
	assert_true(_manager._entity_registry.has(instance_id))

func test_manager_retrieves_entity_by_id() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_retrieve"
	
	var entity = _factory.create_entity(config, _test_parent)
	
	await get_tree().process_frame
	
	var instance_id = entity.get_meta("instance_id")
	var retrieved = _manager.get_entity(instance_id)
	
	assert_eq(retrieved, entity)

func test_manager_tracks_entities_by_type() -> void:
	var config = EntityConfig.new()
	config.entity_id = "bandit"
	
	_factory.create_entity(config, _test_parent)
	_factory.create_entity(config, _test_parent)
	
	await get_tree().process_frame
	
	var bandits = _manager.get_entities_by_type("bandit")
	assert_eq(bandits.size(), 2)

func test_manager_unregisters_despawned_entity() -> void:
	var config = EntityConfig.new()
	config.entity_id = "test_unregister"
	
	var entity = _factory.create_entity(config, _test_parent)
	
	await get_tree().process_frame
	
	var instance_id = entity.get_meta("instance_id")
	entity.despawn("test")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_false(_manager._entity_registry.has(instance_id))

func test_manager_emits_entity_registered_signal() -> void:
	watch_signals(_manager)
	
	var config = EntityConfig.new()
	config.entity_id = "test_signal"
	
	var entity = _factory.create_entity(config, _test_parent)
	
	await get_tree().process_frame
	
	assert_signal_emitted(_manager, "entity_registered")

func test_manager_get_all_entities_returns_array() -> void:
	var config1 = EntityConfig.new()
	config1.entity_id = "type1"
	
	var config2 = EntityConfig.new()
	config2.entity_id = "type2"
	
	_factory.create_entity(config1, _test_parent)
	_factory.create_entity(config2, _test_parent)
	
	await get_tree().process_frame
	
	var all_entities = _manager.get_all_entities()
	assert_eq(all_entities.size(), 2)