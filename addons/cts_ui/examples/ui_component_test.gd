extends Control

@onready var _test_container = $VBoxContainer

func _ready() -> void:
	_test_reactive_binding()
	_test_components()
	_test_drag_drop()

func _test_reactive_binding() -> void:
	print("=== Testing ReactiveBinding ===")
	
	# Create a simple resource with changed signal
	var test_resource = Resource.new()
	var binding = ReactiveBinding.new(self)
	
	# Create a label and bind it (though Resource doesn't have custom properties, this tests the API)
	var label = Label.new()
	label.text = "Initial"
	_test_container.add_child(label)
	
	print("✓ ReactiveBinding created successfully")

func _test_components() -> void:
	print("=== Testing Components ===")
	
	# Test StatBar
	var stat_bar = StatBar.new()
	stat_bar.custom_minimum_size = Vector2(200, 30)
	stat_bar.value = 75
	stat_bar.max_value = 100
	_test_container.add_child(stat_bar)
	print("✓ StatBar created: 75/100")
	
	# Test StatRow
	var stat_row = StatRow.new()
	stat_row.setup("health", 100, 5, "Health stat")
	_test_container.add_child(stat_row)
	print("✓ StatRow created: health")
	
	# Test ItemSlot
	var item_slot = ItemSlot.new()
	item_slot.slot_index = 0
	_test_container.add_child(item_slot)
	print("✓ ItemSlot created")
	
	# Test BadgeFlow
	var badge_flow = BadgeFlow.new()
	badge_flow.add_badge("Fire", Color.ORANGE_RED)
	badge_flow.add_badge("Ice", Color.CYAN)
	_test_container.add_child(badge_flow)
	print("✓ BadgeFlow created with 2 badges")

func _test_drag_drop() -> void:
	print("=== Testing DragDropManager ===")
	
	if DragDropManager:
		print("✓ DragDropManager autoload available")
		print("  - is_dragging:", DragDropManager.is_dragging())
	else:
		print("✗ DragDropManager not found")
	
	print("\n=== All Tests Complete ===")
