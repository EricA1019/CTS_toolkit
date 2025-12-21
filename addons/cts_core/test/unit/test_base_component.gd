extends GutTest

## BaseComponent Tests (18 tests)
## Tests lifecycle, auto-registration, signals, state management

var BaseComponent = preload("res://addons/cts_core/Core/base_component.gd")
var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
var _manager: Node

# ============================================================
# SETUP / TEARDOWN
# ============================================================

func before_each() -> void:
	_manager = get_node_or_null("/root/CTS_Core")
	assert_not_null(_manager, "CTS_Core autoload not found")

# ============================================================
# LIFECYCLE TESTS (5 tests)
# ============================================================

func test_component_initializes_on_ready() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	owner_node.add_child(component)
	
	await get_tree().process_frame
	
	assert_true(component.is_initialized)
	assert_eq(component.get_state(), Constants.ComponentState.READY)
	
	owner_node.queue_free()

func test_component_validates_component_type() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	# No component_type set
	owner_node.add_child(component)
	
	await get_tree().process_frame
	
	assert_eq(component.get_state(), Constants.ComponentState.ERROR)
	
	owner_node.queue_free()

func test_component_registers_with_manager() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	
	var count_before: int = _manager.get_component_count()
	owner_node.add_child(component)
	await get_tree().process_frame
	var count_after: int = _manager.get_component_count()
	
	assert_gt(count_after, count_before)
	
	owner_node.queue_free()

func test_component_cleanup_unregisters() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	owner_node.add_child(component)
	await get_tree().process_frame
	
	var count_before: int = _manager.get_component_count()
	component.cleanup()
	var count_after: int = _manager.get_component_count()
	
	assert_lt(count_after, count_before)
	
	owner_node.queue_free()

func test_component_cleanup_called_on_delete() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	owner_node.add_child(component)
	await get_tree().process_frame
	
	var count_before: int = _manager.get_component_count()
	owner_node.queue_free()
	await get_tree().process_frame
	var count_after: int = _manager.get_component_count()
	
	assert_lt(count_after, count_before)

# ============================================================
# SIGNAL TESTS (4 tests)
# ============================================================

func test_component_emits_component_ready() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	
	watch_signals(component)
	owner_node.add_child(component)
	await get_tree().process_frame
	
	assert_signal_emitted(component, "component_ready")
	
	owner_node.queue_free()

func test_component_emits_component_initialized() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	
	watch_signals(component)
	owner_node.add_child(component)
	await get_tree().process_frame
	
	assert_signal_emitted(component, "component_initialized")
	
	owner_node.queue_free()

func test_component_emits_cleanup_started() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	owner_node.add_child(component)
	await get_tree().process_frame
	
	watch_signals(component)
	component.cleanup()
	
	assert_signal_emitted(component, "component_cleanup_started")
	
	owner_node.queue_free()

func test_component_emits_error_on_validation_failure() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	# No component_type - validation fails
	
	watch_signals(component)
	owner_node.add_child(component)
	await get_tree().process_frame
	
	assert_signal_emitted(component, "component_error")
	
	owner_node.queue_free()

# ============================================================
# STATE MANAGEMENT TESTS (4 tests)
# ============================================================

func test_component_starts_in_uninitialized_state() -> void:
	var component = BaseComponent.new()
	
	assert_eq(component.get_state(), Constants.ComponentState.UNINITIALIZED)
	
	component.queue_free()

func test_component_transitions_to_ready_state() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	owner_node.add_child(component)
	await get_tree().process_frame
	
	assert_eq(component.get_state(), Constants.ComponentState.READY)
	
	owner_node.queue_free()

func test_component_is_ready_returns_correct_value() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	
	assert_false(component.is_ready())
	
	owner_node.add_child(component)
	await get_tree().process_frame
	
	assert_true(component.is_ready())
	
	owner_node.queue_free()

func test_component_has_error_returns_correct_value() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	# No component_type - triggers error state
	owner_node.add_child(component)
	await get_tree().process_frame
	
	assert_true(component.has_error())
	
	owner_node.queue_free()

# ============================================================
# ENABLE/DISABLE TESTS (3 tests)
# ============================================================

func test_component_starts_enabled() -> void:
	var component = BaseComponent.new()
	
	assert_true(component.is_enabled)
	
	component.queue_free()

func test_set_enabled_changes_state() -> void:
	var component = BaseComponent.new()
	
	component.set_enabled(false)
	assert_false(component.is_enabled)
	
	component.set_enabled(true)
	assert_true(component.is_enabled)
	
	component.queue_free()

func test_disabled_component_still_registers() -> void:
	var owner_node: Node = Node.new()
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	component.set_enabled(false)
	
	owner_node.add_child(component)
	await get_tree().process_frame
	
	# Should still register even if disabled
	assert_true(component.is_initialized)
	
	owner_node.queue_free()

# ============================================================
# CONFIGURATION TESTS (2 tests)
# ============================================================

func test_validate_configuration_returns_true_by_default() -> void:
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	
	var result: bool = component.validate_configuration()
	
	assert_true(result)
	
	component.queue_free()

func test_component_stores_owner_reference() -> void:
	var owner_node: Node = Node.new()
	owner_node.name = "TestOwner"
	add_child(owner_node)
	
	var component = BaseComponent.new()
	component.component_type = "TestComponent"
	owner_node.add_child(component)
	await get_tree().process_frame
	
	# Access private _owner_node via get()
	var stored_owner = component.get("_owner_node")
	assert_eq(stored_owner, owner_node)
	
	owner_node.queue_free()
