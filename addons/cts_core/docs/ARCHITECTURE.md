# CTS Core Architecture

## Overview

CTS Core is a foundation addon providing base classes, component registry, and infrastructure patterns for Godot 4.x game development. It enforces signal-first architecture, auto-registration, and loose coupling through composition.

## Core Principles

1. **Signal-First**: Define signals before implementation
2. **Auto-Registration**: Components register themselves with CTS_Core manager
3. **Loose Coupling**: No class_name on BaseComponent, identified by component_type string
4. **Type Safety**: Explicit types, Array[Type] syntax, headless compatible
5. **Frame Budgets**: Performance targets enforced (2ms per system)
6. **Signature Validation**: CORE_SIGNATURE ensures addon compatibility

---

## System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      CTS_Core Autoload                      │
│                   (CoreManager Singleton)                   │
├─────────────────────────────────────────────────────────────┤
│ • Component Registry (_registry: Dict)                     │
│ • Metadata Tracking (_metadata: Dict)                      │
│ • Query System (filter_callback support)                   │
│ • Signature Validation (CORE_SIGNATURE)                    │
└────────────┬────────────────────────────────┬───────────────┘
             │                                │
    ┌────────▼─────────┐           ┌─────────▼──────────┐
    │  BaseComponent   │           │   BaseFactory      │
    │  (Auto-Register) │           │   (Caching)        │
    └────────┬─────────┘           └─────────┬──────────┘
             │                                │
    ┌────────▼─────────┐           ┌─────────▼──────────┐
    │  BaseResource    │           │  BaseProcessor     │
    │  (Validation)    │           │  (Frame Budget)    │
    └──────────────────┘           └────────────────────┘
```

---

## Component Lifecycle

### Auto-Registration Flow

```
┌─────────────────────────────────────────────┐
│ 1. Component added to scene tree            │
│    (add_child or scene instantiation)       │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 2. _ready() called by Godot                 │
│    • Validates component_type property      │
│    • Sets state to INITIALIZING             │
│    • Stores parent reference                │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 3. register_component(self) called          │
│    • CTS_Core checks component_type         │
│    • Adds to _registry dict                 │
│    • Creates ComponentMetadata              │
│    • Emits component_registered signal      │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 4. initialize() called (override point)     │
│    • Child class setup logic                │
│    • Emits component_initialized signal     │
│    • Emits component_ready signal           │
│    • Sets state to READY                    │
└─────────────────────────────────────────────┘
```

### Cleanup Flow

```
┌─────────────────────────────────────────────┐
│ 1. cleanup() called explicitly OR           │
│    NOTIFICATION_PREDELETE received          │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 2. Emits component_cleanup_started signal   │
│    • Sets state to CLEANING_UP              │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 3. unregister_component(self) called        │
│    • CTS_Core removes from _registry        │
│    • Clears ComponentMetadata               │
│    • Emits component_unregistered signal    │
└─────────────────────────────────────────────┘
```

---

## Factory Pattern

### Resource Caching with LRU Eviction

```
┌─────────────────────────────────────────────┐
│ cache_resource(path) called                 │
└─────────────────┬───────────────────────────┘
                  │
         ┌────────┴────────┐
         │ Cache enabled?  │
         └────────┬────────┘
           ┌──────┴──────┐
           │ YES    │ NO │
           ▼        ▼    │
    ┌──────────┐  Load directly
    │ Check    │  (no caching)
    │ _cache   │
    └────┬─────┘
         │
    ┌────┴─────┐
    │ Exists?  │
    └────┬─────┘
    ┌────┴────┐
    │ YES│ NO │
    ▼    ▼    │
 ┌─────────┐  │
 │ Check   │  │
 │ expired?│  │
 └───┬─────┘  │
     │        │
  ┌──┴──┐     │
  │Valid│Exp  │
  ▼     ▼     ▼
Cache  Reload  Load + Cache
Hit    + Cache (Check max size)
       
If cache full → Evict oldest (LRU)
```

---

## Processor Frame Budget

### Processing Loop with Budget Enforcement

```
┌─────────────────────────────────────────────┐
│ process_items(delta) called                 │
│ • Via _process() or _physics_process()      │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ Check: enabled && !paused && items exist?   │
└─────────────────┬───────────────────────────┘
         ┌────────┴────────┐
         │ YES        │ NO │
         ▼            ▼    
┌─────────────┐  Return (skip)
│ Emit        │
│ processing_ │
│ started     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ Loop: Process items one by one              │
│ • Call _process_item(item, delta)           │
│ • Check elapsed time after each item        │
│ • Break if elapsed >= frame_budget_ms       │
└─────────────────┬───────────────────────────┘
                  │
         ┌────────┴────────┐
         │ Budget exceeded?│
         └────────┬────────┘
           ┌──────┴──────┐
           │ YES    │ NO │
           ▼        ▼
    Emit budget_  Continue
    exceeded      all items
           │        │
           └────┬───┘
                ▼
┌─────────────────────────────────────────────┐
│ Update ProcessingStats                      │
│ Emit processing_completed(count)            │
└─────────────────────────────────────────────┘
```

---

## Signature Validation

### Addon Compatibility Check

Every dependent addon must validate CORE_SIGNATURE in plugin.gd:

```gdscript
func _enable_plugin() -> void:
    var cts_core = get_node_or_null("/root/CTS_Core")
    if cts_core == null:
        push_error("[MyAddon] CTS_Core not found!")
        return
    
    var Constants = preload("res://addons/cts_core/Data/core_constants.gd")
    if not cts_core.validate_signature(Constants.CORE_SIGNATURE):
        push_error("[MyAddon] CTS Core signature mismatch!")
        return
    
    # Proceed with addon initialization
```

**CORE_SIGNATURE Format**: `"CTS_CORE:0.0.0.1:550e8400-e29b-41d4-a716-446655440000"`
- Version: 0.0.0.1 (incremented on breaking changes)
- UUID: Unique identifier for this CTS ecosystem

---

## Query System

### Flexible Component Discovery

```gdscript
# Simple type query
var all_cameras: Array[Node] = CTS_Core.get_components_by_type("Camera")

# Filtered query with callback
var query = RegistryQuery.new()
query.component_type = "Enemy"
query.filter_callback = func(node: Node) -> bool:
    return node.get("health", 0) > 0  # Only alive enemies
query.max_results = 10

var alive_enemies: Array[Node] = CTS_Core.query_components(query)

# Find specific component by owner
var player_inventory: Node = CTS_Core.find_component(
    player.get_path(), 
    "InventoryComponent"
)
```

---

## Performance Considerations

### Frame Budget System

- **Default Budget**: 2ms per system (allows 8 systems at 60 FPS)
- **Configurable**: Set via ProcessorConfig.frame_budget_ms
- **Measured**: ProcessingStats tracks elapsed time per frame
- **Enforced**: Processing loop breaks when budget exceeded

### Cache Management

- **Max Cache Size**: Configurable via FactoryConfig.max_cache_size
- **Eviction Strategy**: LRU (Least Recently Used)
- **Access Tracking**: CacheEntry.access_count and last_access_time
- **Expiration**: Optional timeout via cache_timeout_ms

### Registry Optimization

- **Capacity Limit**: MAX_REGISTERED_COMPONENTS = 1000 (configurable)
- **Orphan Cleanup**: get_components_by_type() removes invalid nodes
- **Batch Operations**: batch_register() for multiple components

---

## Extension Patterns

### Creating Custom Components

```gdscript
# MyCustomComponent.gd
extends "res://addons/cts_core/Core/base_component.gd"
class_name MyCustomComponent  # Add class_name if desired

@export var my_property: int = 10

func _ready() -> void:
    component_type = "MyCustomComponent"  # REQUIRED
    super._ready()  # Call parent to trigger registration

func initialize() -> void:
    super.initialize()  # Call parent first
    # Your initialization logic here
    print("MyCustomComponent initialized with value: ", my_property)
```

### Creating Custom Resources

```gdscript
# MyCustomResource.gd
extends "res://addons/cts_core/Core/base_resource.gd"
class_name MyCustomResource

@export var custom_data: String = ""

func _validate_custom() -> void:
    # Add custom validation logic
    if custom_data.is_empty():
        _validation_cache.add_warning("custom_data is empty")
```

### Creating Custom Factories

```gdscript
# MyFactory.gd
extends "res://addons/cts_core/Core/base_factory.gd"

func create_enemy(enemy_type: String) -> Node:
    var scene_path: String = "res://enemies/%s.tscn" % enemy_type
    return create_node(scene_path, get_tree().current_scene)
```

---

## Integration with Other Addons

### CTS Ecosystem Addons

CTS Core is designed as the foundation for 13+ specialized addons:
- **cts_entity**: Entity spawning and lifecycle
- **cts_items**: Item system with crafting
- **cts_combat**: Combat resolution
- **cts_abilities**: Skill/ability system
- **cts_progression**: Leveling and XP
- (See ADDON_MASTERLIST.md for full list)

Each addon follows the same patterns:
1. Validate CORE_SIGNATURE in plugin.gd
2. Use CTS_ prefix for autoloads
3. Register components with CTS_Core
4. Define signals before implementation
5. Follow <500 lines per file limit

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common errors and solutions.

---

## Related Documentation

- [API Reference](API_REFERENCE.md) - Complete method signatures
- [Signal Contracts](SIGNAL_CONTRACTS.md) - All signal definitions
- [Examples](EXAMPLES.md) - Code samples and use cases
- [Implementation Plan](CTS_CORE_IMPLEMENTATION_PLAN.md) - Development roadmap