# CTS Core - Usage Examples

> Practical code samples demonstrating common patterns and integration scenarios

## Table of Contents

1. [Quick Start](#quick-start)
2. [Component Examples](#component-examples)
3. [Factory Examples](#factory-examples)
4. [Processor Examples](#processor-examples)
5. [Resource Examples](#resource-examples)
6. [Registry Query Examples](#registry-query-examples)
7. [Integration Patterns](#integration-patterns)
8. [Advanced Patterns](#advanced-patterns)

---

## Quick Start

### Minimal Component

```gdscript
extends "res://addons/cts_core/Core/base_component.gd"

func initialize() -> void:
    super.initialize()
    print("%s initialized!" % component_type)
```

### Using the Component

```gdscript
# Add component to any node
var health_component = preload("res://components/health_component.gd").new()
health_component.component_type = "HealthComponent"
player.add_child(health_component)

# Component auto-registers with CTS_Core when added to scene tree
await get_tree().process_frame

# Query it back
var found = CTS_Core.find_component(player, "HealthComponent")
print("Found: ", found.component_type)
```

---

## Component Examples

### Example 1: Health Component

```gdscript
# health_component.gd
extends "res://addons/cts_core/Core/base_component.gd"

signal health_changed(new_health: int, max_health: int)
signal died()

@export var max_health: int = 100
var current_health: int = 100

func initialize() -> void:
    super.initialize()
    current_health = max_health
    component_type = "HealthComponent"

func take_damage(amount: int) -> void:
    if not is_enabled:
        return
    
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    
    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    if not is_enabled:
        return
    
    current_health = mini(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

func cleanup() -> void:
    health_changed.disconnectAll()
    died.disconnectAll()
    super.cleanup()
```

**Usage**:

```gdscript
# Add to player
var health = HealthComponent.new()
player.add_child(health)

# Use component
health.take_damage(25)
health.heal(10)

# Query from registry
var player_health = CTS_Core.find_component(player, "HealthComponent")
print("Player HP: %d/%d" % [player_health.current_health, player_health.max_health])
```

### Example 2: Inventory Component

```gdscript
# inventory_component.gd
extends "res://addons/cts_core/Core/base_component.gd"

signal item_added(item: Resource)
signal item_removed(item: Resource)
signal inventory_full()

@export var max_slots: int = 20
var items: Array[Resource] = []

func initialize() -> void:
    super.initialize()
    component_type = "InventoryComponent"

func add_item(item: Resource) -> bool:
    if items.size() >= max_slots:
        inventory_full.emit()
        return false
    
    items.append(item)
    item_added.emit(item)
    return true

func remove_item(item: Resource) -> bool:
    var idx = items.find(item)
    if idx >= 0:
        items.remove_at(idx)
        item_removed.emit(item)
        return true
    return false

func has_item(item_id: StringName) -> bool:
    for item in items:
        if item.resource_id == item_id:
            return true
    return false

func get_item_count() -> int:
    return items.size()
```

### Example 3: Movement Component with State

```gdscript
# movement_component.gd
extends "res://addons/cts_core/Core/base_component.gd"

@export var speed: float = 100.0
@export var can_move: bool = true

var _velocity: Vector2 = Vector2.ZERO

func initialize() -> void:
    super.initialize()
    component_type = "MovementComponent"

func move(direction: Vector2, delta: float) -> void:
    if not is_enabled or not can_move:
        return
    
    _velocity = direction.normalized() * speed
    var owner_node = get_owner_node()
    if owner_node:
        owner_node.position += _velocity * delta

func stop() -> void:
    _velocity = Vector2.ZERO

func _on_disabled() -> void:
    stop()
```

---

## Factory Examples

### Example 1: Item Factory with Caching

```gdscript
# item_factory.gd
extends "res://addons/cts_core/Core/base_factory.gd"

func _init():
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    var config = TypeDefs.FactoryConfig.new()
    config.cache_enabled = true
    config.max_cache_size = 50
    config.cache_timeout_ms = 30000  # 30 seconds
    super._init(config)

func create_item(item_id: StringName) -> Resource:
    var path = "res://data/items/%s.tres" % item_id
    var item = cache_resource(path)
    
    if item:
        resource_created.emit("Item", item)
    
    return item
```

**Usage**:

```gdscript
var factory = ItemFactory.new()
add_child(factory)

# First load - cache miss
var sword = factory.create_item(&"sword_001")
print("Loaded sword: ", sword.resource_id)

# Second load - cache hit!
var sword2 = factory.create_item(&"sword_001")
print("Same instance: ", sword == sword2)  # true

# Check cache stats
print("Cached items: ", factory.get_cache_size())
```

### Example 2: Enemy Spawner Factory

```gdscript
# enemy_spawner.gd
extends "res://addons/cts_core/Core/base_factory.gd"

@export var spawn_parent: NodePath

func create_enemy(enemy_type: String, position: Vector2) -> Node:
    var scene_path = "res://enemies/%s.tscn" % enemy_type.to_lower()
    var parent = get_node_or_null(spawn_parent)
    
    var enemy = create_node(scene_path, parent)
    if enemy:
        enemy.position = position
        
        # Add components
        var health = HealthComponent.new()
        health.max_health = 50
        enemy.add_child(health)
        
        var movement = MovementComponent.new()
        movement.speed = 75.0
        enemy.add_child(movement)
    
    return enemy
```

**Usage**:

```gdscript
var spawner = EnemySpawner.new()
spawner.spawn_parent = ^"Enemies"
add_child(spawner)

# Spawn enemies
var goblin = spawner.create_enemy("Goblin", Vector2(100, 100))
var orc = spawner.create_enemy("Orc", Vector2(200, 150))
```

### Example 3: Resource Pool with Validation

```gdscript
# resource_pool.gd
extends "res://addons/cts_core/Core/base_factory.gd"

func load_and_validate(path: String) -> Resource:
    var resource = cache_resource(path)
    
    if resource and resource.has_method("validate"):
        if not resource.validate():
            push_error("Resource validation failed: %s" % path)
            for error in resource.get_validation_errors():
                push_error("  - %s" % error)
            return null
    
    return resource
```

---

## Processor Examples

### Example 1: AI Update Processor

```gdscript
# ai_processor.gd
extends "res://addons/cts_core/Core/base_processor.gd"

func _init():
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    var config = TypeDefs.ProcessorConfig.new()
    config.processing_mode = 0  # IDLE mode
    config.frame_budget_ms = 2.0
    config.max_items_per_frame = 20
    super._init(config)

func _process_item(entity: Variant, delta: float) -> void:
    if not is_instance_valid(entity):
        return
    
    # Update AI behavior
    var ai_component = CTS_Core.find_component(entity, "AIComponent")
    if ai_component and ai_component.is_enabled:
        ai_component.update(delta)
```

**Usage**:

```gdscript
var ai_processor = AIProcessor.new()
add_child(ai_processor)

# Add entities to process
ai_processor.add_item(enemy1)
ai_processor.add_item(enemy2)
ai_processor.add_item(enemy3)

# Processor runs automatically in _process()
# Check stats
var stats = ai_processor.get_stats()
print("Processed: ", stats.total_items_processed)
print("Avg time: ", stats.average_time_per_frame, "ms")

# Pause if needed
ai_processor.pause()
```

### Example 2: Status Effect Processor

```gdscript
# status_effect_processor.gd
extends "res://addons/cts_core/Core/base_processor.gd"

class StatusEffect:
    var entity: Node
    var effect_type: String
    var duration: float
    var tick_interval: float
    var time_since_tick: float = 0.0

func _init():
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    var config = TypeDefs.ProcessorConfig.new()
    config.frame_budget_ms = 1.0
    super._init(config)

func _process_item(item: Variant, delta: float) -> void:
    var effect = item as StatusEffect
    if not is_instance_valid(effect.entity):
        remove_item(item)
        return
    
    # Update duration
    effect.duration -= delta
    if effect.duration <= 0:
        _remove_effect(effect)
        remove_item(item)
        return
    
    # Apply tick damage/healing
    effect.time_since_tick += delta
    if effect.time_since_tick >= effect.tick_interval:
        _apply_effect_tick(effect)
        effect.time_since_tick = 0.0

func _apply_effect_tick(effect: StatusEffect) -> void:
    match effect.effect_type:
        "poison":
            var health = CTS_Core.find_component(effect.entity, "HealthComponent")
            if health:
                health.take_damage(5)
        "regen":
            var health = CTS_Core.find_component(effect.entity, "HealthComponent")
            if health:
                health.heal(3)

func _remove_effect(effect: StatusEffect) -> void:
    print("Effect %s expired on %s" % [effect.effect_type, effect.entity.name])
```

### Example 3: Batch Processing with Manual Mode

```gdscript
# batch_processor.gd
extends "res://addons/cts_core/Core/base_processor.gd"

func _init():
    var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")
    var config = TypeDefs.ProcessorConfig.new()
    config.processing_mode = 2  # MANUAL mode
    config.frame_budget_ms = 5.0  # Longer budget for batch
    super._init(config)

func process_batch(items: Array) -> void:
    clear_items()
    for item in items:
        add_item(item)
    
    # Process all items manually
    process_items(0.0)
    
    # Get results
    var stats = get_stats()
    print("Batch processed %d items in %.2f ms" % [stats.total_items_processed, stats.total_processing_time])

func _process_item(item: Variant, delta: float) -> void:
    # Custom batch processing logic
    item.process_batch_data()
```

---

## Resource Examples

### Example 1: Item Resource with Validation

```gdscript
# item_resource.gd
extends "res://addons/cts_core/Core/base_resource.gd"
class_name ItemResource

@export var item_name: String = ""
@export var description: String = ""
@export var weight: float = 1.0
@export var value: int = 10
@export var max_stack: int = 1

func _validate_custom() -> void:
    var result = get_validation_result()
    
    if item_name.is_empty():
        result.add_error("item_name cannot be empty")
    
    if weight < 0:
        result.add_error("weight must be non-negative")
    
    if weight > 100.0:
        result.add_warning("weight is very high (>100)")
    
    if value < 0:
        result.add_error("value must be non-negative")
    
    if max_stack < 1:
        result.add_error("max_stack must be at least 1")

func to_dict() -> Dictionary:
    var data = super.to_dict()
    data["item_name"] = item_name
    data["description"] = description
    data["weight"] = weight
    data["value"] = value
    data["max_stack"] = max_stack
    return data

func from_dict(data: Dictionary) -> void:
    super.from_dict(data)
    item_name = data.get("item_name", "")
    description = data.get("description", "")
    weight = data.get("weight", 1.0)
    value = data.get("value", 10)
    max_stack = data.get("max_stack", 1)
```

**Usage**:

```gdscript
# Create item
var sword = ItemResource.new()
sword.resource_id = &"sword_001"
sword.item_name = "Iron Sword"
sword.weight = 5.0
sword.value = 100

# Validate
if sword.validate():
    print("Item is valid")
else:
    print("Validation errors:")
    for error in sword.get_validation_errors():
        print("  - ", error)

# Serialize
var save_data = sword.to_dict()
var json = JSON.stringify(save_data)

# Deserialize
var loaded_sword = ItemResource.new()
loaded_sword.from_dict(JSON.parse_string(json))
```

### Example 2: Quest Resource

```gdscript
# quest_resource.gd
extends "res://addons/cts_core/Core/base_resource.gd"
class_name QuestResource

@export var quest_name: String = ""
@export var objectives: Array[String] = []
@export var rewards: Array[Resource] = []
@export var required_level: int = 1

func _validate_custom() -> void:
    var result = get_validation_result()
    
    if quest_name.is_empty():
        result.add_error("quest_name cannot be empty")
    
    if objectives.is_empty():
        result.add_warning("quest has no objectives")
    
    if required_level < 1:
        result.add_error("required_level must be at least 1")
```

---

## Registry Query Examples

### Example 1: Find Components by Type

```gdscript
# Get all health components
var health_components = CTS_Core.get_components_by_type("HealthComponent")
for comp in health_components:
    print("%s has %d health" % [comp.get_parent().name, comp.current_health])
```

### Example 2: Custom Filter Query

```gdscript
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")

# Find low-health entities
var query = TypeDefs.RegistryQuery.new()
query.component_type = "HealthComponent"
query.custom_filter = func(component: Node, metadata) -> bool:
    return component.current_health < component.max_health * 0.25

var low_health = CTS_Core.query_components(query)
print("Found %d low-health entities" % low_health.size())
```

### Example 3: Find Enabled Components

```gdscript
var TypeDefs = preload("res://addons/cts_core/Data/type_definitions.gd")

var query = TypeDefs.RegistryQuery.new()
query.component_type = "AIComponent"
query.custom_filter = func(component: Node, metadata) -> bool:
    return component.is_enabled

var active_ai = CTS_Core.query_components(query)
print("%d AI components are active" % active_ai.size())
```

### Example 4: Batch Operations

```gdscript
# Disable all AI when player enters safe zone
func enter_safe_zone():
    var ai_components = CTS_Core.get_components_by_type("AIComponent")
    for ai in ai_components:
        ai.disable()

# Re-enable on exit
func exit_safe_zone():
    var ai_components = CTS_Core.get_components_by_type("AIComponent")
    for ai in ai_components:
        ai.enable()
```

---

## Integration Patterns

### Example 1: Entity with Multiple Components

```gdscript
# enemy.gd
extends CharacterBody2D

var health_component: Node
var movement_component: Node
var ai_component: Node
var inventory_component: Node

func _ready():
    # Create components
    health_component = HealthComponent.new()
    health_component.max_health = 100
    add_child(health_component)
    
    movement_component = MovementComponent.new()
    movement_component.speed = 75.0
    add_child(movement_component)
    
    ai_component = AIComponent.new()
    add_child(ai_component)
    
    inventory_component = InventoryComponent.new()
    inventory_component.max_slots = 5
    add_child(inventory_component)
    
    # Connect signals
    health_component.died.connect(_on_died)
    inventory_component.item_added.connect(_on_item_added)

func _on_died():
    # Drop inventory
    for item in inventory_component.items:
        spawn_dropped_item(item, global_position)
    
    queue_free()

func _on_item_added(item: Resource):
    print("%s picked up %s" % [name, item.item_name])
```

### Example 2: System Manager

```gdscript
# combat_system.gd
extends Node

var combat_processor: Node
var effect_processor: Node

func _ready():
    # Set up processors
    combat_processor = CombatProcessor.new()
    add_child(combat_processor)
    
    effect_processor = StatusEffectProcessor.new()
    add_child(effect_processor)
    
    # Connect to events
    EventBus.combat_started.connect(_on_combat_started)
    EventBus.combat_ended.connect(_on_combat_ended)

func _on_combat_started():
    # Get all combatants
    var combatants = CTS_Core.get_components_by_type("CombatComponent")
    for combatant in combatants:
        combat_processor.add_item(combatant)

func _on_combat_ended():
    combat_processor.clear_items()
```

### Example 3: Save/Load System

```gdscript
# save_system.gd
extends Node

func save_game(save_path: String) -> void:
    var save_data = {
        "player": _save_entity(player),
        "enemies": _save_entities("EnemyEntity"),
        "timestamp": Time.get_unix_time_from_system()
    }
    
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()

func _save_entity(entity: Node) -> Dictionary:
    var data = {
        "name": entity.name,
        "position": {"x": entity.position.x, "y": entity.position.y},
        "components": {}
    }
    
    # Save health
    var health = CTS_Core.find_component(entity, "HealthComponent")
    if health:
        data.components["health"] = {
            "current": health.current_health,
            "max": health.max_health
        }
    
    # Save inventory
    var inventory = CTS_Core.find_component(entity, "InventoryComponent")
    if inventory:
        var items = []
        for item in inventory.items:
            items.append(item.to_dict())
        data.components["inventory"] = {"items": items}
    
    return data

func _save_entities(type: String) -> Array:
    var entities = []
    var components = CTS_Core.get_components_by_type(type)
    for comp in components:
        var entity = comp.get_parent()
        if entity:
            entities.append(_save_entity(entity))
    return entities
```

---

## Advanced Patterns

### Example 1: Component Communication via Signals

```gdscript
# damage_component.gd
extends "res://addons/cts_core/Core/base_component.gd"

signal damage_dealt(target: Node, amount: int)

func deal_damage(target: Node, amount: int) -> void:
    var target_health = CTS_Core.find_component(target, "HealthComponent")
    if target_health:
        target_health.take_damage(amount)
        damage_dealt.emit(target, amount)

# combat_component.gd
extends "res://addons/cts_core/Core/base_component.gd"

func initialize() -> void:
    super.initialize()
    
    # Find damage component on same entity
    var owner = get_owner_node()
    var damage_comp = CTS_Core.find_component(owner, "DamageComponent")
    if damage_comp:
        damage_comp.damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(target: Node, amount: int):
    print("Dealt %d damage to %s!" % [amount, target.name])
```

### Example 2: Dynamic Component Loading

```gdscript
# entity_builder.gd
extends Node

var component_factory: BaseFactory

func build_entity(template: Dictionary) -> Node:
    var entity = Node.new()
    entity.name = template.get("name", "Entity")
    
    # Add components from template
    for comp_data in template.get("components", []):
        var component = _create_component(comp_data)
        if component:
            entity.add_child(component)
    
    return entity

func _create_component(data: Dictionary) -> Node:
    var type = data.get("type", "")
    var script_path = "res://components/%s.gd" % type.to_snake_case()
    
    var script = load(script_path)
    if script:
        var component = script.new()
        
        # Apply properties
        for key in data.get("properties", {}).keys():
            component.set(key, data.properties[key])
        
        return component
    
    return null
```

### Example 3: Performance Monitoring

```gdscript
# performance_monitor.gd
extends Node

func _ready():
    # Monitor all processors
    _connect_processor_signals("AIProcessor")
    _connect_processor_signals("StatusEffectProcessor")
    _connect_processor_signals("CombatProcessor")

func _connect_processor_signals(type: String):
    var processors = CTS_Core.get_components_by_type(type)
    for processor in processors:
        processor.budget_exceeded.connect(_on_budget_exceeded.bind(type))

func _on_budget_exceeded(elapsed_ms: float, processor_type: String):
    push_warning("%s exceeded budget: %.2f ms" % [processor_type, elapsed_ms])
    
    # Log to analytics
    var stats = {
        "processor": processor_type,
        "elapsed": elapsed_ms,
        "timestamp": Time.get_ticks_msec()
    }
    _log_performance_issue(stats)
```

---

## Testing Examples

### Example 1: Component Unit Test

```gdscript
# test_health_component.gd
extends GutTest

var _health_component: Node

func before_each():
    _health_component = HealthComponent.new()
    _health_component.max_health = 100
    add_child_autofree(_health_component)
    await get_tree().process_frame

func test_component_registers_with_core():
    assert_true(CTS_Core.is_component_registered(_health_component))

func test_take_damage_reduces_health():
    _health_component.take_damage(25)
    assert_eq(_health_component.current_health, 75)

func test_health_cannot_go_negative():
    _health_component.take_damage(150)
    assert_eq(_health_component.current_health, 0)

func test_died_signal_emitted_on_zero_health():
    watch_signals(_health_component)
    _health_component.take_damage(100)
    assert_signal_emitted(_health_component, "died")
```

---

## See Also

- [API Reference](API_REFERENCE.md) - Complete API documentation
- [Signal Contracts](SIGNAL_CONTRACTS.md) - Signal usage and payloads
- [Architecture](ARCHITECTURE.md) - System design and patterns
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions