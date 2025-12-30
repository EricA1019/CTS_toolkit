extends Node2D
class_name EntityBase

## Base entity container - lifecycle management and component orchestration
## Entities are pure containers. All gameplay logic (stats, movement, abilities)
## lives in separate plugins that attach to entity containers.
##
## Usage:
##   # Factory-spawned (recommended):
##   var entity = CTS_Entity.create_entity(config)
##   
##   # Scene-instanced (fallback):
##   var entity = preload("res://my_entity.tscn").instantiate()

@onready var _signals: Node = EntitySignalRegistry

# =============================================================================
# SIGNAL REGISTRY
# =============================================================================

## All entity signals centralized in EntitySignalRegistry
## This class emits lifecycle signals via the registry

# =============================================================================
# EXPORTS
# =============================================================================

## Entity configuration (assigned by factory or in inspector)
@export var entity_config: EntityConfig = null

# =============================================================================
# STATE
# =============================================================================

## Unique instance identifier (set by factory or generated)
var _instance_id: String = ""
var entity_id: String:
	get:
		return get_entity_id()

## Despawn state guard
var _is_despawning: bool = false

## Cleanup guard to avoid double unregister
var _did_cleanup: bool = false

## Selection state
var _is_selected: bool = false

## Context menu for entity actions
var _context_menu: TooltipContextMenu = null

# =============================================================================
# CONTAINER REFERENCES
# =============================================================================

## Container for stats components (HP, stamina, etc.)
@onready var stats_container: Node = _get_optional_child("StatsContainer")

## Container for inventory system
@onready var inventory_container: Node = _get_optional_child("InventoryContainer")

## Container for abilities/skills
@onready var abilities_container: Node = _get_optional_child("AbilitiesContainer")

## Container for misc components (AI, movement, etc.)
@onready var components_container: Node = _get_optional_child("ComponentsContainer")

## Optional typed containers (added if present in scene)
@onready var skills_container: Node = get_node_or_null("SkillsContainer")
@onready var affix_container: Node = get_node_or_null("AffixContainer")
@onready var equipment_container: Node = get_node_or_null("EquipmentContainer")
@onready var crafting_container: Node = get_node_or_null("CraftingContainer")

func _get_optional_child(path: String) -> Node:
	var node := get_node_or_null(path)
	if node == null:
		print("EntityBase: missing child ", path, " on ", name)
	return node

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Dual-path initialization: factory-spawned vs scene-instanced
	var factory_id: String = str(get_meta("instance_id", ""))
	if not factory_id.is_empty():
		# Factory-spawned: ID already assigned
		_instance_id = factory_id
	else:
		# Scene-instanced fallback: generate ID
		_instance_id = _generate_fallback_id()
		set_meta("instance_id", _instance_id)
	
	# Initialize entity
	_initialize()

	# Connect selection input area if present
	var select_area := get_node_or_null("SelectArea")
	if select_area:
		print("[EntityBase] SelectArea FOUND for ", _instance_id)
		print("[EntityBase]   input_pickable = ", select_area.input_pickable)
		print("[EntityBase]   collision_layer = ", select_area.collision_layer)
		print("[EntityBase]   collision_mask = ", select_area.collision_mask)
		print("[EntityBase]   global_position = ", global_position)
		
		# Check for collision shape
		var collision_shape := select_area.get_node_or_null("CollisionShape2D")
		if collision_shape:
			print("[EntityBase]   CollisionShape2D FOUND, disabled = ", collision_shape.disabled)
			if collision_shape.shape:
				print("[EntityBase]   Shape type = ", collision_shape.shape.get_class())
				if collision_shape.shape is CircleShape2D:
					print("[EntityBase]   Circle radius = ", collision_shape.shape.radius)
			else:
				print("[EntityBase]   ERROR: CollisionShape2D has NO shape!")
		else:
			print("[EntityBase]   ERROR: CollisionShape2D NOT FOUND!")
		
		# Connect signals
		select_area.connect("input_event", Callable(self, "_on_select_area_input"))
		print("[EntityBase]   input_event signal connected")
		
		# Also connect mouse_entered to see if ANY detection works
		select_area.connect("mouse_entered", Callable(self, "_on_select_area_mouse_entered"))
		select_area.connect("mouse_exited", Callable(self, "_on_select_area_mouse_exited"))
		print("[EntityBase]   mouse_entered/exited signals connected")
	else:
		print("[EntityBase] ERROR: SelectArea NOT FOUND for ", _instance_id)
	
	# Setup context menu
	_setup_context_menu()

## Internal initialization after ID assigned
func _initialize() -> void:
	# Emit container ready signals for plugins to attach components
	_emit_container_signals()
	
	# Load config if provided
	if entity_config:
		if entity_config._validate():
			if _signals:
				_signals.emit_signal("entity_config_loaded", _instance_id, entity_config)
		else:
			push_error("[EntityBase] EntityConfig validation failed for %s" % _instance_id)
	
	# Entity ready for plugins to use
	if _signals:
		_signals.emit_signal("entity_ready", _instance_id)

## Emit container ready signals
func _emit_container_signals() -> void:
	var containers := [
		stats_container,
		inventory_container,
		abilities_container,
		components_container
	]
	
	for container in containers:
		if container and _signals:
			_signals.emit_signal("container_ready", _instance_id, container.name)

# =============================================================================
# DESPAWN & CLEANUP
# =============================================================================

## Despawn entity with reason (death, manual removal, area exit, etc.)
## Handles death sprite replacement, signal emission, and cleanup
func despawn(reason: String = "manual") -> void:
	if _is_despawning:
		return
	
	_is_despawning = true
	
	# Emit despawn signal (plugins can respond: loot drops, death VFX, etc.)
	if _signals:
		_signals.emit_signal("entity_despawning", _instance_id, reason)
	
	# Handle death sprite replacement if applicable
	if reason == "death":
		await _handle_death_sprite()
	
	# Wait for signal handlers to complete
	await get_tree().process_frame
	
	# Cleanup and remove
	_cleanup()
	queue_free()

## Handle death sprite replacement
## Emits despawn signal, waits brief moment for sprite swap
func _handle_death_sprite() -> void:
	# Other plugins (cts_vfx) can connect to entity_despawning
	# and swap sprite here. Wait for swap to complete.
	await get_tree().create_timer(0.1).timeout

## Internal cleanup before queue_free
func _cleanup() -> void:
	if _did_cleanup:
		return
	_did_cleanup = true

	if _signals:
		_signals.emit_signal("entity_cleanup_started", _instance_id)

	# Notify EntityManager to unregister
	var manager := get_node_or_null("/root/CTS_Entity")
	if manager and manager.has_method("unregister_entity"):
		manager.unregister_entity(_instance_id)

	# Plugins disconnect signals, cleanup components

# =============================================================================
# PUBLIC API
# =============================================================================

## Get unique instance identifier (string)
func get_entity_id() -> String:
	return _instance_id

## Get container by name
func get_container(container_name: String) -> Node:
	match container_name:
		"StatsContainer":
			return stats_container
		"InventoryContainer":
			return inventory_container
		"AbilitiesContainer":
			return abilities_container
		"ComponentsContainer":
			return components_container
		"SkillsContainer":
			return skills_container
		"AffixContainer":
			return affix_container
		"EquipmentContainer":
			return equipment_container
		"CraftingContainer":
			return crafting_container
		_:
			push_error("[EntityBase] Unknown container: %s" % container_name)
			return null

## Check if entity has specific container
func has_container(container_name: String) -> bool:
	return get_container(container_name) != null

## Get all containers as dictionary
func get_all_containers() -> Dictionary:
	return {
		"StatsContainer": stats_container,
		"InventoryContainer": inventory_container,
		"AbilitiesContainer": abilities_container,
		"ComponentsContainer": components_container,
		"SkillsContainer": skills_container,
		"AffixContainer": affix_container,
		"EquipmentContainer": equipment_container,
		"CraftingContainer": crafting_container,
	}

func get_skills_container() -> Node:
	return skills_container

func get_affix_container() -> Node:
	return affix_container

func get_inventory_container_typed() -> Node:
	return inventory_container

func get_equipment_container() -> Node:
	return equipment_container

func get_crafting_container() -> Node:
	return crafting_container

# =============================================================================
# SELECTION API
# =============================================================================

func is_selected() -> bool:
	return _is_selected

func deselect() -> void:
	if _is_selected:
		_is_selected = false
		_set_selected_visual(false)
		if _signals:
			_signals.emit_signal("entity_deselected", _instance_id)

func _on_select_area_mouse_entered() -> void:
	print("[EntityBase] MOUSE ENTERED entity: ", _instance_id)

func _on_select_area_mouse_exited() -> void:
	print("[EntityBase] MOUSE EXITED entity: ", _instance_id)

func _input(event: InputEvent) -> void:
	if not _is_selected:
		return
	
	if event is InputEventKey and event.pressed:
		# 'E' to open context menu
		if event.keycode == KEY_E:
			print("[EntityBase] 'E' pressed on selected entity ", _instance_id)
			if _context_menu:
				_context_menu.show_menu(self)
				get_viewport().set_input_as_handled()

func _on_select_area_input(_viewport, event, _shape_idx) -> void:
	# Skip logging mouse motion to reduce spam
	if not event is InputEventMouseMotion:
		print("[EntityBase] INPUT EVENT received for ", _instance_id, " - event type: ", event.get_class())
	if event is InputEventMouseButton:
		print("[EntityBase]   MouseButton: button=", event.button_index, " pressed=", event.pressed)
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Toggle selection
				if not _is_selected:
					_is_selected = true
					_set_selected_visual(true)
					if _signals:
						_signals.emit_signal("entity_selected", _instance_id, self)
				else:
					_is_selected = false
					_set_selected_visual(false)
					if _signals:
						_signals.emit_signal("entity_deselected", _instance_id)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Show context menu
				print("[EntityBase] Right-click detected on ", _instance_id)
				if _context_menu:
					print("[EntityBase] Showing context menu")
					_context_menu.show_menu(self)
				else:
					print("[EntityBase] ERROR: Context menu is null!")

## Public API for central input dispatcher
func show_context_menu() -> void:
	if not _context_menu:
		_setup_context_menu()
	if _context_menu:
		_context_menu.show_menu(self)

func trigger_context_option(index: int) -> void:
	print("[EntityBase] trigger_context_option: ", index)
	if not _context_menu:
		print("[EntityBase] trigger_context_option: context menu missing, setting up")
		_setup_context_menu()
	if _context_menu:
		print("[EntityBase] trigger_context_option: menu visible=", _context_menu.is_menu_visible())
		_context_menu.trigger_item_by_index(index)

func is_context_menu_visible() -> bool:
	return _context_menu != null and _context_menu.is_menu_visible()

func _set_selected_visual(selected: bool) -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals:
		if selected:
			visuals.modulate = Color(1.2, 1.2, 1.2)
		else:
			visuals.modulate = Color(1, 1, 1)

func _setup_context_menu() -> void:
	print("[EntityBase] Setting up context menu for ", _instance_id)
	if _context_menu:
		return
	_context_menu = TooltipContextMenu.new()
	_context_menu.attach_to(self)
	# Use NODE_BOTTOM so keyboard-triggered menus appear anchored to the entity
	_context_menu.set_position_mode(TooltipContextMenu.PositionMode.NODE_BOTTOM)
	
	# Add menu items
	_context_menu.add_item("Look at Skills", func():
		print("[EntityBase] Skills menu item clicked")
		if _signals:
			_signals.emit_signal("entity_action_requested", _instance_id, "look_skills", self)
	)
	
	_context_menu.add_item("Look at Inventory", func():
		print("[EntityBase] Inventory menu item clicked")
		if _signals:
			_signals.emit_signal("entity_action_requested", _instance_id, "look_inventory", self)
	)
	print("[EntityBase] Context menu setup complete")

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

## Generate fallback ID for scene-instanced entities
func _generate_fallback_id() -> String:
	# Use Object.get_instance_id(self) to avoid recursion into our get_instance_id()
	var unique_id := str(get_instance_id())
	if entity_config and not entity_config.entity_id.is_empty():
		return "%s_scene_%s" % [entity_config.entity_id, unique_id]
	return "entity_%s" % unique_id

func _exit_tree() -> void:
	# If the node is removed without calling despawn(), ensure cleanup happens
	if _did_cleanup:
		return
	_cleanup()
