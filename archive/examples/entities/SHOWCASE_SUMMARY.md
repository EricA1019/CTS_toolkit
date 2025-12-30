# CTS Toolbox - Showcase Example Summary

## Overview
The showcase example demonstrates integration of multiple CTS plugins working together on a single entity. This serves as a reference implementation and testing ground for plugin compatibility.

## Current Implementation

### Integrated Plugins
1. **cts_entity** - Entity lifecycle management
2. **cts_skills** - Usage-based skill progression system

### Features Demonstrated
- ✅ Entity creation with EntityConfig
- ✅ SkillsComponent attachment to entity
- ✅ Skill XP gain and leveling mechanics
- ✅ Signal-based feedback system
- ✅ Interactive keyboard controls
- ✅ Registry-based signal routing (CTS_Skills singleton)

### Available Skill Types
The showcase uses these skills from the cts_skills plugin:
- **UNARMED** (Combat skill) - Starting Level 5
- **SNEAKING** (Survival skill) - Starting Level 3  
- **SCAVENGING** (Crafting skill) - Starting Level 1
- **LOCKPICKING** (Survival skill) - Starting Level 0

## Interactive Controls
- **Key 1**: Gain +50 XP in Unarmed Combat
- **Key 2**: Gain +50 XP in Sneaking
- **Key 3**: Gain +50 XP in Scavenging  
- **Key 4**: Gain +50 XP in Lockpicking
- **Space**: Display current skill levels

## Automated Demo Sequence
1. Entity spawns at position (400, 300)
2. Skills system initializes with preset levels
3. After 1 second: Gains 150 XP in Unarmed Combat
4. After 2 seconds: Gains 200 XP in Sneaking
5. After 3 seconds: Gains 300 XP in Scavenging
6. Final levels displayed

## Signal Flow Architecture

```
┌─────────────────────────────────────┐
│  SkillsComponent (on Entity)        │
│  - gain_xp(skill, amount, source)   │
└──────────────┬──────────────────────┘
               │ calls _emit methods
               ▼
┌─────────────────────────────────────┐
│  CTS_Skills Registry (Singleton)    │
│  - Emits xp_gained signal           │
│  - Emits skill_leveled_up signal    │
└──────────────┬──────────────────────┘
               │ broadcast
               ▼
┌─────────────────────────────────────┐
│  showcase_example.gd (Listeners)    │
│  - _on_xp_gained()                  │
│  - _on_skill_leveled_up()           │
└─────────────────────────────────────┘
```

## Next Steps for Expansion

### Plugins to Add
1. **cts_progression_stats** - Core stats system (STR, DEX, INT, etc.)
2. **cts_abilities** - Active/passive abilities tied to skills
3. **cts_items** - Equipment and inventory (already partially integrated with gloot)
4. **cts_combat** - Combat mechanics using skills and stats
5. **cts_needs** - Survival needs (hunger, thirst, fatigue)
6. **cts_ai** - AI behaviors for NPCs
7. **cts_factions** - Faction relationships and reputation

### Integration Ideas
- **Skills + Stats**: Skill levels provide stat bonuses
- **Skills + Abilities**: Unlock abilities at skill thresholds
- **Skills + Combat**: Skill checks during combat resolution
- **Skills + Items**: Crafting requirements based on skill levels
- **Skills + Needs**: Skills affect need decay rates

## Testing the Example

### Setup
1. Open Godot 4.x project
2. Enable these plugins in Project Settings:
   - cts_core
   - cts_entity  
   - cts_skills
3. Create new scene with Node2D root
4. Attach `showcase_example.gd` script
5. Run scene

### Expected Console Output
```
[Showcase] Hero spawned with ID: showcase_hero
[Showcase] Skills initialized:
  - Unarmed Combat: Level 5
  - Sneaking: Level 3
  - Scavenging: Level 1
  - Lockpicking: Level 0

[Showcase] Gaining Unarmed Combat XP...
[Showcase] +150.0 XP to UNARMED (Level 5, Progress: 45.2%, Source: training)

[Showcase] Gaining Sneaking XP...
[Showcase] +200.0 XP to SNEAKING (Level 3, Progress: 78.9%, Source: stealth_practice)
[Showcase] ⚡ LEVEL UP! SNEAKING: 3 → 4 (Entity: showcase_hero)

[Showcase] Gaining Scavenging XP...
[Showcase] +300.0 XP to SCAVENGING (Level 1, Progress: 12.5%, Source: looting)
[Showcase] ⚡ LEVEL UP! SCAVENGING: 1 → 2 (Entity: showcase_hero)

[Showcase] Final skill levels:
  - Unarmed Combat: Level 5
  - Sneaking: Level 4
  - Scavenging: Level 2
```

## Files
- **Script**: `examples/entities/showcase_example.gd`
- **Scene**: (Create manually or via editor)
- **Documentation**: `examples/entities/README.md` (updated)

## Architecture Notes
- Follows **Signal-First** CTS principle
- Uses **EntityConfig** pattern from cts_entity
- Uses **SkillBlock** resource for skill configuration
- Signals route through registry singleton (not component)
- Entity ID used for signal filtering (supports multiple entities)

## Performance Considerations
- XP calculations use exponential curve (configurable)
- Level-up loops handled in single frame
- Signal emissions batched per operation
- No visual overhead (console-only demo)

## Related Documentation
- [CTS Core Methodology](../../cts/00_CTS_CORE.md)
- [Signal-First Architecture](../../cts/concepts/SIGNAL_FIRST.md)
- [cts_entity README](../../addons/cts_entity/README.md)
- [cts_skills README](../../addons/cts_skills/README.md)
