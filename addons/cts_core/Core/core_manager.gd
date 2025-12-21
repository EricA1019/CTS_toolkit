extends Node

## CTS Core Manager
## Central registry and discovery system for all components
## Registered as autoload: CTS_Core
## Docs: See docs/API_REFERENCE.md#core-manager

# ============================================================
# SIGNALS (See docs/SIGNAL_CONTRACTS.md)
# ============================================================

signal manager_initialized()
signal signature_mismatch_detected(expected: String, actual: String)
signal component_registered(component_type: String, component: Node)
signal component_unregistered(component_type: String)
signal registry_full()

# ============================================================
# CONSTANTS
# ============================================================

const CORE_SIGNATURE: String = "CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"
const addon_version: String = "0.0.0.1"

# ============================================================
# PRIVATE PROPERTIES
# ============================================================

var _registry: Dictionary = {}  # component_type: String -> Array[Node]
var _metadata: Dictionary = {}  # component instance -> ComponentMetadata
var _is_initialized: bool = false

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
    _is_initialized = true
    manager_initialized.emit()
    print("[CTS Core] Manager initialized - Signature: %s" % CORE_SIGNATURE)

# ============================================================
# PUBLIC API - Signature Validation
# ============================================================

## Get authoritative signature for version validation
func get_signature() -> String:
    return CORE_SIGNATURE

## Validate addon signature matches expected
## Emits signature_mismatch_detected if mismatch
func validate_signature(expected: String) -> bool:
    if expected != CORE_SIGNATURE:
        signature_mismatch_detected.emit(expected, CORE_SIGNATURE)
        return false
    return true

# ============================================================
# PUBLIC API - Component Registration
# ============================================================

## Register component in registry
## Returns true if successful, false if failed
func register_component(component: Node) -> bool:
    if not is_instance_valid(component):
        push_error("[CTS Core] Cannot register null/invalid component")
        return false
    
    # Get component type
    var comp_type: String = component.get("component_type")
    if comp_type == null or comp_type == "":
        push_error("[CTS Core] Component missing 'component_type' property: %s" % component.get_path())
        return false
    
    # Check component type length
    if comp_type.length() > preload("res://addons/cts_core/Data/core_constants.gd").COMPONENT_TYPE_MAX_LENGTH:
        push_error("[CTS Core] Component type too long (max %d): %s" % [preload("res://addons/cts_core/Data/core_constants.gd").COMPONENT_TYPE_MAX_LENGTH, comp_type])
        return false
    
    # Check registry capacity
    var total_components: int = get_component_count()
    if total_components >= preload("res://addons/cts_core/Data/core_constants.gd").MAX_REGISTERED_COMPONENTS:
        registry_full.emit()
        push_error("[CTS Core] Registry full (max %d components)" % preload("res://addons/cts_core/Data/core_constants.gd").MAX_REGISTERED_COMPONENTS)
        return false
    
    # Initialize type array if needed
    if not _registry.has(comp_type):
        _registry[comp_type] = []
    
    # Check for duplicate registration
    if component in _registry[comp_type]:
        push_warning("[CTS Core] Component already registered: %s" % component.get_path())
        return false
    
    # Add to registry
    _registry[comp_type].append(component)
    
    # Create metadata
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    var metadata = TypeDefs.ComponentMetadata.new(comp_type, component.get_path())
    _metadata[component] = metadata
    
    # Emit signal
    component_registered.emit(comp_type, component)
    
    return true

## Unregister component from registry
## Returns true if successful, false if not found
func unregister_component(component: Node) -> bool:
    if not is_instance_valid(component):
        return false
    
    # Find component type
    var comp_type: String = ""
    if _metadata.has(component):
        comp_type = _metadata[component].component_type
    else:
        # Fallback: search all registry entries
        for type in _registry.keys():
            if component in _registry[type]:
                comp_type = type
                break
    
    if comp_type == "":
        return false
    
    # Remove from registry
    if _registry.has(comp_type):
        var idx: int = _registry[comp_type].find(component)
        if idx >= 0:
            _registry[comp_type].remove_at(idx)
            
            # Clean up empty type arrays
            if _registry[comp_type].is_empty():
                _registry.erase(comp_type)
    
    # Remove metadata
    if _metadata.has(component):
        _metadata.erase(component)
    
    # Emit signal
    component_unregistered.emit(comp_type)
    
    return true

# ============================================================
# PUBLIC API - Component Queries
# ============================================================

## Get all components of specific type
## Returns Array[Node] (may be empty)
func get_components_by_type(type: String) -> Array[Node]:
    if not _registry.has(type):
        return []
    
    # Clean up invalid components
    var valid_components: Array[Node] = []
    for comp in _registry[type]:
        if is_instance_valid(comp):
            valid_components.append(comp)
    
    # Update registry with cleaned list
    if valid_components.size() != _registry[type].size():
        _registry[type] = valid_components
    
    return valid_components

## Find first component of type attached to owner
## Returns component or null if not found
func find_component(owner: Node, type: String) -> Node:
    if not is_instance_valid(owner):
        return null
    
    var components: Array[Node] = get_components_by_type(type)
    var owner_path: NodePath = owner.get_path()
    
    for comp in components:
        if is_instance_valid(comp):
            var comp_parent := comp.get_parent()
            if is_instance_valid(comp_parent) and comp_parent.get_path() == owner_path:
                return comp
    
    return null

## Get all registered component types
## Returns Array[String]
func get_all_registered_types() -> Array[String]:
    var types: Array[String] = []
    for type in _registry.keys():
        types.append(type)
    types.sort()
    return types

## Get total number of registered components
func get_component_count() -> int:
    var count: int = 0
    for type in _registry.keys():
        count += _registry[type].size()
    return count

## Get component count for specific type
func get_component_count_by_type(type: String) -> int:
    if not _registry.has(type):
        return 0
    return _registry[type].size()

## Check if component is registered
func is_component_registered(component: Node) -> bool:
    return _metadata.has(component)

## Get metadata for component
func get_component_metadata(component: Node):  # Returns ComponentMetadata or null
    if _metadata.has(component):
        return _metadata[component]
    return null

# ============================================================
# PUBLIC API - Advanced Queries (Phase 1 Stretch Goal)
# ============================================================

## Query components with custom filter
## Returns Array[Node] matching query criteria
func query_components(query) -> Array[Node]:  # Takes RegistryQuery
    var results: Array[Node] = []
    var max_results: int = query.max_results if query.max_results > 0 else 999999
    
    for type in _registry.keys():
        if results.size() >= max_results:
            break
        
        for comp in _registry[type]:
            if not is_instance_valid(comp):
                continue
            
            var metadata = _metadata.get(comp)
            if metadata and query.matches(comp, metadata):
                results.append(comp)
                
                if results.size() >= max_results:
                    break
    
    return results

## Batch register multiple components
## Returns number of successful registrations
func batch_register(components: Array[Node]) -> int:
    var success_count: int = 0
    for comp in components:
        if register_component(comp):
            success_count += 1
    return success_count

# ============================================================
# DEBUG / ANALYTICS
# ============================================================

## Get registry statistics for debugging
func get_registry_stats() -> Dictionary:
    return {
        "total_components": get_component_count(),
        "total_types": _registry.size(),
        "types": get_all_registered_types(),
        "is_initialized": _is_initialized,
        "signature": CORE_SIGNATURE,
        "version": addon_version
    }