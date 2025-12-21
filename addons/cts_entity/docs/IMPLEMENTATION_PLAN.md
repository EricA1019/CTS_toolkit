# cts_entity Implementation Plan

> **Hop**: Entity Core System - Complete Lifecycle  
> **Status**: Planning  
> **Estimated Scope**: ~1,030 lines (exceeds 750 guideline but justified as foundation)  
> **CTS Phase**: 0 → 1 (Prototype to Clean)

---

## Overview

Build complete entity foundation supporting BOTH data-driven generation (procedural mobs from .tres) AND scene-based instantiation (handcrafted story NPCs from .tscn) with smart ID generation, full lifecycle including despawning with death sprite replacement, and graceful error handling.

**Core Principle**: Entity is a pure container. All gameplay logic (stats, movement, abilities, combat) lives in separate plugins that attach to entity containers.

---

## Objectives

- ✅ Hybrid entity creation (data-driven + scene-based)
- ✅ Smart ID strategy (unique entities vs auto-increment generic)
- ✅ Full lifecycle (spawn → ready → despawn → cleanup)
- ✅ Death sprite replacement (await sprite swap before cleanup)
- ✅ Batch despawn with staggering (performance-friendly)
- ✅ Container validation with abort + warn (fail-safe)
- ✅ Signal-first architecture (no hardcoded dependencies)
- ✅ Integration points for other CTS plugins

---

## Architecture Decisions

### 1. Entity ID Strategy

**Unique Entities** (story NPCs, player):
```gdscript
# EntityConfig
entity_id = "detective"
is_unique = true

# Factory generates:
instance_id = "detective"  # Always the same
```

**Generic Entities** (mobs, bandits):
```gdscript
# EntityConfig
entity_id = "bandit"
is_unique = false

# Factory generates:
instance_id = "bandit_001", "bandit_002", "bandit_003"...
# Display name might be "Larry", "Bob", "Greg" but ID is auto-incremented
```

**Rationale**: Unique entities need consistent IDs for save/load, quest tracking. Generic entities need unique instances for combat targeting.

---

### 2. Despawn Lifecycle

**Single Entity Despawn**:
```
entity.despawn("death") 
  ↓
emit entity_despawning(entity_id, "death")
  ↓
await death_sprite_replacement (if applicable)
  ↓
await get_tree().process_frame
  ↓
emit entity_cleanup_started(entity_id)
  ↓
_cleanup() internal tasks
  ↓
queue_free()
```

**Batch Despawn** (combat cleanup, area exit):
```
manager.despawn_all_by_type("bandit")
  ↓
emit batch_despawn_started(type, count)
  ↓
Stagger despawns (2-5 per frame)
  ↓
Each entity follows single despawn lifecycle
  ↓
emit batch_despawn_complete(type, count)
```

**Rationale**: Await death sprite ensures visual feedback before removal. Staggering prevents lag spikes when despawning 100+ entities after combat.

---

### 3. Container Validation Strategy

**On Custom Scene Load**:
```
factory.load_from_scene(custom_scene, config)
  ↓
Validate required containers exist:
  - StatsContainer (Node)
  - InventoryContainer (Node)
  - AbilitiesContainer (Node)
  - ComponentsContainer (Node)
  ↓
If missing ANY required container:
  → push_error("Missing required container: StatsContainer in scene '{path}'")
  → emit entity_generation_failed(config.entity_id, "missing_containers")
  → return null (abort spawn)
```

**Rationale**: Abort + warn is fail-safe. Silent auto-fix could hide user errors. Permissive spawning breaks plugin integration.

---

### 4. Hybrid Factory Logic

**Decision Tree**:
```
create_entity(config: EntityConfig)
  ↓
  ├─ config.prefab_scene != null?
  │   ├─ YES → load_from_scene(prefab_scene, config)
  │   │         └─ Validate containers (abort if missing)
  │   │         └─ Preserve custom nodes (AnimatedSprite2D, etc.)
  │   │         └─ Apply instance ID + metadata
  │   │         
  │   └─ NO  → generate_from_base(config)
  │             └─ Instantiate entity_base.tscn
  │             └─ Apply instance ID + metadata
  │
  ↓
Apply position (if spawn_at_position used)
  ↓
emit entity_spawned(instance_id, entity_node, config)
  ↓
return entity_node
```

---

## File Structure

```
addons/cts_entity/
├── Core/
│   ├── entity_base.gd         (~180 lines) - Lifecycle controller
│   ├── entity_factory.gd      (~250 lines) - Hybrid creation + validation
│   ├── entity_manager.gd      (~150 lines) - Registry + batch operations
│   └── entity_spawner.gd      (STUB - future movement integration)
├── Data/
│   └── entity_config.gd       (~60 lines)  - Resource definition
├── Components/
│   └── entity_component.gd    (STUB - base component class)
├── Prefabs/
│   └── entity_base.tscn       (Scene file) - Container template
├── docs/
│   ├── SIGNAL_CONTRACTS.md    (~80 lines)  - Signal documentation
│   ├── ARCHITECTURE.md        (~60 lines)  - Hybrid pattern explanation
│   ├── API_REFERENCE.md       (Auto-generated from code)
│   └── EXAMPLES.md            (~40 lines)  - Usage patterns
├── test/
│   └── entity_tests.gd        (~250 lines) - 20+ comprehensive tests
└── examples/
    ├── detective_demo/        (Unique entity example)
    └── bandit_demo/           (Generic entity example)
```

**Total Estimated Lines**: ~1,030 lines (implementation + tests + docs)

---

## Implementation Steps

### Step 1: EntityConfig Resource (60 lines)

**File**: `addons/cts_entity/Data/entity_config.gd`

**Extends**: `BaseResource` (from cts_core)

**Properties**:
```gdscript
@export var entity_id: String = ""           # Base ID (e.g., "bandit", "detective")
@export var entity_name: String = ""         # Display name
@export var is_unique: bool = false          # True = use entity_id as-is, False = auto-increment
@export var description: String = ""
@export var tile_size: int = 16              # Grid size for position tracking
@export var prefab_scene: PackedScene = null # Optional custom scene
@export var custom_data: Dictionary = {}     # Plugin extension data
```

**Validation**:
- `entity_id` must be non-empty
- `entity_id` must match pattern: `^[a-zA-Z0-9_]+$` (alphanumeric + underscore, no spaces)
- `entity_name` non-empty if provided
- `tile_size` must be positive

**Methods**:
```gdscript
func _validate_custom() -> void:
    # Add validation errors to result
    
func get_stats_path() -> String:
    # Helper: custom_data.get("stats_path", "")
    
func get_abilities_path() -> String:
    # Helper: custom_data.get("abilities_path", "")
```

---

### Step 2: EntityBase Scene & Script (180 lines)

**Scene File**: `addons/cts_entity/Prefabs/entity_base.tscn`

**Structure**:
```
EntityBase (Node2D)
├── StatsContainer (Node)
├── InventoryContainer (Node)
├── AbilitiesContainer (Node)
└── ComponentsContainer (Node)
```

**Script**: `addons/cts_entity/Core/entity_base.gd`

**Extends**: `Node2D`

**Signals**:
```gdscript
signal entity_ready(entity_id: String)
signal entity_config_loaded(entity_id: String, config: EntityConfig)
signal container_ready(entity_id: String, container_name: String)
signal entity_despawning(entity_id: String, reason: String)
signal entity_cleanup_started(entity_id: String)
```

**Properties**:
```gdscript
@export var entity_config: EntityConfig = null

var _instance_id: String = ""
var _is_despawning: bool = false

@onready var stats_container: Node = $StatsContainer
@onready var inventory_container: Node = $InventoryContainer
@onready var abilities_container: Node = $AbilitiesContainer
@onready var components_container: Node = $ComponentsContainer
```

**Methods**:
```gdscript
func _ready() -> void:
    # Dual-path initialization
    var factory_id: String = str(get_meta("instance_id", ""))
    if not factory_id.is_empty():
        # Factory-spawned
        _instance_id = factory_id
    else:
        # Scene-instanced fallback
        _instance_id = _generate_fallback_id()
        set_meta("instance_id", _instance_id)
    
    _initialize()

func _initialize() -> void:
    # Emit container ready signals
    for container in [stats_container, inventory_container, abilities_container, components_container]:
        if container:
            container_ready.emit(_instance_id, container.name)
    
    # Load config if provided
    if entity_config:
        entity_config_loaded.emit(_instance_id, entity_config)
    
    # Ready signal
    entity_ready.emit(_instance_id)

func despawn(reason: String = "manual") -> void:
    if _is_despawning:
        return
    
    _is_despawning = true
    entity_despawning.emit(_instance_id, reason)
    
    # Check for death sprite replacement
    if reason == "death":
        await _handle_death_sprite()
    
    # Wait for signal handlers
    await get_tree().process_frame
    
    # Cleanup
    _cleanup()
    
    # Remove from scene
    queue_free()

func _handle_death_sprite() -> void:
    # Emit signal for death sprite system (if exists)
    # Other plugins can connect to entity_despawning and swap sprite
    # Wait brief moment for swap to occur
    await get_tree().create_timer(0.1).timeout

func _cleanup() -> void:
    entity_cleanup_started.emit(_instance_id)
    
    # Notify EntityManager
    var manager = get_node_or_null("/root/CTS_Entity")
    if manager:
        manager.unregister_entity(_instance_id)
    
    # Plugin cleanup (other systems disconnect signals)

func get_instance_id() -> String:
    return _instance_id

func get_container(container_name: String) -> Node:
    match container_name:
        "StatsContainer": return stats_container
        "InventoryContainer": return inventory_container
        "AbilitiesContainer": return abilities_container
        "ComponentsContainer": return components_container
        _: 
            push_error("Unknown container: %s" % container_name)
            return null

func _generate_fallback_id() -> String:
    # Scene-instanced entities get unique ID
    if entity_config:
        return "%s_scene_%d" % [entity_config.entity_id, get_instance_id()]
    return "entity_%d" % get_instance_id()
```

---

### Step 3: EntityFactory (250 lines)

**File**: `addons/cts_entity/Core/entity_factory.gd`

**Extends**: `BaseFactory` (from cts_core)

**Signals**:
```gdscript
signal entity_spawned(entity_id: String, entity_node: EntityBase, config: EntityConfig)
signal entity_generation_started(config: EntityConfig)
signal entity_scene_loaded(scene_path: String, entity_id: String)
signal entity_generation_failed(entity_id: String, reason: String)
signal container_validation_failed(scene_path: String, missing_containers: Array[String])
```

**Properties**:
```gdscript
const BASE_ENTITY_SCENE: String = "res://addons/cts_entity/Prefabs/entity_base.tscn"
const REQUIRED_CONTAINERS: Array[String] = [
    "StatsContainer",
    "InventoryContainer", 
    "AbilitiesContainer",
    "ComponentsContainer"
]

var _id_counters: Dictionary = {}  # Track auto-increment per entity type
```

**Methods**:
```gdscript
func create_entity(config: EntityConfig, parent: Node = null) -> EntityBase:
    if not config:
        push_error("[EntityFactory] Cannot create entity: config is null")
        return null
    
    if not config.validate():
        push_error("[EntityFactory] EntityConfig validation failed: %s" % config.resource_id)
        entity_generation_failed.emit(config.entity_id, "invalid_config")
        return null
    
    entity_generation_started.emit(config)
    
    var entity: EntityBase = null
    
    # Hybrid creation
    if config.prefab_scene:
        entity = _create_from_scene(config)
    else:
        entity = _create_from_base(config)
    
    if not entity:
        return null
    
    # Apply instance ID
    var instance_id := _generate_instance_id(config)
    entity.set_meta("instance_id", instance_id)
    entity.entity_config = config
    
    # Add to scene tree
    if parent:
        parent.add_child(entity)
    
    # Emit success
    entity_spawned.emit(instance_id, entity, config)
    
    return entity

func spawn_at_position(config: EntityConfig, global_pos: Vector2, parent: Node) -> EntityBase:
    var entity := create_entity(config, parent)
    if entity:
        entity.global_position = global_pos
    return entity

func _create_from_scene(config: EntityConfig) -> EntityBase:
    var scene := config.prefab_scene
    if not scene:
        push_error("[EntityFactory] prefab_scene is null for %s" % config.entity_id)
        entity_generation_failed.emit(config.entity_id, "null_prefab_scene")
        return null
    
    var instance = scene.instantiate()
    if not instance is EntityBase:
        push_error("[EntityFactory] Prefab scene root must be EntityBase for %s" % config.entity_id)
        entity_generation_failed.emit(config.entity_id, "invalid_scene_type")
        instance.queue_free()
        return null
    
    # Validate containers
    var validation_result := _validate_containers(instance, scene.resource_path)
    if not validation_result.is_valid:
        push_error("[EntityFactory] Container validation failed for %s: %s" % [
            config.entity_id, 
            ", ".join(validation_result.missing_containers)
        ])
        container_validation_failed.emit(scene.resource_path, validation_result.missing_containers)
        entity_generation_failed.emit(config.entity_id, "missing_containers")
        instance.queue_free()
        return null
    
    entity_scene_loaded.emit(scene.resource_path, config.entity_id)
    return instance

func _create_from_base(config: EntityConfig) -> EntityBase:
    var base_scene := load(BASE_ENTITY_SCENE) as PackedScene
    if not base_scene:
        push_error("[EntityFactory] Failed to load base entity scene: %s" % BASE_ENTITY_SCENE)
        entity_generation_failed.emit(config.entity_id, "missing_base_scene")
        return null
    
    var entity := base_scene.instantiate() as EntityBase
    return entity

func _validate_containers(entity: EntityBase, scene_path: String) -> Dictionary:
    var result := {
        "is_valid": true,
        "missing_containers": []
    }
    
    for container_name in REQUIRED_CONTAINERS:
        var container := entity.get_node_or_null(container_name)
        if not container:
            result.is_valid = false
            result.missing_containers.append(container_name)
    
    return result

func _generate_instance_id(config: EntityConfig) -> String:
    if config.is_unique:
        # Unique entities always use base ID
        return config.entity_id
    
    # Generic entities get auto-incremented ID
    var base_id := config.entity_id
    if not _id_counters.has(base_id):
        _id_counters[base_id] = 0
    
    _id_counters[base_id] += 1
    return "%s_%03d" % [base_id, _id_counters[base_id]]

func reset_counters() -> void:
    _id_counters.clear()
```

---

### Step 4: EntityManager (150 lines)

**File**: `addons/cts_entity/Core/entity_manager.gd`

**Extends**: `Node`

**Autoload**: `CTS_Entity`

**Signals**:
```gdscript
signal entity_registered(entity_id: String, entity: EntityBase)
signal entity_unregistered(entity_id: String)
signal batch_despawn_started(entity_type: String, count: int)
signal batch_despawn_complete(entity_type: String, count: int)
```

**Properties**:
```gdscript
var _entity_registry: Dictionary = {}  # String -> EntityBase
var _entities_by_type: Dictionary = {} # String -> Array[String] (type -> entity_ids)
var _factory: EntityFactory = null
```

**Methods**:
```gdscript
func _ready() -> void:
    _factory = EntityFactory.new()
    add_child(_factory)
    
    # Connect to factory signals
    _factory.entity_spawned.connect(_on_entity_spawned)

func register_entity(entity_id: String, entity: EntityBase) -> void:
    if _entity_registry.has(entity_id):
        push_warning("[EntityManager] Entity already registered: %s" % entity_id)
        return
    
    _entity_registry[entity_id] = entity
    
    # Track by type
    var entity_type := _get_entity_type(entity)
    if not _entities_by_type.has(entity_type):
        _entities_by_type[entity_type] = []
    _entities_by_type[entity_type].append(entity_id)
    
    entity_registered.emit(entity_id, entity)

func unregister_entity(entity_id: String) -> void:
    if not _entity_registry.has(entity_id):
        return
    
    var entity := _entity_registry[entity_id]
    var entity_type := _get_entity_type(entity)
    
    _entity_registry.erase(entity_id)
    
    # Remove from type tracking
    if _entities_by_type.has(entity_type):
        _entities_by_type[entity_type].erase(entity_id)
    
    entity_unregistered.emit(entity_id)

func get_entity(entity_id: String) -> EntityBase:
    return _entity_registry.get(entity_id, null)

func get_all_entities() -> Array[EntityBase]:
    var entities: Array[EntityBase] = []
    for entity in _entity_registry.values():
        entities.append(entity)
    return entities

func get_entities_by_type(entity_type: String) -> Array[EntityBase]:
    var entities: Array[EntityBase] = []
    if not _entities_by_type.has(entity_type):
        return entities
    
    for entity_id in _entities_by_type[entity_type]:
        var entity := get_entity(entity_id)
        if entity:
            entities.append(entity)
    
    return entities

func despawn_entity(entity_id: String, reason: String = "manual") -> void:
    var entity := get_entity(entity_id)
    if not entity:
        push_warning("[EntityManager] Cannot despawn unknown entity: %s" % entity_id)
        return
    
    entity.despawn(reason)

func despawn_all_by_type(entity_type: String, reason: String = "batch_cleanup") -> void:
    var entities := get_entities_by_type(entity_type)
    if entities.is_empty():
        return
    
    batch_despawn_started.emit(entity_type, entities.size())
    
    # Stagger despawns to prevent lag spike
    await _staggered_despawn(entities, reason)
    
    batch_despawn_complete.emit(entity_type, entities.size())

func _staggered_despawn(entities: Array[EntityBase], reason: String) -> void:
    const ENTITIES_PER_FRAME: int = 3
    var count := 0
    
    for entity in entities:
        entity.despawn(reason)
        count += 1
        
        # Wait for next frame every N entities
        if count % ENTITIES_PER_FRAME == 0:
            await get_tree().process_frame

func create_entity(config: EntityConfig, parent: Node = null) -> EntityBase:
    return _factory.create_entity(config, parent)

func spawn_at_position(config: EntityConfig, global_pos: Vector2, parent: Node) -> EntityBase:
    return _factory.spawn_at_position(config, global_pos, parent)

func _get_entity_type(entity: EntityBase) -> String:
    if entity.entity_config:
        return entity.entity_config.entity_id
    return "unknown"

func _on_entity_spawned(entity_id: String, entity_node: EntityBase, config: EntityConfig) -> void:
    register_entity(entity_id, entity_node)
```

---

### Step 5: Signal Contracts Documentation (80 lines)

**File**: `addons/cts_entity/docs/SIGNAL_CONTRACTS.md`

**Content**:
```markdown
# cts_entity Signal Contracts

## EntityBase Signals

### entity_ready
**When**: After entity fully initialized in scene tree
**Payload**: 
- entity_id: String - Unique instance identifier

**Emitters**: EntityBase._initialize()
**Listeners**: Other plugins (cts_stats, cts_abilities) begin setup

---

### entity_config_loaded
**When**: After entity_config processed
**Payload**:
- entity_id: String
- config: EntityConfig

**Emitters**: EntityBase._initialize()
**Listeners**: Plugins load data from config.custom_data

---

### container_ready
**When**: After each container validated
**Payload**:
- entity_id: String
- container_name: String ("StatsContainer", etc.)

**Emitters**: EntityBase._initialize()
**Listeners**: Plugins attach components to containers

---

### entity_despawning
**When**: Before entity cleanup begins
**Payload**:
- entity_id: String
- reason: String ("death", "manual", "batch_cleanup", etc.)

**Emitters**: EntityBase.despawn()
**Listeners**: Death sprite system, loot drop system, quest system

---

### entity_cleanup_started
**When**: After despawn delay, before queue_free
**Payload**:
- entity_id: String

**Emitters**: EntityBase._cleanup()
**Listeners**: EntityManager (unregister), plugins (disconnect signals)

---

## EntityFactory Signals

### entity_spawned
**When**: After entity created and added to scene tree
**Payload**:
- entity_id: String
- entity_node: EntityBase
- config: EntityConfig

**Emitters**: EntityFactory.create_entity()
**Listeners**: EntityManager (auto-register), spawn VFX system

---

### entity_generation_started
**When**: Before entity creation begins
**Payload**:
- config: EntityConfig

**Emitters**: EntityFactory.create_entity()
**Listeners**: Profiler, analytics

---

### entity_scene_loaded
**When**: After prefab_scene instantiated successfully
**Payload**:
- scene_path: String
- entity_id: String

**Emitters**: EntityFactory._create_from_scene()
**Listeners**: Debug logger

---

### entity_generation_failed
**When**: Entity creation aborted (validation failure)
**Payload**:
- entity_id: String
- reason: String ("invalid_config", "missing_containers", etc.)

**Emitters**: EntityFactory (various validation points)
**Listeners**: Error handler, user feedback system

---

### container_validation_failed
**When**: Custom scene missing required containers
**Payload**:
- scene_path: String
- missing_containers: Array[String]

**Emitters**: EntityFactory._validate_containers()
**Listeners**: Editor tools, validation GUI

---

## EntityManager Signals

### entity_registered
**When**: Entity added to registry
**Payload**:
- entity_id: String
- entity: EntityBase

**Emitters**: EntityManager.register_entity()
**Listeners**: Debug UI, entity tracker

---

### entity_unregistered
**When**: Entity removed from registry
**Payload**:
- entity_id: String

**Emitters**: EntityManager.unregister_entity()
**Listeners**: Debug UI, entity tracker

---

### batch_despawn_started
**When**: Batch despawn operation begins
**Payload**:
- entity_type: String
- count: int

**Emitters**: EntityManager.despawn_all_by_type()
**Listeners**: Combat UI (show cleanup progress)

---

### batch_despawn_complete
**When**: All entities in batch despawned
**Payload**:
- entity_type: String
- count: int

**Emitters**: EntityManager._staggered_despawn()
**Listeners**: Combat UI (cleanup complete), next wave trigger
```

---

### Step 6: Architecture Documentation (60 lines)

**File**: `addons/cts_entity/docs/ARCHITECTURE.md`

Explains:
- Hybrid scene/data pattern
- Unique vs generic ID strategy
- Container naming convention
- Despawn lifecycle
- When to use procedural vs handcrafted

---

### Step 7: Examples & Templates (40 lines)

**Examples**:
- `examples/detective_demo/` - Unique entity (story NPC)
- `examples/bandit_demo/` - Generic entity (procedural mob)

**Templates**:
- `docs/templates/entity_config.template.tres`
- `docs/templates/entity_scene.template.tscn`

---

## Testing Strategy (250 lines)

**File**: `addons/cts_entity/test/entity_tests.gd`

**Test Categories**:

1. **EntityConfig Tests** (5 tests):
   - Valid config creation
   - Validation errors (empty entity_id, invalid format)
   - custom_data access helpers

2. **EntityBase Tests** (6 tests):
   - Dual-path initialization (factory vs scene)
   - Container ready signals
   - Config loaded signal
   - Despawn with death reason
   - Cleanup lifecycle

3. **EntityFactory Tests** (8 tests):
   - Create from base template
   - Create from custom scene
   - Container validation (success)
   - Container validation (failure → abort)
   - Unique ID generation
   - Generic ID auto-increment
   - spawn_at_position

4. **EntityManager Tests** (6 tests):
   - Register/unregister
   - Get entity by ID
   - Get entities by type
   - despawn_entity
   - despawn_all_by_type (batch)
   - Staggered despawn timing

---

## Integration Points

### For Other Plugins

**cts_stats**:
```gdscript
# Listen for entity ready
func _ready():
    CTS_Entity.entity_registered.connect(_on_entity_registered)

func _on_entity_registered(entity_id: String, entity: EntityBase):
    # Attach StatsComponent to entity.stats_container
    var stats_comp = StatsComponent.new()
    entity.stats_container.add_child(stats_comp)
```

**cts_abilities**:
```gdscript
# Listen for config loaded
func _on_entity_config_loaded(entity_id: String, config: EntityConfig):
    var abilities_path = config.custom_data.get("abilities_path", "")
    if abilities_path:
        # Load abilities resource, attach to entity.abilities_container
```

**cts_items/inventory**:
```gdscript
# Listen for despawn to drop loot
func _on_entity_despawning(entity_id: String, reason: String):
    if reason == "death":
        # Drop inventory contents at entity position
```

---

## Performance Targets

- **Entity spawn**: <1ms per entity (data-driven)
- **Entity spawn**: <2ms per entity (scene-based)
- **Container validation**: <0.5ms per scene
- **Batch despawn**: 3 entities per frame (staggered)
- **Registry lookup**: O(1) by ID, O(n) by type

---

## Known Limitations

1. **No entity pooling** - Instantiate new entities each spawn (Phase 2 optimization)
2. **No save/load** - State persistence in separate addon (cts_save)
3. **No networking** - Multiplayer sync in separate addon (cts_network)
4. **Basic death sprite** - Simple timer-based swap (cts_vfx addon improves)

---

## Future Enhancements (Phase 2+)

- Entity pooling (cts_spawner integration)
- Advanced despawn reasons (death types, visual effects)
- Entity templates/variants (inherit from base configs)
- Editor tools (entity inspector, spawn preview)
- Performance profiling dashboard
- Benchmarking suite (1000+ entity stress test)

---

## Dependencies

**Required CTS Addons**:
- cts_core (BaseResource, BaseFactory, TypeDefs)

**Optional Integrations**:
- cts_stats (stat management)
- cts_abilities (ability system)
- cts_items (inventory, loot drops)
- cts_vfx (death sprites, spawn effects)

---

## Completion Criteria

- [ ] All files implemented (<500 lines each)
- [ ] 20+ tests passing (100% coverage on critical paths)
- [ ] Signal contracts documented
- [ ] Architecture guide written
- [ ] Examples created (detective + bandit)
- [ ] Templates provided
- [ ] Plugin loads without errors
- [ ] No hardcoded dependencies (signal-first)
- [ ] Boot test: Spawn 100 bandits, despawn all by type

---

**CTS Compliance Note**: This hop exceeds 750-line guideline (~1,030 total) but is justified as foundational system that prevents duplicate work in future plugins. Splitting would create artificial boundaries in tightly-coupled lifecycle logic.

**Status**: Ready for implementation (Phase 0 → Phase 1)
