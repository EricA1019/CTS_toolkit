extends Node

## Base Component
## Foundation for composition-based component architecture
## NO class_name (loose coupling - child classes add as needed)
## Docs: See docs/API_REFERENCE.md#base-component

# ============================================================
# SIGNALS (See docs/SIGNAL_CONTRACTS.md)
# ============================================================

signal component_ready(component_type: String)
signal component_initialized(component_type: String)
signal component_error(error_code: int, message: String)
signal component_cleanup_started(component_type: String)

# ============================================================
# PROPERTIES
# ============================================================

@export var component_type: String = ""
var is_initialized: bool = false
var is_enabled: bool = true

# Private properties
var _state: int = 0  # CoreConstants.ComponentState
var _owner_node: Node = null

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
    # Validate component_type
    if component_type.is_empty():
        _emit_error(1, "component_type cannot be empty")  # ERR_COMPONENT_INVALID
        _state = 3  # ERROR
        return
    
    # Set state
    _state = 1  # INITIALIZING
    
    # Store owner reference
    _owner_node = get_parent()
    
    # Register with CTS_Core
    var core_manager: Node = get_node_or_null("/root/CTS_Core")
    if core_manager:
        if not core_manager.register_component(self):
            _emit_error(8, "Failed to register component with CTS_Core")  # ERR_ALREADY_EXISTS
            _state = 3  # ERROR
            return
    else:
        push_warning("[BaseComponent] CTS_Core not found - component will not be registered")
    
    # Call initialize (override in child classes)
    initialize()

## Override in child classes for custom initialization
func initialize() -> void:
    component_initialized.emit(component_type)
    is_initialized = true
    _state = 2  # READY
    component_ready.emit(component_type)

## Override in child classes for custom cleanup
func cleanup() -> void:
    component_cleanup_started.emit(component_type)
    _state = 4  # CLEANING_UP
    
    # Unregister from CTS_Core
    var core_manager: Node = get_node_or_null("/root/CTS_Core")
    if core_manager:
        core_manager.unregister_component(self)
    
    is_initialized = false

## Called before component is freed
func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if is_initialized:
            cleanup()

# ============================================================
# PUBLIC API
# ============================================================

## Check if component configuration is valid
func validate_configuration() -> bool:
    if component_type.is_empty():
        return false
    
    var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
    if component_type.length() > Constants.COMPONENT_TYPE_MAX_LENGTH:
        return false
    
    return true

## Enable or disable component at runtime
func set_enabled(enabled: bool) -> void:
    is_enabled = enabled

## Get current component state
func get_state() -> int:
    return _state

## Get component type (convenience method)
func get_component_type() -> String:
    return component_type

## Get owner node (parent)
func get_owner_node() -> Node:
    return _owner_node

## Check if component is in READY state
func is_ready() -> bool:
    return _state == 2  # CoreConstants.ComponentState.READY

## Check if component is in ERROR state
func has_error() -> bool:
    return _state == 3  # CoreConstants.ComponentState.ERROR

# ============================================================
# PRIVATE HELPERS
# ============================================================

func _emit_error(code: int, message: String) -> void:
    component_error.emit(code, message)
    var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
    push_error("[BaseComponent:%s] Error %d: %s" % [component_type, code, message])