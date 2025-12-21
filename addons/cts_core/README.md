# CTS Core

Foundation addon for the CTS Toolbox ecosystem - provides base classes, component registry, and infrastructure patterns for Godot 4.x game development.

## Features

- **Component Registry**: Auto-registration system with type-based discovery
- **Base Classes**: BaseComponent, BaseResource, BaseFactory, BaseProcessor
- **Signal-First Architecture**: Pre-defined signals for decoupled systems
- **Frame Budget Enforcement**: Processing loops with performance targets
- **Resource Caching**: LRU cache with configurable limits
- **Signature Validation**: Version compatibility checks across addons
- **Type Safety**: Headless-compatible, explicit types throughout

## Quick Start

### Installation

1. Copy `addons/cts_core/` to your project's `addons/` folder
2. Enable plugin: **Project → Project Settings → Plugins → CTS Core**
3. Verify autoload registered: **Project → Project Settings → Autoload** (should see "CTS_Core")

### Creating a Custom Component

```gdscript
extends "res://addons/cts_core/Core/base_component.gd"
class_name MyComponent

func _ready() -> void:
    component_type = "MyComponent"  # REQUIRED
    super._ready()  # Auto-registers with CTS_Core

func initialize() -> void:
    super.initialize()
    print("MyComponent initialized!")
```

### Discovering Components

```gdscript
# Get all components of a type
var all_cameras: Array[Node] = CTS_Core.get_components_by_type("Camera")

# Find component on specific node
var inventory = CTS_Core.find_component(player.get_path(), "InventoryComponent")

# Advanced query with filter
var query = RegistryQuery.new()
query.component_type = "Enemy"
query.filter_callback = func(node: Node) -> bool:
    return node.health > 0
var alive_enemies = CTS_Core.query_components(query)
```

## Core Concepts

### Auto-Registration

Components automatically register with `CTS_Core` manager when added to scene tree:
1. Component added to tree via `add_child()` or scene instantiation
2. `_ready()` validates `component_type` property
3. Component registers with global registry
4. Manager emits `component_registered` signal

### Signal-First Design

All signals documented **before** implementation in [SIGNAL_CONTRACTS.md](docs/SIGNAL_CONTRACTS.md). Enables:
- Decoupled systems (no direct references)
- Clear API contracts
- Easy testing (signal watchers)

### Frame Budget System

`BaseProcessor` enforces performance targets:
- Default: 2ms per system (allows 8 systems at 60 FPS)
- Configurable via `ProcessorConfig.frame_budget_ms`
- Emits `budget_exceeded` signal when over budget
- Tracks performance with `ProcessingStats`

### Loose Coupling

- BaseComponent has **NO class_name** (loose coupling by design)
- Components identified by `component_type: String` property
- Query system uses filter callbacks, not class checks
- Systems communicate via signals, not direct calls

## Documentation

- **[Architecture](docs/ARCHITECTURE.md)** - System design, flowcharts, integration patterns
- **[API Reference](docs/API_REFERENCE.md)** - Complete method signatures and examples
- **[Signal Contracts](docs/SIGNAL_CONTRACTS.md)** - All signal definitions (20 signals)
- **[Examples](docs/EXAMPLES.md)** - Code samples for common use cases
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common errors and solutions

## CTS Toolbox Ecosystem

CTS Core is the foundation for 13+ specialized addons:
- `cts_entity` - Entity spawning and lifecycle management
- `cts_items` - Item system with crafting
- `cts_combat` - Combat resolution and damage calculation
- `cts_abilities` - Skills and ability system
- `cts_progression` - Leveling and experience
- `cts_factions` - Faction reputation and relationships
- `cts_needs` - Survival needs (hunger, thirst, etc.)
- `cts_time` - Game time and calendar system
- `cts_ai` - AI behavior and state machines
- `cts_economy` - Trading and economy simulation
- `cts_resources` - Resource gathering and management
- `cts_spawner` - Advanced spawning with pooling
- `cts_affix` - Procedural item modifiers

All addons validate `CORE_SIGNATURE` for compatibility.

## Testing

CTS Core includes **85 comprehensive tests** using the GUT framework:
- 15 CoreManager tests (registration, queries, signatures)
- 18 BaseComponent tests (lifecycle, signals, state)
- 12 BaseResource tests (validation, serialization)
- 16 BaseFactory tests (caching, LRU eviction)
- 14 BaseProcessor tests (frame budgets, queues)
- 10 Integration tests (cross-system workflows)

Run tests:
```bash
# Headless mode
godot4 --headless -s addons/gut/gut_cmdln.gd -gtest=res://addons/cts_core/test/

# Or via GUT panel in editor
```

## Requirements

- **Godot**: 4.3+ (tested on 4.5)
- **GDScript**: 2.0+ (static typing required)
- **GUT**: 9.0+ (for tests)

## CTS Methodology

CTS Core follows Close-to-Shore (CTS) methodology:
- **<500 lines per file**: All files under limit
- **Signal-first**: Signals documented before implementation
- **Type safety**: Explicit types, `Array[Type]` syntax
- **Frame budgets**: 2ms performance targets
- **Test-driven**: 10-20 tests Phase 1, 30+ tests Phase 2

See [../../cts/00_CTS_CORE.md](../../cts/00_CTS_CORE.md) for methodology details.

## License

[Your License Here]

## Contributing

1. Follow CTS methodology standards
2. Document signals in SIGNAL_CONTRACTS.md before implementation
3. Add tests for new features (min 10-20 tests)
4. Keep files under 500 lines
5. Update documentation