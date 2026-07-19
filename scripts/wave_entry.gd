class_name WaveEntry
extends RefCounted

var column: int = 0
var health: int = 1

func _init(entry_column: int, entry_health: int) -> void:
	column = entry_column
	health = entry_health
