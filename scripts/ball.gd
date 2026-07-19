class_name Ball
extends CharacterBody2D

signal recovered(reason: StringName)

@export var config: GameConfig

const BALL_COLOR: Color = Color("d9ff3f")

enum MotionState {
	ACTIVE,
	ROLLING,
	LIFTING,
	ROOF_RETURN,
}

var _elapsed: float = 0.0
var _is_active: bool = false
var _is_recovered: bool = false
var _recovery_reason: StringName = &""
var _motion_state: int = MotionState.ACTIVE
var _recovery_direction: float = 1.0
var _roof_return_targets: Array[Vector2] = []
var _roof_return_target_index: int = 0
var _trail: Line2D
var _trail_points: Array[Vector2] = []
var _trail_ages: Array[float] = []

func _ready() -> void:
	assert(config != null, "Ball requires a GameConfig resource.")
	_setup_trail()
	queue_redraw()

func launch(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0:
		return
	velocity = direction.normalized() * config.ball_speed
	_is_active = true
	_motion_state = MotionState.ACTIVE

func _physics_process(delta: float) -> void:
	if not _is_active or _is_recovered:
		return
	match _motion_state:
		MotionState.ACTIVE:
			_process_active_motion(delta)
		MotionState.ROLLING:
			_process_bottom_roll(delta)
		MotionState.LIFTING:
			_process_side_lift(delta)
		MotionState.ROOF_RETURN:
			_process_roof_return(delta)

func get_motion_state() -> int:
	return _motion_state

func has_recovered() -> bool:
	return _is_recovered

func get_recovery_reason() -> StringName:
	return _recovery_reason

func _process_active_motion(delta: float) -> void:
	_elapsed += delta
	velocity.y += config.ball_gravity * delta
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision != null:
		var normal: Vector2 = collision.get_normal()
		velocity = velocity.bounce(normal)
		var collider: Node = collision.get_collider() as Node
		if collider is Obstacle:
			# 障碍物使用较低回弹系数，避免六边形块把球弹得过猛；墙体仍保持完整反弹。
			velocity *= config.obstacle_bounce_restitution
			collider.take_hit()
	if _has_reached_bottom_trough():
		_begin_bottom_recovery()
		return
	_update_trail(delta)
	if _elapsed >= config.ball_max_lifetime:
		_recover(&"lifetime_expired")
	elif global_position.y >= config.recovery_y:
		_recover(&"bottom_exit")

func _has_reached_bottom_trough() -> bool:
	if velocity.y <= 0.0:
		return false
	var trough_y: float = config.get_bottom_trough_y(global_position.x)
	return global_position.y + config.ball_radius >= trough_y

func _begin_bottom_recovery() -> void:
	var center_x: float = (config.arena_left + config.arena_right) * 0.5
	if is_equal_approx(global_position.x, center_x):
		_recovery_direction = signf(velocity.x)
		if is_zero_approx(_recovery_direction):
			_recovery_direction = 1.0
	else:
		_recovery_direction = -1.0 if global_position.x < center_x else 1.0
	global_position.y = config.get_bottom_trough_y(global_position.x) - config.ball_radius
	velocity = Vector2.ZERO
	_motion_state = MotionState.ROLLING
	_clear_trail()

func _process_bottom_roll(delta: float) -> void:
	var left_exit_x: float = config.arena_left - config.ball_radius
	var right_exit_x: float = config.arena_right + config.ball_radius
	var next_x: float = global_position.x + _recovery_direction * config.recovery_roll_speed * delta
	if _recovery_direction < 0.0:
		next_x = maxf(next_x, left_exit_x)
	else:
		next_x = minf(next_x, right_exit_x)
	var trough_x: float = clampf(next_x, config.arena_left, config.arena_right)
	global_position = Vector2(next_x, config.get_bottom_trough_y(trough_x) - config.ball_radius)
	if is_equal_approx(next_x, left_exit_x) or is_equal_approx(next_x, right_exit_x):
		_motion_state = MotionState.LIFTING

func _process_side_lift(delta: float) -> void:
	var side_x: float = config.arena_left - config.ball_radius if _recovery_direction < 0.0 else config.arena_right + config.ball_radius
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
		_recover(&"bottom_trough")
		return
	var target: Vector2 = _roof_return_targets[_roof_return_target_index]
	global_position = global_position.move_toward(target, config.recovery_roof_speed * delta)
	if global_position.distance_to(target) <= 0.1:
		global_position = target
		_roof_return_target_index += 1
		if _roof_return_target_index >= _roof_return_targets.size():
			_recover(&"bottom_trough")

func _recover(reason: StringName) -> void:
	if _is_recovered:
		return
	_is_recovered = true
	_is_active = false
	_recovery_reason = reason
	_clear_trail()
	recovered.emit(reason)

func _setup_trail() -> void:
	_trail = Line2D.new()
	_trail.name = "MotionTrail"
	_trail.show_behind_parent = true
	_trail.top_level = true
	_trail.width = config.ball_radius * config.ball_trail_width_multiplier
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND

	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	gradient.colors = PackedColorArray([
		Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.0),
		Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.36),
		Color(BALL_COLOR.r, BALL_COLOR.g, BALL_COLOR.b, 0.92),
	])
	_trail.gradient = gradient

	var width_curve := Curve.new()
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

	var minimum_spacing: float = config.ball_radius * 0.25
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
	draw_circle(Vector2.ZERO, config.ball_radius, BALL_COLOR)
	draw_arc(Vector2.ZERO, config.ball_radius + 3.0, 0.0, TAU, 24, Color("f7ffb2"), 2.0)
