extends Node2D

@onready var player_book = $UI/PlayerBook
@onready var event_bus = $EventBus
@onready var spawn_point = $SpawnPoint

func _ready() -> void:
	# Setup event bus
	var bus = get_node_or_null("/root/EventBus")
	if not bus:
		bus = $EventBus
	
	# Cleanup static entity if it exists in the scene
	if has_node("Entity"):
		get_node("Entity").queue_free()
	
	# Setup Factory and Config
	var factory = EntityFactory.new()
	var config = EntityConfig.new()
	config.entity_id = "player"
	config.entity_name = "Player"
	config.is_unique = true
	
	# Spawn Entity at spawn point
	var entity = factory.spawn_at_position(config, spawn_point.global_position, self)
	
	# Manually add components for testing
	if entity:
		var stats = _create_test_stats()
		stats.name = "Stats"
		entity.add_child(stats)
		
		var affix_container = Node.new()
		affix_container.name = "AffixContainer"
		entity.add_child(affix_container)
		
		player_book.setup(bus, entity)
	else:
		push_error("Failed to spawn entity in LocationManager")

func _create_test_stats() -> Node:
	var stats = Node.new()
	stats.set_script(preload("res://addons/cts_ui/PlayerBook/examples/dummy_stats.gd"))
	return stats
