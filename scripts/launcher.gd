class_name Launcher
extends Node2D

signal launch_requested(direction: Vector2)

@export var config: GameConfig

var _is_dragging: bool = false
var _pointer_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	assert(config != null, "Launcher requires a GameConfig resource.")
	_pointer_position = global_position
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer_button(event.position, event.pressed)
	elif event is InputEventScreenTouch:
		_handle_pointer_button(event.position, event.pressed)
	elif event is InputEventMouseMotion and _is_dragging:
		_update_drag(event.position)
	elif event is InputEventScreenDrag and _is_dragging:
		_update_drag(event.position)

func _handle_pointer_button(pointer_position: Vector2, is_pressed: bool) -> void:
	if is_pressed:
		if pointer_position.y >= global_position.y:
			_is_dragging = true
			_pointer_position = pointer_position
			queue_redraw()
		return
	if not _is_dragging:
		return
	_is_dragging = false
	_pointer_position = pointer_position
	var drag_vector: Vector2 = pointer_position - global_position
	var launch_direction: Vector2 = drag_vector
	if launch_direction.y > 0.0:
		launch_requested.emit(launch_direction.normalized())
	queue_redraw()

func _update_drag(pointer_position: Vector2) -> void:
	_pointer_position = pointer_position
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, config.launcher_radius, 0.0, TAU, 20, Color("eef4f4"), 5.0)
	if _is_dragging:
		var aim_direction: Vector2 = _pointer_position - global_position
		if aim_direction.length_squared() > 0.0:
			var aim_end: Vector2 = aim_direction.normalized() * 220.0
			draw_dashed_line(Vector2.ZERO, aim_end, Color("d9ff3f"), 4.0, 12.0)
