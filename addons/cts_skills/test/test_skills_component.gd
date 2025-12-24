extends GutTest

## cts_skills Plugin Tests
## Verifies XP gain, leveling, modifiers, and skill progression

const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")
const SkillBlock = preload("res://addons/cts_skills/Data/skill_block.gd")
const SkillModifier = preload("res://addons/cts_skills/Data/skill_modifier.gd")
const SkillsComponent = preload("res://addons/cts_skills/Components/skills_component.gd")
const XPCalculator = preload("res://addons/cts_skills/Core/xp_calculator.gd")

var _component: SkillsComponent
var _block: SkillBlock

func before_each() -> void:
	_component = SkillsComponent.new()
	_block = SkillBlock.new()
	_component.skill_block = _block
	add_child_autofree(_component)

func after_each() -> void:
	_component = null
	_block = null

# =============================================================================
# XP Calculator Tests
# =============================================================================

func test_xp_calculator_linear_curve() -> void:
	var curve := {
		"curve_type": XPCalculator.XPCurveType.LINEAR,
		"base_xp": 100.0,
		"multiplier": 1.0,
	}
	
	assert_eq(XPCalculator.xp_required_for_level(0, curve), 100.0, "Level 0->1 should require 100 XP")
	assert_eq(XPCalculator.xp_required_for_level(1, curve), 200.0, "Level 1->2 should require 200 XP")
	assert_eq(XPCalculator.xp_required_for_level(9, curve), 1000.0, "Level 9->10 should require 1000 XP")

func test_xp_calculator_exponential_curve() -> void:
	var curve := {
		"curve_type": XPCalculator.XPCurveType.EXPONENTIAL,
		"base_xp": 100.0,
		"multiplier": 1.5,
	}
	
	assert_eq(XPCalculator.xp_required_for_level(0, curve), 100.0, "Level 0->1 base")
	assert_eq(XPCalculator.xp_required_for_level(1, curve), 150.0, "Level 1->2 exponential")
	assert_almost_eq(XPCalculator.xp_required_for_level(2, curve), 225.0, 0.1, "Level 2->3 exponential")

func test_xp_calculator_level_from_total_xp() -> void:
	var curve := {
		"curve_type": XPCalculator.XPCurveType.LINEAR,
		"base_xp": 100.0,
		"multiplier": 1.0,
	}
	
	var result := XPCalculator.level_from_total_xp(0.0, curve)
	assert_eq(result["level"], 0, "0 XP = level 0")
	assert_eq(result["xp_into_level"], 0.0)
	
	result = XPCalculator.level_from_total_xp(50.0, curve)
	assert_eq(result["level"], 0, "50 XP = level 0")
	assert_eq(result["xp_into_level"], 50.0, "50 XP into level 0")
	
	result = XPCalculator.level_from_total_xp(100.0, curve)
	assert_eq(result["level"], 1, "100 XP = level 1")
	assert_eq(result["xp_into_level"], 0.0)
	
	result = XPCalculator.level_from_total_xp(350.0, curve)
	assert_eq(result["level"], 2, "350 XP = level 2 (100 + 200 + 50)")
	assert_eq(result["xp_into_level"], 50.0)

# =============================================================================
# SkillsComponent XP Gain Tests
# =============================================================================

func test_gain_xp_basic() -> void:
	watch_signals(_component)
	_component.gain_xp(SkillEnums.SkillType.RIFLES, 50.0, "test")
	
	var level := _component._levels_by_skill.get(SkillEnums.SkillType.RIFLES, 0)
	var xp := _component._xp_progress_by_skill.get(SkillEnums.SkillType.RIFLES, 0.0)
	
	assert_eq(level, 0, "Should still be level 0 with only 50 XP")
	assert_eq(xp, 50.0, "Should have 50 XP progress")

func test_gain_xp_level_up() -> void:
	watch_signals(_component)
	_component.gain_xp(SkillEnums.SkillType.RIFLES, 100.0, "test")
	
	var level := _component._levels_by_skill.get(SkillEnums.SkillType.RIFLES, 0)
	assert_eq(level, 1, "Should level up to 1 with 100 XP")

func test_gain_xp_multiple_levels() -> void:
	watch_signals(_component)
	_component.gain_xp(SkillEnums.SkillType.RIFLES, 500.0, "test")
	
	var level := _component._levels_by_skill.get(SkillEnums.SkillType.RIFLES, 0)
	assert_gt(level, 1, "Should level up multiple times with 500 XP")

func test_gain_xp_negative_ignored() -> void:
	_component.gain_xp(SkillEnums.SkillType.RIFLES, -50.0, "test")
	
	var level := _component._levels_by_skill.get(SkillEnums.SkillType.RIFLES, 0)
	var xp := _component._xp_progress_by_skill.get(SkillEnums.SkillType.RIFLES, 0.0)
	
	assert_eq(level, 0, "Negative XP should be ignored")
	assert_eq(xp, 0.0, "No XP progress from negative value")

# =============================================================================
# Modifier Tests
# =============================================================================

func test_apply_modifier_add() -> void:
	_component._levels_by_skill[SkillEnums.SkillType.RIFLES] = 10
	
	var base_value := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(base_value, 10.0, "Base skill value should be 10")
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 5.0,
		"source_id": "test_item",
	})
	
	var modified_value := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(modified_value, 15.0, "Modified value should be base + 5")

func test_apply_modifier_multiply() -> void:
	_component._levels_by_skill[SkillEnums.SkillType.RIFLES] = 10
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.MULTIPLY,
		"value": 0.5,  # +50% bonus
		"source_id": "test_buff",
	})
	
	var modified_value := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(modified_value, 15.0, "Modified value should be base * 1.5")

func test_apply_modifier_override() -> void:
	_component._levels_by_skill[SkillEnums.SkillType.RIFLES] = 10
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.OVERRIDE,
		"value": 99.0,
		"source_id": "test_override",
	})
	
	var modified_value := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(modified_value, 99.0, "Override should set exact value")

func test_modifier_stacking_same_source_replaces() -> void:
	_component._levels_by_skill[SkillEnums.SkillType.RIFLES] = 10
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 5.0,
		"source_id": "armor",
	})
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 10.0,
		"source_id": "armor",  # Same source
	})
	
	var modified_value := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(modified_value, 20.0, "Same source should replace, not stack (10 + 10)")

func test_modifier_stacking_different_sources_sum() -> void:
	_component._levels_by_skill[SkillEnums.SkillType.RIFLES] = 10
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 5.0,
		"source_id": "armor",
	})
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 3.0,
		"source_id": "buff",  # Different source
	})
	
	var modified_value := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(modified_value, 18.0, "Different sources should sum (10 + 5 + 3)")

func test_remove_modifier_by_source() -> void:
	_component._levels_by_skill[SkillEnums.SkillType.RIFLES] = 10
	
	_component.apply_modifier({
		"skill_type": SkillEnums.SkillType.RIFLES,
		"modifier_type": SkillEnums.ModifierType.ADD,
		"value": 5.0,
		"source_id": "armor",
	})
	
	var modified := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(modified, 15.0, "Should have modifier applied")
	
	_component.remove_modifier_by_source("armor")
	
	var after_remove := _component.get_skill_value(SkillEnums.SkillType.RIFLES)
	assert_eq(after_remove, 10.0, "Modifier should be removed")

# =============================================================================
# Action Handling Tests
# =============================================================================

func test_handle_action_awards_xp() -> void:
	_block.action_xp = {
		"rifle_hit": {
			"skill_type": SkillEnums.SkillType.RIFLES,
			"xp": 5.0,
		}
	}
	
	_component.handle_action("rifle_hit", {})
	
	var xp := _component._xp_progress_by_skill.get(SkillEnums.SkillType.RIFLES, 0.0)
	assert_eq(xp, 5.0, "Action should award 5 XP")

func test_handle_action_unknown_ignored() -> void:
	_block.action_xp = {}
	
	_component.handle_action("unknown_action", {})
	
	var xp := _component._xp_progress_by_skill.get(SkillEnums.SkillType.RIFLES, 0.0)
	assert_eq(xp, 0.0, "Unknown action should not award XP")

# =============================================================================
# SkillBlock Configuration Tests
# =============================================================================

func test_skill_block_starting_levels() -> void:
	_block.starting_levels = {
		SkillEnums.SkillType.RIFLES: 5,
		SkillEnums.SkillType.SNEAKING: 10,
	}
	
	_component._load_block()
	
	assert_eq(_component._levels_by_skill.get(SkillEnums.SkillType.RIFLES, 0), 5)
	assert_eq(_component._levels_by_skill.get(SkillEnums.SkillType.SNEAKING, 0), 10)

func test_skill_block_per_skill_curves() -> void:
	_block.per_skill_curves = {
		SkillEnums.SkillType.RIFLES: {
			"curve_type": XPCalculator.XPCurveType.LINEAR,
			"base_xp": 50.0,
			"multiplier": 1.0,
		}
	}
	
	var curve := _component._get_curve(SkillEnums.SkillType.RIFLES)
	assert_eq(curve["base_xp"], 50.0, "Should use per-skill override")
	assert_eq(curve["curve_type"], XPCalculator.XPCurveType.LINEAR)
