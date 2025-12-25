@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("DragDropManager", "res://addons/cts_ui/Core/drag_drop_manager.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("DragDropManager")
