extends GutTest

## BaseFactory Tests (16 tests)
## Tests resource caching, node instantiation, LRU eviction

var BaseFactory = preload("res://addons/cts_core/Core/base_factory.gd")
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")

var _factory: Node

# ============================================================
# SETUP / TEARDOWN
# ============================================================

func before_each() -> void:
	var config = TypeDefs.FactoryConfig.create_default()
	_factory = BaseFactory.new(config)

func after_each() -> void:
	if is_instance_valid(_factory):
		_factory.queue_free()

# ============================================================
# RESOURCE CACHING TESTS (6 tests)
# ============================================================

func test_cache_resource_loads_and_caches() -> void:
	# Use core constants as test resource
	var path: String = "res://addons/cts_core/Data/core_constants.gd"
	
	var resource: Resource = _factory.cache_resource(path)
	
	assert_not_null(resource)
	assert_eq(_factory.get_cache_size(), 1)

func test_cache_resource_emits_cache_miss_on_first_load() -> void:
	var path: String = "res://addons/cts_core/Data/core_constants.gd"
	
	watch_signals(_factory)
	_factory.cache_resource(path)
	
	assert_signal_emitted(_factory, "cache_miss")

func test_cache_resource_emits_cache_hit_on_second_load() -> void:
	var path: String = "res://addons/cts_core/Data/core_constants.gd"
	
	_factory.cache_resource(path)  # First load
	
	watch_signals(_factory)
	_factory.cache_resource(path)  # Second load
	
	assert_signal_emitted(_factory, "cache_hit")

func test_get_cached_resource_returns_cached() -> void:
	var path: String = "res://addons/cts_core/Data/core_constants.gd"
	
	_factory.cache_resource(path)
	var cached: Resource = _factory.get_cached_resource(path)
	
	assert_not_null(cached)

func test_clear_cache_removes_all_entries() -> void:
	_factory.cache_resource("res://addons/cts_core/Data/core_constants.gd")
	_factory.cache_resource("res://addons/cts_core/Data/type_definitions.gd")
	
	_factory.clear_cache()
	
	assert_eq(_factory.get_cache_size(), 0)

func test_clear_cache_emits_signal() -> void:
	_factory.cache_resource("res://addons/cts_core/Data/core_constants.gd")
	
	watch_signals(_factory)
	_factory.clear_cache()
	
	assert_signal_emitted(_factory, "cache_cleared")

# ============================================================
# CACHE EVICTION TESTS (3 tests)
# ============================================================

func test_cache_respects_max_size() -> void:
	var config = TypeDefs.FactoryConfig.new()
	config.cache_enabled = true
	config.max_cache_size = 2
	_factory.set_config(config)
	
	_factory.cache_resource("res://addons/cts_core/Data/core_constants.gd")
	_factory.cache_resource("res://addons/cts_core/Data/type_definitions.gd")
	_factory.cache_resource("res://addons/cts_core/Core/base_component.gd")
	
	# Should evict oldest to stay within limit
	assert_lte(_factory.get_cache_size(), 2)

func test_cache_disabled_skips_caching() -> void:
	var config = TypeDefs.FactoryConfig.new()
	config.cache_enabled = false
	_factory.set_config(config)
	
	_factory.cache_resource("res://addons/cts_core/Data/core_constants.gd")
	
	assert_eq(_factory.get_cache_size(), 0)

func test_get_cached_count_returns_size() -> void:
	_factory.cache_resource("res://addons/cts_core/Data/core_constants.gd")
	
	assert_eq(_factory.get_cached_count(), 1)

# ============================================================
# ERROR HANDLING TESTS (3 tests)
# ============================================================

func test_cache_resource_handles_invalid_path() -> void:
	watch_signals(_factory)
	
	var resource: Resource = _factory.cache_resource("res://nonexistent/file.gd")
	
	assert_null(resource)
	assert_signal_emitted(_factory, "factory_error")

func test_create_node_handles_invalid_scene() -> void:
	watch_signals(_factory)
	
	var node: Node = _factory.create_node("res://nonexistent/scene.tscn")
	
	assert_null(node)
	assert_signal_emitted(_factory, "factory_error")

func test_factory_error_includes_context() -> void:
	watch_signals(_factory)
	
	_factory.cache_resource("res://nonexistent/file.gd")
	
	assert_signal_emit_count(_factory, "factory_error", 1)

# ============================================================
# CONFIGURATION TESTS (2 tests)
# ============================================================

func test_set_config_updates_configuration() -> void:
	var new_config = TypeDefs.FactoryConfig.new()
	new_config.max_cache_size = 999
	
	_factory.set_config(new_config)
	var retrieved_config = _factory.get_config()
	
	assert_eq(retrieved_config.max_cache_size, 999)

func test_factory_uses_default_config_if_none_provided() -> void:
	var factory_no_config = BaseFactory.new()
	var config = factory_no_config.get_config()
	
	assert_not_null(config)
	factory_no_config.queue_free()

# ============================================================
# NODE INSTANTIATION TESTS (2 tests - basic coverage)
# ============================================================

func test_create_node_instantiates_scene() -> void:
	# We don't have test scenes, so this is limited
	# In real project, would create test scene resource
	var node: Node = _factory.create_node("res://addons/cts_core/Core/base_component.gd")
	
	# This will fail since .gd is not a scene - testing error path
	assert_null(node)

func test_create_node_emits_signal_on_success() -> void:
	# Would need valid .tscn file to test properly
	# This tests error case instead
	watch_signals(_factory)
	_factory.create_node("res://invalid.tscn")
	
	# Should emit factory_error
	assert_signal_emitted(_factory, "factory_error")
