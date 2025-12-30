@tool
@icon("res://addons/cts_core/assets/node_2D/icon_marker.png")
class_name SpawnPoint
extends Marker2D

## SpawnPoint
##
## A designated location for spawning entities.
## Registers itself with the EntityManager via EntitySignalRegistry.
## Can be configured with a specific category and entity config.

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
const EntityCategoryRef = preload("res://addons/cts_entity/Core/entity_category.gd")

@export_group("Spawn Configuration")
@export var category: EntityCategoryRef.Category = EntityCategoryRef.Category.NONE
@export var entity_config: Resource # EntityConfig
@export var active: bool = true
@export var spawn_on_ready: bool = false

@export_group("Gizmo")
@export var gizmo_color: Color = Color(0.0, 1.0, 0.0, 0.5)

# ------------------------------------------------------------------------------
# Internal State
# ------------------------------------------------------------------------------
var _spawned_entity: Node = null

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------
func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	# Register with system
	EntitySignalRegistry.spawn_point_registered.emit(self)
	
	if spawn_on_ready and active:
		spawn()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
		
	EntitySignalRegistry.spawn_point_unregistered.emit(self)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func spawn(override_config: Resource = null) -> Node:
	if not active:
		return null
		
	var config_to_use = override_config if override_config else entity_config
	
	if not config_to_use:
		push_warning("SpawnPoint: No config assigned for spawn at %s" % name)
		return null
		
	# Request spawn via EntityManager (or Factory directly if we had access, 
	# but we go through the signal bus for decoupling)
	
	# Actually, SpawnPoint is the *location*. The Manager handles the *creation*.
	# But if we want "SpawnPoint.spawn()", it implies immediate action.
	# Let's request it via the registry.
	
	EntitySignalRegistry.spawn_requested.emit(category, global_position, {
		"config": config_to_use,
		"spawn_point": self
	})
	
	return null # Async spawn, can't return node immediately

func is_occupied() -> bool:
	return is_instance_valid(_spawned_entity)

# ------------------------------------------------------------------------------
# Editor Visualization
# ------------------------------------------------------------------------------
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 16.0, gizmo_color)
		draw_line(Vector2.ZERO, Vector2(24, 0), gizmo_color, 2.0) # Direction indicator
