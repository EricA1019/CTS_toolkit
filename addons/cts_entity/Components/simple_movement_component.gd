extends Node
class_name SimpleMovementComponent

## Basic back-and-forth movement for demo entities

@export var speed: float = 100.0
@export var bounce_distance: float = 100.0

var _entity: EntityBase
var _start_position: Vector2
var _direction: int = 1  # 1 = right, -1 = left

func _ready() -> void:
	_entity = get_parent().get_parent() as EntityBase
	if not _entity:
		push_error("SimpleMovementComponent must be child of ComponentsContainer")
		return
	
	_start_position = _entity.position

func _physics_process(delta: float) -> void:
	if not _entity:
		return
	
	# Move entity
	_entity.position.x += speed * _direction * delta
	
	# Check if we've moved beyond bounce distance
	var distance_from_start := abs(_entity.position.x - _start_position.x)
	if distance_from_start >= bounce_distance:
		_direction *= -1  # Reverse direction
		_entity.position.x = _start_position.x + (bounce_distance * _direction)

func set_movement_data(base_speed: float, distance: float) -> void:
	"""Configure movement from EntityResource data"""
	speed = base_speed
	bounce_distance = distance
