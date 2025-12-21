extends Node

## Entity Manager - Central registry for all entity instances
## Autoload: CTS_Entity
## Tracks entity lifecycle, provides lookup methods, handles batch operations
##
## Usage:
##   var entity = CTS_Entity.create_entity(config, parent)
##   var entity = CTS_Entity.get_entity("detective")
##   CTS_Entity.despawn_all_by_type("bandit")

const EntityBase = preload("res://addons/cts_entity/Core/entity_base.gd")
const EntityFactory = preload("res://addons/cts_entity/Core/entity_factory.gd")
const EntityConfig = preload("res://addons/cts_entity/Data/entity_config.gd")

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when entity added to registry
signal entity_registered(entity_id: String, entity: EntityBase)

## Emitted when entity removed from registry
signal entity_unregistered(entity_id: String)

## Emitted when batch despawn operation begins
signal batch_despawn_started(entity_type: String, count: int)

## Emitted when all entities in batch despawned
signal batch_despawn_complete(entity_type: String, count: int)

# =============================================================================
# STATE
# =============================================================================

## Entity registry (entity_id -> EntityBase)
var _entity_registry: Dictionary = {}

## Entities by type tracking (entity_type -> Array[String])
var _entities_by_type: Dictionary = {}

## Entity factory instance
var _factory: EntityFactory = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Create factory
	_factory = EntityFactory.new()
	_factory.name = "EntityFactory"
	add_child(_factory)
	
	# Connect to factory signals
	_factory.entity_spawned.connect(_on_entity_spawned)
	
	print("[EntityManager] Initialized (autoload: CTS_Entity)")

# =============================================================================
# REGISTRY MANAGEMENT
# =============================================================================

## Register entity in central registry
func register_entity(entity_id: String, entity: EntityBase) -> void:
	if _entity_registry.has(entity_id):
		push_warning("[EntityManager] Entity already registered: %s" % entity_id)
		return
	
	_entity_registry[entity_id] = entity
	
	# Track by type
	var entity_type := _get_entity_type(entity)
	if not _entities_by_type.has(entity_type):
		_entities_by_type[entity_type] = []
	_entities_by_type[entity_type].append(entity_id)
	
	entity_registered.emit(entity_id, entity)

## Unregister entity from central registry
func unregister_entity(entity_id: String) -> void:
	if not _entity_registry.has(entity_id):
		return
	
	var entity := _entity_registry[entity_id]
	var entity_type := _get_entity_type(entity)
	
	_entity_registry.erase(entity_id)
	
	# Remove from type tracking
	if _entities_by_type.has(entity_type):
		_entities_by_type[entity_type].erase(entity_id)
		
		# Clean up empty type arrays
		if _entities_by_type[entity_type].is_empty():
			_entities_by_type.erase(entity_type)
	
	entity_unregistered.emit(entity_id)

# =============================================================================
# LOOKUP METHODS
# =============================================================================

## Get entity by instance ID
func get_entity(entity_id: String) -> EntityBase:
	return _entity_registry.get(entity_id, null)

## Get all registered entities
func get_all_entities() -> Array[EntityBase]:
	var entities: Array[EntityBase] = []
	for entity in _entity_registry.values():
		if entity:
			entities.append(entity)
	return entities

## Get entities by type (bandit, detective, etc.)
func get_entities_by_type(entity_type: String) -> Array[EntityBase]:
	var entities: Array[EntityBase] = []
	if not _entities_by_type.has(entity_type):
		return entities
	
	for entity_id in _entities_by_type[entity_type]:
		var entity := get_entity(entity_id)
		if entity:
			entities.append(entity)
	
	return entities

## Get entity count
func get_entity_count() -> int:
	return _entity_registry.size()

## Get entity count by type
func get_entity_count_by_type(entity_type: String) -> int:
	if not _entities_by_type.has(entity_type):
		return 0
	return _entities_by_type[entity_type].size()

## Check if entity exists
func has_entity(entity_id: String) -> bool:
	return _entity_registry.has(entity_id)

# =============================================================================
# DESPAWN OPERATIONS
# =============================================================================

## Despawn single entity by ID
func despawn_entity(entity_id: String, reason: String = "manual") -> void:
	var entity := get_entity(entity_id)
	if not entity:
		push_warning("[EntityManager] Cannot despawn unknown entity: %s" % entity_id)
		return
	
	entity.despawn(reason)

## Despawn all entities of a specific type (batch cleanup)
## Staggered to prevent lag spikes
func despawn_all_by_type(entity_type: String, reason: String = "batch_cleanup") -> void:
	var entities := get_entities_by_type(entity_type)
	if entities.is_empty():
		return
	
	batch_despawn_started.emit(entity_type, entities.size())
	
	# Stagger despawns to prevent lag spike
	await _staggered_despawn(entities, reason)
	
	batch_despawn_complete.emit(entity_type, entities.size())

## Despawn all entities (cleanup)
func despawn_all_entities(reason: String = "cleanup") -> void:
	var all_entities := get_all_entities()
	if all_entities.is_empty():
		return
	
	print("[EntityManager] Despawning all entities: %d" % all_entities.size())
	await _staggered_despawn(all_entities, reason)

# =============================================================================
# FACTORY METHODS (CONVENIENCE)
# =============================================================================

## Create entity using internal factory
func create_entity(config: EntityConfig, parent: Node = null) -> EntityBase:
	if not _factory:
		push_error("[EntityManager] Factory not initialized")
		return null
	return _factory.create_entity(config, parent)

## Spawn entity at position using internal factory
func spawn_at_position(config: EntityConfig, global_pos: Vector2, parent: Node) -> EntityBase:
	if not _factory:
		push_error("[EntityManager] Factory not initialized")
		return null
	return _factory.spawn_at_position(config, global_pos, parent)

## Reset factory ID counters
func reset_factory_counters() -> void:
	if _factory:
		_factory.reset_counters()

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

## Staggered despawn to prevent lag spikes
## Despawns 3 entities per frame
func _staggered_despawn(entities: Array[EntityBase], reason: String) -> void:
	const ENTITIES_PER_FRAME: int = 3
	var count := 0
	
	for entity in entities:
		if not is_instance_valid(entity):
			continue
		
		entity.despawn(reason)
		count += 1
		
		# Wait for next frame every N entities
		if count % ENTITIES_PER_FRAME == 0:
			await get_tree().process_frame

## Get entity type from entity instance
func _get_entity_type(entity: EntityBase) -> String:
	if entity.entity_config:
		return entity.entity_config.entity_id
	return "unknown"

## Signal handler: auto-register entities spawned by factory
func _on_entity_spawned(entity_id: String, entity_node: EntityBase, config: EntityConfig) -> void:
	register_entity(entity_id, entity_node)
