extends Resource
class_name AffixPool

const AffixEnums = preload("res://addons/cts_affix/Data/affix_enums.gd")
const AffixData = preload("res://addons/cts_affix/Data/affix_data.gd")
const AffixInstance = preload("res://addons/cts_affix/Data/affix_instance.gd")

@export var pool_id: String = ""
@export var available_affixes: Array[AffixData] = []
@export var rarity_weights: Dictionary = {
    AffixEnums.Rarity.COMMON: 60.0,
    AffixEnums.Rarity.UNCOMMON: 25.0,
    AffixEnums.Rarity.RARE: 10.0,
    AffixEnums.Rarity.EPIC: 4.0,
    AffixEnums.Rarity.LEGENDARY: 1.0,
}

func roll_from_pool(rarity: int = -1, rng: RandomNumberGenerator = null) -> AffixInstance:
    var chosen_rarity := rarity
    var local_rng := rng if rng else RandomNumberGenerator.new()
    if rng == null:
        local_rng.randomize()

    if chosen_rarity == -1:
        chosen_rarity = _pick_rarity(local_rng)

    var candidates: Array = []
    for data in available_affixes:
        if data == null:
            continue
        if int(data.rarity) == int(chosen_rarity):
            candidates.append(data)

    if candidates.is_empty():
        return null

    var data: AffixData = candidates[local_rng.randi_range(0, candidates.size() - 1)]
    var rolled_value := local_rng.randf_range(data.value_min, data.value_max)
    var inst := AffixInstance.new()
    inst.affix_data = data
    inst.rolled_value = rolled_value
    inst.ensure_source_id()
    return inst

func _pick_rarity(rng: RandomNumberGenerator) -> int:
    var total := 0.0
    for weight in rarity_weights.values():
        total += float(weight)
    if total <= 0.0:
        return AffixEnums.Rarity.COMMON

    var roll := rng.randf() * total
    for rarity in rarity_weights.keys():
        roll -= float(rarity_weights[rarity])
        if roll <= 0.0:
            return int(rarity)
    return AffixEnums.Rarity.COMMON
