extends Node2D

var _entity: EntityBase
var _pis_manager: RefCounted

func _ready() -> void:
	print("[ContextMenuTest] Scene ready")
	
	# Wait for singletons
	await get_tree().create_timer(1.0).timeout
	
	# Spawn entity
	var manager = get_node_or_null("/root/CTS_Entity")
	if manager:
		# Create config manually since we don't have a resource file handy
		var config = EntityConfig.new()
		config.entity_id = "test_entity"
		config.entity_name = "Test Entity"
		
		_entity = manager.spawn_at_position(config, Vector2(400, 300), self)
		if _entity:
			print("[ContextMenuTest] Entity spawned: ", _entity.name)
		else:
			print("[ContextMenuTest] ERROR: Failed to spawn entity")
			return
			
		# Connect to signal registry
		var registry = get_node_or_null("/root/EntitySignalRegistry")
		if registry:
			if not registry.entity_action_requested.is_connected(_on_entity_action):
				registry.entity_action_requested.connect(_on_entity_action)
			print("[ContextMenuTest] Connected to EntitySignalRegistry")
	else:
		print("[ContextMenuTest] ERROR: CTS_Entity manager not found")
		return
	
	# Get PIS Manager
	var cli = get_node_or_null("/root/CTS_Tools")
	if cli:
		_pis_manager = cli.pis_manager
		print("[ContextMenuTest] PIS Manager found")
	else:
		print("[ContextMenuTest] ERROR: CTS_Tools not found")
	
	# Start test
	_run_test()

func _run_test() -> void:
	await get_tree().create_timer(1.0).timeout
	
	# Step 1: Select entity manually
	print("[ContextMenuTest] Step 1: Selecting entity...")
	if _entity:
		var click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		_entity._on_select_area_input(null, click, 0)
		
		if _entity.is_selected():
			print("[ContextMenuTest] Entity selected successfully")
		else:
			print("[ContextMenuTest] ERROR: Entity NOT selected")
			return
	
	# Step 2: Run PIS macro
	print("[ContextMenuTest] Step 2: Running PIS macro (E -> 1)...")
	if _pis_manager:
		var test_file = "res://scenes/pis_test/context_menu_macro.json"
		_pis_manager.play_macro(test_file)
	else:
		print("[ContextMenuTest] ERROR: PIS Manager not found, cannot run macro")

func _on_entity_action(entity_id: String, action: String, source: Node) -> void:
	print("[ContextMenuTest] ACTION RECEIVED: ", action, " for ", entity_id)
	if action == "look_skills":
		print("[ContextMenuTest] SUCCESS: 'Look at Skills' triggered!")
		
		var label = Label.new()
		label.text = "SUCCESS: Skills Menu Triggered!"
		label.position = Vector2(350, 150)
		label.modulate = Color.GREEN
		label.scale = Vector2(2, 2)
		add_child(label)
