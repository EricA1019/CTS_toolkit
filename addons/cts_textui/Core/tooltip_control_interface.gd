extends Control
## Interface for tooltip controls. Implement this for custom tooltip visuals.
class_name TooltipControlInterface

## Determines if the tooltip can be interacted with.
var is_interactable: bool = false:
	set(value):
		is_interactable = value
		mouse_filter = MOUSE_FILTER_STOP if value else MOUSE_FILTER_IGNORE

## Sets the minimum width of the tooltip.
var minimum_width: float = 0.0

## Shows the progress in time on how much longer the tooltip needs to stay open to be pinned.
## Ranges from 0 to 1, where 0 means no progress and 1 means the tooltip is pinned.
var lock_progress: float = 0.0

## Shows the progress in time on how much longer the tooltip needs to stay open to be unlocked.
## Ranges from 0 to 1, where 0 means no progress and 1 means the tooltip is unlocked.
var unlock_progress: float = 0.0

## The text displayed in the tooltip.
var content_text: String = ""

## Determines whether the text in the tooltip should wrap.
var wrap_text: bool = true

## Emitted when a link in the tooltip is clicked.
signal link_clicked(position: Vector2, meta: String)
