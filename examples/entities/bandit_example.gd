extends Node2D

## Example: Bandit Entities (Procedural with Auto-Increment)
## Demonstrates procedural entity creation with automatic ID generation

func _ready() -> void:
	# Create EntityConfig for bandit (non-unique)
	var bandit_config = EntityConfig.new()
	bandit_config.entity_id = "bandit"
	bandit_config.is_unique = false  # Allow multiple instances
	bandit_config.custom_data = {
		"stats_path": "res://examples/entities/bandit_stats.tres",
		"difficulty": "easy",
		"loot_table": "common_enemies"
	}
	
	# Spawn 5 bandits with auto-incrementing IDs
	for i in range(5):
		var bandit = CTS_Entity.create_entity(bandit_config, self)
		
		if bandit:
			# Position bandits in a line
			bandit.position = Vector2(200 + (i * 150), 300)
			print("[Example] Bandit %d spawned with ID: %s" % [i + 1, bandit._instance_id])
		else:
			push_error("[Example] Failed to spawn bandit %d" % (i + 1))
	
	print("\n[Example] Expected IDs: bandit_001, bandit_002, bandit_003, bandit_004, bandit_005")
	print("[Example] All bandits tracked in registry by type 'bandit'")
	
	# Demonstrate batch despawn after 3 seconds
	await get_tree().create_timer(3.0).timeout
	print("\n[Example] Batch despawning all bandits...")
	CTS_Entity.despawn_all_by_type("bandit", "example_cleanup")
	print("[Example] Batch despawn initiated (staggered: 3 entities per frame)")

const EntityConfig = preload("res://addons/cts_entity/Data/entity_config.gd")
