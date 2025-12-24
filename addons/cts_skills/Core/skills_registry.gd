extends Node

## Skills Registry - centralized signals and API for usage-based skills
## Short-name convention per CTS: skills_registry
## Other plugins emit actions; this registry routes to SkillsComponent and broadcasts changes.

const SKILLS_COMPONENT_PATH := "res://addons/cts_skills/Containers/skills_container.gd"
const SkillEnums = preload("res://addons/cts_skills/Data/skill_enums.gd")
const SkillBlock = preload("res://addons/cts_skills/Data/skill_block.gd")
const SkillsContainer = preload(SKILLS_COMPONENT_PATH)
@onready var _signals: Node = EntitySignalRegistry

# =============================================================================
# SIGNALS (Signal-First)
# =============================================================================

## Emitted when entity gains XP in a skill
signal xp_gained(entity_id: String, skill_type: int, xp_amount: float, source: String)

## Emitted when a skill levels up
signal skill_leveled_up(entity_id: String, skill_type: int, old_level: int, new_level: int)

## Emitted when a modifier is applied
signal modifier_applied(entity_id: String, modifier)

## Emitted when a modifier is removed
signal modifier_removed(entity_id: String, modifier, reason: String)

## Emitted when an action is recorded (other plugins emit; skills plugin listens)
signal action_recorded(entity_id: String, action_type: String, context: Dictionary)

# =============================================================================
# PUBLIC API (Called by other plugins)
# =============================================================================

func _ready() -> void:
    if _signals:
        _signals.connect("entity_ready", _on_entity_ready)

## Award XP to a skill (quest rewards, scripted events)
func award_xp(entity_id: String, skill_type: int, xp_amount: float, source: String = "manual") -> void:
    var comp := _get_skills_container(entity_id)
    if not comp:
        return
    comp.gain_xp(skill_type, xp_amount, source)

## Apply a modifier (equipment, drugs, injuries)
## modifier_data keys: skill_type (int), modifier_type (ModifierType), value (float), source_id (String), duration (float, -1 permanent)
func apply_modifier(entity_id: String, modifier_data: Dictionary) -> void:
    var comp := _get_skills_container(entity_id)
    if not comp:
        return
    comp.apply_modifier(modifier_data)

## Remove modifier(s) by source_id (unequip item, cure debuff)
func remove_modifier(entity_id: String, source_id: String) -> void:
    var comp := _get_skills_container(entity_id)
    if not comp:
        return
    comp.remove_modifier_by_source(source_id)

## Get current skill value (base + modifiers)
func get_skill_value(entity_id: String, skill_type: int) -> float:
    var comp := _get_skills_container(entity_id)
    if not comp:
        return 0.0
    return comp.get_skill_value(skill_type)

## Record an action performed by entity (other plugins emit)
func record_action(entity_id: String, action_type: String, context: Dictionary = {}) -> void:
    var comp := _get_skills_container(entity_id)
    if comp:
        comp.handle_action(action_type, context)
    action_recorded.emit(entity_id, action_type, context)

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

func _on_entity_ready(entity_id: String) -> void:
    _attach_container_if_missing(entity_id)

func _get_skills_container(entity_id: String) -> SkillsContainer:
    if not Engine.has_singleton("CTS_Entity"):
        return null
    var entity := CTS_Entity.get_entity(entity_id)
    if not entity:
        return null
    
    if entity.has_node("SkillsContainer"):
        return entity.get_node("SkillsContainer")
    for child in entity.get_children():
        if child is SkillsContainer:
            return child
    return null

func _attach_container_if_missing(entity_id: String) -> void:
    if _get_skills_container(entity_id):
        return
    if not Engine.has_singleton("CTS_Entity"):
        return
    var entity := CTS_Entity.get_entity(entity_id)
    if not entity:
        return

    var config = entity.get("entity_config") if entity.has_method("get") else null
    var skill_path := ""
    if config and config.has_method("get_plugin_path"):
        skill_path = config.get_plugin_path("skills")
    elif config and config.has("custom_data"):
        skill_path = config.custom_data.get("skills_path", "")

    var block: SkillBlock = null
    if skill_path != "":
        block = load(skill_path)
        if block and not (block is SkillBlock):
            push_warning("[SkillsRegistry] Resource at %s is not a SkillBlock" % skill_path)
            block = null

    var comp: SkillsContainer = SkillsContainer.new()
    comp.name = "SkillsContainer"
    comp.skill_block = block
    entity.add_child(comp)
