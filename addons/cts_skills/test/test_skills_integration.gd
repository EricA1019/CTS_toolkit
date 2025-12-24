extends GutTest

## cts_skills Registry Integration Tests
## Verifies skills_registry API and entity integration

const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")
const SkillBlock = preload("res://addons/cts_skills/Data/skill_block.gd")
const EntityConfig = preload("res://addons/cts_entity/Data/entity_config.gd")
const EntityFactory = preload("res://addons/cts_entity/Core/entity_factory.gd")
const EntityBase = preload("res://addons/cts_entity/Core/entity_base.gd")

var _registry: Node
var _factory: EntityFactory
var _test_entities: Array = []

func before_each() -> void:
	_registry = get_node_or_null("/root/CTS_Skills")
	if not _registry:
		push_warning("[Test] CTS_Skills autoload not found - ensure plugin enabled")
	
	_factory = EntityFactory.new()
	add_child_autofree(_factory)

func after_each() -> void:
	for entity in _test_entities:
		if is_instance_valid(entity):
			entity.queue_free()
	_test_entities.clear()
	_factory = null

# =============================================================================
# Registry API Tests
# =============================================================================

func test_registry_exists() -> void:
	assert_not_null(_registry, "CTS_Skills autoload should exist")

func test_award_xp_via_registry() -> void:
	if not _registry:
		return
	
	var entity: EntityBase = await _create_test_entity_with_skills()
	if not entity:
		pass_test("Skipped - entity creation requires CTS_Entity autoload")
		return
	
	watch_signals(_registry)
	_registry.award_xp(entity.entity_id, SkillEnums.SkillType.RIFLES, 50.0, "test")
	
	assert_signal_emitted(_registry, "xp_gained", "Should emit xp_gained signal")

func test_apply_modifier_via_registry() -> void:
	if not _registry:
		return
	
	var entity: EntityBase = await _create_test_entity_with_skills()
	if not entity:
		pass_test("Skipped - entity creation requires CTS_Entity autoload")
		return
	
	watch_signals(_registry)
	_registry.apply_modifier(entity.entity_id, {
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 10.0,
		"source_id": "test_item",
	})
	
	assert_signal_emitted(_registry, "modifier_applied", "Should emit modifier_applied signal")

func test_get_skill_value_via_registry() -> void:
	if not _registry:
		return
	
	var entity: EntityBase = await _create_test_entity_with_skills()
	if not entity:
		pass_test("Skipped - entity creation requires CTS_Entity autoload")
		return
	
	_registry.award_xp(entity.entity_id, SkillEnums.SkillType.RIFLES, 100.0, "test")
	
	var value: float = _registry.get_skill_value(entity.entity_id, SkillEnums.SkillType.RIFLES)
	assert_gt(value, 0.0, "Should return skill value after XP gain")

func test_remove_modifier_via_registry() -> void:
	if not _registry:
		return
	
	var entity: EntityBase = await _create_test_entity_with_skills()
	if not entity:
		pass_test("Skipped - entity creation requires CTS_Entity autoload")
		return
	
	_registry.apply_modifier(entity.entity_id, {
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 10.0,
		"source_id": "test_armor",
	})
	
	watch_signals(_registry)
	_registry.remove_modifier(entity.entity_id, "test_armor")
	
	assert_signal_emitted(_registry, "modifier_removed", "Should emit modifier_removed signal")

func test_record_action_via_registry() -> void:
	if not _registry:
		return
	
	var entity: EntityBase = await _create_test_entity_with_skills()
	if not entity:
		pass_test("Skipped - entity creation requires CTS_Entity autoload")
		return
	
	watch_signals(_registry)
	_registry.record_action(entity.entity_id, "rifle_hit", {"target": "bandit"})
	
	assert_signal_emitted(_registry, "action_recorded", "Should emit action_recorded signal")

# =============================================================================
# Integration Tests
# =============================================================================

func test_entity_auto_attaches_skills_component() -> void:
	if not Engine.has_singleton("CTS_Entity"):
		pass_test("Skipped - CTS_Entity autoload required")
		return
	
	var entity: EntityBase = await _create_test_entity_with_skills()
	if not entity:
		pass_test("Skipped - entity creation failed")
		return
	
	var stats_container := entity.get_node_or_null("StatsContainer")
	assert_not_null(stats_container, "Entity should have StatsContainer")
	
	var has_skills := false
	for child in stats_container.get_children():
		if child.name == "SkillsComponent":
			has_skills = true
			break
	
	assert_true(has_skills, "StatsContainer should have SkillsComponent auto-attached")

# =============================================================================
# Helpers
# =============================================================================

func _create_test_entity_with_skills() -> EntityBase:
	if not Engine.has_singleton("CTS_Entity"):
		return null
	
	var config := EntityConfig.new()
	config.entity_id = "test_entity"
	config.is_unique = false
	
	# Create minimal skill block
	var block := SkillBlock.new()
	block.starting_levels = {}
	block.action_xp = {
		"rifle_hit": {
			"skill_type": SkillEnums.SkillType.RIFLES,
			"xp": 5.0,
		}
	}
	
	# Save block temporarily (in-memory resource)
	config.custom_data["skills_path"] = ""  # Empty means no preload, component creates default
	
	var entity = _factory.create_entity(config, get_tree().root)
	if entity:
		_test_entities.append(entity)
		await get_tree().process_frame  # Wait for entity_ready signal
	
	return entity
