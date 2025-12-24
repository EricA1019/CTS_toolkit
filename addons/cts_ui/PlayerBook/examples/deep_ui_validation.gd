extends Node

func _ready():
	print("Starting Deep UI Validation Test...")
	
	# 1. Load the Location Scene
	var location_scene = load("res://entity_showcase/location.tscn")
	var location = location_scene.instantiate()
	get_tree().root.call_deferred("add_child", location)
	
	# Wait for _ready and tree entry
	await get_tree().process_frame
	await get_tree().process_frame
	
	var ui = location.get_node("UI")
	var book = ui.get_node("PlayerBook")
	var skills = book.get_node("SkillsPage")
	var inventory = book.get_node("InventoryPage")
	
	# 2. Validate PlayerBook
	if not book.visible:
		print("❌ PlayerBook is hidden by default (Expected). Toggling...")
		book.toggle()
		if book.visible:
			print("✅ PlayerBook is now visible.")
		else:
			print("❌ PlayerBook failed to toggle visibility.")
	
	# 3. Validate Skills Page
	print("\n--- Validating Skills Page ---")
	if skills.config:
		print("✅ Config assigned: ", skills.config.resource_path)
	else:
		print("❌ No config assigned to SkillsPage.")
		
	var skill_children = skills.get_children()
	# Note: SkillsPage adds children directly or to a container. 
	# Based on previous code it was ScrollContainer/VBoxContainer.
	# Let's check if it has children at all first.
	if skills.get_child_count() > 0:
		print("✅ SkillsPage has ", skills.get_child_count(), " children.")
	else:
		print("❌ SkillsPage container is EMPTY.")
		
	# 4. Validate Inventory Page
	print("\n--- Validating Inventory Page ---")
	var inv_list = inventory.get_node("VBoxContainer/ItemList")
	if inv_list.item_count > 0:
		print("✅ InventoryPage has ", inv_list.item_count, " items.")
	else:
		print("❌ InventoryPage list is EMPTY.")
		
	# 5. Validate Entity
	print("\n--- Validating Entity ---")
	var location_children = location.get_children()
	print("Location children: ", location_children.size())
	
	var entity_found = false
	for child in location_children:
		if child.name == "PlayerEntity" or child is CharacterBody2D:
			entity_found = true
			print("✅ Entity found: ", child.name)
			if child.visible:
				print("✅ Entity is visible.")
			else:
				print("❌ Entity is HIDDEN.")
				
	if not entity_found:
		print("❌ No Entity found in Location.")

	print("\nTest Complete.")
	get_tree().quit()

