extends Resource
class_name AffixBlock

const AffixInstance = preload("res://addons/cts_affix/Data/affix_instance.gd")

@export var starting_affixes: Array[AffixInstance] = []

func get_starting_affixes() -> Array:
    var copies: Array = []
    for affix_instance in starting_affixes:
        if affix_instance == null:
            continue
        var inst := AffixInstance.new()
        inst.affix_data = affix_instance.affix_data
        inst.rolled_value = affix_instance.rolled_value
        inst.source_id = affix_instance.source_id
        copies.append(inst)
    return copies
