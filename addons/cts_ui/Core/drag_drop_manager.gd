extends Node

## Global manager for cross-page drag-drop operations
## Registered as autoload: DragDropManager

signal drag_started(payload: DragPayload)
signal drag_ended(payload: DragPayload)
signal drop_completed(payload: DragPayload, target: Node)

var _current_payload: DragPayload
var _is_dragging: bool = false

func start_drag(payload: DragPayload) -> void:
	if not payload or not payload.is_valid():
		return
		
	_current_payload = payload
	_is_dragging = true
	drag_started.emit(payload)
	
	# Notify EventBus if available
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if bus.has_signal("ui_drag_started"):
			bus.ui_drag_started.emit(payload)

func end_drag() -> void:
	if not _is_dragging:
		return
		
	var payload = _current_payload
	_is_dragging = false
	_current_payload = null
	drag_ended.emit(payload)
	
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if bus.has_signal("ui_drag_cancelled"):
			bus.ui_drag_cancelled.emit(payload)

func complete_drop(target: Node) -> void:
	if not _is_dragging or not _current_payload:
		return
		
	var payload = _current_payload
	drop_completed.emit(payload, target)
	
	if has_node("/root/EventBus"):
		var bus = get_node("/root/EventBus")
		if bus.has_signal("ui_drop_completed"):
			bus.ui_drop_completed.emit(payload, target)
			
	# Reset state
	_is_dragging = false
	_current_payload = null

func get_current_payload() -> DragPayload:
	return _current_payload

func is_dragging() -> bool:
	return _is_dragging
