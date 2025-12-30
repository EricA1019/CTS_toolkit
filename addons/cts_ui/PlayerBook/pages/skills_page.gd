class_name SkillsPage
extends BookPage

@export var config: StatPageConfig

@onready var container: VBoxContainer = $ScrollContainer/VBoxContainer

func setup(event_bus: Node, data_provider: Node) -> void:
	super.setup(event_bus, data_provider)
	
	if not config:
		push_warning("SkillsPage: No config provided.")
		return
	
	name = config.title
	
	# Connect signals
	if event_bus.has_signal("skill_level_changed"):
		if not event_bus.skill_level_changed.is_connected(_on_skill_level_changed):
			event_bus.skill_level_changed.connect(_on_skill_level_changed)

func refresh() -> void:
	if not _data_provider or not _data_provider.has_method("get_page_data"):
		return
		
	var data = _data_provider.get_page_data(&"skills")
	_build_ui(data)

func _build_ui(data: Dictionary) -> void:
	# Clear existing
	for child in container.get_children():
		child.queue_free()
		
	for stat_name in config.stats_to_show:
		var label = Label.new()
		label.name = stat_name
		
		var val_str = "0"
		if data.has(stat_name):
			var skill_data = data[stat_name]
			if skill_data is Dictionary:
				val_str = str(skill_data.get("level", 0))
			else:
				val_str = str(skill_data)
				
		label.text = "%s: %s" % [stat_name, val_str]
		container.add_child(label)

func _on_skill_level_changed(entity_id: String, skill_name: String, level: int, _xp: int) -> void:
	if not is_for_this_entity(entity_id):
		return

	var display_name := skill_name.capitalize().replace("_", " ")
	if display_name in config.stats_to_show:
		_update_label(display_name, level)

func _update_label(stat_name: String, value: int) -> void:
	var label = container.get_node_or_null(stat_name)
	if label:
		label.text = "%s: %s" % [stat_name, str(value)]
