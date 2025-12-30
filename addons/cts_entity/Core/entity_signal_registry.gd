extends Node

## Entity Signal Registry - Centralized signal definitions for cts_entity plugin
## Autoloaded as "EntitySignalRegistry" - access via Engine.get_singleton()
## All entity-related signals defined here for consistency and discoverability
##
## Signal-First Architecture (CTS Methodology):
## - Define signals BEFORE implementation
## - Document contracts before emitting
## - Single source of truth for all entity events
##
## Usage:
##   EntitySignalRegistry.entity_spawned.emit(entity_id, entity_node, config)
##   EntitySignalRegistry.entity_ready.connect(_on_entity_ready)

# =============================================================================
# ENTITY BASE SIGNALS (Lifecycle)
# =============================================================================

## Emitted after entity fully initialized in scene tree
signal entity_ready(entity_id: String)

## Emitted after entity_config processed
signal entity_config_loaded(entity_id: String, config: Resource)

## Emitted for each container after validation
signal container_ready(entity_id: String, container_name: String)

## Emitted before entity cleanup begins (death, removal, etc.)
signal entity_despawning(entity_id: String, reason: String)

## Emitted after despawn delay, before queue_free
signal entity_cleanup_started(entity_id: String)

## Selection signals for entities (signal-first: add to contracts before use)
## Emitted when an entity is selected via input (click, UI pick, etc.)
signal entity_selected(entity_id: String, entity_node: Node)

## Emitted when an entity is deselected (click elsewhere, second click to cancel)
signal entity_deselected(entity_id: String)

## Emitted when a context menu action is triggered on an entity
## action_type: "look_skills", "look_inventory", etc.
signal entity_action_requested(entity_id: String, action_type: String, entity_node: Node)

# =============================================================================
# SKILL SIGNALS
# =============================================================================

## Emitted when a skill level or XP changes
signal skill_level_changed(entity_id: String, skill_name: String, level: int, xp: int)

# =============================================================================
# ENTITY FACTORY SIGNALS (Creation)
# =============================================================================

## Emitted after entity created and added to scene tree
signal entity_spawned(entity_id: String, entity_node: Node, config: Resource)

## Emitted before entity creation begins
signal entity_generation_started(config: Resource)

## Emitted after prefab_scene instantiated successfully
signal entity_scene_loaded(scene_path: String, entity_id: String)

## Emitted when entity creation aborted (validation failure)
signal entity_generation_failed(entity_id: String, reason: String)

# =============================================================================
# SPAWN SYSTEM SIGNALS (Placement)
# =============================================================================

## Emitted when a system requests an entity spawn (UI, GameLogic, etc.)
## Handled by EntityManager to find appropriate SpawnPoint or create at position
signal spawn_requested(category: int, position: Vector2, data: Dictionary)

## Emitted when a SpawnPoint registers itself with the system
signal spawn_point_registered(spawn_point: Node)

## Emitted when a SpawnPoint is unregistered (freed)
signal spawn_point_unregistered(spawn_point: Node)

## Emitted when a SpawnPoint successfully spawns an entity
signal spawn_point_activated(spawn_point: Node, entity: Node)


## Emitted when custom scene missing required containers
signal container_validation_failed(scene_path: String, missing_containers: Array)

# =============================================================================
# ENTITY MANAGER SIGNALS (Registry)
# =============================================================================

## Emitted when entity added to registry
signal entity_registered(entity_id: String, entity: Node)

## Emitted when entity removed from registry
signal entity_unregistered(entity_id: String)

## Emitted when batch despawn operation begins
signal batch_despawn_started(entity_type: String, count: int)

## Emitted when all entities in batch despawned
signal batch_despawn_complete(entity_type: String, count: int)
