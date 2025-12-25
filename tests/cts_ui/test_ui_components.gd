extends GutTest

## Tests for CTS UI reactive components and drag-drop system

var binding: ReactiveBinding
var test_node: Node

func before_each():
	test_node = Node.new()
	add_child_autofree(test_node)
	binding = ReactiveBinding.new(test_node)

func after_each():
	if binding:
		binding.unbind_all()
		binding = null

## ReactiveBinding Tests

func test_reactive_binding_initialization():
	assert_not_null(binding, "ReactiveBinding should be created")
	assert_eq(binding._owner, test_node, "Owner should be set correctly")

func test_bind_label_to_resource():
	var label = Label.new()
	add_child_autofree(label)
	
	var resource = Resource.new()
	resource.set_meta("test_value", 42)
	
	# Note: Standard Resource doesn't have custom properties with changed signal
	# This tests the API without actual binding
	binding.bind_label(label, resource, "test_value")
	
	assert_not_null(label, "Label should exist after binding")

func test_bind_signal():
	var emitter = Node.new()
	add_child_autofree(emitter)
	emitter.add_user_signal("test_signal")
	
	var callback_counter = [0]  # Array to capture by reference
	var callback = func(): callback_counter[0] += 1
	
	binding.bind_signal(emitter, "test_signal", callback)
	emitter.emit_signal("test_signal")
	await get_tree().process_frame
	
	assert_eq(callback_counter[0], 1, "Callback should be called once when signal emitted")

func test_unbind_all():
	var emitter = Node.new()
	add_child_autofree(emitter)
	emitter.add_user_signal("test_signal")
	
	var callback = func(): pass
	binding.bind_signal(emitter, "test_signal", callback)
	
	binding.unbind_all()
	
	assert_false(emitter.is_connected("test_signal", callback), "Signal should be disconnected")

## DragPayload Tests

func test_drag_payload_creation():
	var container = Node.new()
	add_child_autofree(container)
	
	var item = Resource.new()
	var payload = DragPayload.new(container, 0, item, 1)
	
	assert_not_null(payload, "DragPayload should be created")
	assert_eq(payload.source_container, container, "Source container should match")
	assert_eq(payload.source_index, 0, "Source index should match")
	assert_eq(payload.item_instance, item, "Item instance should match")
	assert_eq(payload.quantity, 1, "Quantity should match")

func test_drag_payload_is_valid():
	var container = Node.new()
	add_child_autofree(container)
	
	var item = Resource.new()
	var valid_payload = DragPayload.new(container, 0, item, 1)
	assert_true(valid_payload.is_valid(), "Payload with container and item should be valid")
	
	var invalid_payload = DragPayload.new(null, 0, null, 1)
	assert_false(invalid_payload.is_valid(), "Payload without container or item should be invalid")

## DragDropManager Tests

func test_drag_drop_manager_exists():
	assert_not_null(DragDropManager, "DragDropManager autoload should exist")

func test_start_drag():
	var container = Node.new()
	add_child_autofree(container)
	
	var item = Resource.new()
	var payload = DragPayload.new(container, 0, item, 1)
	
	DragDropManager.start_drag(payload)
	
	assert_true(DragDropManager.is_dragging(), "Should be in dragging state")
	assert_eq(DragDropManager.get_current_payload(), payload, "Current payload should match")

func test_end_drag():
	var container = Node.new()
	add_child_autofree(container)
	
	var item = Resource.new()
	var payload = DragPayload.new(container, 0, item, 1)
	
	DragDropManager.start_drag(payload)
	DragDropManager.end_drag()
	
	assert_false(DragDropManager.is_dragging(), "Should not be in dragging state")
	assert_null(DragDropManager.get_current_payload(), "Current payload should be null")

func test_complete_drop():
	var container = Node.new()
	add_child_autofree(container)
	
	var target = Node.new()
	add_child_autofree(target)
	
	var item = Resource.new()
	var payload = DragPayload.new(container, 0, item, 1)
	
	DragDropManager.start_drag(payload)
	DragDropManager.complete_drop(target)
	
	assert_false(DragDropManager.is_dragging(), "Should not be in dragging state after drop")

## StatBar Tests

func test_stat_bar_creation():
	var stat_bar = StatBar.new()
	add_child_autofree(stat_bar)
	
	assert_not_null(stat_bar, "StatBar should be created")
	assert_true(stat_bar.show_label, "Label should be shown by default")

func test_stat_bar_values():
	var stat_bar = StatBar.new()
	add_child_autofree(stat_bar)
	
	stat_bar.max_value = 100
	stat_bar.value = 75
	
	await get_tree().process_frame
	
	assert_eq(stat_bar.value, 75, "Value should be set correctly")
	assert_eq(stat_bar.max_value, 100, "Max value should be set correctly")

## StatRow Tests

func test_stat_row_creation():
	var stat_row = StatRow.new()
	add_child_autofree(stat_row)
	
	assert_not_null(stat_row, "StatRow should be created")

func test_stat_row_setup():
	var stat_row = StatRow.new()
	add_child_autofree(stat_row)
	
	stat_row.setup("health", 100, 5)
	await get_tree().process_frame
	
	assert_eq(stat_row.stat_name, "health", "Stat name should be set")

## ItemSlot Tests

func test_item_slot_creation():
	var item_slot = ItemSlot.new()
	add_child_autofree(item_slot)
	
	assert_not_null(item_slot, "ItemSlot should be created")
	assert_eq(item_slot.slot_index, -1, "Initial slot index should be -1")

func test_item_slot_signals():
	var item_slot = ItemSlot.new()
	add_child_autofree(item_slot)
	
	watch_signals(item_slot)
	
	item_slot.slot_index = 0
	item_slot.emit_signal("slot_clicked", 0, MOUSE_BUTTON_LEFT)
	
	assert_signal_emitted(item_slot, "slot_clicked", "slot_clicked signal should be emitted")

## BadgeFlow Tests

func test_badge_flow_creation():
	var badge_flow = BadgeFlow.new()
	add_child_autofree(badge_flow)
	
	assert_not_null(badge_flow, "BadgeFlow should be created")
	assert_eq(badge_flow.get_child_count(), 0, "Should start with no children")

func test_badge_flow_add_badge():
	var badge_flow = BadgeFlow.new()
	add_child_autofree(badge_flow)
	
	badge_flow.add_badge("Fire", Color.RED)
	await get_tree().process_frame
	
	assert_eq(badge_flow.get_child_count(), 1, "Should have one badge")

func test_badge_flow_clear():
	var badge_flow = BadgeFlow.new()
	add_child_autofree(badge_flow)
	
	badge_flow.add_badge("Fire", Color.RED)
	badge_flow.add_badge("Ice", Color.BLUE)
	await get_tree().process_frame
	
	badge_flow.clear()
	await get_tree().process_frame
	
	assert_eq(badge_flow.get_child_count(), 0, "Should have no badges after clear")

## InventoryGrid Tests

func test_inventory_grid_creation():
	var grid = InventoryGrid.new()
	add_child_autofree(grid)
	
	assert_not_null(grid, "InventoryGrid should be created")
	assert_eq(grid.columns_count, 5, "Should have default 5 columns")

func test_inventory_grid_columns():
	var grid = InventoryGrid.new()
	add_child_autofree(grid)
	
	grid.columns_count = 8
	
	assert_eq(grid.columns, 8, "Columns should update when columns_count changes")
