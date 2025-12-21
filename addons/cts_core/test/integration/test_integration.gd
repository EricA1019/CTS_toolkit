extends GutTest

## Integration Tests (10 tests)
## Tests cross-class workflows and system interactions

var BaseComponent = preload("res://addons/cts_core/Core/base_component.gd")
var BaseFactory = preload("res://addons/cts_core/Core/base_factory.gd")
var BaseProcessor = preload("res://addons/cts_core/Core/base_processor.gd")
var BaseResource = preload("res://addons/cts_core/Core/base_resource.gd")
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
var Constants = preload("res://addons/cts_core/Data/core_constants.gd")

var _manager: Node

# ============================================================
# SETUP / TEARDOWN
# ============================================================

func before_each() -> void:
	_manager = get_node_or_null("/root/CTS_Core")
	assert_not_null(_manager, "CTS_Core autoload not found")

# ============================================================
# COMPONENT + MANAGER INTEGRATION (3 tests)
# ============================================================

func test_multiple_components_register_correctly() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var comp1 = BaseComponent.new()
	comp1.component_type = "ComponentA"
	var comp2 = BaseComponent.new()
	comp2.component_type = "ComponentB"
	var comp3 = BaseComponent.new()
	comp3.component_type = "ComponentA"
	
	owner_node.add_child(comp1)
	owner_node.add_child(comp2)
	owner_node.add_child(comp3)
	await get_tree().process_frame
	
	var type_a_components: Array[Node] = _manager.get_components_by_type("ComponentA")
	var type_b_components: Array[Node] = _manager.get_components_by_type("ComponentB")
	
	assert_eq(type_a_components.size(), 2)
	assert_eq(type_b_components.size(), 1)
	
	owner_node.queue_free()

func test_component_lifecycle_unregisters_on_cleanup() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "LifecycleTest"
	owner_node.add_child(component)
	await get_tree().process_frame
	
	var count_registered: int = _manager.get_components_by_type("LifecycleTest").size()
	assert_eq(count_registered, 1)
	
	component.cleanup()
	var count_after_cleanup: int = _manager.get_components_by_type("LifecycleTest").size()
	assert_eq(count_after_cleanup, 0)
	
	owner_node.queue_free()

func test_manager_query_filters_components() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var comp1 = BaseComponent.new()
	comp1.component_type = "QueryTest"
	comp1.set_meta("priority", 1)
	var comp2 = BaseComponent.new()
	comp2.component_type = "QueryTest"
	comp2.set_meta("priority", 10)
	
	owner_node.add_child(comp1)
	owner_node.add_child(comp2)
	await get_tree().process_frame
	
	var query = TypeDefs.RegistryQuery.new()
	query.component_type = "QueryTest"
	query.filter_callback = func(node: Node) -> bool: 
		return node.get_meta("priority", 0) > 5
	
	var results: Array[Node] = _manager.query_components(query)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0], comp2)
	
	owner_node.queue_free()

# ============================================================
# FACTORY + RESOURCE INTEGRATION (2 tests)
# ============================================================

func test_factory_caches_and_retrieves_resources() -> void:
	var factory = BaseFactory.new()
	var path: String = "res://addons/cts_core/Data/core_constants.gd"
	
	var resource1: Resource = factory.cache_resource(path)
	var resource2: Resource = factory.cache_resource(path)
	
	# Should be same cached instance
	assert_same(resource1, resource2)
	
	factory.queue_free()

func test_factory_validates_cached_resources() -> void:
	var factory = BaseFactory.new()
	
	# Cache a resource
	var path: String = "res://addons/cts_core/Data/type_definitions.gd"
	factory.cache_resource(path)
	
	# Retrieve from cache
	var cached: Resource = factory.get_cached_resource(path)
	assert_not_null(cached)
	
	factory.queue_free()

# ============================================================
# PROCESSOR + COMPONENT INTEGRATION (2 tests)
# ============================================================

func test_processor_manages_component_processing() -> void:
	var config = TypeDefs.ProcessorConfig.create_default()
	config.auto_start = false
	var processor = BaseProcessor.new(config)
	add_child(processor)
	
	# Create components to process
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var comp1 = BaseComponent.new()
	comp1.component_type = "ProcessableA"
	var comp2 = BaseComponent.new()
	comp2.component_type = "ProcessableB"
	
	owner_node.add_child(comp1)
	owner_node.add_child(comp2)
	await get_tree().process_frame
	
	# Add components to processor
	processor.add_item(comp1)
	processor.add_item(comp2)
	
	assert_eq(processor.get_item_count(), 2)
	
	# Process
	watch_signals(processor)
	processor.process_items(0.016)
	
	assert_signal_emitted(processor, "processing_completed")
	
	processor.queue_free()
	owner_node.queue_free()

func test_processor_respects_frame_budget() -> void:
	var config = TypeDefs.ProcessorConfig.create_default()
	config.auto_start = false
	config.frame_budget_ms = 0.001  # Very tight budget
	var processor = BaseProcessor.new(config)
	add_child(processor)
	
	# Add many items
	for i in range(100):
		processor.add_item("item_%d" % i)
	
	watch_signals(processor)
	processor.process_items(0.016)
	
	# Should exceed budget with 100 items
	assert_signal_emitted(processor, "budget_exceeded")
	
	processor.queue_free()

# ============================================================
# CROSS-SYSTEM WORKFLOWS (3 tests)
# ============================================================

func test_factory_creates_component_via_scene() -> void:
	# This would require a test scene - testing error path instead
	var factory = BaseFactory.new()
	
	watch_signals(factory)
	var node: Node = factory.create_node("res://nonexistent.tscn")
	
	assert_null(node)
	assert_signal_emitted(factory, "factory_error")
	
	factory.queue_free()

func test_resource_validation_workflow() -> void:
	var resource = BaseResource.new()
	resource.resource_id = &"integration_test"
	resource.resource_version = 1
	
	# Validate
	var is_valid: bool = resource.validate()
	assert_true(is_valid)
	
	# Serialize
	var dict: Dictionary = resource.to_dict()
	assert_eq(dict["resource_id"], &"integration_test")
	
	# Load into new resource
	var resource2 = BaseResource.new()
	resource2.from_dict(dict)
	
	# Compare
	assert_true(resource.equals(resource2))

func test_signature_validation_across_components() -> void:
	# Verify manager signature
	var manager_signature: String = _manager.get_signature()
	assert_eq(manager_signature, Constants.CORE_SIGNATURE)
	
	# Validate signature
	var is_valid: bool = _manager.validate_signature(Constants.CORE_SIGNATURE)
	assert_true(is_valid)
	
	# Test mismatch detection
	watch_signals(_manager)
	var invalid_check: bool = _manager.validate_signature("WRONG:0.0.0.0:uuid")
	
	assert_false(invalid_check)
	assert_signal_emitted(_manager, "signature_mismatch_detected")
