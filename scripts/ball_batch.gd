class_name BallBatch
extends RefCounted

var id: int = 0
var definitions: Array[BallDefinition] = []
var launch_spread_degrees: float = 0.0

func _init(batch_id: int, ball_definitions: Array[BallDefinition], spread_degrees: float) -> void:
	id = batch_id
	definitions = ball_definitions
	launch_spread_degrees = spread_degrees

func get_launch_direction(base_direction: Vector2, _ball_index: int) -> Vector2:
	return base_direction.normalized()
