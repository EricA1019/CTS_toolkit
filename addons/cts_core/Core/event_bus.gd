extends Node

## EventBus for CTS Toolbox
## Central hub for system-wide signals.

# Entity Signals
signal entity_spawned(entity_id: String, entity_type: String)
signal entity_despawned(entity_id: String)
signal entity_health_changed(entity_id: String, new_health: int, max_health: int)
signal stat_changed(entity_id: String, stat: String, value: int)

# System Signals
signal game_started
signal game_paused(is_paused: bool)
