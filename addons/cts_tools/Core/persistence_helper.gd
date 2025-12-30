class_name CLIPersistenceHelper
extends RefCounted

## Handles saving and loading of custom CLI commands to JSON.
## Used by CLI Manager to persist user-defined commands.

# =============================================================================
# CONSTANTS
# =============================================================================

const DEFAULT_SAVE_PATH: String = "user://cts_cli_custom_commands.json"

# =============================================================================
# PUBLIC API
# =============================================================================

## Save custom commands to file
## @param commands: Dictionary of command_name -> {signal, description}
## @param path: Optional custom path (defaults to DEFAULT_SAVE_PATH)
func save_commands(commands: Dictionary, path: String = DEFAULT_SAVE_PATH) -> void:
	if commands.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		return
	
	var save_data: Array[Dictionary] = []
	for cmd_name: String in commands.keys():
		var info: Dictionary = commands[cmd_name]
		save_data.append({
			"name": cmd_name,
			"signal": info.get("signal", ""),
			"description": info.get("description", "")
		})
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_warning("[CLIPersistenceHelper] Failed to save: %s" % FileAccess.get_open_error())
		return
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("[CLIPersistenceHelper] Saved %d custom commands to %s" % [save_data.size(), path])


## Load custom commands from file
## @param path: Optional custom path (defaults to DEFAULT_SAVE_PATH)
## @return Array of command data dictionaries [{name, signal, description}]
func load_commands(path: String = DEFAULT_SAVE_PATH) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	if not FileAccess.file_exists(path):
		return result
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[CLIPersistenceHelper] Failed to load commands from %s" % path)
		return result
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error: int = json.parse(json_text)
	if error != OK:
		push_warning("[CLIPersistenceHelper] Failed to parse JSON: %s" % json.get_error_message())
		return result
	
	var data: Variant = json.data
	if not data is Array:
		push_warning("[CLIPersistenceHelper] Invalid format in %s" % path)
		return result
	
	for item: Variant in data:
		if not item is Dictionary:
			continue
		var cmd_data: Dictionary = item
		var name: String = cmd_data.get("name", "")
		var signal_name: String = cmd_data.get("signal", "")
		
		if name.is_empty() or signal_name.is_empty():
			continue
		
		result.append({
			"name": name,
			"signal": signal_name,
			"description": cmd_data.get("description", "")
		})
	
	if not result.is_empty():
		print("[CLIPersistenceHelper] Loaded %d custom commands from %s" % [result.size(), path])
	
	return result


## Check if save file exists
func has_saved_commands(path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)
