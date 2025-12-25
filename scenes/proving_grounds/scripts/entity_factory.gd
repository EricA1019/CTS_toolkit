class_name TestEntitySpawner
extends Node

## TestEntitySpawner
##
## Responsible for creating and configuring entities for the Proving Grounds.
## Will be expanded to support procgen and random affixes.

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal entity_created(entity: Node)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var base_entity_scene: PackedScene

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func create_entity(type: String = "base_entity") -> Node:
	if not base_entity_scene:
		push_warning("Base entity scene not assigned in EntityFactory")
		# Fallback for testing if no scene is assigned
		var sprite = Sprite2D.new()
		# Use icon as placeholder
		sprite.texture = load("res://icon.svg")
		sprite.name = "TestEntity_" + str(randi())
		return sprite
		
	var instance = base_entity_scene.instantiate()
	instance.name = type.capitalize() + "_" + str(randi())
	
	# Future: Apply affixes here
	_apply_random_affixes(instance)
	
	entity_created.emit(instance)
	return instance

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _apply_random_affixes(entity: Node) -> void:
	# Placeholder for future procgen logic
	pass
