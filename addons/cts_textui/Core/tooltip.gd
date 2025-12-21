class_name Tooltip
extends RefCounted
## The readonly class that represents a created tooltip.

var parent: Tooltip = null
var text: String = ""
var position: Vector2 = Vector2.ZERO
var pivot: TooltipPivot.Position = TooltipPivot.Position.TOP_LEFT

var _get_child_func: Callable


func _init(_get_child: Callable, _parent: Tooltip, _text: String, _pos: Vector2, _pivot: TooltipPivot.Position) -> void:
	_get_child_func = _get_child
	parent = _parent
	text = _text
	position = _pos
	pivot = _pivot


func get_child() -> Tooltip:
	if _get_child_func.is_valid():
		return _get_child_func.call()
	return null
