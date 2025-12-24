extends Node
class_name StatsContainer

const StatsBlock = preload("res://addons/cts_stats/Data/stats_block.gd")

@export var stats_block: StatsBlock
var _stats: Dictionary = {}

func _ready() -> void:
    _load_block()

func get_stat(stat_name: String, default_value: float = 0.0) -> float:
    return float(_stats.get(stat_name, default_value))

func set_stat(stat_name: String, value: float) -> void:
    _stats[stat_name] = value
    _emit_stat_changed(stat_name, value)

func modify_stat(stat_name: String, delta: float) -> void:
    set_stat(stat_name, get_stat(stat_name) + delta)

func _load_block() -> void:
    _stats.clear()
    if stats_block == null:
        return
    for key in stats_block.stats.keys():
        var entry = stats_block.stats[key]
        if entry is Dictionary and entry.has("base"):
            _stats[key] = float(entry["base"])

func _emit_stat_changed(stat_name: String, value: float) -> void:
    var bus := _signal_bus()
    if bus:
        bus.emit_signal("stat_changed", _resolve_entity_id(), stat_name, value)

func _signal_bus() -> Node:
    return Engine.get_singleton("CTS_Stats") if Engine.has_singleton("CTS_Stats") else null

func _resolve_entity_id() -> String:
    var parent := get_parent()
    if parent and parent.has_method("get_entity_id"):
        return parent.get_entity_id()
    return name
