@tool
class_name CharacterSheetPage
extends BookPage

## Page displaying character stats

var _stats_container: VBoxContainer
var _binding: ReactiveBinding
var _event_bus: Node

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	if get_child_count() > 0: return
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	
	_stats_container = VBoxContainer.new()
	_stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_stats_container)

func setup(event_bus: Node, data_provider: Node) -> void:
	super.setup(event_bus, data_provider)
	_event_bus = event_bus
	_binding = ReactiveBinding.new(self)
	name = "Stats"
	
	if data_provider.has_method("get_stats_container"):
		var stats = data_provider.get_stats_container()
		if stats:
			_build_stats(stats)
		else:
			_build_stats(null)

	if _event_bus and _event_bus.has_signal("container_ready"):
		if not _event_bus.container_ready.is_connected(_on_container_ready):
			_event_bus.container_ready.connect(_on_container_ready)

func _build_stats(stats: Node) -> void:
	# Clear existing
	for child in _stats_container.get_children():
		child.queue_free()
		
	if not stats:
		var missing := Label.new()
		missing.text = "No stats available for this entity"
		_stats_container.add_child(missing)
		return
		
	var built_any := false
	for child in stats.get_children():
		if child.has_method("get_value"):
			var label := Label.new()
			label.text = "%s: %s" % [child.name, str(child.get_value())]
			_stats_container.add_child(label)
			built_any = true

	if not built_any:
		var placeholder := Label.new()
		placeholder.text = "No stat components expose values yet"
		_stats_container.add_child(placeholder)

func _on_container_ready(entity_id: String, container_name: String) -> void:
	if not is_for_this_entity(entity_id):
		return
	if container_name != "StatsContainer":
		return
	if _data_provider and _data_provider.has_method("get_stats_container"):
		_build_stats(_data_provider.get_stats_container())
