@tool
extends EditorPlugin

const AUTOLOAD_NAME := "CTS_Tools"
const AUTOLOAD_PATH := "res://addons/cts_tools/Core/cli_manager.gd"

func _enter_tree() -> void:
	# Register the main manager as an autoload
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("[CTS Tools] Enabled")

func _exit_tree() -> void:
	# Clean up the autoload
	remove_autoload_singleton(AUTOLOAD_NAME)
	print("[CTS Tools] Disabled")
