extends Node

const AffixData = preload("res://addons/cts_affix/Data/affix_data.gd")
const AffixPool = preload("res://addons/cts_affix/Data/affix_pool.gd")
const AffixInstance = preload("res://addons/cts_affix/Data/affix_instance.gd")
const AffixEnums = preload("res://addons/cts_affix/Data/affix_enums.gd")
const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")

func _ready() -> void:
    # Example: build a pool, roll an affix, and (if singletons exist) apply to an entity
    var sharp := AffixData.new()
    sharp.affix_id = "sharp"
    sharp.display_name = "Sharp"
    sharp.skill_type = SkillEnums.SkillType.MELEE_BLADED
    sharp.modifier_type = SkillEnums.ModifierType.ADD
    sharp.value_min = 1.0
    sharp.value_max = 3.0
    sharp.rarity = AffixEnums.Rarity.UNCOMMON

    var pool := AffixPool.new()
    pool.pool_id = "melee_pool"
    pool.available_affixes = [sharp]

    var inst := pool.roll_from_pool()
    if inst:
        if Engine.has_singleton("CTS_Affix"):
            Engine.get_singleton("CTS_Affix").apply_affix_to_entity("entity_1", inst)
        else:
            print("Rolled affix", inst.affix_data.affix_id, "value", inst.rolled_value)
