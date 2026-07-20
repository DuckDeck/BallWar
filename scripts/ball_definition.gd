class_name BallDefinition
extends Resource

enum Type {
	NORMAL,
	HEAVY,
}

@export_group("Gameplay")
@export var type: Type = Type.NORMAL
@export_range(1, 99, 1) var damage: int = 1
@export_range(0.1, 4.0, 0.1) var gravity_multiplier: float = 1.0
@export_range(0.5, 3.0, 0.05) var radius_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var double_damage_probability: float = 0.0

@export_group("Visual")
@export var visual_color: Color = Color("d9ff3f")

@export_group("Extensions")
@export var effects: Array[BallEffect] = []
