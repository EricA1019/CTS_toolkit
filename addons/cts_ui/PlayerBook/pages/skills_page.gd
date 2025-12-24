class_name SkillsPage
extends BookPage

@export var config: StatPageConfig

var _stats_component: Node

@onready var container: VBoxContainer = $ScrollContainer/VBoxContainer

func setup(event_bus: Node, data_provider: Node) -> void:
	if not config:
		push_warning("SkillsPage: No config provided.")
		return
		
	name = config.title
	
	# Try to find the component
	if data_provider.has_node(config.component_name):
		_stats_component = data_provider.get_node(config.component_name)
	else:
		push_warning("SkillsPage: Could not find component %s on provider." % config.component_name)
		return
		
	# Connect signals
	if event_bus.has_signal("stat_changed"):
		event_bus.stat_changed.connect(_on_stat_changed)
		
	_build_ui()

func _build_ui() -> void:
	# Clear existing
	for child in container.get_children():
		child.queue_free()
		
	for stat_name in config.stats_to_show:
		var label = Label.new()
		label.name = stat_name
		label.text = "%s: ..." % stat_name
		container.add_child(label)
		
		# Initial update if possible
		if _stats_component and _stats_component.has_method("get_stat"):
			var val = _stats_component.get_stat(stat_name)
			_update_label(stat_name, val)

func _on_stat_changed(stat_name: String, new_value: float) -> void:
	if stat_name in config.stats_to_show:
		_update_label(stat_name, new_value)

func _update_label(stat_name: String, value: float) -> void:
	var label = container.get_node_or_null(stat_name)
	if label:
		label.text = "%s: %s" % [stat_name, str(value)]
