extends Node

## Base Factory
## Factory pattern for creating Resources and Nodes with caching
## Docs: See docs/API_REFERENCE.md#base-factory

# ============================================================
# SIGNALS (See docs/SIGNAL_CONTRACTS.md)
# ============================================================

signal resource_created(resource_type: String, resource: Resource)
signal node_instantiated(scene_path: String, node: Node)
signal cache_hit(path: String)
signal cache_miss(path: String)
signal cache_cleared()
signal factory_error(error_code: int, context: Dictionary)

# ============================================================
# PROPERTIES
# ============================================================

var _resource_cache: Dictionary = {}  # path: String -> CacheEntry
var _instantiated_nodes: Array[Node] = []
var _config = null  # FactoryConfig

# ============================================================
# LIFECYCLE
# ============================================================

func _init(config = null) -> void:  # Takes FactoryConfig or null
    if config != null:
        _config = config
    else:
        var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
        _config = TypeDefs.FactoryConfig.create_default()

# ============================================================
# PUBLIC API - Resource Creation
# ============================================================

## Create and configure resource
func create_resource(type: String, config: Dictionary) -> Resource:
    # This is a generic factory method - override for specific resource types
    # Or use as template for child classes
    push_warning("[BaseFactory] create_resource() should be overridden in child classes")
    return null

## Load and cache resource from path
func cache_resource(path: String) -> Resource:
    if not _config.cache_enabled:
        # Caching disabled, load directly
        cache_miss.emit(path)
        return _load_resource(path)
    
    # Check cache
    if _resource_cache.has(path):
        var entry = _resource_cache[path]  # CacheEntry
        
        # Check if expired
        var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
        if entry.is_expired(_config.cache_timeout_ms):
            # Expired, reload
            _resource_cache.erase(path)
            cache_miss.emit(path)
            return _cache_and_load(path)
        
        # Cache hit
        entry.access()
        cache_hit.emit(path)
        return entry.cached_resource
    
    # Cache miss
    cache_miss.emit(path)
    return _cache_and_load(path)

## Get cached resource without loading
func get_cached_resource(path: String) -> Resource:
    if _resource_cache.has(path):
        return _resource_cache[path].cached_resource
    return null

## Clear all cached resources
func clear_cache() -> void:
    _resource_cache.clear()
    cache_cleared.emit()

## Get cache size
func get_cache_size() -> int:
    return _resource_cache.size()

## Get cache count (alias)
func get_cached_count() -> int:
    return get_cache_size()

# ============================================================
# PUBLIC API - Node Creation
# ============================================================

## Instantiate scene and optionally add to parent
func create_node(scene_path: String, parent: Node = null) -> Node:
    var scene: PackedScene = _load_resource(scene_path) as PackedScene
    
    if scene == null:
        _emit_error(4, {"message": "Failed to load scene", "path": scene_path})  # ERR_CACHE_MISS
        return null
    
    var node: Node = scene.instantiate()
    if node == null:
        _emit_error(1, {"message": "Failed to instantiate scene", "path": scene_path})  # ERR_COMPONENT_INVALID
        return null
    
    # Track instantiated node
    _instantiated_nodes.append(node)
    
    # Add to parent if provided
    if parent != null and is_instance_valid(parent):
        parent.add_child(node)
    
    node_instantiated.emit(scene_path, node)
    return node

# ============================================================
# PUBLIC API - Configuration
# ============================================================

## Update factory configuration
func set_config(config) -> void:  # Takes FactoryConfig
    _config = config

## Get current configuration
func get_config():  # Returns FactoryConfig
    return _config

# ============================================================
# PRIVATE HELPERS
# ============================================================

func _load_resource(path: String) -> Resource:
    if not ResourceLoader.exists(path):
        _emit_error(7, {"message": "Resource not found", "path": path})  # ERR_NOT_FOUND
        return null
    
    var resource: Resource = load(path)
    if resource == null:
        _emit_error(4, {"message": "Failed to load resource", "path": path})  # ERR_CACHE_MISS
    
    return resource

func _cache_and_load(path: String) -> Resource:
    var resource: Resource = _load_resource(path)
    if resource == null:
        return null
    
    # Check cache size limit
    if _resource_cache.size() >= _config.max_cache_size:
        _evict_oldest_cache_entry()
    
    # Add to cache
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    var entry = TypeDefs.CacheEntry.new(path, resource)
    _resource_cache[path] = entry
    
    return resource

func _evict_oldest_cache_entry() -> void:
    # Simple LRU: remove oldest last_access_time
    var oldest_path: String = ""
    var oldest_time: int = 999999999999
    
    for path in _resource_cache.keys():
        var entry = _resource_cache[path]
        if entry.last_access_time < oldest_time:
            oldest_time = entry.last_access_time
            oldest_path = path
    
    if oldest_path != "":
        _resource_cache.erase(oldest_path)

func _emit_error(code: int, context: Dictionary) -> void:
    factory_error.emit(code, context)
    var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
    var msg: String = context.get("message", "Unknown error")
    push_error("[BaseFactory] Error %d: %s" % [code, msg])