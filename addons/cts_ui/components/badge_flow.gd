@tool
class_name BadgeFlow
extends FlowContainer

## Displays a collection of badges (affixes, tags)

func add_badge(text: String, color: Color = Color.GRAY) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = text
	panel.add_child(label)
	
	add_child(panel)

func clear() -> void:
	for child in get_children():
		child.queue_free()
