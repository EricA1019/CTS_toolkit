extends "res://addons/gut/test.gd"

const AffixData = preload("res://addons/cts_affix/Data/affix_data.gd")
const AffixInstance = preload("res://addons/cts_affix/Data/affix_instance.gd")
const AffixPool = preload("res://addons/cts_affix/Data/affix_pool.gd")
const AffixComponent = preload("res://addons/cts_affix/Components/affix_component.gd")
const AffixBlock = preload("res://addons/cts_affix/Data/affix_block.gd")
const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")
const CTS_Affix = preload("res://addons/cts_affix/Core/affix_manager.gd")

func test_roll_from_pool_returns_instance() -> void:
    var d1 := AffixData.new()
    d1.affix_id = "sharp"
    d1.skill_type = SkillEnums.SkillType.MELEE_BLADED
    d1.value_min = 1.0
    d1.value_max = 2.0
    var pool := AffixPool.new()
    pool.pool_id = "weapons"
    pool.available_affixes = [d1]

    var inst := pool.roll_from_pool(d1.rarity)
    assert_not_null(inst)
    assert_true(inst.rolled_value >= 1.0 and inst.rolled_value <= 2.0)

func test_affix_instance_to_modifier_data_has_source() -> void:
    var data := AffixData.new()
    data.affix_id = "steady"
    data.value_min = 3.0
    data.value_max = 3.0
    var inst := AffixInstance.new()
    inst.affix_data = data
    inst.rolled_value = 3.0
    inst.ensure_source_id()
    var mod := inst.to_modifier_data()
    assert_true(mod.has("source_id"))
    assert_eq(mod["value"], 3.0)

func test_component_applies_block_affixes_without_skills_singleton() -> void:
    var data := AffixData.new()
    data.affix_id = "tough"
    data.value_min = 2.0
    data.value_max = 2.0
    var inst := AffixInstance.new()
    inst.affix_data = data
    inst.rolled_value = 2.0
    var block := AffixBlock.new()
    block.starting_affixes = [inst]

    var comp := AffixComponent.new()
    comp.affix_block = block
    comp._ready()
    assert_eq(comp._active_affixes.size(), 1)

func test_manager_roll_affix() -> void:
    var data := AffixData.new()
    data.affix_id = "keen"
    data.value_min = 5.0
    data.value_max = 6.0
    var mgr := CTS_Affix.new()
    var inst := mgr.roll_affix(data)
    assert_not_null(inst)
    assert_true(inst.rolled_value >= 5.0 and inst.rolled_value <= 6.0)