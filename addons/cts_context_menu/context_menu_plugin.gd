@tool
extends EditorPlugin


func _enter_tree() -> void:
	var script := preload("res://addons/cts_context_menu/Code/context_menu_control.gd")
	var texture := preload("res://addons/cts_context_menu/Assets/Icon.png")
	
	add_custom_type("Context Menu Control", "Control", script, texture)


func _exit_tree() -> void:
	remove_custom_type("Context Menu Control")
