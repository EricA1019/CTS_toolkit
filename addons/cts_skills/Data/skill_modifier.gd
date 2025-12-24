extends Resource
class_name SkillModifier

const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")

## Buff/Debuff modifier applied to a skill
@export var skill_type: int = SkillEnums.SkillType.RIFLES
@export var modifier_type: int = SkillEnums.ModifierType.ADD
@export var value: float = 0.0
@export var source_id: String = ""  # e.g., item_id, effect_id
@export var duration: float = -1.0   # seconds; -1 = permanent
