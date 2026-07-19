class_name Launcher
extends Node2D

signal launch_requested(direction: Vector2)

@export var config: GameConfig

const BALL_COLOR: Color = Color("d9ff3f")
const BALL_OUTLINE_COLOR: Color = Color("f7ffb2")

var _is_dragging: bool = false
var _is_launch_ready: bool = true
var _pointer_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	assert(config != null, "Launcher requires a GameConfig resource.")
	_pointer_position = global_position
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_launch_ready:
		return
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

func set_launch_ready(is_ready: bool) -> void:
	_is_launch_ready = is_ready
	if not _is_launch_ready:
		_is_dragging = false
	queue_redraw()

func is_launch_ready() -> bool:
	return _is_launch_ready

func _draw() -> void:
	if _is_launch_ready:
		# 缺口内的待发球与真实生成球使用相同配色，明确提示下一颗球的起点。
		draw_circle(Vector2.ZERO, config.ball_radius, BALL_COLOR)
		draw_arc(Vector2.ZERO, config.ball_radius + 3.0, 0.0, TAU, 24, BALL_OUTLINE_COLOR, 2.0)
	if _is_dragging:
		var aim_direction: Vector2 = _pointer_position - global_position
		if aim_direction.length_squared() > 0.0:
			var aim_end: Vector2 = aim_direction.normalized() * 220.0
			draw_dashed_line(Vector2.ZERO, aim_end, BALL_COLOR, 4.0, 12.0)
