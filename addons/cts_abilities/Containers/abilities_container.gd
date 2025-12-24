extends Node
class_name AbilitiesContainer

const AbilitiesBlock = preload("res://addons/cts_abilities/Data/abilities_block.gd")

@export var abilities_block: AbilitiesBlock

func use_ability(_ability_id: String) -> void:
    # Stub: implement ability execution
    pass

func get_cooldown(_ability_id: String) -> float:
    return 0.0

func has_ability(_ability_id: String) -> bool:
    return false
