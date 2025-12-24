extends Resource
class_name AffixData

const AffixEnums = preload("res://addons/cts_affix/Data/affix_enums.gd")
const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")

@export var affix_id: String = ""          # Unique identifier (e.g., "sharp", "fiery")
@export var display_name: String = ""       # Human-readable name
@export var skill_type: int = SkillEnums.SkillType.RIFLES
@export var modifier_type: int = SkillEnums.ModifierType.ADD
@export var value_min: float = 0.0
@export var value_max: float = 0.0
@export var rarity: int = AffixEnums.Rarity.COMMON
@export var slot: int = AffixEnums.AffixSlot.PREFIX

func get_value_range() -> Vector2:
    return Vector2(value_min, value_max)