class_name TooltipDataProvider
extends RefCounted
## Interface for providing tooltip data by ID.

## Finds and returns a TooltipData from its id.
## Returns null if nothing was found.
func get_tooltip_data(_id: String) -> TooltipData:
	return null


class BasicTooltipDataProvider extends TooltipDataProvider:
	## A simple implementation that stores tooltips in a dictionary.
	
	var _tooltips: Dictionary = {}  # String -> TooltipData
	
	func add_tooltip(data: TooltipData) -> void:
		_tooltips[data.id] = data
	
	func remove_tooltip(id: String) -> void:
		_tooltips.erase(id)
	
	func get_tooltip_data(id: String) -> TooltipData:
		return _tooltips.get(id, null)
	
	static func create_empty() -> BasicTooltipDataProvider:
		return BasicTooltipDataProvider.new()
