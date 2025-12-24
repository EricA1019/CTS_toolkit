extends Node
class_name CTS_Affix

const COMPONENT_PATH := "res://addons/cts_affix/Containers/affix_container.gd"
const AffixContainer = preload(COMPONENT_PATH)
const AffixPool = preload("res://addons/cts_affix/Data/affix_pool.gd")
const AffixData = preload("res://addons/cts_affix/Data/affix_data.gd")
const AffixInstance = preload("res://addons/cts_affix/Data/affix_instance.gd")
const AffixSignalRegistry = preload("res://addons/cts_affix/Core/affix_signal_registry.gd")

@onready var _signals: Node = EntitySignalRegistry

var _pools: Dictionary = {}

func _ready() -> void:
	if _signals:
		_signals.connect("entity_ready", Callable(self, "_on_entity_ready"))

func apply_affix_to_entity(entity_id: String, affix_instance: AffixInstance) -> void:
	var comp := _get_container(entity_id, true)
	if comp == null:
		return
	comp.apply_affix(affix_instance)

func remove_affix_from_entity(entity_id: String, source_id: String) -> void:
	var comp := _get_container(entity_id)
	if comp == null:
		return
	comp.remove_affix(source_id)

func roll_affix(data: AffixData, rng: RandomNumberGenerator = null) -> AffixInstance:
	if data == null:
		return null
	var local_rng := rng if rng else RandomNumberGenerator.new()
	if rng == null:
		local_rng.randomize()
	var inst := AffixInstance.new()
	inst.affix_data = data
	inst.rolled_value = local_rng.randf_range(data.value_min, data.value_max)
	inst.ensure_source_id()
	_emit_affix_rolled("direct", inst)
	return inst

func register_pool(pool: AffixPool) -> void:
	if pool == null or pool.pool_id.is_empty():
		return
	_pools[pool.pool_id] = pool

func roll_from_pool(pool_id: String, rarity: int = -1, rng: RandomNumberGenerator = null) -> AffixInstance:
	if not _pools.has(pool_id):
		return null
	var pool: AffixPool = _pools[pool_id]
	var inst := pool.roll_from_pool(rarity, rng)
	if inst == null:
		return null
	if Engine.has_singleton("AffixSignalRegistry"):
		Engine.get_singleton("AffixSignalRegistry").emit_signal("pool_rolled", pool_id, rarity if rarity != -1 else inst.affix_data.rarity)
	_emit_affix_rolled(pool_id, inst)
	return inst

func _emit_affix_rolled(pool_id: String, inst: AffixInstance) -> void:
	if inst == null or inst.affix_data == null:
		return
	var registry := _signal_registry()
	if registry:
		registry.emit_signal("affix_rolled", pool_id, inst.affix_data, inst.rolled_value, inst)

func _on_entity_ready(entity_id: String) -> void:
	_attach_container_if_missing(entity_id)

func _get_container(entity_id: String, create_if_missing: bool = false) -> AffixContainer:
	if not Engine.has_singleton("CTS_Entity"):
		return null
	var entity := CTS_Entity.get_entity(entity_id)
	if entity == null:
		return null
	var container := entity.get_node_or_null("ComponentsContainer")
	if container == null:
		return null
	if container.has_node("AffixContainer"):
		return container.get_node("AffixContainer")
	for child in container.get_children():
		if child is AffixContainer:
			return child
	if not create_if_missing:
		return null
	var comp: AffixContainer = AffixContainer.new()
	comp.name = "AffixContainer"
	container.add_child(comp)
	return comp

func _attach_container_if_missing(entity_id: String) -> void:
	_get_container(entity_id, true)

func _signal_registry() -> Node:
	return Engine.get_singleton("AffixSignalRegistry") if Engine.has_singleton("AffixSignalRegistry") else null
