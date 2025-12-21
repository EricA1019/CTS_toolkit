extends Resource

## Base Resource
## Custom Resource with validation and type safety
## NO signals (resources can't emit - not in scene tree)
## Docs: See docs/API_REFERENCE.md#base-resource

# ============================================================
# PROPERTIES
# ============================================================

@export var resource_id: StringName = &""
@export var resource_version: int = 1

# Private properties
var _validation_cache: Variant = null  # ValidationResult or null

# ============================================================
# VALIDATION API
# ============================================================

## Validate resource and update cache
## Returns true if valid, false if errors found
func validate() -> bool:
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    _validation_cache = TypeDefs.ValidationResult.new()
    
    # Check resource_id
    var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
    if resource_id == &"" or resource_id.length() < Constants.RESOURCE_ID_MIN_LENGTH:
        _validation_cache.add_error("resource_id is required and must be at least %d character(s)" % Constants.RESOURCE_ID_MIN_LENGTH)
    
    # Check resource_version
    if resource_version < Constants.RESOURCE_VERSION_MIN:
        _validation_cache.add_error("resource_version must be >= %d" % Constants.RESOURCE_VERSION_MIN)
    
    # Override in child classes for additional validation
    _validate_custom()
    
    return _validation_cache.is_valid

## Override in child classes for custom validation logic
func _validate_custom() -> void:
    # Override in child classes
    pass

## Get validation errors from last validate() call
func get_validation_errors() -> Array[String]:
    if _validation_cache == null:
        return []
    return _validation_cache.errors

## Get validation warnings from last validate() call
func get_validation_warnings() -> Array[String]:
    if _validation_cache == null:
        return []
    return _validation_cache.warnings

## Get complete validation result
func get_validation_result():  # Returns ValidationResult or null
    return _validation_cache

## Check if resource is valid (read-only property)
func is_valid() -> bool:
    if _validation_cache == null:
        # Auto-validate on first access
        return validate()
    return _validation_cache.is_valid

# ============================================================
# RESOURCE OPERATIONS
# ============================================================

## Reset resource to default values
## Override in child classes
func reset_to_defaults() -> void:
    resource_id = &""
    resource_version = 1
    _validation_cache = null

## Create type-safe duplicate of resource
func duplicate_resource() -> Resource:
    return duplicate(true)

## Compare resources for equality
## Override in child classes for deep comparison
func equals(other: Resource) -> bool:
    if other == null:
        return false
    
    # Compare scripts explicitly (operator `is` cannot take expressions)
    if other.get_script() != get_script():
        return false
    
    return other.resource_id == resource_id and other.resource_version == resource_version

# ============================================================
# SERIALIZATION HELPERS
# ============================================================

## Get dictionary representation for debugging
func to_dict() -> Dictionary:
    return {
        "resource_id": resource_id,
        "resource_version": resource_version,
        "is_valid": is_valid()
    }

## Load from dictionary (basic implementation)
func from_dict(data: Dictionary) -> void:
    if data.has("resource_id"):
        resource_id = data["resource_id"]
    if data.has("resource_version"):
        resource_version = data["resource_version"]
    
    _validation_cache = null  # Invalidate cache