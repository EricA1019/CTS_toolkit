class_name ProvingGrounds
extends Node2D

const TestEntitySpawnerScript = preload("res://scenes/proving_grounds/scripts/test_entity_spawner.gd")
const EntityCategoryRef = preload("res://addons/cts_entity/Core/entity_category.gd")

## ProvingGrounds
##
## Dedicated test space for testing entities, procgen, and systems.
## Orchestrates the test environment, UI, and entity spawning.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal test_started
signal entity_spawned(entity: Node)

# ------------------------------------------------------------------------------
# Constants & Enums
# ------------------------------------------------------------------------------
enum TestState {
	IDLE,
	SPAWNING,
	RUNNING
}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_group("References")
@export var spawn_markers: Array[Node2D] = []
# @export var entity_factory: TestEntitySpawnerScript # Deprecated
@export var ui: UnifiedUI
@export var camera: Camera2D

# ------------------------------------------------------------------------------
# Internal Variables
# ------------------------------------------------------------------------------
var _current_state: TestState = TestState.IDLE
var _entities: Array[Node] = []
var _spawn_sequence_index: int = 0
var _world_container: Node2D
var _current_selected_entity: Node = null

# ------------------------------------------------------------------------------
# Lifecycle Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	print("[ProvingGrounds] Ready.")
	
	# Setup World Container for Y-Sorting
	_world_container = Node2D.new()
	_world_container.name = "WorldContainer"
	_world_container.y_sort_enabled = true
	add_child(_world_container)
	
	# Move existing Set/Bunkers into WorldContainer if found
	var set_node = get_node_or_null("Set")
	if set_node:
		print("[ProvingGrounds] Moving environment to Y-Sort container...")
		var children = set_node.get_children()
		for child in children:
			child.reparent(_world_container)
			if child is Node2D:
				child.y_sort_enabled = true
	
	# Fallback for exports
	if not ui:
		print("[ProvingGrounds] UI export null, attempting fallback...")
		ui = get_node_or_null("UnifiedUI")
		
	if not camera:
		camera = get_node_or_null("Camera2D")
	
	_initialize_environment()
	_connect_signals()

	# Listen for entity spawns to auto-select the first one (helps automated PIS tests)
	if EntitySignalRegistry:
		if not EntitySignalRegistry.entity_spawned.is_connected(_on_entity_spawned_auto_select):
			EntitySignalRegistry.entity_spawned.connect(_on_entity_spawned_auto_select)

	# Connect entity selection signals
	if EntitySignalRegistry:
		if not EntitySignalRegistry.entity_selected.is_connected(_on_entity_selected):
			EntitySignalRegistry.entity_selected.connect(_on_entity_selected)
		if not EntitySignalRegistry.entity_deselected.is_connected(_on_entity_deselected):
			EntitySignalRegistry.entity_deselected.connect(_on_entity_deselected)
		if not EntitySignalRegistry.entity_action_requested.is_connected(_on_entity_action_requested):
			EntitySignalRegistry.entity_action_requested.connect(_on_entity_action_requested)
		# Configure PlayerBook if present
		if ui:
			var pb = ui.get_node_or_null("Control/PlayerBook") as Node
			if pb:
				if pb.has_method("hide"):
					pb.hide()
	
	if ui:
		ui.update_status("Proving Grounds Ready")
		
		# Auto-run context menu PIS test (disabled by file rename)
		if FileAccess.file_exists("res://test_context_menu.json"):
			print("[ProvingGrounds] Found context menu PIS test. Running in 2 seconds...")
			spawn_test_entity()
			await get_tree().create_timer(2.0).timeout
			if CTS_Tools and CTS_Tools.pis_manager and FileAccess.file_exists("res://test_context_menu.json"):
				print("[ProvingGrounds] Starting PIS test...")
				CTS_Tools.pis_manager.play_macro("res://test_context_menu.json")
	else:
		push_error("[ProvingGrounds] UI not found!")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func spawn_test_entity() -> void:
	print("[ProvingGrounds] Spawn requested via Signal Registry.")
	
	var spawn_pos = Vector2.ZERO
	if not spawn_markers.is_empty():
		var marker = spawn_markers.pick_random()
		spawn_pos = marker.global_position
		print("[ProvingGrounds] Using spawn marker at: ", spawn_pos)
	else:
		spawn_pos = Vector2(randf_range(100, 900), randf_range(100, 500))
		print("[ProvingGrounds] No markers, using random pos: ", spawn_pos)
		
	# Create a test config
	var config = EntityConfig.new()
	config.entity_id = "survivor"
	config.entity_name = "Test Survivor"
	config.is_unique = false
	
	# Request spawn via registry
	print("[ProvingGrounds] Emitting spawn_requested with pos: ", spawn_pos)
	EntitySignalRegistry.spawn_requested.emit(
		EntityCategoryRef.Category.NPC,
		spawn_pos,
		{
			"config": config,
			"parent": _world_container
		}
	)
	
	if ui:
		ui.log_message("Requested spawn at %s" % spawn_pos)

func clear_entities() -> void:
	for entity in _entities:
		if is_instance_valid(entity):
			entity.queue_free()
	_entities.clear()
	if ui:
		ui.log_message("Cleared all entities")

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _initialize_environment() -> void:
	# Setup basic tilemap if needed
	pass

func _connect_signals() -> void:
	if ui:
		ui.spawn_requested.connect(spawn_test_entity)
		ui.clear_requested.connect(clear_entities)

func _get_next_spawn_marker() -> Node2D:
	if spawn_markers.is_empty():
		return null
	var marker = spawn_markers[_spawn_sequence_index % spawn_markers.size()]
	_spawn_sequence_index += 1
	return marker

# ------------------------------------------------------------------------------
# Selection Handlers
# ------------------------------------------------------------------------------
func _on_entity_selected(_entity_id: String, entity_node: Node) -> void:
	# Deselect previous if different
	if _current_selected_entity and is_instance_valid(_current_selected_entity):
		if _current_selected_entity != entity_node and _current_selected_entity.has_method("deselect"):
			_current_selected_entity.deselect()
	
	_current_selected_entity = entity_node
	# Show player book
	if ui:
		var pb = ui.get_node_or_null("PlayerBook") as Node
		if pb and pb.has_method("setup"):
			pb.setup(EntitySignalRegistry, entity_node)
			if pb.has_method("show"):
				pb.show()

func _on_entity_deselected(entity_id: String) -> void:
	if _current_selected_entity and is_instance_valid(_current_selected_entity):
		if _current_selected_entity.get_entity_id() == entity_id and _current_selected_entity.has_method("deselect"):
			_current_selected_entity.deselect()
			_current_selected_entity = null
	if ui:
		var pb = ui.get_node_or_null("PlayerBook") as Node
		if pb and pb.has_method("hide"):
			pb.hide()

func _on_entity_action_requested(_entity_id: String, action_type: String, entity_node: Node) -> void:
	print("[ProvingGrounds] Entity action requested: ", action_type, " for entity: ", _entity_id)
	_current_selected_entity = entity_node
	
	if ui:
		var pb := ui.get_node_or_null("Control/PlayerBook")
		if pb:
			# Setup PlayerBook with entity data
			pb.setup(EntitySignalRegistry, entity_node)
			pb.show()
			
			# Switch to appropriate tab based on action
			match action_type:
				"look_skills":
					# Find Skills tab index
					for i in range(pb.get_tab_count()):
						if pb.get_tab_title(i) == "Skills":
							pb.current_tab = i
							break
				"look_inventory":
					# Find Inventory tab index
					for i in range(pb.get_tab_count()):
						if pb.get_tab_title(i) == "Inventory":
							pb.current_tab = i
							break

# ----------------------------------------------------------------------------
# Auto-select helper for tests
# ----------------------------------------------------------------------------
func _on_entity_spawned_auto_select(entity_id: String, entity_node: Node, _config: Resource) -> void:
	# If nothing is selected yet, simulate a left-click selection on the new entity
	if _current_selected_entity:
		return
	if not entity_node:
		return

	# Simulate a left mouse press to reuse entity selection logic
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true

	if entity_node.has_method("_on_select_area_input"):
		entity_node._on_select_area_input(null, click, 0)
		print("[ProvingGrounds] Auto-selected spawned entity: ", entity_id)
