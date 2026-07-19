class_name Ball
extends CharacterBody2D

signal recovered(reason: StringName)

@export var config: GameConfig
@export var definition: BallDefinition

enum MotionState {
	ACTIVE,
	TIMEOUT_DESCENT,
	ROLLING,
	LIFTING,
	ROOF_RETURN,
}

var runtime_state: BallRuntimeState = BallRuntimeState.new()
var _is_active: bool = false
var _board_shift_offset: Vector2 = Vector2.ZERO
var _board_shift_duration_seconds: float = 0.0
var _board_shift_elapsed_seconds: float = 0.0
var _motion_state: int = MotionState.ACTIVE
var _recovery_direction: float = 1.0
var _pending_recovery_reason: StringName = &"bottom_trough"
var _roof_return_targets: Array[Vector2] = []
var _roof_return_target_index: int = 0
var _trail: Line2D
var _trail_points: Array[Vector2] = []
var _trail_ages: Array[float] = []
var _hit_sequence: int = 0
var _hit_resolver: HitResolver = HitResolver.new()

func _ready() -> void:
	assert(config != null, "Ball requires a GameConfig resource.")
	if definition == null:
		definition = BallDefinition.new()
	if runtime_state == null:
		runtime_state = BallRuntimeState.new()
	_sync_collision_radius()
	_setup_trail()
	queue_redraw()

func launch(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0:
		return
	velocity = direction.normalized() * config.ball_speed
	runtime_state.velocity = velocity
	runtime_state.is_gravity_enabled = false
	_is_active = true
	_motion_state = MotionState.ACTIVE

func force_recover(reason: StringName) -> void:
	_recover(reason)

func freeze_for_game_over() -> void:
	if runtime_state.is_recovered:
		return
	_is_active = false
	velocity = Vector2.ZERO
	runtime_state.velocity = Vector2.ZERO
	_clear_trail()

func begin_board_shift(offset: Vector2, duration_seconds: float) -> void:
	if not _is_active or runtime_state.is_recovered:
		return
	_board_shift_offset = offset
	_board_shift_duration_seconds = maxf(duration_seconds, 0.001)
	_board_shift_elapsed_seconds = 0.0

func _physics_process(delta: float) -> void:
	if not _is_active or runtime_state.is_recovered:
		return
	_apply_board_shift(delta)
	match _motion_state:
		MotionState.ACTIVE:
			_process_active_motion(delta)
		MotionState.TIMEOUT_DESCENT:
			_process_timeout_descent(delta)
		MotionState.ROLLING:
			_process_bottom_roll(delta)
		MotionState.LIFTING:
			_process_side_lift(delta)
		MotionState.ROOF_RETURN:
			_process_roof_return(delta)
	runtime_state.velocity = velocity

func _apply_board_shift(delta: float) -> void:
	if _board_shift_elapsed_seconds >= _board_shift_duration_seconds:
		return
	var previous_progress: float = _board_shift_elapsed_seconds / _board_shift_duration_seconds
	_board_shift_elapsed_seconds = minf(_board_shift_elapsed_seconds + delta, _board_shift_duration_seconds)
	var current_progress: float = _board_shift_elapsed_seconds / _board_shift_duration_seconds
	# 与棋盘 Tween 的 QUAD / EASE_OUT 相同：1 - (1 - t)^2。
	var previous_eased: float = 1.0 - pow(1.0 - previous_progress, 2.0)
	var current_eased: float = 1.0 - pow(1.0 - current_progress, 2.0)
	var frame_offset: Vector2 = _board_shift_offset * (current_eased - previous_eased)
	global_position += frame_offset
	_translate_trail(frame_offset)

func _translate_trail(offset: Vector2) -> void:
	if offset.is_zero_approx():
		return
	for index: int in _trail_points.size():
		_trail_points[index] += offset

func get_motion_state() -> int:
	return _motion_state

func has_recovered() -> bool:
	return runtime_state.is_recovered

func get_recovery_reason() -> StringName:
	return runtime_state.recovery_reason

func get_visual_color() -> Color:
	return definition.visual_color

func _process_active_motion(delta: float) -> void:
	runtime_state.elapsed_seconds += delta
	if runtime_state.is_gravity_enabled:
		velocity.y += config.ball_gravity * definition.gravity_multiplier * delta
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		# 首次命中墙或障碍前保持瞄准方向；命中后才进入受重力轨迹。
		runtime_state.is_gravity_enabled = true
		var hit_result: HitResult = _resolve_collision(collision)
		if hit_result.should_bounce:
			# Cap every rebound to prevent repeated obstacle multipliers from compounding.
			var bounced_velocity: Vector2 = velocity.bounce(collision.get_normal()) * hit_result.bounce_multiplier
			velocity = bounced_velocity.limit_length(config.ball_max_rebound_speed)
	if _has_reached_bottom_trough():
		_begin_bottom_recovery()
		return
	_update_trail(delta)
	if runtime_state.elapsed_seconds >= config.ball_max_lifetime:
		_begin_lifetime_recovery()
	elif global_position.y >= config.recovery_y:
		_begin_bottom_recovery(&"bottom_exit")

func _begin_lifetime_recovery() -> void:
	if _motion_state != MotionState.ACTIVE:
		return
	_pending_recovery_reason = &"lifetime_expired"
	velocity = Vector2.ZERO
	_motion_state = MotionState.TIMEOUT_DESCENT
	_clear_trail()

func _process_timeout_descent(delta: float) -> void:
	var target_x: float = clampf(global_position.x, config.arena_left, config.arena_right)
	var target: Vector2 = Vector2(target_x, config.get_bottom_trough_y(target_x) - _get_radius())
	global_position = global_position.move_toward(target, config.recovery_timeout_descent_speed * delta)
	if global_position.distance_to(target) <= 0.1:
		global_position = target
		_enter_bottom_recovery()

func _resolve_collision(collision: KinematicCollision2D) -> HitResult:
	var collider: Node = collision.get_collider() as Node
	var default_result: HitResult = HitResult.new()
	if collider == null or not collider.has_method(&"receive_hit"):
		return default_result
	var context: HitContext = HitContext.new()
	context.source_ball = self
	context.damage = definition.damage
	context.hit_position = collision.get_position()
	context.hit_normal = collision.get_normal()
	context.incoming_velocity = velocity
	context.hit_id = _hit_sequence
	_hit_sequence += 1
	return _hit_resolver.resolve(collider, context, definition.effects)

func _has_reached_bottom_trough() -> bool:
	if velocity.y <= 0.0:
		return false
	var trough_y: float = config.get_bottom_trough_y(global_position.x)
	return global_position.y + _get_radius() >= trough_y

func _begin_bottom_recovery(reason: StringName = &"bottom_trough") -> void:
	if _motion_state != MotionState.ACTIVE:
		return
	_pending_recovery_reason = reason
	_enter_bottom_recovery()

func _enter_bottom_recovery() -> void:
	var center_x: float = (config.arena_left + config.arena_right) * 0.5
	if is_equal_approx(global_position.x, center_x):
		_recovery_direction = signf(velocity.x)
		if is_zero_approx(_recovery_direction):
			_recovery_direction = 1.0
	else:
		_recovery_direction = -1.0 if global_position.x < center_x else 1.0
	global_position.y = config.get_bottom_trough_y(global_position.x) - _get_radius()
	velocity = Vector2.ZERO
	_motion_state = MotionState.ROLLING
	_clear_trail()

func _process_bottom_roll(delta: float) -> void:
	var radius: float = _get_radius()
	var left_exit_x: float = config.arena_left - radius
	var right_exit_x: float = config.arena_right + radius
	var next_x: float = global_position.x + _recovery_direction * config.recovery_roll_speed * delta
	if _recovery_direction < 0.0:
		next_x = maxf(next_x, left_exit_x)
	else:
		next_x = minf(next_x, right_exit_x)
	var trough_x: float = clampf(next_x, config.arena_left, config.arena_right)
	global_position = Vector2(next_x, config.get_bottom_trough_y(trough_x) - radius)
	if is_equal_approx(next_x, left_exit_x) or is_equal_approx(next_x, right_exit_x):
		_motion_state = MotionState.LIFTING

func _process_side_lift(delta: float) -> void:
	var side_x: float = config.arena_left - _get_radius() if _recovery_direction < 0.0 else config.arena_right + _get_radius()
	var target: Vector2 = Vector2(side_x, config.arena_top)
	global_position = global_position.move_toward(target, config.recovery_lift_speed * delta)
	if global_position.distance_to(target) <= 0.1:
		global_position = target
		_build_roof_return_path()
		_motion_state = MotionState.ROOF_RETURN

func _build_roof_return_path() -> void:
	var gap_center_x: float = config.design_size.x * 0.5
	var side_top_x: float = config.arena_left if _recovery_direction < 0.0 else config.arena_right
	var roof_apex_x: float = gap_center_x - config.roof_gap_width * 0.5 if _recovery_direction < 0.0 else gap_center_x + config.roof_gap_width * 0.5
	_roof_return_targets = [
		Vector2(side_top_x, config.arena_top),
		Vector2(roof_apex_x, config.roof_apex_y),
		config.launcher_position,
	]
	_roof_return_target_index = 0

func _process_roof_return(delta: float) -> void:
	if _roof_return_target_index >= _roof_return_targets.size():
		_recover(_pending_recovery_reason)
		return
	var target: Vector2 = _roof_return_targets[_roof_return_target_index]
	global_position = global_position.move_toward(target, config.recovery_roof_speed * delta)
	if global_position.distance_to(target) <= 0.1:
		global_position = target
		_roof_return_target_index += 1
		if _roof_return_target_index >= _roof_return_targets.size():
			_recover(_pending_recovery_reason)

func _recover(reason: StringName) -> void:
	if runtime_state.is_recovered:
		return
	runtime_state.is_recovered = true
	runtime_state.recovery_reason = reason
	_is_active = false
	_clear_trail()
	recovered.emit(reason)

func _get_radius() -> float:
	return config.ball_radius

func _sync_collision_radius() -> void:
	var collision_shape: CollisionShape2D = get_node("CollisionShape2D") as CollisionShape2D
	var circle: CircleShape2D = collision_shape.shape as CircleShape2D
	circle.radius = _get_radius()

func _setup_trail() -> void:
	_trail = Line2D.new()
	_trail.name = "MotionTrail"
	_trail.show_behind_parent = true
	_trail.top_level = true
	_trail.width = _get_radius() * config.ball_trail_width_multiplier
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var color: Color = get_visual_color()
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	gradient.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 0.0),
		Color(color.r, color.g, color.b, 0.36),
		Color(color.r, color.g, color.b, 0.92),
	])
	_trail.gradient = gradient
	var width_curve: Curve = Curve.new()
	width_curve.add_point(Vector2(0.0, 0.0))
	width_curve.add_point(Vector2(0.65, 0.58))
	width_curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = width_curve
	add_child(_trail)

func _update_trail(delta: float) -> void:
	for index: int in _trail_ages.size():
		_trail_ages[index] += delta
	while not _trail_ages.is_empty() and _trail_ages[0] > config.ball_trail_duration:
		_trail_ages.remove_at(0)
		_trail_points.remove_at(0)
	var minimum_spacing: float = _get_radius() * 0.25
	if _trail_points.is_empty() or _trail_points.back().distance_to(global_position) >= minimum_spacing:
		_trail_points.append(global_position)
		_trail_ages.append(0.0)
	_trail.clear_points()
	for point: Vector2 in _trail_points:
		_trail.add_point(point)

func _clear_trail() -> void:
	_trail_points.clear()
	_trail_ages.clear()
	if is_instance_valid(_trail):
		_trail.clear_points()

func _draw() -> void:
	var color: Color = get_visual_color()
	var radius: float = _get_radius()
	draw_circle(Vector2.ZERO, radius, color)
