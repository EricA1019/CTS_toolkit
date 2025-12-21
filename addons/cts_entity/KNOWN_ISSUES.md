# CTS Entity Plugin - Known Issues & Improvements

## Issues Discovered During Phase 1

### 1. Headless Testing Limitations
**Issue**: Tests cannot run in `godot4 --headless` mode due to type inference errors  
**Cause**: GDScript parser can't resolve types without editor cache in headless mode  
**Workaround**: Tests must be run in Godot editor using GUT panel  
**Status**: Documented in examples/entities/README.md  

### 2. Mixed Indentation
**Issue**: Some auto-generated stubs had spaces instead of tabs  
**Fix**: Removed trailing `func _ready() -> void: pass` stubs from entity_factory.gd and entity_manager.gd  
**Status**: ✅ Fixed  

### 3. Missing Type Preloads
**Issue**: entity_manager.gd couldn't find EntityBase, EntityFactory, EntityConfig types  
**Fix**: Added const preloads at top of file  
**Status**: ✅ Fixed  

## Improvements Needed (Phase 2)

### Performance
- [ ] Implement entity pooling (reuse despawned entities instead of destroying)
- [ ] Add frame budget monitoring (log if despawn takes >2ms)
- [ ] Optimize registry lookups (use Dictionary instead of linear search)

### Features
- [ ] Add entity serialization (save/load entity state)
- [ ] Add entity cloning (duplicate existing entity)
- [ ] Add entity groups (tag entities for batch operations beyond type)
- [ ] Add entity query system (find entities by properties)

### Developer Experience
- [ ] Create EditorPlugin for visual entity spawning
- [ ] Add entity inspector (view all entities in scene)
- [ ] Add performance profiler overlay
- [ ] Generate documentation from signal contracts

### Testing
- [ ] Investigate GDScript preload workaround for headless testing
- [ ] Add integration tests with actual game scenes
- [ ] Add stress tests (1000+ entity spawning)
- [ ] Add memory leak tests (repeated spawn/despawn cycles)

## Phase 1 Completion Status

✅ **Core Implementation**: EntityConfig, EntityBase, EntityFactory, EntityManager (850+ lines)  
✅ **Documentation**: README, IMPLEMENTATION_PLAN, SIGNAL_CONTRACTS, examples  
✅ **Tests**: 25 comprehensive unit tests written  
✅ **Cleanup**: Removed redundant stubs (entity_spawner, entity_data, entity_component)  
⚠️ **Testing**: Tests require Godot editor (headless mode blocked by type inference)  
📝 **Examples**: Detective (unique) and Bandit (procedural) examples created  

## Next Plugin: cts_stats

Dependencies:
- ✅ cts_core (complete)
- ✅ cts_entity (Phase 1 complete - containers ready)
- 📋 Integrates with EntityBase.stats_container

Design Goals:
- Stat blocks (health, mana, strength, etc.)
- Stat modifiers (temporary/permanent)
- Stat calculations (base + modifiers)
- Stat change events (for UI updates)
- Integration with entity lifecycle
