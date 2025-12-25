@tool
class_name StatBar
extends TextureProgressBar

## A progress bar with a text overlay for stats (HP, XP, etc.)

@export var label_format: String = "%s / %s"
@export var show_label: bool = true:
	set(value):
		show_label = value
		if _label: _label.visible = value

var _label: Label

func _ready() -> void:
	_setup_label()
	value_changed.connect(_on_value_changed)
	_update_label()

func _setup_label() -> void:
	if not _label:
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.anchors_preset = Control.PRESET_FULL_RECT
		_label.visible = show_label
		add_child(_label)

func _on_value_changed(_new_value: float) -> void:
	_update_label()

func _update_label() -> void:
	if _label and show_label:
		_label.text = label_format % [str(value), str(max_value)]
