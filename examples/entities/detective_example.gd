extends Node2D

## Example: Detective Entity (Unique)
## Demonstrates unique entity creation with custom scene

func _ready() -> void:
	# Create EntityConfig for unique detective
	var config = EntityConfig.new()
	config.entity_id = "detective"
	config.is_unique = true  # Only one detective can exist
	config.custom_data = {
		"stats_path": "res://examples/entities/detective_stats.tres",
		"description": "The player character - unique entity"
	}
	
	# Spawn detective
	var detective = CTS_Entity.create_entity(config, self)
	
	if detective:
		detective.position = Vector2(400, 300)
		print("[Example] Detective spawned with ID: ", detective._instance_id)
		print("[Example] Expected: detective (no auto-increment for unique entities)")
	else:
		push_error("[Example] Failed to spawn detective")

# EntityConfig is a global class from cts_entity plugin
