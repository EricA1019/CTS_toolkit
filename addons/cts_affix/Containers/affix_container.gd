extends Node
class_name AffixContainer

const AffixBlock = preload("res://addons/cts_affix/Data/affix_block.gd")
const AffixInstance = preload("res://addons/cts_affix/Data/affix_instance.gd")

@export var affix_block: AffixBlock

var _active_affixes: Array[AffixInstance] = []

func _ready() -> void:
    _apply_block_affixes()

func apply_affix(affix_instance: AffixInstance) -> void:
    if affix_instance == null:
        return
    affix_instance.ensure_source_id()
    remove_affix(affix_instance.source_id)

    var modifier_data := affix_instance.to_modifier_data()
    var entity_id := _get_entity_id()

    if Engine.has_singleton("CTS_Skills"):
        Engine.get_singleton("CTS_Skills").apply_modifier(entity_id, modifier_data)

    _active_affixes.append(affix_instance)
    var registry := _signal_registry()
    if registry:
        registry.emit_signal("affix_applied", entity_id, affix_instance)

func remove_affix(source_id: String) -> void:
    if source_id.is_empty():
        return
    var entity_id := _get_entity_id()
    var remaining: Array[AffixInstance] = []

    for affix_instance in _active_affixes:
        if affix_instance == null:
            continue
        if str(affix_instance.source_id) == source_id:
            if Engine.has_singleton("CTS_Skills"):
                Engine.get_singleton("CTS_Skills").remove_modifier(entity_id, source_id)
            var registry := _signal_registry()
            if registry:
                registry.emit_signal("affix_removed", entity_id, source_id, affix_instance, "source_removed")
            continue
        remaining.append(affix_instance)
    _active_affixes = remaining

func _apply_block_affixes() -> void:
    if affix_block == null:
        return
    for affix_instance in affix_block.get_starting_affixes():
        apply_affix(affix_instance)

func _remove_by_source(source_id: String) -> void:
    if source_id.is_empty():
        return
    _active_affixes = _active_affixes.filter(func(inst):
        return inst != null and str(inst.source_id) != source_id
    )

func _signal_registry() -> Node:
    return Engine.get_singleton("AffixSignalRegistry") if Engine.has_singleton("AffixSignalRegistry") else null

func _get_entity_id() -> String:
    var parent := get_parent()
    if parent and parent.has_method("get_entity_id"):
        return parent.get_entity_id()
    return name
