class_name ReactiveBinding
extends RefCounted

## Utility for binding UI elements to data resources and signals
## Automatically handles connection management and cleanup

var _connections: Array[Dictionary] = []
var _owner: Node

func _init(owner_node: Node) -> void:
	_owner = owner_node
	if _owner:
		_owner.tree_exiting.connect(unbind_all)

## Bind a label's text to a resource property
## The resource must emit 'changed' signal when the property changes
func bind_label(label: Label, resource: Resource, property: String, format_string: String = "%s") -> void:
	if not resource or not label:
		return
		
	var update_fn = func():
		if is_instance_valid(label) and is_instance_valid(resource):
			var value = resource.get(property)
			label.text = format_string % str(value)
	
	# Initial update
	update_fn.call()
	
	# Connect to changed signal
	if resource.has_signal("changed"):
		resource.changed.connect(update_fn)
		_connections.append({
			"source": resource,
			"signal": "changed",
			"callable": update_fn
		})

## Bind a progress bar to a resource property
func bind_progress_bar(bar: Range, resource: Resource, value_prop: String, max_prop: String = "") -> void:
	if not resource or not bar:
		return
		
	var update_fn = func():
		if is_instance_valid(bar) and is_instance_valid(resource):
			bar.value = resource.get(value_prop)
			if not max_prop.is_empty():
				bar.max_value = resource.get(max_prop)
	
	# Initial update
	update_fn.call()
	
	# Connect
	if resource.has_signal("changed"):
		resource.changed.connect(update_fn)
		_connections.append({
			"source": resource,
			"signal": "changed",
			"callable": update_fn
		})

## Generic binding to a signal
func bind_signal(source: Object, signal_name: String, callback: Callable) -> void:
	if not source or not source.has_signal(signal_name):
		return
	
	if source.is_connected(signal_name, callback):
		return
		
	source.connect(signal_name, callback)
	_connections.append({
		"source": source,
		"signal": signal_name,
		"callable": callback
	})

## Clean up all connections
func unbind_all() -> void:
	for conn in _connections:
		var source = conn.source
		if is_instance_valid(source) and source.is_connected(conn.signal, conn.callable):
			source.disconnect(conn.signal, conn.callable)
	_connections.clear()
