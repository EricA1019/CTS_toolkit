extends Node
class_name SkillsContainer

const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")
const SkillBlock = preload("res://addons/cts_skills/Data/skill_block.gd")
const SkillModifier = preload("res://addons/cts_skills/Data/skill_modifier.gd")
const XPCalculator = preload("res://addons/cts_skills/Core/xp_calculator.gd")

@export var skills_block: SkillBlock

var _levels_by_skill: Dictionary = {}
var _xp_progress_by_skill: Dictionary = {}
var _modifiers: Array = []  # Array[Dictionary]

func _ready() -> void:
    _load_block()

# =============================================================================
# PUBLIC API
# =============================================================================

func gain_xp(skill_type: int, xp_amount: float, source: String = "") -> void:
    if xp_amount <= 0.0:
        return
    var curve := _get_curve(skill_type)
    var level: int = _levels_by_skill.get(skill_type, 0)
    var xp_progress: float = _xp_progress_by_skill.get(skill_type, 0.0)
    var remaining := xp_amount

    while remaining > 0.0:
        var cost_to_next := XPCalculator.xp_required_for_level(level, curve)
        var needed := cost_to_next - xp_progress
        if remaining < needed:
            xp_progress += remaining
            remaining = 0.0
        else:
            remaining -= needed
            level += 1
            xp_progress = 0.0
            _emit_skill_leveled_up(skill_type, level - 1, level)

    _levels_by_skill[skill_type] = level
    _xp_progress_by_skill[skill_type] = xp_progress
    _emit_xp_gained(skill_type, xp_amount, source)

func apply_modifier(modifier_data: Dictionary) -> void:
    var modifier := _modifier_from_data(modifier_data)
    if modifier == null:
        return
    _remove_modifiers_by_source(modifier.source_id, modifier.skill_type)
    _modifiers.append(modifier)
    _emit_modifier_applied(modifier)

func remove_modifier_by_source(source_id: String) -> void:
    _remove_modifiers_by_source(source_id)

func get_skill_value(skill_type: int) -> float:
    var base_value: float = float(_levels_by_skill.get(skill_type, 0))
    var add_total := 0.0
    var mult_total := 0.0
    var override_set := false
    var override_value := 0.0

    for mod in _modifiers:
        if mod.skill_type != skill_type:
            continue
        match mod.modifier_type:
            SkillEnums.ModifierType.ADD:
                add_total += mod.value
            SkillEnums.ModifierType.MULTIPLY:
                mult_total += mod.value
            SkillEnums.ModifierType.OVERRIDE:
                override_set = true
                override_value = mod.value

    var value := (base_value + add_total) * (1.0 + mult_total)
    if override_set:
        value = override_value
    return value

# Adapter for PlayerBook compatibility. Accepts human-readable stat names.
func get_stat(stat_name: String) -> float:
    if stat_name == null:
        return 0.0
    var key := stat_name.strip_edges().to_lower().replace(" ", "_")
    var mapping := {
        "rifles": SkillEnums.SkillType.RIFLES,
        "pistols": SkillEnums.SkillType.PISTOLS,
        "shotguns": SkillEnums.SkillType.SHOTGUNS,
        "melee_bladed": SkillEnums.SkillType.MELEE_BLADED,
        "melee_blunt": SkillEnums.SkillType.MELEE_BLUNT,
        "unarmed": SkillEnums.SkillType.UNARMED,
        "scavenging": SkillEnums.SkillType.SCAVENGING,
        "dodge": SkillEnums.SkillType.DODGE,
        "survival_instinct": SkillEnums.SkillType.SURVIVAL_INSTINCT,
        "pain_tolerance": SkillEnums.SkillType.PAIN_TOLERANCE
    }
    var skill_type := mapping.get(key, null)
    if skill_type == null:
        # Fallback: check enum keys for a case-insensitive match
        for name in SkillEnums.SkillType.keys():
            if name.to_lower() == key:
                skill_type = SkillEnums.SkillType[name]
                break
    if skill_type == null:
        push_warning("SkillsContainer.get_stat: unknown stat '%s'" % stat_name)
        return 0.0
    return get_skill_value(skill_type)

func handle_action(action_type: String, context: Dictionary) -> void:
    if skills_block == null:
        return
    if not skills_block.action_xp.has(action_type):
        return
    var entry: Dictionary = skills_block.action_xp[action_type]
    if not entry.has("skill_type") or not entry.has("xp"):
        return
    gain_xp(entry["skill_type"], float(entry["xp"]), action_type)

# =============================================================================
# INTERNAL
# =============================================================================

func _load_block() -> void:
    _levels_by_skill.clear()
    _xp_progress_by_skill.clear()

    if skills_block == null:
        return

    for skill_type in skills_block.starting_levels.keys():
        _levels_by_skill[int(skill_type)] = int(skills_block.starting_levels[skill_type])

    for skill_type in skills_block.starting_xp.keys():
        _xp_progress_by_skill[int(skill_type)] = float(skills_block.starting_xp[skill_type])

func _get_curve(skill_type: int) -> Dictionary:
    if skills_block == null:
        return {
            "curve_type": XPCalculator.XPCurveType.EXPONENTIAL,
            "base_xp": 100.0,
            "multiplier": 1.15,
            "custom_curve": PackedFloat32Array(),
        }
    return skills_block.get_curve_for(skill_type)

func _modifier_from_data(modifier_data: Dictionary) -> SkillModifier:
    if not modifier_data.has("skill_type") or not modifier_data.has("modifier_type"):
        return null
    var mod := SkillModifier.new()
    mod.skill_type = int(modifier_data.get("skill_type", 0))
    mod.modifier_type = int(modifier_data.get("modifier_type", SkillEnums.ModifierType.ADD))
    mod.value = float(modifier_data.get("value", 0.0))
    mod.source_id = str(modifier_data.get("source_id", modifier_data.get("source", "")))
    mod.duration = float(modifier_data.get("duration", -1.0))
    return mod

func _remove_modifiers_by_source(source_id: String, skill_type: int = -1) -> void:
    var kept: Array = []
    for mod in _modifiers:
        var mod_source: String = str(mod.source_id)
        var mod_skill: int = int(mod.skill_type)
        var same_source: bool = (mod_source == source_id)
        var same_skill: bool = (skill_type == -1) or (mod_skill == skill_type)
        if same_source and same_skill:
            _emit_modifier_removed(mod, "source_removed")
            continue
        kept.append(mod)
    _modifiers = kept

func _emit_xp_gained(skill_type: int, amount: float, source: String) -> void:
    var registry: Node = Engine.get_singleton("CTS_Skills") as Node
    if registry:
        registry.emit_signal("xp_gained", _get_entity_id(), skill_type, amount, source)

func _emit_skill_leveled_up(skill_type: int, old_level: int, new_level: int) -> void:
    var registry: Node = Engine.get_singleton("CTS_Skills") as Node
    if registry:
        registry.emit_signal("skill_leveled_up", _get_entity_id(), skill_type, old_level, new_level)

func _emit_modifier_applied(modifier: SkillModifier) -> void:
    var registry: Node = Engine.get_singleton("CTS_Skills") as Node
    if registry:
        registry.emit_signal("modifier_applied", _get_entity_id(), modifier)

func _emit_modifier_removed(modifier: SkillModifier, reason: String) -> void:
    var registry: Node = Engine.get_singleton("CTS_Skills") as Node
    if registry:
        registry.emit_signal("modifier_removed", _get_entity_id(), modifier, reason)

func _get_entity_id() -> String:
    var parent := get_parent()
    if parent and parent.has_method("get_entity_id"):
        return parent.get_entity_id()
    return name
