extends PopupMenu
class_name ContextPopupMenu

signal numeric_pressed(index: int)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index: int = event.keycode - KEY_1
			print("[ContextPopupMenu] _gui_input numeric key: ", index + 1)
			emit_signal("numeric_pressed", index)
			event.accept()
