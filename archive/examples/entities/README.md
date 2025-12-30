# CTS Entity Plugin Examples

This directory contains example scripts demonstrating how to use the cts_entity plugin.

## Examples

### detective_example.gd
Demonstrates **unique entity** creation:
- Single instance enforcement (`is_unique = true`)
- Custom data attachment
- Direct ID assignment (no auto-increment)

**Usage**:
1. Enable cts_core and cts_entity plugins in Godot
2. Create a new scene with Node2D root
3. Attach `detective_example.gd` script
4. Run scene - detective will spawn with ID "detective"

### bandit_example.gd  
Demonstrates **procedural entity** creation:
- Multiple instances with auto-increment IDs (`is_unique = false`)
- Batch spawning (5 bandits)
- Batch despawn with staggering (3 entities/frame)

**Usage**:
1. Enable cts_core and cts_entity plugins in Godot
2. Create a new scene with Node2D root
3. Attach `bandit_example.gd` script
4. Run scene - 5 bandits spawn with IDs bandit_001 through bandit_005
5. After 3 seconds, all bandits despawn in staggered batches

### showcase_example.gd
Demonstrates **multi-plugin integration** (cts_entity + cts_skills):
- Unique showcase entity with skills system
- SkillsComponent attachment and configuration
- Skill XP gain and leveling mechanics
- Interactive keyboard controls (press 1-4 for skill XP, Space for status)
- Signal-based feedback (level ups, XP gains)

**Usage**:
1. Enable cts_core, cts_entity, and cts_skills plugins in Godot
2. Create a new scene with Node2D root
3. Attach `showcase_example.gd` script
4. Run scene - hero spawns with initial skills
5. Watch automated skill XP demo (3 seconds)
6. Press 1-4 keys to manually gain XP in different skills
7. Press Space to view current skill levels

## Key Concepts Demonstrated

**Unique vs Non-Unique**:
- Unique: `is_unique = true` → ID stays as defined (e.g., "detective")
- Non-Unique: `is_unique = false` → Auto-increment counter appended (e.g., "bandit_001")

**Entity Lifecycle**:
1. Create EntityConfig resource
2. Call `CTS_Entity.create_entity(config, parent)`
3. Entity registers automatically via `entity_spawned` signal
4. Access via `CTS_Entity.get_entity(id)` or `CTS_Entity.get_entities_by_type(type)`
5. Despawn via `entity.despawn(reason)` or batch via `CTS_Entity.despawn_all_by_type(type, reason)`

**Signals Emitted**:
- `EntityBase.entity_ready` - Entity initialization complete
- `EntityFactory.entity_spawned` - New entity created
- `EntityBase.entity_despawning` - Entity cleanup starting
- `EntityManager.entity_registered` - Entity added to registry
- `EntityManager.entity_unregistered` - Entity removed from registry
- `EntityManager.batch_despawn_started` - Batch operation initiated
- `EntityManager.batch_despawn_complete` - All entities despawned

## Testing

Tests are located in `addons/cts_entity/test/test_cts_entity.gd` (25 comprehensive tests).

**Running Tests**:
1. Enable GUT plugin in Godot
2. Open GUT panel (bottom panel)
3. Click "Run All" to execute cts_entity tests

**Note**: Tests require the Godot editor with plugins enabled (headless mode has type inference limitations).

## Next Steps

After testing cts_entity:
- Implement `cts_stats` plugin (integrates with EntityBase.stats_container)
- Implement `cts_movement` plugin (tile-based movement system)
- Implement `cts_abilities` plugin (integrates with EntityBase.abilities_container)
