class_name BallDefinition
extends Resource

@export_group("Gameplay")
@export_range(1, 99, 1) var damage: int = 1
@export_range(0.1, 4.0, 0.1) var gravity_multiplier: float = 1.0

@export_group("Visual")
@export var visual_color: Color = Color("d9ff3f")

@export_group("Extensions")
@export var effects: Array[BallEffect] = []
