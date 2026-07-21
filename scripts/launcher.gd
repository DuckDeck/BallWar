class_name Launcher
extends Node2D

signal launch_requested(direction: Vector2, preferred_definition: BallDefinition)
signal next_ball_release_ready(batch_id: int, definition: BallDefinition)

@export var config: GameConfig

enum Presentation {
	CLASSIC_BLOCKED,
	CLASSIC_OPEN,
	CHALLENGE,
}

class PreviewBall:
	var definition: BallDefinition
	var position: Vector2
	var velocity: Vector2
	var is_in_launch_slot: bool = false
	var is_sleeping: bool = false

	func _init(ball_definition: BallDefinition, initial_position: Vector2, initial_velocity: Vector2) -> void:
		definition = ball_definition
		position = initial_position
		velocity = initial_velocity

var _is_dragging: bool = false
var _is_launch_ready: bool = true
var _launch_ready_requested: bool = true
var _pointer_position: Vector2 = Vector2.ZERO
var _waiting_definitions: Array[BallDefinition] = []
var _presentation: Presentation = Presentation.CLASSIC_BLOCKED
var _classic_preview_balls: Array[PreviewBall] = []
var _classic_gate_open: bool = false
var _classic_recovery_directions_by_color: Dictionary = {}
var _classic_stack_settle_seconds: float = 0.0
var _pending_release_batch_id: int = -1

func _ready() -> void:
	assert(config != null, "Launcher requires a GameConfig resource.")
	_pointer_position = global_position
	set_process(false)
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
		launch_requested.emit(launch_direction.normalized(), _get_current_launch_definition())
	queue_redraw()

func _update_drag(pointer_position: Vector2) -> void:
	_pointer_position = pointer_position
	queue_redraw()

func set_launch_ready(is_ready: bool) -> void:
	_launch_ready_requested = is_ready
	if not _launch_ready_requested:
		_is_launch_ready = false
		_is_dragging = false
	else:
		_update_launch_readiness()
	queue_redraw()

func is_launch_ready() -> bool:
	return _is_launch_ready

func set_waiting_ball_definitions(definitions: Array[BallDefinition]) -> void:
	_waiting_definitions.clear()
	_waiting_definitions.append_array(definitions)
	_sync_classic_preview_balls()

func set_presentation(presentation: Presentation) -> void:
	if _presentation == presentation:
		return
	_presentation = presentation
	# 经典和挑战共用同一套凹槽重力与碰撞预览；挑战模式从开始就保持开口。
	_classic_gate_open = _presentation != Presentation.CLASSIC_BLOCKED
	_sync_classic_preview_balls()
	_update_launch_readiness()
	queue_redraw()

func get_waiting_ball_count() -> int:
	return _waiting_definitions.size()

func get_presentation() -> Presentation:
	return _presentation

func has_classic_launch_slot_ball() -> bool:
	return _find_classic_launch_slot_ball() != null

func get_classic_preview_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for preview_ball: PreviewBall in _classic_preview_balls:
		positions.append(preview_ball.position)
	return positions

func get_challenge_preview_positions() -> Array[Vector2]:
	return get_classic_preview_positions()

func set_preview_recovery_direction(definition: BallDefinition, recovery_direction: float) -> void:
	if definition == null:
		return
	_classic_recovery_directions_by_color[definition.visual_color] = recovery_direction

func request_next_ball_release(batch_id: int) -> void:
	_pending_release_batch_id = batch_id
	_emit_pending_release_if_ready()

func get_aim_guide_segments(direction: Vector2) -> Array[PackedVector2Array]:
	var segments: Array[PackedVector2Array] = []
	if direction.length_squared() <= 0.0 or not is_inside_tree():
		return segments
	var primary_direction: Vector2 = direction.normalized()
	var primary_start: Vector2 = global_position
	var motion: Vector2 = primary_direction * config.aim_guide_max_length
	var primary_end: Vector2 = primary_start + motion
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = _get_ball_radius(_get_current_launch_definition())
	var shape_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	shape_query.shape = circle_shape
	shape_query.transform = Transform2D(0.0, primary_start)
	shape_query.motion = motion
	shape_query.collision_mask = 1
	shape_query.collide_with_bodies = true
	shape_query.collide_with_areas = false
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var cast_result: PackedFloat32Array = space_state.cast_motion(shape_query)
	var safe_fraction: float = cast_result[0] if not cast_result.is_empty() else 1.0
	if safe_fraction < 1.0:
		primary_end = primary_start + motion * safe_fraction
		var unsafe_fraction: float = cast_result[1] if cast_result.size() > 1 else safe_fraction
		shape_query.transform = Transform2D(0.0, primary_start + motion * unsafe_fraction)
		shape_query.motion = Vector2.ZERO
		var rest_info: Dictionary = space_state.get_rest_info(shape_query)
		var hit_normal: Vector2 = rest_info.get("normal", Vector2.ZERO) as Vector2
		if hit_normal.is_zero_approx():
			segments.append(PackedVector2Array([primary_start, primary_end]))
			return segments
		var reflected_direction: Vector2 = primary_direction.bounce(hit_normal).normalized()
		var reflected_end: Vector2 = primary_end + reflected_direction * config.aim_guide_reflection_length
		segments.append(PackedVector2Array([primary_start, primary_end]))
		segments.append(PackedVector2Array([primary_end, reflected_end]))
		return segments
	segments.append(PackedVector2Array([primary_start, primary_end]))
	return segments

func _draw() -> void:
	for preview_ball: PreviewBall in _classic_preview_balls:
		draw_circle(preview_ball.position, _get_ball_radius(preview_ball.definition), preview_ball.definition.visual_color)
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

func _process(delta: float) -> void:
	_process_classic_preview_physics(delta)

func _uses_classic_preview_physics() -> bool:
	return _presentation == Presentation.CLASSIC_BLOCKED or _presentation == Presentation.CLASSIC_OPEN or _presentation == Presentation.CHALLENGE

func _sync_classic_preview_balls() -> void:
	var next_preview_balls: Array[PreviewBall] = []
	for index: int in _waiting_definitions.size():
		var definition: BallDefinition = _waiting_definitions[index]
		var existing: PreviewBall = _find_classic_preview_ball(definition)
		if existing != null:
			next_preview_balls.append(existing)
		else:
			next_preview_balls.append(_create_classic_preview_ball(definition, index))
	_classic_preview_balls = next_preview_balls
	_classic_stack_settle_seconds = 0.0
	if _classic_gate_open and not has_classic_launch_slot_ball():
		for preview_ball: PreviewBall in _classic_preview_balls:
			preview_ball.is_sleeping = false
	if _classic_preview_balls.is_empty():
		_pending_release_batch_id = -1
		set_process(false)
	else:
		set_process(true)
	_update_launch_readiness()
	queue_redraw()

func _find_classic_preview_ball(definition: BallDefinition) -> PreviewBall:
	for preview_ball: PreviewBall in _classic_preview_balls:
		if preview_ball.definition == definition:
			return preview_ball
	return null

func _create_classic_preview_ball(definition: BallDefinition, index: int) -> PreviewBall:
	var entry_position: Vector2 = to_local(config.get_classic_launcher_staging_position())
	var radius: float = _get_ball_radius(definition)
	var lateral_offset: float = float(index % 3 - 1) * radius * 0.42
	var initial_position: Vector2 = entry_position + Vector2(lateral_offset, -float(index % 2) * radius * 0.18)
	var recovery_direction: float = float(_classic_recovery_directions_by_color.get(definition.visual_color, 0.0))
	_classic_recovery_directions_by_color.erase(definition.visual_color)
	var lateral_velocity: float = -recovery_direction * config.launcher_preview_return_inward_speed
	if is_zero_approx(lateral_velocity):
		lateral_velocity = -70.0 if index % 2 == 0 else 70.0
	return PreviewBall.new(definition, initial_position, Vector2(lateral_velocity, -config.launcher_preview_return_toss_speed))

func _process_classic_preview_physics(delta: float) -> void:
	if _classic_preview_balls.is_empty():
		set_process(false)
		return
	for preview_ball: PreviewBall in _classic_preview_balls:
		if preview_ball.is_in_launch_slot or preview_ball.is_sleeping:
			continue
		preview_ball.velocity.y += config.launcher_preview_gravity * delta
		preview_ball.velocity = preview_ball.velocity.move_toward(Vector2.ZERO, config.launcher_preview_velocity_damping * delta)
		preview_ball.position += preview_ball.velocity * delta
		_constrain_classic_preview_ball_to_funnel(preview_ball, delta)
	_resolve_classic_preview_ball_collisions()
	_settle_classic_preview_balls()
	_capture_classic_launch_slot_ball()
	_update_classic_stack_lock(delta)
	_emit_pending_release_if_ready()
	_update_launch_readiness()
	queue_redraw()

func _constrain_classic_preview_ball_to_funnel(preview_ball: PreviewBall, delta: float) -> void:
	var radius: float = _get_ball_radius(preview_ball.definition)
	var maximum_horizontal_offset: float = config.roof_gap_width * 1.8
	preview_ball.position.x = clampf(preview_ball.position.x, -maximum_horizontal_offset, maximum_horizontal_offset)
	var is_opening: bool = _classic_gate_open and not has_classic_launch_slot_ball() and absf(preview_ball.position.x) < radius * 1.15
	if is_opening:
		return
	var support_y: float = _get_classic_funnel_support_y(preview_ball.position.x)
	if preview_ball.position.y + radius <= support_y:
		return
	preview_ball.position.y = support_y - radius
	if preview_ball.velocity.y > 0.0:
		preview_ball.velocity.y *= -config.launcher_preview_restitution
	var slide_direction: float = -signf(preview_ball.position.x)
	if not is_zero_approx(slide_direction):
		preview_ball.velocity.x += slide_direction * config.launcher_preview_gravity * 0.45 * delta
	var floor_friction: float = config.launcher_preview_floor_friction
	if has_classic_launch_slot_ball():
		# 槽位已有球后不再需要长距离补位；提高接触面阻尼以迅速消掉堆叠余震。
		floor_friction = minf(floor_friction, config.launcher_preview_stacked_friction)
	preview_ball.velocity.x *= floor_friction
	if absf(preview_ball.velocity.y) < config.launcher_preview_rest_speed:
		preview_ball.velocity.y = 0.0

func _get_classic_funnel_support_y(local_x: float) -> float:
	# 开口仅供第一颗球穿过；其余球始终由虚线凹槽底部支撑。
	var gate_y: float = -config.ball_radius * 2.1
	return gate_y - absf(local_x) * config.launcher_preview_slope

func _resolve_classic_preview_ball_collisions() -> void:
	for first_index: int in _classic_preview_balls.size():
		for second_index: int in range(first_index + 1, _classic_preview_balls.size()):
			var first_ball: PreviewBall = _classic_preview_balls[first_index]
			var second_ball: PreviewBall = _classic_preview_balls[second_index]
			var minimum_distance: float = (_get_ball_radius(first_ball.definition) + _get_ball_radius(second_ball.definition)) * 0.97
			var offset: Vector2 = second_ball.position - first_ball.position
			var distance: float = offset.length()
			var normal: Vector2 = offset.normalized() if distance > 0.001 else Vector2.RIGHT
			if distance >= minimum_distance:
				continue
			var overlap: float = minimum_distance - distance
			var first_inverse_mass: float = 0.0 if first_ball.is_in_launch_slot else 1.0
			var second_inverse_mass: float = 0.0 if second_ball.is_in_launch_slot else 1.0
			var total_inverse_mass: float = first_inverse_mass + second_inverse_mass
			if is_zero_approx(total_inverse_mass):
				continue
			var correction: Vector2 = normal * overlap / total_inverse_mass
			first_ball.position -= correction * first_inverse_mass
			second_ball.position += correction * second_inverse_mass
			var closing_speed: float = (second_ball.velocity - first_ball.velocity).dot(normal)
			# 静态堆叠仍会因位置修正保持相互接触，但不能把每一帧的
			# 微小接触都当成一次新的碰撞，否则球多时会永远处于抖动状态。
			if closing_speed >= -config.launcher_preview_collision_wake_speed:
				continue
			if not first_ball.is_in_launch_slot:
				first_ball.is_sleeping = false
			if not second_ball.is_in_launch_slot:
				second_ball.is_sleeping = false
			var impulse: float = -closing_speed * (1.0 + config.launcher_preview_restitution) / total_inverse_mass
			first_ball.velocity -= normal * impulse * first_inverse_mass
			second_ball.velocity += normal * impulse * second_inverse_mass

func _settle_classic_preview_balls() -> void:
	for preview_ball: PreviewBall in _classic_preview_balls:
		if preview_ball.is_in_launch_slot or preview_ball.velocity.length() > config.launcher_preview_rest_speed:
			continue
		# 开口空闲时，不能把仍在向槽口滑落的球提前钉死在虚线底部。
		if _classic_gate_open and not has_classic_launch_slot_ball():
			continue
		if _is_classic_preview_ball_supported(preview_ball):
			preview_ball.velocity = Vector2.ZERO
			preview_ball.is_sleeping = true

func _is_classic_preview_ball_supported(preview_ball: PreviewBall) -> bool:
	var radius: float = _get_ball_radius(preview_ball.definition)
	var support_y: float = _get_classic_funnel_support_y(preview_ball.position.x)
	if preview_ball.position.y + radius >= support_y - 1.0:
		return true
	for other_ball: PreviewBall in _classic_preview_balls:
		if other_ball == preview_ball:
			continue
		var offset: Vector2 = preview_ball.position - other_ball.position
		var contact_distance: float = (radius + _get_ball_radius(other_ball.definition)) * 1.02
		if offset.length() <= contact_distance and other_ball.position.y >= preview_ball.position.y - radius * 0.35:
			return true
	return false

func _update_classic_stack_lock(delta: float) -> void:
	if not _classic_gate_open or not has_classic_launch_slot_ball():
		_classic_stack_settle_seconds = 0.0
		return
	_classic_stack_settle_seconds += delta
	if _classic_stack_settle_seconds < config.launcher_preview_stack_lock_delay_seconds:
		return
	# 球口已有待发球后的顶部堆叠只承担展示职责；保留短暂余震后锁定，
	# 防止多球圆形推挤在有限空间内形成长期的能量循环。
	for preview_ball: PreviewBall in _classic_preview_balls:
		if preview_ball.is_in_launch_slot:
			continue
		preview_ball.velocity = Vector2.ZERO
		preview_ball.is_sleeping = true

func _capture_classic_launch_slot_ball() -> void:
	if not _classic_gate_open or has_classic_launch_slot_ball():
		return
	var candidate: PreviewBall = null
	for preview_ball: PreviewBall in _classic_preview_balls:
		var radius: float = _get_ball_radius(preview_ball.definition)
		if absf(preview_ball.position.x) <= radius * 1.15 and preview_ball.position.y >= -radius * 0.45:
			if candidate == null or preview_ball.position.y > candidate.position.y:
				candidate = preview_ball
	if candidate == null:
		return
	candidate.position = Vector2.ZERO
	candidate.velocity = Vector2.ZERO
	candidate.is_in_launch_slot = true
	candidate.is_sleeping = true

func _find_classic_launch_slot_ball() -> PreviewBall:
	for preview_ball: PreviewBall in _classic_preview_balls:
		if preview_ball.is_in_launch_slot:
			return preview_ball
	return null

func _get_current_launch_definition() -> BallDefinition:
	if _uses_classic_preview_physics():
		var slot_ball: PreviewBall = _find_classic_launch_slot_ball()
		if slot_ball != null:
			return slot_ball.definition
	return _waiting_definitions[0] if not _waiting_definitions.is_empty() else null

func _emit_pending_release_if_ready() -> void:
	if _pending_release_batch_id < 0 or not has_classic_launch_slot_ball():
		return
	var batch_id: int = _pending_release_batch_id
	_pending_release_batch_id = -1
	next_ball_release_ready.emit(batch_id, _get_current_launch_definition())

func _update_launch_readiness() -> void:
	if not _launch_ready_requested:
		_is_launch_ready = false
		return
	_is_launch_ready = _presentation != Presentation.CLASSIC_BLOCKED and has_classic_launch_slot_ball()

func _get_ball_radius(definition: BallDefinition) -> float:
	var radius_multiplier: float = 1.0 if definition == null else definition.radius_multiplier
	return config.ball_radius * radius_multiplier
