extends Resource
class_name EntityResourceData

## Visual, physics, and behavior data for entities
## Separates presentation from configuration (EntityConfig)
## NOTE: This is a duplicate - consider using Core/entity_resource.gd instead

@export_group("Visual")
@export var sprite_texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var z_index: int = 0
@export var scale: Vector2 = Vector2.ONE

@export_group("Collision")
@export var collision_shape: Shape2D
@export var collision_layer: int = 1
@export var collision_mask: int = 1

@export_group("Movement")
@export var base_speed: float = 100.0
@export var acceleration: float = 500.0
@export var friction: float = 500.0
@export var bounce_distance: float = 100.0  # For back-and-forth demo

func apply_to_entity(entity: EntityBase) -> void:
	"""Apply this resource's data to an entity instance"""
	if not is_instance_valid(entity):
		push_error("EntityResource: Invalid entity provided")
		return
	
	# Apply visual data
	var sprite: Sprite2D = entity.get_node_or_null("Visuals/Sprite2D")
	if sprite and sprite_texture:
		sprite.texture = sprite_texture
		sprite.offset = sprite_offset
		sprite.z_index = z_index
		sprite.scale = scale
	
	# Apply collision (if entity has Area2D or CharacterBody2D)
	var collision: CollisionShape2D = entity.get_node_or_null("CollisionShape2D")
	if collision and collision_shape:
		collision.shape = collision_shape
		collision.collision_layer = collision_layer
		collision.collision_mask = collision_mask
	
	# Apply movement component if present
	var movement: SimpleMovementComponent = entity.get_node_or_null("ComponentsContainer/SimpleMovementComponent")
	if movement:
		movement.set_movement_data(base_speed, bounce_distance)
