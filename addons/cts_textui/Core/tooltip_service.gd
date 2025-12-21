extends Node
## Service for managing tooltips in the application.
## Use as an autoload singleton.
class_name TooltipService

@export var tooltips_parent: Control

const DEFAULT_TOOLTIP_PREFAB_PATH := "res://addons/cts_textui/Prefabs/default_tooltip.tscn"

var _destroyed_tooltips: Array[Tooltip] = []
var _active_tooltips: Dictionary = {}  # Tooltip -> TooltipHandler
var _data_provider: TooltipDataProvider = TooltipDataProvider.BasicTooltipDataProvider.create_empty()
var _tooltip_prefab_path: String = ""
var _settings: TooltipSettings = TooltipSettings.create_default()


#region Lifecycle Methods

func _process(delta: float) -> void:
	# Process all active tooltip handlers
	for handler in _active_tooltips.values():
		handler.process(delta)
	
	# Destroy all tooltips queued for destruction
	for tooltip in _destroyed_tooltips:
		_active_tooltips.erase(tooltip)
	_destroyed_tooltips.clear()

#endregion


#region Configuration API

## The provider used to retrieve tooltip data by id.
func set_tooltip_data_provider(provider: TooltipDataProvider) -> void:
	if not provider:
		push_error("TooltipService: Tooltip data provider cannot be null")
		return
	_data_provider = provider
	clear_all_tooltips()


func get_tooltip_data_provider() -> TooltipDataProvider:
	return _data_provider


## The path to the tooltip prefab that is used to create new tooltips.
func set_tooltip_prefab_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("TooltipService: The tooltip prefab path '%s' does not point to a valid resource." % path)
		return
	
	var scene := load(path) as PackedScene
	if not scene:
		push_error("TooltipService: The tooltip prefab path '%s' does not point to a valid PackedScene." % path)
		return
	
	var instance := scene.instantiate()
	if not instance is TooltipControlInterface:
		instance.queue_free()
		push_error("TooltipService: The tooltip prefab at '%s' does not inherit from TooltipControlInterface." % path)
		return
	
	instance.queue_free()
	_tooltip_prefab_path = path
	clear_all_tooltips()


func get_tooltip_prefab_path() -> String:
	return _tooltip_prefab_path if _tooltip_prefab_path else DEFAULT_TOOLTIP_PREFAB_PATH


## Determines the behaviour of the tooltip system.
func set_tooltip_settings(settings: TooltipSettings) -> void:
	_settings = settings
	clear_all_tooltips()


func get_tooltip_settings() -> TooltipSettings:
	return _settings

#endregion


#region API

## All currently active tooltips, including all nested ones.
func get_active_tooltips() -> Array[Tooltip]:
	var active: Array[Tooltip] = []
	for tooltip in _active_tooltips.keys():
		if not _destroyed_tooltips.has(tooltip):
			active.append(tooltip)
	return active


## Creates a new tooltip at the given position with the given pivot and text.
func show_tooltip(position: Vector2, pivot: TooltipPivot.Position, text: String, width: int = -1) -> Tooltip:
	var result := _create_tooltip(position, pivot, width)
	var handler: TooltipHandler = result.handler
	handler.set_text(text)
	return result.tooltip


## Creates a new tooltip at the given position with the given pivot and the text of the tooltip with the given id.
func show_tooltip_by_id(position: Vector2, pivot: TooltipPivot.Position, tooltip_id: String, width: int = -1) -> Tooltip:
	var tooltip_data := _data_provider.get_tooltip_data(tooltip_id)
	if not tooltip_data:
		push_error("TooltipService: No tooltip data found for id: %s" % tooltip_id)
		return null
	
	var actual_width := width if width >= 0 else tooltip_data.desired_width
	var result := _create_tooltip(position, pivot, actual_width)
	var handler: TooltipHandler = result.handler
	handler.set_text(tooltip_data.text)
	return result.tooltip


## If action lock is set in the settings, then this method will lock a tooltip.
func action_lock_tooltip(tooltip: Tooltip) -> void:
	if not tooltip:
		push_error("TooltipService: Tooltip cannot be null")
		return
	
	if not _active_tooltips.has(tooltip):
		push_error("TooltipService: Tooltip not found")
		return
	
	var handler: TooltipHandler = _active_tooltips[tooltip]
	handler.on_this_clicked()


## Forces the tooltip and all nested tooltips to be removed.
func force_destroy(tooltip: Tooltip) -> void:
	if not tooltip:
		push_error("TooltipService: Tooltip cannot be null")
		return
	
	if not _active_tooltips.has(tooltip):
		push_error("TooltipService: Tooltip not found")
		return
	
	var handler: TooltipHandler = _active_tooltips[tooltip]
	handler.force_destroy()


## Sets a flag on the tooltip that indicates it can destroy itself if locking allows it.
func release_tooltip(tooltip: Tooltip) -> void:
	if not tooltip:
		push_error("TooltipService: Tooltip cannot be null")
		return
	
	if not _active_tooltips.has(tooltip):
		push_error("TooltipService: Tooltip not found")
		return
	
	var handler: TooltipHandler = _active_tooltips[tooltip]
	handler.release()


## Forcefully destroys all existing tooltips.
func clear_tooltips() -> void:
	clear_all_tooltips()

#endregion


#region Utility Methods

## Calculates the position of a tooltip based on size and pivot.
func _calculate_position_from_pivot(position: Vector2, pivot: TooltipPivot.Position, tooltip_size: Vector2) -> Vector2:
	var pivot_vector := Vector2.ZERO
	
	match pivot:
		TooltipPivot.Position.TOP_LEFT:
			pivot_vector = Vector2(0, 0)
		TooltipPivot.Position.TOP_CENTER:
			pivot_vector = Vector2(0.5, 0)
		TooltipPivot.Position.TOP_RIGHT:
			pivot_vector = Vector2(1, 0)
		TooltipPivot.Position.CENTER_LEFT:
			pivot_vector = Vector2(0, 0.5)
		TooltipPivot.Position.CENTER:
			pivot_vector = Vector2(0.5, 0.5)
		TooltipPivot.Position.CENTER_RIGHT:
			pivot_vector = Vector2(1, 0.5)
		TooltipPivot.Position.BOTTOM_LEFT:
			pivot_vector = Vector2(0, 1)
		TooltipPivot.Position.BOTTOM_CENTER:
			pivot_vector = Vector2(0.5, 1)
		TooltipPivot.Position.BOTTOM_RIGHT:
			pivot_vector = Vector2(1, 1)
	
	return position - (tooltip_size * pivot_vector)


## Validates that the position for the new tooltip fits within screen bounds.
func _calculate_new_tooltip_location(position: Vector2, size: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	
	var clamped_x := clampf(position.x, 0.0, maxf(0.0, viewport_size.x - size.x))
	var clamped_y := clampf(position.y, 0.0, maxf(0.0, viewport_size.y - size.y))
	
	return Vector2(clamped_x, clamped_y)


## Calculates the position for a nested tooltip based on cursor location.
func _calculate_nested_tooltip_location(position: Vector2) -> Dictionary:
	const OFFSET_FACTOR := 15.0
	
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_center := viewport_size / 2.0
	
	var pivot: TooltipPivot.Position
	var offset := Vector2.ZERO
	
	# Determine best pivot based on screen quadrant
	if position.x < screen_center.x:  # Left half
		if position.y < screen_center.y:  # Top-Left -> open bottom-right
			pivot = TooltipPivot.Position.TOP_LEFT
			offset = Vector2(1, 1) * OFFSET_FACTOR
		else:  # Bottom-Left -> open top-right
			pivot = TooltipPivot.Position.BOTTOM_LEFT
			offset = Vector2(1, -1) * OFFSET_FACTOR
	else:  # Right half
		if position.y < screen_center.y:  # Top-Right -> open bottom-left
			pivot = TooltipPivot.Position.TOP_RIGHT
			offset = Vector2(-1, 1) * OFFSET_FACTOR
		else:  # Bottom-Right -> open top-left
			pivot = TooltipPivot.Position.BOTTOM_RIGHT
			offset = Vector2(-1, -1) * OFFSET_FACTOR
	
	position += offset
	
	return {
		"position": position,
		"pivot": pivot
	}


func _create_tooltip(position: Vector2, pivot: TooltipPivot.Position, width: int, parent_handler: RefCounted = null) -> Dictionary:
	var tooltip_path := get_tooltip_prefab_path()
	var tooltip_scene := load(tooltip_path) as PackedScene
	
	if not tooltip_scene:
		push_error("TooltipService: Could not load tooltip scene from path: %s" % tooltip_path)
		return {}
	
	var tooltip_control_node := tooltip_scene.instantiate()
	tooltips_parent.add_child(tooltip_control_node)
	
	if not tooltip_control_node is TooltipControlInterface:
		push_error("TooltipService: The tooltip prefab at '%s' does not inherit from TooltipControlInterface." % tooltip_path)
		return {}
	
	var tooltip_handler := TooltipHandler.new(self, tooltip_control_node, parent_handler, position, pivot, width)
	var tooltip := tooltip_handler.get_tooltip()
	
	_active_tooltips[tooltip] = tooltip_handler
	
	return {
		"handler": tooltip_handler,
		"tooltip": tooltip
	}


func clear_all_tooltips() -> void:
	for handler in _active_tooltips.values():
		handler.force_destroy()

#endregion


#region TooltipHandler Inner Class

class TooltipHandler extends RefCounted:
	var _service: TooltipService
	var _control: TooltipControlInterface
	var _desired_position: Vector2
	var _desired_pivot: TooltipPivot.Position
	
	var _alive_time: float = 0.0
	var _cursor_away_time: float = 0.0
	var _queued_for_release: bool = false
	var _is_freed: bool = false
	var _is_action_locked: bool = false
	var _last_size: Vector2 = Vector2.ZERO
	var _was_locked: bool = false
	
	var parent: TooltipHandler = null
	var child: TooltipHandler = null
	var tooltip: Tooltip = null
	
	
	func _init(service: TooltipService, control: TooltipControlInterface, parent_handler: TooltipHandler, desired_position: Vector2, desired_pivot: TooltipPivot.Position, width: int) -> void:
		_service = service
		_control = control
		parent = parent_handler
		_desired_position = desired_position
		_desired_pivot = desired_pivot
		_last_size = _control.size
		
		_update_position()
		
		_control.visible = false
		_control.is_interactable = false
		_control.link_clicked.connect(_on_link_clicked)
		
		# Set width
		if width >= 0:
			_control.minimum_width = width
			_control.wrap_text = true
		else:
			_control.minimum_width = 0
			_control.wrap_text = false
		
		# Create readonly tooltip
		tooltip = Tooltip.new(
			func() -> Tooltip: return child.tooltip if child else null,
			parent.tooltip if parent else null,
			"",
			_desired_position,
			_desired_pivot
		)
	
	
	func get_tooltip() -> Tooltip:
		return tooltip
	
	
	func set_text(text: String) -> void:
		_control.content_text = text
		tooltip.text = text
	
	
	func release() -> void:
		if not _was_locked:
			_destroy_internal()
			return
		_queued_for_release = true
	
	
	func force_destroy() -> void:
		_destroy_internal()
	
	
	func on_this_clicked() -> void:
		_is_action_locked = true
	
	
	func process(delta: float) -> void:
		if _is_freed:
			return
		
		_alive_time += delta
		
		# Show tooltip after delay
		var show_delay := _service.get_tooltip_settings().lock_time if _service.get_tooltip_settings() else 0.0
		_control.visible = _alive_time >= show_delay
		
		# Update cursor away time
		if _is_cursor_over_tooltip() or child != null:
			_cursor_away_time = 0.0
			_control.unlock_progress = 0.0
		elif _queued_for_release:
			_cursor_away_time += delta
			_control.unlock_progress = _get_unlock_progress()
		
		# Check locking
		var lock_mode := _service.get_tooltip_settings().lock_mode if _service.get_tooltip_settings() else TooltipLockMode.Mode.NONE
		match lock_mode:
			TooltipLockMode.Mode.HOVER_LOCK:
				var result := _is_locked_by_hover_lock()
				_control.lock_progress = result.progress
				_was_locked = _was_locked or result.is_locked
			TooltipLockMode.Mode.ACTION_LOCK:
				var is_locked := _is_locked_by_action_lock()
				_was_locked = _was_locked or is_locked
				_control.lock_progress = 1.0 if is_locked else 0.0
		
		_control.is_interactable = _was_locked
		
		# Handle release logic
		if _queued_for_release:
			var is_cursor_over := _is_cursor_over_tooltip()
			var is_unlocked := _get_unlock_progress() >= 1.0
			var no_open_child := child == null
			
			if not is_cursor_over and is_unlocked and no_open_child:
				_destroy_internal()
		
		# Update position if size changed
		if _control.size != _last_size:
			_last_size = _control.size
			_update_position()
	
	
	func _get_unlock_progress() -> float:
		var unlock_time := _service.get_tooltip_settings().unlock_time if _service.get_tooltip_settings() else 0.3
		return clampf(_cursor_away_time / unlock_time, 0.0, 1.0)
	
	
	func _is_locked_by_hover_lock() -> Dictionary:
		var lock_time := _service.get_tooltip_settings().lock_time if _service.get_tooltip_settings() else 0.5
		var is_locked := _alive_time >= lock_time
		var lock_progress := clampf(_alive_time / lock_time, 0.0, 1.0)
		return {"is_locked": is_locked, "progress": lock_progress}
	
	
	func _is_locked_by_action_lock() -> bool:
		return _is_action_locked
	
	
	func _is_cursor_over_tooltip() -> bool:
		if not _control or not is_instance_valid(_control):
			return false
		var mouse_pos := _control.get_global_mouse_position()
		var rect := Rect2(_control.global_position, _control.size)
		return rect.has_point(mouse_pos)
	
	
	func _on_link_clicked(position: Vector2, meta: String) -> void:
		if not _was_locked:
			return
		
		# Destroy existing child
		_destroy_child()
		
		# Get tooltip data
		var tooltip_data := _service.get_tooltip_data_provider().get_tooltip_data(meta)
		if not tooltip_data:
			push_error("TooltipService: No tooltip data found for id: %s" % meta)
			return
		
		# Create nested tooltip
		var nested_location := _service._calculate_nested_tooltip_location(position)
		var result := _service._create_tooltip(
			nested_location.position,
			nested_location.pivot,
			tooltip_data.desired_width,
			self
		)
		
		if result.has("handler"):
			var child_handler: TooltipHandler = result.handler
			child_handler.set_text(tooltip_data.text)
			child = child_handler
	
	
	func _destroy_child() -> void:
		if not child:
			return
		child.force_destroy()
		child = null
	
	
	func _update_position() -> void:
		var placement_position := _service._calculate_position_from_pivot(_desired_position, _desired_pivot, _control.size)
		placement_position = _service._calculate_new_tooltip_location(placement_position, _control.size)
		_control.position = placement_position
	
	
	func _destroy_internal() -> void:
		if _is_freed:
			return
		
		_is_freed = true
		if _control and is_instance_valid(_control):
			_control.queue_free()
		
		# Destroy children
		if child:
			child.force_destroy()
			child = null
		
		# Tell parent
		if parent:
			parent.child = null
		
		# Tell service
		_service._destroyed_tooltips.append(tooltip)

#endregion
