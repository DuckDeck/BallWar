class_name BallRuntimeState
extends RefCounted

var velocity: Vector2 = Vector2.ZERO
var elapsed_seconds: float = 0.0
var is_gravity_enabled: bool = false
var is_recovered: bool = false
var recovery_reason: StringName = &""
