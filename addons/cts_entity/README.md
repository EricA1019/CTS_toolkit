# cts_entity

**Entity lifecycle management plugin** - Pure containers for component-based game systems.

## Features

- ✅ **Hybrid Creation**: Data-driven (procedural mobs) + Scene-based (handcrafted NPCs)
- ✅ **Smart ID Generation**: Unique entities ("detective") vs auto-increment ("bandit_001")
- ✅ **Full Lifecycle**: Spawn → Ready → Despawn → Cleanup
- ✅ **Signal-First**: Zero hardcoded dependencies, plugin integration via signals
- ✅ **Container Architecture**: Stats, Inventory, Abilities, Components containers
- ✅ **Batch Despawn**: Staggered cleanup (3 entities/frame, prevents lag spikes)
- ✅ **Death Sprite Support**: Await sprite swap before cleanup

## Quick Start

```gdscript
# Create entity config
var config = EntityConfig.new()
config.entity_id = "bandit"
config.is_unique = false  # Auto-increment: bandit_001, bandit_002...
config.custom_data["stats_path"] = "res://data/stats/bandit.tres"

# Spawn entity
var bandit = CTS_Entity.spawn_at_position(config, Vector2(100, 200), get_tree().root)

# Get entity later
var entity = CTS_Entity.get_entity("bandit_001")

# Despawn entity
entity.despawn("death")

# Batch cleanup (combat end)
CTS_Entity.despawn_all_by_type("bandit", "combat_end")
await CTS_Entity.batch_despawn_complete
```

## Documentation

- [SIGNAL_CONTRACTS.md](docs/SIGNAL_CONTRACTS.md) - All entity signals with examples
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Design patterns and integration
- [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) - Complete development plan
- [API_REFERENCE.md](docs/API_REFERENCE.md) - Public API methods
- [EXAMPLES.md](docs/EXAMPLES.md) - Usage patterns

## Required Container Names

Custom scenes **must** include these exact node names:
- `StatsContainer`
- `InventoryContainer`
- `AbilitiesContainer`
- `ComponentsContainer`

## Integration with Other Plugins

**cts_stats**: Attach StatsComponent to `entity.stats_container`  
**cts_items**: Attach InventoryComponent to `entity.inventory_container`  
**cts_abilities**: Attach AbilitiesComponent to `entity.abilities_container`  
**cts_movement**: Attach MovementComponent to `entity.components_container`

Listen to `entity_ready` signal to know when entity is ready for component attachment.

## Autoload

**CTS_Entity** - EntityManager singleton (auto-added by plugin)
