class_name BookPage
extends Control

## Base class for all pages in the PlayerBook.
## Handles setup and dependency injection.

@export var page_title: String = "Page"
@export var page_icon: Texture2D

var _entity_id: String = ""
var _data_provider: Node = null

## Called by the PlayerBook to inject dependencies.
## Override this to initialize your page.
func setup(event_bus: Node, data_provider: Node) -> void:
	_data_provider = data_provider
	if data_provider and data_provider.has_method("get_entity_id"):
		_entity_id = data_provider.get_entity_id()
	
	# Initial data load
	refresh()

## Refreshes the page data from the provider
## Override to implement specific data loading logic
func refresh() -> void:
	pass

## Helper to check if a signal is for this entity
func is_for_this_entity(entity_id: String) -> bool:
	return not _entity_id.is_empty() and entity_id == _entity_id
