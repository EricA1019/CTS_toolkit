@tool
extends EditorPlugin

const CRAFTING_AUTOLOAD := "CTS_Crafting"
const CRAFTING_PATH := "res://addons/cts_items/Core/crafting_manager.gd"

func _enter_tree() -> void:
	add_autoload_singleton(CRAFTING_AUTOLOAD, CRAFTING_PATH)

func _exit_tree() -> void:
	remove_autoload_singleton(CRAFTING_AUTOLOAD)
