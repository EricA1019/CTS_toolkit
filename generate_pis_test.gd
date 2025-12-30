@tool
extends EditorScript

func _run() -> void:
	var events = []
	var frame = 60
	var time = 1000
	
	for i in range(20):
		# Press S
		events.append({
			"type": "key",
			"keycode": 83, # KEY_S
			"pressed": true,
			"frame": frame,
			"time": time
		})
		frame += 5
		time += 100
		
		# Release S
		events.append({
			"type": "key",
			"keycode": 83,
			"pressed": false,
			"frame": frame,
			"time": time
		})
		frame += 10
		time += 200
		
	var data = {
		"version": "1.0",
		"events": events
	}
	
	var file = FileAccess.open("res://test_spawn_multi.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	print("Generated test_spawn_multi.json with ", events.size(), " events.")
