extends Node
class_name CTSEntityFactory

## Entity factory for cts_entity plugin
## Creates entities from EntityConfig (data-driven) or PackedScene (handcrafted)
## Handles dual-path instantiation with smart ID generation
##
## Usage:
##   var factory = EntityFactory.new()
##   var entity = factory.create_entity(config, parent_node)
##   var entity = factory.spawn_at_position(config, Vector2(100, 100), parent_node)

@onready var _signals: Node = EntitySignalRegistry

# =============================================================================
# SIGNAL REGISTRY
# =============================================================================

## All entity signals centralized in EntitySignalRegistry
## This class emits creation signals via the registry

# =============================================================================
# CONSTANTS
# =============================================================================

## Base entity template scene
const BASE_ENTITY_SCENE: String = "res://addons/cts_entity/Prefabs/base_entity.tscn"

## Required container node names (exact match)
const REQUIRED_CONTAINERS: Array[String] = [
	"StatsContainer",
	"InventoryContainer",
	"AbilitiesContainer",
	"ComponentsContainer"
]

# =============================================================================
# STATE
# =============================================================================

## ID counters for auto-increment (entity_type -> counter)
var _id_counters: Dictionary = {}

# =============================================================================
# PUBLIC API
# =============================================================================

## Create entity from config
## @param config: EntityConfig resource
## @param parent: Parent node to add entity to (optional)
## @return: EntityBase instance or null on failure
func create_entity(config: EntityConfig, parent: Node = null) -> EntityBase:
	if not config:
		push_error("[EntityFactory] Cannot create entity: config is null")
		return null
	
	if not config._validate():
		push_error("[EntityFactory] EntityConfig validation failed: %s" % config.entity_id)
		if _signals:
			_signals.emit_signal("entity_generation_failed", config.entity_id, "invalid_config")
		return null
	
	if _signals:
		_signals.emit_signal("entity_generation_started", config)
	
	# Hybrid creation: scene-based or template-based
	var entity: EntityBase = null
	
	if config.prefab_scene:
		entity = _create_from_scene(config)
	else:
		entity = _create_from_base(config)
	
	if not entity:
		return null
	
	# Apply instance ID
	var instance_id := _generate_instance_id(config)
	entity.set_meta("instance_id", instance_id)
	entity.entity_config = config

	# Attach typed containers based on config blocks
	_attach_typed_containers(entity, config)
	
	# Apply visual data if provided
	if config.visual_data:
		config.visual_data.apply_to_entity(entity)
	
	# Assign to groups
	for group in config.groups:
		entity.add_to_group(group)
	
	# Add to scene tree
	if parent:
		parent.add_child(entity)
	
	# Emit success signal
	if _signals:
		_signals.emit_signal("entity_spawned", instance_id, entity, config)
	
	return entity

# =============================================================================
# INTERNAL: CONTAINER ATTACHMENT
# =============================================================================

func _attach_typed_containers(entity: EntityBase, config: EntityConfig) -> void:
	if config.skills_block:
		var skills := entity.get_node_or_null("SkillsContainer")
		if skills == null:
			skills = preload("res://addons/cts_skills/Containers/skills_container.gd").new()
			skills.name = "SkillsContainer"
			entity.add_child(skills)
		skills.skills_block = config.skills_block

	if config.affix_block:
		var affix := entity.get_node_or_null("AffixContainer")
		if affix == null:
			affix = preload("res://addons/cts_affix/Containers/affix_container.gd").new()
			affix.name = "AffixContainer"
			entity.add_child(affix)
		affix.affix_block = config.affix_block

	if config.inventory_block:
		var inv := entity.get_node_or_null("InventoryContainer")
		if inv == null:
			inv = preload("res://addons/cts_items/Containers/inventory_container.gd").new()
			inv.name = "InventoryContainer"
			entity.add_child(inv)
		inv.inventory_block = config.inventory_block

	if config.equipment_block:
		var equip := entity.get_node_or_null("EquipmentContainer")
		if equip == null:
			equip = preload("res://addons/cts_items/Containers/equipment_container.gd").new()
			equip.name = "EquipmentContainer"
			entity.add_child(equip)
		equip.equipment_block = config.equipment_block

	if config.recipe_book:
		var craft := entity.get_node_or_null("CraftingContainer")
		if craft == null:
			craft = preload("res://addons/cts_items/Containers/crafting_container.gd").new()
			craft.name = "CraftingContainer"
			entity.add_child(craft)
		craft.recipe_book = config.recipe_book

	if config.stats_block:
		var stats := entity.get_node_or_null("StatsContainer")
		if stats == null:
			# TODO: cts_stats addon not yet implemented - manual Stats node creation required
			push_warning("EntityFactory: cts_stats addon missing - Stats container not created automatically")
			# stats = preload("res://addons/cts_stats/Containers/stats_container.gd").new()
			# stats.name = "StatsContainer"
			# entity.add_child(stats)
		if stats:
			stats.stats_block = config.stats_block

	if config.abilities_block:
		var abil := entity.get_node_or_null("AbilitiesContainer")
		if abil == null:
			abil = preload("res://addons/cts_abilities/Containers/abilities_container.gd").new()
			abil.name = "AbilitiesContainer"
			entity.add_child(abil)
		abil.abilities_block = config.abilities_block

## Spawn entity at specific position
## @param config: EntityConfig resource
## @param global_pos: World position to spawn at
## @param parent: Parent node to add entity to
## @return: EntityBase instance or null on failure
func spawn_at_position(config: EntityConfig, global_pos: Vector2, parent: Node) -> EntityBase:
	print("[EntityFactory] spawn_at_position called with pos: ", global_pos)
	var entity := create_entity(config, parent)
	if entity:
		print("[EntityFactory] Setting entity.global_position = ", global_pos)
		entity.global_position = global_pos
		print("[EntityFactory] After set, entity.global_position = ", entity.global_position)
	return entity

## Reset ID counters (useful for testing or level transitions)
func reset_counters() -> void:
	_id_counters.clear()

## Get current counter for entity type
func get_counter(entity_type: String) -> int:
	return _id_counters.get(entity_type, 0)

# =============================================================================
# INTERNAL: SCENE-BASED CREATION
# =============================================================================

## Create entity from prefab scene
func _create_from_scene(config: EntityConfig) -> EntityBase:
	var scene := config.prefab_scene
	if not scene:
		push_error("[EntityFactory] prefab_scene is null for %s" % config.entity_id)
		if _signals:
			_signals.emit_signal("entity_generation_failed", config.entity_id, "null_prefab_scene")
		return null
	
	# Instantiate scene
	var instance := scene.instantiate()
	if not instance is EntityBase:
		push_error("[EntityFactory] Prefab scene root must be EntityBase for %s" % config.entity_id)
		if _signals:
			_signals.emit_signal("entity_generation_failed", config.entity_id, "invalid_scene_type")
		instance.queue_free()
		return null
	
	# Validate containers (abort if missing required)
	var validation_result := _validate_containers(instance, scene.resource_path)
	if not validation_result.is_valid:
		push_error("[EntityFactory] Container validation failed for %s: %s" % [
			config.entity_id,
			", ".join(validation_result.missing_containers)
		])
		if _signals:
			_signals.emit_signal("container_validation_failed", scene.resource_path, validation_result.missing_containers)
			_signals.emit_signal("entity_generation_failed", config.entity_id, "missing_containers")
		instance.queue_free()
		return null
	
	if _signals:
		_signals.emit_signal("entity_scene_loaded", scene.resource_path, config.entity_id)
	return instance

## Create entity from base template
func _create_from_base(config: EntityConfig) -> EntityBase:
	var base_scene := load(BASE_ENTITY_SCENE) as PackedScene
	if not base_scene:
		push_error("[EntityFactory] Failed to load base entity scene: %s" % BASE_ENTITY_SCENE)
		if _signals:
			_signals.emit_signal("entity_generation_failed", config.entity_id, "missing_base_scene")
		return null
	
	var entity := base_scene.instantiate() as EntityBase
	return entity

# =============================================================================
# INTERNAL: VALIDATION
# =============================================================================

## Validate entity has all required containers
## Preserves custom nodes, checks for missing containers
func _validate_containers(entity: EntityBase, scene_path: String) -> Dictionary:
	var result := {
		"is_valid": true,
		"missing_containers": []
	}
	
	for container_name in REQUIRED_CONTAINERS:
		var container := entity.get_node_or_null(container_name)
		if not container:
			result.is_valid = false
			result.missing_containers.append(container_name)
	
	return result

# =============================================================================
# INTERNAL: ID GENERATION
# =============================================================================

## Generate instance ID based on config
## Unique entities: use entity_id as-is
## Generic entities: auto-increment suffix (bandit_001, bandit_002)
func _generate_instance_id(config: EntityConfig) -> String:
	if config.is_unique:
		# Unique entities always use base ID
		return config.entity_id
	
	# Generic entities get auto-incremented ID
	var base_id := config.entity_id
	if not _id_counters.has(base_id):
		_id_counters[base_id] = 0
	
	_id_counters[base_id] += 1
	return "%s_%03d" % [base_id, _id_counters[base_id]]
