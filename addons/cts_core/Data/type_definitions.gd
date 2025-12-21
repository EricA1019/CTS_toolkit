extends Node

## CTS Core Type Definitions
## Typed data structures for type-safe APIs
## Docs: See docs/API_REFERENCE.md#type-definitions

# ============================================================
# COMPONENT METADATA
# ============================================================

## Metadata tracked for each registered component
class ComponentMetadata:
    var component_type: String = ""
    var registration_time: int = 0  # Time.get_ticks_msec()
    var owner_path: NodePath = NodePath()
    var is_valid: bool = true
    var state: int = 0  # CoreConstants.ComponentState
    
    func _init(type: String = "", owner: NodePath = NodePath()) -> void:
        component_type = type
        owner_path = owner
        registration_time = Time.get_ticks_msec()

# ============================================================
# FACTORY CACHE
# ============================================================

## Cache entry for factory resource caching
class CacheEntry:
    var resource_path: String = ""
    var cached_resource: Resource = null
    var access_count: int = 0
    var last_access_time: int = 0  # Time.get_ticks_msec()
    var creation_time: int = 0
    
    func _init(path: String = "", resource: Resource = null) -> void:
        resource_path = path
        cached_resource = resource
        creation_time = Time.get_ticks_msec()
        last_access_time = creation_time
    
    func access() -> void:
        access_count += 1
        last_access_time = Time.get_ticks_msec()
    
    func is_expired(timeout_ms: float) -> bool:
        var elapsed: float = Time.get_ticks_msec() - last_access_time
        return elapsed > timeout_ms

# ============================================================
# PROCESSOR STATS
# ============================================================

## Processing statistics for performance monitoring
class ProcessingStats:
    var items_processed: int = 0
    var elapsed_ms: float = 0.0
    var budget_exceeded: bool = false
    var frame_count: int = 0
    var total_items: int = 0
    
    func reset() -> void:
        items_processed = 0
        elapsed_ms = 0.0
        budget_exceeded = false
        frame_count = 0
        total_items = 0
    
    func record_frame(processed: int, elapsed: float, budget: float, total: int) -> void:
        items_processed += processed
        elapsed_ms = elapsed
        budget_exceeded = elapsed > budget
        frame_count += 1
        total_items = total

# ============================================================
# VALIDATION RESULT
# ============================================================

## Result of resource validation with errors and warnings
class ValidationResult:
    var is_valid: bool = true
    var errors: Array[String] = []
    var warnings: Array[String] = []
    var info: Array[String] = []
    
    func add_error(message: String) -> void:
        errors.append(message)
        is_valid = false
    
    func add_warning(message: String) -> void:
        warnings.append(message)
    
    func add_info(message: String) -> void:
        info.append(message)
    
    func has_errors() -> bool:
        return errors.size() > 0
    
    func has_warnings() -> bool:
        return warnings.size() > 0
    
    func get_all_messages() -> Array[String]:
        var all: Array[String] = []
        all.append_array(errors)
        all.append_array(warnings)
        all.append_array(info)
        return all

# ============================================================
# ERROR CONTEXT
# ============================================================

## Detailed error information for debugging
class ErrorContext:
    var error_code: int = 0  # CoreConstants.ErrorCode
    var message: String = ""
    var stack_trace_ref: String = ""  # File:line reference
    var timestamp: int = 0
    var additional_data: Dictionary = {}
    
    func _init(code: int = 0, msg: String = "") -> void:
        error_code = code
        message = msg
        timestamp = Time.get_ticks_msec()
    
    func to_string() -> String:
        return "[Error %d] %s at %s (timestamp: %d)" % [error_code, message, stack_trace_ref, timestamp]

# ============================================================
# REGISTRY QUERY
# ============================================================

## Query parameters for component registry searches
class RegistryQuery:
    var component_type: String = ""  # Filter by type (empty = all)
    var owner_path: NodePath = NodePath()  # Filter by owner (empty = all)
    var filter_callback: Callable = Callable()  # Custom filter function
    var max_results: int = -1  # -1 = unlimited
    var include_invalid: bool = false  # Include invalid components
    
    func _init(type: String = "") -> void:
        component_type = type
    
    func matches(component: Node, metadata: ComponentMetadata) -> bool:
        # Type filter
        if component_type != "" and metadata.component_type != component_type:
            return false
        
        # Owner filter
        if owner_path != NodePath() and metadata.owner_path != owner_path:
            return false
        
        # Validity filter
        if not include_invalid and not metadata.is_valid:
            return false
        
        # Custom filter
        if filter_callback.is_valid():
            return filter_callback.call(component, metadata)
        
        return true

# ============================================================
# FACTORY CONFIG
# ============================================================

## Configuration for BaseFactory behavior
class FactoryConfig:
    var pool_enabled: bool = false
    var cache_enabled: bool = true
    var max_cache_size: int = 100
    var cache_timeout_ms: float = 60000.0
    var pooling_mode: int = 0  # CoreConstants.FactoryPooling
    var auto_cleanup: bool = true  # Auto-free old cache entries
    
    func _init() -> void:
        # Default values set above
        pass
    
    static func create_default() -> FactoryConfig:
        return FactoryConfig.new()
    
    static func create_aggressive() -> FactoryConfig:
        var config := FactoryConfig.new()
        config.pool_enabled = true
        config.pooling_mode = 2  # CoreConstants.FactoryPooling.AGGRESSIVE
        config.max_cache_size = 200
        return config

# ============================================================
# PROCESSOR CONFIG
# ============================================================

## Configuration for BaseProcessor behavior
class ProcessorConfig:
    var frame_budget_ms: float = 2.0
    var processing_mode: int = 0  # CoreConstants.ProcessingMode.IDLE
    var auto_start: bool = true
    var max_items_per_frame: int = 100
    var deterministic: bool = false  # Use fixed seed for testing
    var random_seed: int = 0  # Seed for deterministic processing
    
    func _init() -> void:
        # Default values set above
        pass
    
    static func create_default() -> ProcessorConfig:
        return ProcessorConfig.new()
    
    static func create_physics() -> ProcessorConfig:
        var config := ProcessorConfig.new()
        config.processing_mode = 1  # CoreConstants.ProcessingMode.PHYSICS
        return config
    
    static func create_deterministic(seed: int = 12345) -> ProcessorConfig:
        var config := ProcessorConfig.new()
        config.deterministic = true
        config.random_seed = seed
        return config

# ============================================================
# PERFORMANCE SAMPLE
# ============================================================

## Performance profiling sample for benchmarking
class PerformanceSample:
    var operation: String = ""
    var elapsed_ms: float = 0.0
    var budget_exceeded: bool = false
    var item_count: int = 0
    var timestamp: int = 0
    var additional_metrics: Dictionary = {}
    
    func _init(op: String = "") -> void:
        operation = op
        timestamp = Time.get_ticks_msec()
    
    func record(elapsed: float, budget: float, items: int = 0) -> void:
        elapsed_ms = elapsed
        budget_exceeded = elapsed > budget
        item_count = items
    
    func to_string() -> String:
        var status := "OK" if not budget_exceeded else "EXCEEDED"
        return "%s: %.2fms (%d items) [%s]" % [operation, elapsed_ms, item_count, status]