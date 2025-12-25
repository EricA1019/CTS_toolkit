@tool
class_name CharacterSheetPage
extends BookPage

## Page displaying character stats

var _stats_container: VBoxContainer
var _binding: ReactiveBinding

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
	_binding = ReactiveBinding.new(self)
	
	if data_provider.has_method("get_stats_container"):
		var stats = data_provider.get_stats_container()
		if stats:
			_build_stats(stats)

func _build_stats(stats: Node) -> void:
	# Clear existing
	for child in _stats_container.get_children():
		child.queue_free()
		
	# Placeholder for stat building logic
	# This would iterate over stats defined in a config or the container itself
	var label = Label.new()
	label.text = "Stats"
	_stats_container.add_child(label)
