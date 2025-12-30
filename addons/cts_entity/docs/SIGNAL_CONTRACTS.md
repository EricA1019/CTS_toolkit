# cts_entity Signal Contracts

## Overview

This document defines all signals emitted by the cts_entity plugin. Signals must be documented here to maintain the signal-first architecture pattern.

## EntityBase Signals

### entity_ready
**When**: After entity fully initialized in scene tree  
**Payload**: 
- `entity_id: String` - Unique instance identifier

**Emitters**: `EntityBase._initialize()`  
**Listeners**: Other plugins (cts_stats, cts_abilities) begin setup

**Example**:
```gdscript
func _ready():
    var entity = get_parent() as EntityBase
    entity.entity_ready.connect(_on_entity_ready)

func _on_entity_ready(entity_id: String):
    print("Entity ready: %s" % entity_id)
```

---

### entity_config_loaded
**When**: After entity_config processed  
**Payload**:
- `entity_id: String`
- `config: EntityConfig`

**Emitters**: `EntityBase._initialize()`  
**Listeners**: Plugins load data from `config.custom_data`

**Example**:
```gdscript
func _on_entity_config_loaded(entity_id: String, config: EntityConfig):
    var stats_path = config.get_stats_path()
    if not stats_path.is_empty():
        _load_stats(stats_path)
```

---

### container_ready
**When**: After each container validated  
**Payload**:
- `entity_id: String`
- `container_name: String` ("StatsContainer", "InventoryContainer", etc.)

**Emitters**: `EntityBase._emit_container_signals()`  
**Listeners**: Plugins attach components to containers

**Example**:
```gdscript
func _on_container_ready(entity_id: String, container_name: String):
    if container_name == "StatsContainer":
        var entity = CTS_Entity.get_entity(entity_id)
        var stats_comp = StatsComponent.new()
        entity.stats_container.add_child(stats_comp)
```

---

### entity_despawning
**When**: Before entity cleanup begins  
**Payload**:
- `entity_id: String`
- `reason: String` ("death", "manual", "batch_cleanup", "area_exit", etc.)

**Emitters**: `EntityBase.despawn()`  
**Listeners**: Death sprite system, loot drop system, quest system

**Example**:
```gdscript
func _on_entity_despawning(entity_id: String, reason: String):
    if reason == "death":
        _drop_loot(entity_id)
        _play_death_animation(entity_id)
```

---

### entity_cleanup_started
**When**: After despawn delay, before queue_free  
**Payload**:
- `entity_id: String`

**Emitters**: `EntityBase._cleanup()`  
**Listeners**: EntityManager (unregister), plugins (disconnect signals)

**Example**:
```gdscript
func _on_entity_cleanup_started(entity_id: String):
    # Disconnect signals, cleanup component data
    _cleanup_entity_data(entity_id)
```

---

### entity_selected
**When**: When an entity is selected by the player (mouse click, UI pick, or other selection mechanic)
**Payload**:
- `entity_id: String` - Unique instance identifier
- `entity_node: Node` - The instance of the selected entity

**Emitters**: `EntityBase._gui_input()` (or other selection handlers)
**Listeners**: UI systems (PlayerBook), selection managers, debug gizmos

**Example**:
```gdscript
func _on_entity_selected(entity_id: String, entity_node: Node):
    # Open player book and show entity stats
    PlayerBook.setup(EntitySignalRegistry, entity_node)
```

---

### entity_deselected
**When**: When an entity selection is cleared (click elsewhere, second click to deselect)
**Payload**:
- `entity_id: String`

**Emitters**: `EntityBase._gui_input()` or selection manager when deselection occurs
**Listeners**: UI systems (PlayerBook) to hide or clear displays

**Example**:
```gdscript
func _on_entity_deselected(entity_id: String):
    PlayerBook.hide()
```

---

### entity_action_requested
**When**: When a context menu action is triggered on an entity (right-click menu)
**Payload**:
- `entity_id: String` - Unique instance identifier
- `action_type: String` - Type of action requested ("look_skills", "look_inventory", etc.)
- `entity_node: Node` - The entity instance

**Emitters**: `EntityBase._setup_context_menu()` via context menu callbacks
**Listeners**: Scene managers (ProvingGrounds) to open appropriate UI (PlayerBook with specific page)

**Example**:
```gdscript
func _on_entity_action_requested(entity_id: String, action_type: String, entity_node: Node):
    match action_type:
        "look_skills":
            PlayerBook.setup(EntitySignalRegistry, entity_node)
            PlayerBook.show()
            PlayerBook.show_page("Skills")
        "look_inventory":
            PlayerBook.show_page("Inventory")
```

---

## EntityFactory Signals

### entity_spawned
**When**: After entity created and added to scene tree  
**Payload**:
- `entity_id: String`
- `entity_node: EntityBase`
- `config: EntityConfig`

**Emitters**: `EntityFactory.create_entity()`  
**Listeners**: EntityManager (auto-register), spawn VFX system

**Example**:
```gdscript
CTS_Entity._factory.entity_spawned.connect(_on_entity_spawned)

func _on_entity_spawned(entity_id: String, entity_node: EntityBase, config: EntityConfig):
    print("Entity spawned: %s at %s" % [entity_id, entity_node.global_position])
```

---

### entity_generation_started
**When**: Before entity creation begins  
**Payload**:
- `config: EntityConfig`

**Emitters**: `EntityFactory.create_entity()`  
**Listeners**: Profiler, analytics, loading screens

**Example**:
```gdscript
func _on_entity_generation_started(config: EntityConfig):
    _show_loading_spinner()
```

---

### entity_scene_loaded
**When**: After prefab_scene instantiated successfully  
**Payload**:
- `scene_path: String`
- `entity_id: String`

**Emitters**: `EntityFactory._create_from_scene()`  
**Listeners**: Debug logger, asset tracker

**Example**:
```gdscript
func _on_entity_scene_loaded(scene_path: String, entity_id: String):
    print("Loaded custom scene: %s for %s" % [scene_path, entity_id])
```

---

### entity_generation_failed
**When**: Entity creation aborted (validation failure)  
**Payload**:
- `entity_id: String`
- `reason: String` ("invalid_config", "missing_containers", "null_prefab_scene", etc.)

**Emitters**: `EntityFactory` (various validation points)  
**Listeners**: Error handler, user feedback system

**Example**:
```gdscript
func _on_entity_generation_failed(entity_id: String, reason: String):
    push_error("Failed to create entity %s: %s" % [entity_id, reason])
    _show_error_message("Entity creation failed")
```

---

### container_validation_failed
**When**: Custom scene missing required containers  
**Payload**:
- `scene_path: String`
- `missing_containers: Array[String]`

**Emitters**: `EntityFactory._validate_containers()`  
**Listeners**: Editor tools, validation GUI, error reporting

**Example**:
```gdscript
func _on_container_validation_failed(scene_path: String, missing_containers: Array):
    var msg = "Scene %s missing containers: %s" % [scene_path, ", ".join(missing_containers)]
    push_error(msg)
```

---

## EntityManager Signals

### entity_registered
**When**: Entity added to registry  
**Payload**:
- `entity_id: String`
- `entity: EntityBase`

**Emitters**: `EntityManager.register_entity()`  
**Listeners**: Debug UI, entity tracker, minimap

**Example**:
```gdscript
func _ready():
    CTS_Entity.entity_registered.connect(_on_entity_registered)

func _on_entity_registered(entity_id: String, entity: EntityBase):
    _add_entity_to_minimap(entity)
```

---

### entity_unregistered
**When**: Entity removed from registry  
**Payload**:
- `entity_id: String`

**Emitters**: `EntityManager.unregister_entity()`  
**Listeners**: Debug UI, entity tracker, minimap

**Example**:
```gdscript
func _on_entity_unregistered(entity_id: String):
    _remove_entity_from_minimap(entity_id)
```

---

### batch_despawn_started
**When**: Batch despawn operation begins  
**Payload**:
- `entity_type: String`
- `count: int`

**Emitters**: `EntityManager.despawn_all_by_type()`  
**Listeners**: Combat UI (show cleanup progress), loading screens

**Example**:
```gdscript
func _on_batch_despawn_started(entity_type: String, count: int):
    print("Despawning %d entities of type: %s" % [count, entity_type])
    _show_progress_bar("Cleaning up...", count)
```

---

### batch_despawn_complete
**When**: All entities in batch despawned  
**Payload**:
- `entity_type: String`
- `count: int`

**Emitters**: `EntityManager._staggered_despawn()`  
**Listeners**: Combat UI (cleanup complete), next wave trigger, victory screen

**Example**:
```gdscript
func _on_batch_despawn_complete(entity_type: String, count: int):
    print("Despawned %d entities of type: %s" % [count, entity_type])
    _hide_progress_bar()
    _trigger_next_wave()
```

---

## Signal Usage Patterns

### Plugin Integration Pattern

**cts_stats example**:
```gdscript
# Stats plugin listens for entity ready
class_name StatsPlugin extends Node

func _ready():
    CTS_Entity.entity_registered.connect(_on_entity_registered)

func _on_entity_registered(entity_id: String, entity: EntityBase):
    # Load stats config from entity config
    if entity.entity_config:
        var stats_path = entity.entity_config.get_stats_path()
        if not stats_path.is_empty():
            var stats_comp = StatsComponent.new()
            stats_comp.load_from_path(stats_path)
            entity.stats_container.add_child(stats_comp)
```

### Combat Cleanup Pattern

**Combat manager example**:
```gdscript
# After combat ends, cleanup enemy entities
func _on_combat_ended():
    # Despawn all bandits (staggered)
    CTS_Entity.despawn_all_by_type("bandit", "combat_end")
    
    # Wait for cleanup to complete
    await CTS_Entity.batch_despawn_complete
    
    # Show victory screen
    _show_victory_screen()
```

### Death VFX Pattern

**VFX system example**:
```gdscript
# Replace sprite on death
func _on_entity_despawning(entity_id: String, reason: String):
    if reason == "death":
        var entity = CTS_Entity.get_entity(entity_id)
        if entity:
            var sprite = entity.get_node_or_null("AnimatedSprite2D")
            if sprite:
                sprite.play("death")
                # Entity will wait 0.1s for sprite swap
```

---

## Required Container Names

**Exact naming required** (EntityFactory validates):
- `StatsContainer` - For cts_stats plugin
- `InventoryContainer` - For cts_items plugin  
- `AbilitiesContainer` - For cts_abilities plugin
- `ComponentsContainer` - For misc components (AI, movement, etc.)

**Custom scenes must include all four containers or EntityFactory will abort with `container_validation_failed` signal.**

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Entity lifecycle and hybrid pattern
- [API_REFERENCE.md](API_REFERENCE.md) - Public API methods
- [EXAMPLES.md](EXAMPLES.md) - Usage examples
