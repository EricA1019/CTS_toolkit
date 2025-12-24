extends Control

@onready var player_book = $PlayerBook
@onready var dummy_player = $DummyPlayer

# Mock EventBus
class MockEventBus extends Node:
	signal stat_changed(stat_name, value)
	signal inventory_updated(slot, item)

var event_bus = MockEventBus.new()

func _ready() -> void:
	add_child(event_bus)
	
	# Setup the book
	player_book.setup(event_bus, dummy_player)
	
	# Open it immediately for testing
	player_book.visible = true
	
	# Simulate a stat change after 2 seconds
	await get_tree().create_timer(2.0).timeout
	dummy_player.get_node("Stats").set_stat("Health", 90)
	event_bus.stat_changed.emit("Health", 90)
