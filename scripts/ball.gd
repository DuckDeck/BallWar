class_name Ball
extends CharacterBody2D

signal recovered(reason: StringName)

@export var config: GameConfig

const BALL_COLOR: Color = Color("d9ff3f")

var _elapsed: float = 0.0
var _is_active: bool = false
var _is_recovered: bool = false
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

func _physics_process(delta: float) -> void:
	if not _is_active or _is_recovered:
		return
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
	_update_trail(delta)
	if global_position.y >= config.recovery_y:
		_recover(&"bottom_exit")
	elif _elapsed >= config.ball_max_lifetime:
		_recover(&"lifetime_expired")

func _recover(reason: StringName) -> void:
	if _is_recovered:
		return
	_is_recovered = true
	_is_active = false
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

func _draw() -> void:
	draw_circle(Vector2.ZERO, config.ball_radius, BALL_COLOR)
	draw_arc(Vector2.ZERO, config.ball_radius + 3.0, 0.0, TAU, 24, Color("f7ffb2"), 2.0)
