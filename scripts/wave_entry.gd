class_name WaveEntry
extends RefCounted

enum Content {
	OBSTACLE,
	ADD_BALL_REWARD,
	ENLARGE_BALL_REWARD,
}

var column: int = 0
var health: int = 1
var shape_type: int = 0
var rotation_degrees: float = 0.0
var content: Content = Content.OBSTACLE

func _init(entry_column: int, entry_health: int, entry_shape_type: int = 0, entry_rotation_degrees: float = 0.0, entry_content: Content = Content.OBSTACLE) -> void:
	column = entry_column
	health = entry_health
	shape_type = entry_shape_type
	rotation_degrees = entry_rotation_degrees
	content = entry_content
