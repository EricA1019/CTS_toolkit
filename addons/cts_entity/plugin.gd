@tool
extends EditorPlugin

const AUTOLOAD_NAME := "CTS_Entity"
const AUTOLOAD_PATH := "res://addons/cts_entity/Core/entity_manager.gd"
const REQUIRED_DEPENDENCIES := ["CTS_Core"]

func _enable_plugin() -> void:
    if not _validate_dependencies():
        push_error("%s requires dependencies: %s" % [AUTOLOAD_NAME, REQUIRED_DEPENDENCIES])
        assert(false, "Missing dependencies")
        return
    if not Engine.has_singleton(AUTOLOAD_NAME):
        add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _disable_plugin() -> void:
    if Engine.has_singleton(AUTOLOAD_NAME):
        remove_autoload_singleton(AUTOLOAD_NAME)

func _validate_dependencies() -> bool:
    for dep in REQUIRED_DEPENDENCIES:
        if not Engine.has_singleton(dep):
            printerr("%s requires %s to be enabled" % [AUTOLOAD_NAME, dep])
            return false
    return true