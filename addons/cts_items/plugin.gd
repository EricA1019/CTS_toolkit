@tool
extends EditorPlugin

const ITEMS_REGISTRY_AUTOLOAD := "ItemsSignalRegistry"
const ITEMS_REGISTRY_PATH := "res://addons/cts_items/Core/items_signal_registry.gd"

func _enter_tree() -> void:
	add_autoload_singleton(ITEMS_REGISTRY_AUTOLOAD, ITEMS_REGISTRY_PATH)

func _exit_tree() -> void:
	remove_autoload_singleton(ITEMS_REGISTRY_AUTOLOAD)
