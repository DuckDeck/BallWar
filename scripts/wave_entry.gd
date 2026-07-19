class_name WaveEntry
extends RefCounted

var column: int = 0
var health: int = 1
var shape_type: int = 0
var rotation_degrees: float = 0.0

func _init(entry_column: int, entry_health: int, entry_shape_type: int = 0, entry_rotation_degrees: float = 0.0) -> void:
	column = entry_column
	health = entry_health
	shape_type = entry_shape_type
	rotation_degrees = entry_rotation_degrees
