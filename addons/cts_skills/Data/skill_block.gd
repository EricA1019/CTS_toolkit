extends Resource
class_name SkillBlock

## SkillBlock - preset skill levels and XP curve configuration

# Local enum to avoid cross-file load issues
enum XPCurveType {
    LINEAR = 0,
    EXPONENTIAL = 1,
    CUSTOM = 2,
}

## Starting levels per skill (skill_type -> level)
@export var starting_levels: Dictionary = {}

## Starting XP per skill (skill_type -> xp)
@export var starting_xp: Dictionary = {}

## Default curve settings (used when per-skill override missing)
@export var default_curve_type: int = XPCurveType.EXPONENTIAL
@export var default_base_xp: float = 100.0
@export var default_multiplier: float = 1.15
@export var default_custom_curve: PackedFloat32Array = PackedFloat32Array()

## Per-skill curve overrides (skill_type -> {curve_type, base_xp, multiplier, custom_curve})
@export var per_skill_curves: Dictionary = {}

## Action XP mapping: action_name -> {skill_type: int, xp: float}
@export var action_xp: Dictionary = {}

func get_curve_for(skill_type: int) -> Dictionary:
    var curve: Dictionary = per_skill_curves.get(skill_type, {})
    return {
        "curve_type": curve.get("curve_type", default_curve_type),
        "base_xp": curve.get("base_xp", default_base_xp),
        "multiplier": curve.get("multiplier", default_multiplier),
        "custom_curve": curve.get("custom_curve", default_custom_curve),
    }
