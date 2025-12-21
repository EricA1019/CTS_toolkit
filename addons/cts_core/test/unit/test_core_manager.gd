extends GutTest

## CoreManager Tests (15 tests)
## Tests component registration, queries, signature validation

var _manager: Node
var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")

# ============================================================
# SETUP / TEARDOWN
# ============================================================

func before_each() -> void:
	_manager = get_node_or_null("/root/CTS_Core")
	assert_not_null(_manager, "CTS_Core autoload not found")

# ============================================================
# REGISTRATION TESTS (5 tests)
# ============================================================

func test_register_component_adds_to_registry() -> void:
	var component: Node = Node.new()
	component.set_meta("component_type", "TestComponent")
	
	var result: int = _manager.register_component(component)
	
	assert_eq(result, Constants.ErrorCode.SUCCESS)
	assert_true(_manager.get_component_count() > 0)
	
	component.queue_free()

func test_register_component_requires_component_type() -> void:
	var component: Node = Node.new()
	# No component_type meta set
	
	var result: int = _manager.register_component(component)
	
	assert_eq(result, Constants.ErrorCode.ERR_COMPONENT_INVALID)
	
	component.queue_free()

func test_register_component_emits_signal() -> void:
	var component: Node = Node.new()
	component.set_meta("component_type", "TestComponent")
	
	watch_signals(_manager)
	_manager.register_component(component)
	
	assert_signal_emitted(_manager, "component_registered")
	
	component.queue_free()

func test_unregister_component_removes_from_registry() -> void:
	var component: Node = Node.new()
	component.set_meta("component_type", "TestComponent")
	
	_manager.register_component(component)
	var count_before: int = _manager.get_component_count()
	
	_manager.unregister_component(component)
	var count_after: int = _manager.get_component_count()
	
	assert_lt(count_after, count_before)
	
	component.queue_free()

func test_unregister_component_emits_signal() -> void:
	var component: Node = Node.new()
	component.set_meta("component_type", "TestComponent")
	
	_manager.register_component(component)
	watch_signals(_manager)
	_manager.unregister_component(component)
	
	assert_signal_emitted(_manager, "component_unregistered")
	
	component.queue_free()

# ============================================================
# QUERY TESTS (5 tests)
# ============================================================

func test_get_components_by_type_returns_correct_type() -> void:
	var comp1: Node = Node.new()
	comp1.set_meta("component_type", "TypeA")
	var comp2: Node = Node.new()
	comp2.set_meta("component_type", "TypeB")
	
	_manager.register_component(comp1)
	_manager.register_component(comp2)
	
	var results: Array[Node] = _manager.get_components_by_type("TypeA")
	
	assert_eq(results.size(), 1)
	assert_eq(results[0], comp1)
	
	comp1.queue_free()
	comp2.queue_free()

func test_get_components_by_type_returns_empty_for_nonexistent() -> void:
	var results: Array[Node] = _manager.get_components_by_type("NonExistentType")
	
	assert_eq(results.size(), 0)

func test_find_component_returns_correct_component() -> void:
	var owner_node: Node = Node.new()
	owner_node.name = "TestOwner"
	add_child(owner_node)
	
	var component: Node = Node.new()
	component.set_meta("component_type", "TestComponent")
	owner_node.add_child(component)
	
	_manager.register_component(component)
	
	var found: Node = _manager.find_component(owner_node.get_path(), "TestComponent")
	
	assert_not_null(found)
	assert_eq(found, component)
	
	owner_node.queue_free()

func test_get_all_registered_types_returns_types() -> void:
	var comp1: Node = Node.new()
	comp1.set_meta("component_type", "TypeA")
	var comp2: Node = Node.new()
	comp2.set_meta("component_type", "TypeB")
	
	_manager.register_component(comp1)
	_manager.register_component(comp2)
	
	var types: Array[String] = _manager.get_all_registered_types()
	
	assert_true(types.has("TypeA"))
	assert_true(types.has("TypeB"))
	
	comp1.queue_free()
	comp2.queue_free()

func test_query_components_with_filter() -> void:
	var comp1: Node = Node.new()
	comp1.set_meta("component_type", "TestComponent")
	comp1.set_meta("enabled", true)
	var comp2: Node = Node.new()
	comp2.set_meta("component_type", "TestComponent")
	comp2.set_meta("enabled", false)
	
	_manager.register_component(comp1)
	_manager.register_component(comp2)
	
	var query = TypeDefs.RegistryQuery.new()
	query.component_type = "TestComponent"
	query.filter_callback = func(node: Node) -> bool: return node.get_meta("enabled", false)
	
	var results: Array[Node] = _manager.query_components(query)
	
	assert_eq(results.size(), 1)
	assert_eq(results[0], comp1)
	
	comp1.queue_free()
	comp2.queue_free()

# ============================================================
# SIGNATURE VALIDATION TESTS (3 tests)
# ============================================================

func test_get_signature_returns_core_signature() -> void:
	var signature: String = _manager.get_signature()
	
	assert_eq(signature, Constants.CORE_SIGNATURE)

func test_validate_signature_returns_true_for_matching() -> void:
	var result: bool = _manager.validate_signature(Constants.CORE_SIGNATURE)
	
	assert_true(result)

func test_validate_signature_emits_signal_for_mismatch() -> void:
	watch_signals(_manager)
	
	var result: bool = _manager.validate_signature("INVALID:0.0.0.0:wrong-uuid")
	
	assert_false(result)
	assert_signal_emitted(_manager, "signature_mismatch_detected")

# ============================================================
# MEMORY & ORPHAN CLEANUP TESTS (2 tests)
# ============================================================

func test_get_components_by_type_cleans_orphans() -> void:
	var component: Node = Node.new()
	component.set_meta("component_type", "TestComponent")
	
	_manager.register_component(component)
	component.queue_free()
	await get_tree().process_frame
	
	# Should clean up orphaned component
	var results: Array[Node] = _manager.get_components_by_type("TestComponent")
	
	assert_eq(results.size(), 0)

func test_batch_register_adds_multiple_components() -> void:
	var components: Array[Node] = []
	for i in range(3):
		var comp: Node = Node.new()
		comp.set_meta("component_type", "BatchComponent")
		components.append(comp)
	
	var results: Array[int] = _manager.batch_register(components)
	
	assert_eq(results.size(), 3)
	for result in results:
		assert_eq(result, Constants.ErrorCode.SUCCESS)
	
	for comp in components:
		comp.queue_free()
