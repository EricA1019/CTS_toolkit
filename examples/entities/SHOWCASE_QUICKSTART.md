# 🎮 Showcase Example - Quick Start Guide

## What This Does
Demonstrates **cts_entity + cts_skills** integration with a living, breathing entity that gains XP and levels up skills.

## 🚀 Run It (3 Steps)

1. **Enable Plugins** (Project Settings → Plugins):
   - ✅ cts_core
   - ✅ cts_entity
   - ✅ cts_skills

2. **Create Scene**:
   - New Scene → Other Node → Node2D
   - Attach script: `examples/entities/showcase_example.gd`
   - Save as `showcase_demo.tscn`

3. **Run Scene** (F6)
   - Watch console for automated demo
   - Press 1-4 keys to gain skill XP
   - Press Space to check levels

## 🎹 Controls
| Key | Action |
|-----|--------|
| `1` | +50 XP to Unarmed Combat |
| `2` | +50 XP to Sneaking |
| `3` | +50 XP to Scavenging |
| `4` | +50 XP to Lockpicking |
| `Space` | Show current levels |

## 📊 What You'll See

```
[Showcase] Hero spawned with ID: showcase_hero
[Showcase] Skills initialized:
  - Unarmed Combat: Level 5
  - Sneaking: Level 3
  - Scavenging: Level 1
  - Lockpicking: Level 0

[Showcase] Gaining Unarmed Combat XP...
[Showcase] +150.0 XP to UNARMED (Level 5, Progress: 45.2%)

[Showcase] ⚡ LEVEL UP! SNEAKING: 3 → 4 (Entity: showcase_hero)
```

## 🔍 What's Happening Under the Hood

1. **Entity Creation** (cts_entity)
   - Spawns unique entity "showcase_hero"
   - Registered in entity manager
   - Positioned at (400, 300)

2. **Skills Initialization** (cts_skills)
   - SkillsComponent attached to entity
   - 4 skills configured with starting levels
   - XP curves set (exponential, base 100, mult 1.15)

3. **Signal Flow**
   ```
   SkillsComponent.gain_xp()
       ↓
   CTS_Skills.xp_gained signal
       ↓
   showcase_example._on_xp_gained()
   ```

4. **Auto Demo** (3 seconds)
   - Gains XP in 3 different skills
   - Some skills level up
   - Final status displayed

5. **Interactive Mode**
   - Keyboard input processed
   - XP gains visible in console
   - Level-ups announced with ⚡

## 🐛 Troubleshooting

**No output?**
- Check plugins are enabled
- Check Output panel (not just console)
- Verify CTS_Skills autoload exists

**"CTS_Skills registry not found"?**
- Plugin not enabled in Project Settings
- Restart editor after enabling

**Signals not firing?**
- Check CTS_Skills autoload in Project → Project Settings → Autoload
- Should be: `CTS_Skills` → `res://addons/cts_skills/Core/skills_registry.gd`

## 📚 Next Steps

1. **Add more plugins**: Try cts_progression_stats, cts_abilities
2. **Visual feedback**: Add UI panels showing skill bars
3. **Multiple entities**: Spawn NPCs with different skills
4. **Skill checks**: Implement skill roll mechanics
5. **Persistence**: Save/load skill data

## 📄 Related Files
- Script: [showcase_example.gd](showcase_example.gd)
- Details: [SHOWCASE_SUMMARY.md](SHOWCASE_SUMMARY.md)
- Entity Plugin: [../../addons/cts_entity/](../../addons/cts_entity/)
- Skills Plugin: [../../addons/cts_skills/](../../addons/cts_skills/)
