class_name TooltipData
extends Resource
## The information required to display a tooltip based on its id.

## The unique identifier of the tooltip.
@export var id: String = ""

## The bbcode formatted text of the tooltip.
@export_multiline var text: String = ""

## The desired width of the tooltip in pixels. If null, auto-sized.
@export var desired_width: int = -1


func _init(_id: String = "", _text: String = "", _width: int = -1) -> void:
	id = _id
	text = _text
	desired_width = _width
