extends Node

## Test script to validate the new signal-first items system
## Run this from the Godot editor or attach to a node

func _ready() -> void:
	print("=== ITEMS SYSTEM TEST ===")
	test_signal_registry()
	test_inventory_system()
	test_crafting_system()
	print("=== TEST COMPLETE ===")

func test_signal_registry() -> void:
	print("\n--- Testing Signal Registry ---")
	
	# Check if registry exists
	if not Engine.has_singleton("ItemsSignalRegistry"):
		push_error("ItemsSignalRegistry not found! Plugin needs reload.")
		print("❌ Registry not found - disable/enable cts_items plugin")
		return
	
	var registry = Engine.get_singleton("ItemsSignalRegistry")
	print("✓ ItemsSignalRegistry found")
	
	# List signals
	var signals := registry.get_signal_list()
	print("📡 Registry has ", signals.size(), " signals")
	
	# Connect to test signal
	if registry.has_signal("inventory_container_registered"):
		print("✓ inventory_container_registered signal exists")
	if registry.has_signal("item_add_requested"):
		print("✓ item_add_requested signal exists")
	if registry.has_signal("craft_requested"):
		print("✓ craft_requested signal exists")

func test_inventory_system() -> void:
	print("\n--- Testing Inventory System ---")
	
	# Load test items
	var wood := load("res://addons/cts_items/Data/test_items/wood.tres") as CtsItemDefinition
	var iron_ore := load("res://addons/cts_items/Data/test_items/iron_ore.tres") as CtsItemDefinition
	
	if not wood or not iron_ore:
		push_error("Test items not found!")
		return
	
	print("✓ Loaded test items: wood, iron_ore")
	
	# Load test entity scene
	var test_entity_scene := load("res://addons/cts_items/Data/test_items/test_item_entity.tscn") as PackedScene
	if not test_entity_scene:
		push_error("Test entity scene not found!")
		return
	
	print("✓ Test entity scene loaded")
	
	# Instantiate entity
	var test_entity := test_entity_scene.instantiate()
	add_child(test_entity)
	
	await get_tree().create_timer(0.5).timeout
	
	print("✓ Test entity instantiated (containers should emit registered signals)")
	
	# Check containers exist
	var inv_container = test_entity.get_node_or_null("InventoryContainer")
	var eq_container = test_entity.get_node_or_null("EquipmentContainer")
	var craft_container = test_entity.get_node_or_null("CraftingContainer")
	
	if inv_container:
		print("✓ InventoryContainer found, entity_id:", inv_container.entity_id)
	if eq_container:
		print("✓ EquipmentContainer found, entity_id:", eq_container.entity_id)
	if craft_container:
		print("✓ CraftingContainer found, entity_id:", craft_container.entity_id)
	
	# Test adding items via signal
	if Engine.has_singleton("ItemsSignalRegistry"):
		var registry = Engine.get_singleton("ItemsSignalRegistry")
		var new_item := ItemInstance.new(wood, 5)
		
		print("📤 Emitting item_add_requested signal (5x wood)...")
		registry.item_add_requested.emit("test_player", new_item)
		
		await get_tree().create_timer(0.2).timeout
		
		# Check if item was added (if systems are active)
		if inv_container and inv_container.has_method("get_item_count"):
			var count: int = inv_container.get_item_count(wood.item_id)
			print("  → Inventory now has ", count, " wood")

func test_crafting_system() -> void:
	print("\n--- Testing Crafting System ---")
	
	# Load recipe book
	var recipe_book := load("res://addons/cts_items/Data/test_recipes/test_recipe_book.tres") as RecipeBook
	if not recipe_book:
		push_error("Recipe book not found!")
		return
	
	print("✓ Recipe book loaded with ", recipe_book.recipes.size(), " recipes")
	
	for recipe in recipe_book.recipes:
		print("  - ", recipe.id, ": ", recipe.ingredients.size(), " ingredients → ", recipe.amount, "x ", recipe.result_item.display_name)
	
	# Test crafting signal
	if Engine.has_singleton("ItemsSignalRegistry"):
		var registry = Engine.get_singleton("ItemsSignalRegistry")
		
		print("📤 Emitting craft_requested signal (smelt_iron recipe)...")
		registry.craft_requested.emit("test_player", &"smelt_iron")
		
		await get_tree().create_timer(0.2).timeout
		print("  → Craft request sent (check for craft_completed or craft_failed signals)")
