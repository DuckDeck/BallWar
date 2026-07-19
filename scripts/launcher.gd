class_name Launcher
extends Node2D

signal launch_requested(direction: Vector2)

@export var config: GameConfig

const BALL_OUTLINE_COLOR: Color = Color("f7ffb2")

var _is_dragging: bool = false
var _is_launch_ready: bool = true
var _pointer_position: Vector2 = Vector2.ZERO
var _waiting_definitions: Array[BallDefinition] = []

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
	var launch_direction: Vector2 = pointer_position - global_position
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

func set_waiting_ball_definitions(definitions: Array[BallDefinition]) -> void:
	_waiting_definitions.clear()
	_waiting_definitions.append_array(definitions)
	queue_redraw()

func get_waiting_ball_count() -> int:
	return _waiting_definitions.size()

func get_aim_guide_segments(direction: Vector2) -> Array[PackedVector2Array]:
	var segments: Array[PackedVector2Array] = []
	if direction.length_squared() <= 0.0 or not is_inside_tree():
		return segments
	var primary_direction: Vector2 = direction.normalized()
	var primary_start: Vector2 = global_position
	var motion: Vector2 = primary_direction * config.aim_guide_max_length
	var primary_end: Vector2 = primary_start + motion
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = config.ball_radius
	var shape_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	shape_query.shape = circle_shape
	shape_query.transform = Transform2D(0.0, primary_start)
	shape_query.motion = motion
	shape_query.collision_mask = 1
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var cast_result: PackedFloat32Array = space_state.cast_motion(shape_query)
	var safe_fraction: float = cast_result[0] if not cast_result.is_empty() else 1.0
	if safe_fraction < 1.0:
		primary_end = primary_start + motion * safe_fraction
		shape_query.transform = Transform2D(0.0, primary_end)
		shape_query.motion = motion * (1.0 - safe_fraction)
		var rest_info: Dictionary = space_state.get_rest_info(shape_query)
		var hit_normal: Vector2 = rest_info.get("normal", Vector2.ZERO) as Vector2
		var reflected_direction: Vector2 = primary_direction.bounce(hit_normal).normalized()
		var reflected_end: Vector2 = primary_end + reflected_direction * config.aim_guide_reflection_length
		segments.append(PackedVector2Array([primary_start, primary_end]))
		segments.append(PackedVector2Array([primary_end, reflected_end]))
		return segments
	segments.append(PackedVector2Array([primary_start, primary_end]))
	return segments

func _draw() -> void:
	for index: int in _waiting_definitions.size():
		var position: Vector2 = _get_waiting_ball_position(index)
		var color: Color = _waiting_definitions[index].visual_color
		draw_circle(position, config.ball_radius, color)
		draw_arc(position, config.ball_radius + 3.0, 0.0, TAU, 24, BALL_OUTLINE_COLOR, 2.0)
	if _is_dragging:
		var aim_direction: Vector2 = _pointer_position - global_position
		if aim_direction.length_squared() > 0.0:
			var aim_color: Color = _waiting_definitions[0].visual_color if not _waiting_definitions.is_empty() else Color("d9ff3f")
			var guide_segments: Array[PackedVector2Array] = get_aim_guide_segments(aim_direction)
			if not guide_segments.is_empty():
				var primary_segment: PackedVector2Array = guide_segments[0]
				draw_dashed_line(to_local(primary_segment[0]), to_local(primary_segment[1]), aim_color, 4.0, 12.0)
			if guide_segments.size() > 1:
				var reflected_segment: PackedVector2Array = guide_segments[1]
				var reflected_color: Color = Color(aim_color.r, aim_color.g, aim_color.b, 0.55)
				draw_dashed_line(to_local(reflected_segment[0]), to_local(reflected_segment[1]), reflected_color, 3.0, 10.0)

func _get_waiting_ball_position(index: int) -> Vector2:
	if index == 0:
		return Vector2.ZERO
	var layer: int = (index + 1) / 2
	var side: float = -1.0 if index % 2 == 1 else 1.0
	var horizontal_spacing: float = config.ball_radius * 1.25
	var vertical_spacing: float = config.ball_radius * 1.30
	return Vector2(side * float(layer) * horizontal_spacing, -float(layer) * vertical_spacing)
