class_name StaticEntitySpawner
extends Node

## StaticEntitySpawner
##
## A simple spawner that creates entities from a base scene and applies a specific sprite.
## Useful for deterministic spawning (e.g. placed enemies, specific NPCs).

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_created(entity: Node)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var base_entity_scene: PackedScene
@export var default_sprite: Texture2D

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func create_entity(type: String = "base_entity", sprite_override: Texture2D = null) -> Node:
	var instance: Node
	
	if base_entity_scene:
		instance = base_entity_scene.instantiate()
	else:
		push_warning("[StaticEntitySpawner] Base entity scene not assigned! Using basic Node2D.")
		instance = Node2D.new()
	
	# Set basic name
	instance.name = type.capitalize() + "_" + str(randi())
	
	# Setup Visuals
	_setup_visuals(instance, sprite_override)
	
	entity_created.emit(instance)
	return instance

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _setup_visuals(entity: Node, sprite_override: Texture2D) -> void:
	# Hide existing ColorRect if present (default in BaseEntity)
	var color_rect = entity.get_node_or_null("ColorRect")
	if color_rect:
		color_rect.visible = false
		
	# Determine which sprite to use
	var tex = sprite_override
	if not tex:
		tex = default_sprite
		
	if not tex:
		# No sprite available, just return (ColorRect might be hidden, but that's okay)
		return

	# Add Sprite
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.name = "VisualSprite"
	sprite.scale = Vector2(4, 4) # Scale up for visibility
	entity.add_child(sprite)
