class_name BallLaunchSequence
extends RefCounted

var batch_id: int = 0
var pending_definitions: Array[BallDefinition] = []
var active_balls: Dictionary = {}
var origin: Vector2 = Vector2.ZERO
var launch_direction: Vector2 = Vector2.DOWN
var seconds_until_next_launch: float = 0.0

func _init(batch: BallBatch, batch_origin: Vector2, direction: Vector2) -> void:
	batch_id = batch.id
	pending_definitions.append_array(batch.definitions)
	origin = batch_origin
	launch_direction = direction.normalized()
