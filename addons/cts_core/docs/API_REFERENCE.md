# CTS Core - API Reference

> **Version**: 0.0.0.1  
> **Signature**: `CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000`

## Table of Contents

1. [CoreManager (Autoload: CTS_Core)](#coremanager)
2. [BaseComponent](#basecomponent)
3. [BaseFactory](#basefactory)
4. [BaseProcessor](#baseprocessor)
5. [BaseResource](#baseresource)
6. [Type Definitions](#type-definitions)
7. [Core Constants](#core-constants)

---

## CoreManager

**Path**: `addons/cts_core/Core/core_manager.gd`  
**Autoload Name**: `CTS_Core`  
**Purpose**: Central registry and discovery system for all components

### Signals

See [SIGNAL_CONTRACTS.md](SIGNAL_CONTRACTS.md) for detailed signal documentation.

```gdscript
signal manager_initialized()
signal signature_mismatch_detected(expected: String, actual: String)
signal component_registered(component_type: String, component: Node)
signal component_unregistered(component_type: String)
signal registry_full()
```

### Properties

```gdscript
const CORE_SIGNATURE: String  # "CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"
const addon_version: String   # "0.0.0.1"
```

### Signature Validation API

#### `get_signature() -> String`
Returns the authoritative signature for version validation.

**Returns**: Signature string

**Example**:
```gdscript
var signature: String = CTS_Core.get_signature()
print(signature)  # "CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"
```

#### `validate_signature(expected: String) -> bool`
Validates that the expected signature matches the core signature. Emits `signature_mismatch_detected` signal if mismatch occurs.

**Parameters**:
- `expected: String` - Expected signature to validate

**Returns**: `true` if signatures match, `false` otherwise

**Example**:
```gdscript
var is_valid: bool = CTS_Core.validate_signature("CTS_CORE:0.0.0.1:...")
if not is_valid:
    push_error("Signature mismatch!")
```

### Component Registration API

#### `register_component(component: Node) -> bool`
Registers a component with the core manager. Component must have `component_type` property.

**Parameters**:
- `component: Node` - Component to register (must have `component_type: String` property)

**Returns**: `true` if registration successful, `false` if failed

**Failure Conditions**:
- Component is null or invalid
- Missing `component_type` property
- `component_type` is empty or too long (>64 chars)
- Registry is full (>1000 components)
- Component already registered

**Emits**: `component_registered(component_type, component)` on success

**Example**:
```gdscript
var component = BaseComponent.new()
component.component_type = "HealthComponent"
if CTS_Core.register_component(component):
    print("Registered successfully")
```

#### `unregister_component(component: Node) -> bool`
Unregisters a component from the registry.

**Parameters**:
- `component: Node` - Component to unregister

**Returns**: `true` if unregistration successful, `false` if component not found

**Emits**: `component_unregistered(component_type)` on success

**Example**:
```gdscript
CTS_Core.unregister_component(my_component)
```

### Component Query API

#### `get_components_by_type(type: String) -> Array[Node]`
Retrieves all registered components of a specific type. Automatically cleans up invalid components.

**Parameters**:
- `type: String` - Component type to search for

**Returns**: Array of components (may be empty)

**Example**:
```gdscript
var health_components: Array[Node] = CTS_Core.get_components_by_type("HealthComponent")
for comp in health_components:
    print(comp.get_path())
```

#### `find_component(owner: Node, type: String) -> Node`
Finds the first component of the specified type attached to the owner node.

**Parameters**:
- `owner: Node` - Parent node to search
- `type: String` - Component type to find

**Returns**: First matching component or `null` if not found

**Example**:
```gdscript
var player = get_node("Player")
var health_comp = CTS_Core.find_component(player, "HealthComponent")
if health_comp:
    print("Health: ", health_comp.current_health)
```

#### `get_all_registered_types() -> Array[String]`
Returns sorted array of all registered component types.

**Returns**: Array of component type strings (sorted alphabetically)

**Example**:
```gdscript
var types: Array[String] = CTS_Core.get_all_registered_types()
print("Registered types: ", types)
```

#### `get_component_count() -> int`
Returns total number of registered components across all types.

**Returns**: Total component count

**Example**:
```gdscript
var total: int = CTS_Core.get_component_count()
print("Total components: ", total)
```

#### `get_component_count_by_type(type: String) -> int`
Returns number of components registered for a specific type.

**Parameters**:
- `type: String` - Component type to count

**Returns**: Component count for type

**Example**:
```gdscript
var count: int = CTS_Core.get_component_count_by_type("HealthComponent")
print("Health components: ", count)
```

#### `is_component_registered(component: Node) -> bool`
Checks if a component is currently registered.

**Parameters**:
- `component: Node` - Component to check

**Returns**: `true` if registered, `false` otherwise

**Example**:
```gdscript
if CTS_Core.is_component_registered(my_component):
    print("Component is registered")
```

#### `get_component_metadata(component: Node) -> ComponentMetadata`
Retrieves metadata for a registered component.

**Parameters**:
- `component: Node` - Component to query

**Returns**: `ComponentMetadata` object or `null` if not found

**Example**:
```gdscript
var metadata = CTS_Core.get_component_metadata(my_component)
if metadata:
    print("Type: ", metadata.component_type)
    print("Registration time: ", metadata.registration_timestamp)
```

### Advanced Query API

#### `query_components(query: RegistryQuery) -> Array[Node]`
Queries components using custom filter criteria.

**Parameters**:
- `query: RegistryQuery` - Query object with filter criteria

**Returns**: Array of components matching query

**Example**:
```gdscript
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
var query = TypeDefs.RegistryQuery.new()
query.component_type = "HealthComponent"
query.max_results = 10

var results: Array[Node] = CTS_Core.query_components(query)
```

#### `batch_register(components: Array[Node]) -> int`
Registers multiple components in one operation.

**Parameters**:
- `components: Array[Node]` - Array of components to register

**Returns**: Number of successful registrations

**Example**:
```gdscript
var components: Array[Node] = [comp1, comp2, comp3]
var success_count: int = CTS_Core.batch_register(components)
print("Registered: %d/%d" % [success_count, components.size()])
```

### Debug API

#### `get_registry_stats() -> Dictionary`
Returns registry statistics for debugging.

**Returns**: Dictionary with keys:
- `total_components: int` - Total registered components
- `total_types: int` - Number of unique types
- `types: Array[String]` - List of all types
- `is_initialized: bool` - Manager initialization status
- `signature: String` - Core signature
- `version: String` - Addon version

**Example**:
```gdscript
var stats: Dictionary = CTS_Core.get_registry_stats()
print("Stats: ", JSON.stringify(stats, "\t"))
```

---

## BaseComponent

**Path**: `addons/cts_core/Core/base_component.gd`  
**Base Class**: `Node`  
**Purpose**: Foundation for composition-based component architecture with auto-registration

### Signals

```gdscript
signal component_ready(component_type: String)
signal component_initialized(component_type: String)
signal component_error(error_code: int, message: String)
signal component_cleanup_started(component_type: String)
```

### Properties

```gdscript
@export var component_type: String = ""  # Required - component identifier
var is_initialized: bool = false         # Initialization state
var is_enabled: bool = true              # Enable/disable component
```

### Lifecycle Methods

#### `initialize() -> void`
**Override Point**: Implement custom initialization logic in child classes.

Called automatically after component is added to scene tree and registered with CTS_Core.

**Default Behavior**:
- Emits `component_initialized(component_type)`
- Sets `is_initialized = true`
- Changes state to READY
- Emits `component_ready(component_type)`

**Example**:
```gdscript
extends "res://addons/cts_core/Core/base_component.gd"

func initialize() -> void:
    super.initialize()  # Call parent first
    
    # Custom initialization
    _setup_health_values()
    _connect_damage_signals()
```

#### `cleanup() -> void`
**Override Point**: Implement custom cleanup logic in child classes.

Called before component is freed. Automatically unregisters from CTS_Core.

**Default Behavior**:
- Emits `component_cleanup_started(component_type)`
- Changes state to CLEANING_UP
- Unregisters from CTS_Core
- Sets `is_initialized = false`

**Example**:
```gdscript
func cleanup() -> void:
    _disconnect_signals()
    _clear_cached_data()
    
    super.cleanup()  # Call parent last
```

### Public API

#### `enable() -> void`
Enables the component. Override `_on_enabled()` for custom behavior.

**Example**:
```gdscript
my_component.enable()
```

#### `disable() -> void`
Disables the component. Override `_on_disabled()` for custom behavior.

**Example**:
```gdscript
my_component.disable()
```

#### `get_state() -> int`
Returns current component state from `CoreConstants.ComponentState` enum.

**Returns**: State enum value (CREATED=0, INITIALIZING=1, READY=2, ERROR=3, CLEANING_UP=4)

#### `get_owner_node() -> Node`
Returns the parent node that owns this component.

**Returns**: Owner node or `null`

---

## BaseFactory

**Path**: `addons/cts_core/Core/base_factory.gd`  
**Base Class**: `Node`  
**Purpose**: Factory pattern for creating Resources and Nodes with LRU caching

### Signals

```gdscript
signal resource_created(resource_type: String, resource: Resource)
signal node_instantiated(scene_path: String, node: Node)
signal cache_hit(path: String)
signal cache_miss(path: String)
signal cache_cleared()
signal factory_error(error_code: int, context: Dictionary)
```

### Constructor

```gdscript
func _init(config: FactoryConfig = null) -> void
```

**Parameters**:
- `config: FactoryConfig` - Optional configuration (creates default if null)

### Resource Caching API

#### `cache_resource(path: String) -> Resource`
Loads and caches a resource with LRU eviction. Checks cache first, loads if miss.

**Parameters**:
- `path: String` - Resource path (e.g., "res://items/sword.tres")

**Returns**: Loaded resource or `null` if load failed

**Emits**: `cache_hit(path)` or `cache_miss(path)`

**Example**:
```gdscript
var sword = factory.cache_resource("res://items/sword.tres")
if sword:
    print("Loaded: ", sword.resource_id)
```

#### `get_cached_resource(path: String) -> Resource`
Retrieves cached resource without loading.

**Parameters**:
- `path: String` - Resource path

**Returns**: Cached resource or `null` if not cached

**Example**:
```gdscript
var cached_sword = factory.get_cached_resource("res://items/sword.tres")
if cached_sword == null:
    print("Not in cache")
```

#### `clear_cache() -> void`
Clears all cached resources.

**Emits**: `cache_cleared()`

**Example**:
```gdscript
factory.clear_cache()
```

#### `get_cache_size() -> int`
Returns number of cached resources.

**Returns**: Cache size

**Example**:
```gdscript
print("Cache contains %d resources" % factory.get_cache_size())
```

#### `get_cached_count() -> int`
Alias for `get_cache_size()`.

### Node Instantiation API

#### `create_node(scene_path: String, parent: Node = null) -> Node`
Instantiates a scene and optionally adds to parent.

**Parameters**:
- `scene_path: String` - Path to .tscn file
- `parent: Node` - Optional parent to add node to

**Returns**: Instantiated node or `null` if failed

**Emits**: `node_instantiated(scene_path, node)`

**Example**:
```gdscript
var enemy = factory.create_node("res://enemies/goblin.tscn", get_node("Enemies"))
if enemy:
    enemy.position = Vector2(100, 100)
```

#### `create_resource(type: String, config: Dictionary) -> Resource`
**Override Point**: Generic resource creation method. Override in child classes for specific resource types.

**Parameters**:
- `type: String` - Resource type identifier
- `config: Dictionary` - Configuration data

**Returns**: Created resource

---

## BaseProcessor

**Path**: `addons/cts_core/Core/base_processor.gd`  
**Base Class**: `Node`  
**Purpose**: Processing loop with frame budget enforcement

### Signals

```gdscript
signal processing_started()
signal processing_completed(items_processed: int)
signal budget_exceeded(elapsed_ms: float)
signal item_added(item: Variant)
signal item_removed(item: Variant)
```

### Constructor

```gdscript
func _init(config: ProcessorConfig = null) -> void
```

**Parameters**:
- `config: ProcessorConfig` - Optional configuration (creates default if null)

### Processing API

#### `process_items(delta: float) -> void`
**Override Point**: Main processing loop. Called automatically based on `processing_mode`.

**Parameters**:
- `delta: float` - Delta time since last frame

**Default Behavior**:
- Processes items up to `max_items_per_frame`
- Calls `_process_item(item, delta)` for each item
- Enforces frame budget (`frame_budget_ms`)
- Emits `budget_exceeded(elapsed_ms)` if budget exceeded
- Updates processing statistics

**Emits**:
- `processing_started()` at start
- `processing_completed(items_processed)` at end
- `budget_exceeded(elapsed_ms)` if budget exceeded

**Example**:
```gdscript
extends "res://addons/cts_core/Core/base_processor.gd"

func _process_item(item: Variant, delta: float) -> void:
    # Process individual item
    var entity = item as Node
    entity.update_ai(delta)
```

#### `pause() -> void`
Pauses processing. Items remain in queue.

**Example**:
```gdscript
processor.pause()
```

#### `resume() -> void`
Resumes processing.

**Example**:
```gdscript
processor.resume()
```

#### `is_paused() -> bool`
Checks if processor is paused.

**Returns**: `true` if paused, `false` otherwise

### Item Management API

#### `add_item(item: Variant) -> void`
Adds item to processing queue.

**Parameters**:
- `item: Variant` - Item to process

**Emits**: `item_added(item)`

**Example**:
```gdscript
processor.add_item(enemy_entity)
```

#### `remove_item(item: Variant) -> bool`
Removes item from processing queue.

**Parameters**:
- `item: Variant` - Item to remove

**Returns**: `true` if removed, `false` if not found

**Emits**: `item_removed(item)`

**Example**:
```gdscript
if processor.remove_item(dead_enemy):
    print("Enemy removed from processing")
```

#### `clear_items() -> void`
Clears all items from queue.

**Example**:
```gdscript
processor.clear_items()
```

#### `get_item_count() -> int`
Returns number of items in queue.

**Returns**: Item count

**Example**:
```gdscript
print("Processing %d items" % processor.get_item_count())
```

### Statistics API

#### `get_stats() -> ProcessingStats`
Returns current processing statistics.

**Returns**: `ProcessingStats` object

**Example**:
```gdscript
var stats = processor.get_stats()
print("Total processed: ", stats.total_items_processed)
print("Avg time: ", stats.average_time_per_frame)
```

#### `reset_stats() -> void`
Resets all processing statistics.

**Example**:
```gdscript
processor.reset_stats()
```

---

## BaseResource

**Path**: `addons/cts_core/Core/base_resource.gd`  
**Base Class**: `Resource`  
**Purpose**: Custom Resource with validation and type safety

**Note**: Resources cannot emit signals (not in scene tree).

### Properties

```gdscript
@export var resource_id: StringName = &""  # Unique identifier
@export var resource_version: int = 1      # Version number
```

### Validation API

#### `validate() -> bool`
Validates resource and updates validation cache.

**Returns**: `true` if valid, `false` if errors found

**Default Validation Rules**:
- `resource_id` must be non-empty and >= 1 character
- `resource_version` must be >= 1

**Override Point**: Override `_validate_custom()` for additional validation.

**Example**:
```gdscript
var item = ItemResource.new()
item.resource_id = &"sword_001"
if item.validate():
    print("Item is valid")
else:
    print("Errors: ", item.get_validation_errors())
```

#### `_validate_custom() -> void`
**Override Point**: Implement custom validation logic in child classes.

**Example**:
```gdscript
extends "res://addons/cts_core/Core/base_resource.gd"

func _validate_custom() -> void:
    var result = get_validation_result()
    
    if damage <= 0:
        result.add_error("Damage must be positive")
    
    if weight > 100.0:
        result.add_warning("Weight is very high")
```

#### `is_valid() -> bool`
Checks if resource is valid (auto-validates on first call).

**Returns**: `true` if valid, `false` otherwise

**Example**:
```gdscript
if not my_resource.is_valid():
    push_error("Invalid resource!")
```

#### `get_validation_errors() -> Array[String]`
Returns validation errors from last validation.

**Returns**: Array of error messages

**Example**:
```gdscript
for error in resource.get_validation_errors():
    print("Error: ", error)
```

#### `get_validation_warnings() -> Array[String]`
Returns validation warnings from last validation.

**Returns**: Array of warning messages

**Example**:
```gdscript
for warning in resource.get_validation_warnings():
    print("Warning: ", warning)
```

#### `get_validation_result() -> ValidationResult`
Returns complete validation result object.

**Returns**: `ValidationResult` or `null` if not yet validated

### Serialization API

#### `to_dict() -> Dictionary`
**Override Point**: Converts resource to dictionary for serialization.

**Returns**: Dictionary representation

**Default Keys**:
- `resource_id: String`
- `resource_version: int`

**Example**:
```gdscript
func to_dict() -> Dictionary:
    var data = super.to_dict()
    data["damage"] = damage
    data["weight"] = weight
    return data
```

#### `from_dict(data: Dictionary) -> void`
**Override Point**: Populates resource from dictionary.

**Parameters**:
- `data: Dictionary` - Data to deserialize

**Example**:
```gdscript
func from_dict(data: Dictionary) -> void:
    super.from_dict(data)
    damage = data.get("damage", 10)
    weight = data.get("weight", 1.0)
```

### Comparison API

#### `equals(other: Resource) -> bool`
**Override Point**: Compares two resources for equality.

**Parameters**:
- `other: Resource` - Resource to compare

**Returns**: `true` if equal, `false` otherwise

**Default Behavior**: Compares by script type, `resource_id`, and `resource_version`

**Example**:
```gdscript
if sword1.equals(sword2):
    print("Resources are identical")
```

---

## Type Definitions

**Path**: `addons/cts_core/Data/type_definitions.gd`

### ComponentMetadata

**Purpose**: Metadata for registered components

```gdscript
class ComponentMetadata:
    var component_type: String
    var registration_path: NodePath
    var registration_timestamp: int  # Time.get_ticks_msec()
    
    func _init(type: String, path: NodePath)
```

### CacheEntry

**Purpose**: Cached resource with LRU tracking

```gdscript
class CacheEntry:
    var cached_resource: Resource
    var cache_time: int           # Time.get_ticks_msec()
    var last_access_time: int
    var access_count: int
    
    func access() -> void
    func is_expired(timeout_ms: int) -> bool
```

### ProcessingStats

**Purpose**: Processing performance metrics

```gdscript
class ProcessingStats:
    var total_items_processed: int = 0
    var total_frames: int = 0
    var budget_exceeded_count: int = 0
    var total_processing_time: float = 0.0
    var average_time_per_frame: float = 0.0
    var peak_time: float = 0.0
    var peak_items: int = 0
    
    func record_frame(items: int, time: float, budget: float, queue_size: int)
    func reset()
```

### ValidationResult

**Purpose**: Validation error/warning tracking

```gdscript
class ValidationResult:
    var is_valid: bool = true
    var errors: Array[String] = []
    var warnings: Array[String] = []
    
    func add_error(message: String)
    func add_warning(message: String)
    func clear()
```

### RegistryQuery

**Purpose**: Component query with custom filters

```gdscript
class RegistryQuery:
    var component_type: String = ""
    var max_results: int = 0        # 0 = unlimited
    var custom_filter: Callable = Callable()  # func(component: Node, metadata) -> bool
    
    func matches(component: Node, metadata) -> bool
```

### ProcessorConfig

**Purpose**: Processor configuration

```gdscript
class ProcessorConfig:
    var processing_mode: int = 0              # CoreConstants.ProcessingMode
    var frame_budget_ms: float = 2.0          # Frame budget in milliseconds
    var max_items_per_frame: int = 100
    var auto_start: bool = true
    var deterministic: bool = false
    var random_seed: int = 0
    
    static func create_default() -> ProcessorConfig
```

### FactoryConfig

**Purpose**: Factory configuration

```gdscript
class FactoryConfig:
    var cache_enabled: bool = true
    var max_cache_size: int = 100
    var cache_timeout_ms: int = 60000         # 60 seconds
    var track_instantiated: bool = false
    
    static func create_default() -> FactoryConfig
```

---

## Core Constants

**Path**: `addons/cts_core/Data/core_constants.gd`

### Signature & Version

```gdscript
const CORE_SIGNATURE: String = "CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"
const VERSION: String = "0.0.0.1"
```

### Registry Limits

```gdscript
const MAX_REGISTERED_COMPONENTS: int = 1000
const COMPONENT_TYPE_MAX_LENGTH: int = 64
```

### Resource Validation

```gdscript
const RESOURCE_ID_MIN_LENGTH: int = 1
const RESOURCE_VERSION_MIN: int = 1
```

### Enums

#### ComponentState

```gdscript
enum ComponentState {
    CREATED = 0,        # Just instantiated
    INITIALIZING = 1,   # Running initialize()
    READY = 2,          # Fully initialized
    ERROR = 3,          # Initialization failed
    CLEANING_UP = 4     # Running cleanup()
}
```

#### ProcessingMode

```gdscript
enum ProcessingMode {
    IDLE = 0,           # Process in _process()
    PHYSICS = 1,        # Process in _physics_process()
    MANUAL = 2          # Call process_items() manually
}
```

#### ErrorCode

```gdscript
enum ErrorCode {
    ERR_OK = 0,
    ERR_COMPONENT_INVALID = 1,
    ERR_RESOURCE_LOAD_FAILED = 2,
    ERR_CACHE_FULL = 3,
    ERR_BUDGET_EXCEEDED = 4,
    ERR_VALIDATION_FAILED = 5,
    ERR_ALREADY_REGISTERED = 6,
    ERR_NOT_FOUND = 7,
    ERR_ALREADY_EXISTS = 8
}
```

---

## See Also

- [Signal Contracts](SIGNAL_CONTRACTS.md) - Detailed signal documentation
- [Architecture](ARCHITECTURE.md) - System design and flowcharts
- [Examples](EXAMPLES.md) - Practical usage patterns
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions