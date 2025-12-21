@tool
extends EditorPlugin

## CTS Core Plugin
## Registers CTS_Core autoload singleton
## MUST be first CTS addon enabled (no dependencies)
## Docs: See docs/API_REFERENCE.md#plugin

const AUTOLOAD_NAME := "CTS_Core"
const AUTOLOAD_PATH := "res://addons/cts_core/Core/core_manager.gd"
const REQUIRED_DEPENDENCIES: Array[String] = []  # Core has no dependencies

func _enable_plugin() -> void:
    # CTS_Core has no dependencies, always safe to enable
    if not _validate_dependencies():
        return
    
    # Check if already registered (shouldn't happen, but be safe)
    if Engine.has_singleton(AUTOLOAD_NAME):
        push_warning("%s already registered as autoload" % AUTOLOAD_NAME)
        return
    
    # Warn if not first autoload (load order matters)
    _check_autoload_order()
    
    # Register CTS_Core singleton
    add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
    print("[CTS Core] Enabled - Signature: %s" % _get_signature())

func _disable_plugin() -> void:
    if Engine.has_singleton(AUTOLOAD_NAME):
        remove_autoload_singleton(AUTOLOAD_NAME)
        print("[CTS Core] Disabled")

func _validate_dependencies() -> bool:
    # Core has no dependencies, always returns true
    # Other addons MUST check for CTS_Core and validate signature
    return true

func _check_autoload_order() -> void:
    # Warn if CTS_Core is not first autoload
    # This is informational only, not fatal
    var autoloads: Array = ProjectSettings.get_setting("autoload", [])
    if autoloads.size() > 0:
        # Check if first autoload is CTS_Core
        var first_autoload: String = ""
        for key in autoloads:
            first_autoload = key
            break
        
        if first_autoload != "" and first_autoload != AUTOLOAD_NAME:
            push_warning("[CTS Core] Recommended: CTS_Core should be first autoload for proper initialization order")

func _get_signature() -> String:
    # Import constants to get signature
    var constants_script := preload("res://addons/cts_core/Data/core_constants.gd")
    return constants_script.CORE_SIGNATURE

## TEMPLATE: Other CTS addons should use this pattern:
##
## const EXPECTED_CORE_SIGNATURE := "CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"
## 
## func _enable_plugin() -> void:
##     if not Engine.has_singleton("CTS_Core"):
##         push_error("%s requires CTS_Core addon" % AUTOLOAD_NAME)
##         return
##     
##     var core_sig: String = CTS_Core.get_signature()
##     if core_sig != EXPECTED_CORE_SIGNATURE:
##         push_error("%s signature mismatch. Expected: %s, Found: %s" % [AUTOLOAD_NAME, EXPECTED_CORE_SIGNATURE, core_sig])
##         push_error("Disable and re-enable CTS_Core addon to update signature")
##         return
##     
##     # Safe to proceed...