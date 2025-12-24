class_name BookPage
extends Control

## Base class for all pages in the PlayerBook.
## Handles setup and dependency injection.

@export var page_title: String = "Page"
@export var page_icon: Texture2D

## Called by the PlayerBook to inject dependencies.
## Override this to initialize your page.
func setup(event_bus: Node, data_provider: Node) -> void:
	pass
