extends Node

var _test_started = false

func _ready():
	print("Test runner ready. Press SPACE to run PIS macro.")
	
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		if event_bus.has_signal("entity_spawned"):
			event_bus.entity_spawned.connect(func(id, type):
				print("SUCCESS: Entity Spawned! ID: %s, Type: %s" % [id, type])
			)
	
	# Also listen to EntitySignalRegistry for visual spawns
	var entity_signals = get_node_or_null("/root/EntitySignalRegistry")
	if entity_signals:
		entity_signals.entity_spawned.connect(func(id, node, config):
			print("SUCCESS: Visual Entity Spawned! ID: %s, Node: %s" % [id, node])
		)

func _input(event):
	if _test_started: return
	
	if event.is_action_pressed("ui_accept"):
		_test_started = true
		_run_test()

func _run_test():
	print("Starting test...")
	var cli = get_node_or_null("/root/CTS_Tools")
	if cli and cli.pis_manager:
		print("Found CTS_Tools, playing macro...")
		cli.pis_manager.play_macro("res://test_spawn.json")
	else:
		print("CTS_Tools not found or PIS manager missing")
