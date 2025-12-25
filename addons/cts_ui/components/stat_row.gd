@tool
class_name StatRow
extends HBoxContainer

## Single stat display row with label, value, and optional modifier
## Displays a stat name, its value, and an optional modifier with color coding.

signal stat_hovered(stat_name: String)

@export var stat_name: String = ""
@export var show_modifier: bool = true

var _stat_label: Label
var _stat_value: Label
var _modifier_label: Label

var _pending_setup: Dictionary = {}
var _is_ready: bool = false

func _ready() -> void:
	_build_ui()
	_is_ready = true
	
	mouse_entered.connect(_on_mouse_entered)
	
	if not _pending_setup.is_empty():
		_apply_setup()

func _build_ui() -> void:
	if get_child_count() == 0:
		_stat_label = Label.new()
		_stat_label.name = "StatLabel"
		_stat_label.size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(_stat_label)
		
		_stat_value = Label.new()
		_stat_value.name = "StatValue"
		add_child(_stat_value)
		
		_modifier_label = Label.new()
		_modifier_label.name = "ModifierLabel"
		add_child(_modifier_label)
	else:
		_stat_label = get_node_or_null("StatLabel")
		_stat_value = get_node_or_null("StatValue")
		_modifier_label = get_node_or_null("ModifierLabel")

func setup(p_name: String, value: Variant, modifier: int = 0, tooltip: String = "") -> void:
	_pending_setup = {
		"name": p_name,
		"value": value,
		"modifier": modifier,
		"tooltip": tooltip
	}
	
	if _is_ready:
		_apply_setup()

func _apply_setup() -> void:
	if _pending_setup.is_empty():
		return
	
	stat_name = _pending_setup.get("name", "")
	var tooltip = _pending_setup.get("tooltip", "")
	if not tooltip.is_empty():
		tooltip_text = tooltip
	
	var display_name: String = stat_name.replace("_", " ").capitalize()
	if _stat_label:
		_stat_label.text = display_name
	
	if _stat_value:
		_stat_value.text = str(_pending_setup.get("value", 0))
	
	var mod: int = _pending_setup.get("modifier", 0)
	if _modifier_label:
		if mod != 0 and show_modifier:
			_modifier_label.text = "%+d" % mod
			_modifier_label.visible = true
			if mod > 0:
				_modifier_label.add_theme_color_override("font_color", Color.WEB_GREEN)
			else:
				_modifier_label.add_theme_color_override("font_color", Color.CRIMSON)
		else:
			_modifier_label.visible = false
	
	_pending_setup.clear()

func _on_mouse_entered() -> void:
	stat_hovered.emit(stat_name)
