@tool
extends EditorPlugin
## CTS Text UI Plugin - Unified context menus and tooltips for Godot.


func _enter_tree() -> void:
	# Register custom types
	var context_menu_script := preload("res://addons/cts_textui/Code/context_menu_control.gd")
	var icon := preload("res://addons/cts_textui/Assets/Icon.png")
	
	add_custom_type("ContextMenuControl", "Control", context_menu_script, icon)
	add_custom_type("TooltipControl", "Control", preload("res://addons/cts_textui/Core/tooltip_control.gd"), icon)
	
	# Add autoload for tooltip service
	add_autoload_singleton("TooltipService", "res://addons/cts_textui/Prefabs/tooltip_service.tscn")


func _exit_tree() -> void:
	# Remove custom types
	remove_custom_type("ContextMenuControl")
	remove_custom_type("TooltipControl")
	
	# Remove autoload (only if it exists)
	if ProjectSettings.has_setting("autoload/TooltipService"):
		remove_autoload_singleton("TooltipService")
