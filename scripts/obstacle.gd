class_name Obstacle
extends StaticBody2D

signal damaged(remaining_health: int)
signal destroyed(points: int)

enum Shape {
	HEXAGON,
	PENTAGON,
	SQUARE,
	TRIANGLE,
	CIRCLE,
	DIAMOND,
}

const SHAPE_RADIUS: float = 50.0
const SQUARE_HALF_EXTENT: float = 35.0

@export var config: GameConfig

var board_cell: Vector2i = Vector2i(-1, -1)
var obstacle_id: int = -1
var shape_type: int = Shape.HEXAGON
var _health: int = 0
var _points: int = 0
var _is_destroyed: bool = false

func _ready() -> void:
	assert(config != null, "Obstacle requires a GameConfig resource.")
	if _health == 0:
		configure(config.initial_obstacle_health, config.score_per_obstacle)

func configure(initial_health: int, points: int, next_shape_type: int = Shape.HEXAGON, next_rotation_degrees: float = 0.0) -> void:
	_health = max(1, initial_health)
	_points = points
	_is_destroyed = false
	shape_type = clampi(next_shape_type, Shape.HEXAGON, Shape.DIAMOND)
	rotation_degrees = fposmod(next_rotation_degrees, 360.0)
	_sync_collision_shape()
	queue_redraw()

func receive_hit(context: HitContext) -> HitResult:
	var result: HitResult = HitResult.new()
	result.bounce_multiplier = config.obstacle_bounce_restitution
	if _is_destroyed:
		return result
	var applied_damage: int = max(0, context.damage)
	if applied_damage == 0:
		return result
	_health -= applied_damage
	result.was_applied = true
	damaged.emit(maxi(_health, 0))
	if _health <= 0:
		_is_destroyed = true
		result.was_destroyed = true
		result.points_awarded = _points
		destroyed.emit(_points)
		queue_free()
	else:
		queue_redraw()
	return result

func _sync_collision_shape() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return
	if shape_type == Shape.CIRCLE:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = SHAPE_RADIUS
		collision_shape.shape = circle
		return
	var polygon: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	polygon.points = _get_polygon_points()
	collision_shape.shape = polygon

func _get_polygon_points() -> PackedVector2Array:
	match shape_type:
		Shape.HEXAGON:
			return _get_regular_polygon_points(6, 0.0)
		Shape.PENTAGON:
			return _get_regular_polygon_points(5, -PI * 0.5)
		Shape.SQUARE:
			return PackedVector2Array([
				Vector2(-SQUARE_HALF_EXTENT, -SQUARE_HALF_EXTENT), Vector2(SQUARE_HALF_EXTENT, -SQUARE_HALF_EXTENT),
				Vector2(SQUARE_HALF_EXTENT, SQUARE_HALF_EXTENT), Vector2(-SQUARE_HALF_EXTENT, SQUARE_HALF_EXTENT),
			])
		Shape.TRIANGLE:
			return _get_regular_polygon_points(3, -PI * 0.5)
		Shape.DIAMOND:
			return PackedVector2Array([
				Vector2(0.0, -SHAPE_RADIUS), Vector2(SHAPE_RADIUS, 0.0),
				Vector2(0.0, SHAPE_RADIUS), Vector2(-SHAPE_RADIUS, 0.0),
			])
		_:
			return PackedVector2Array()

func _get_regular_polygon_points(side_count: int, start_angle: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for side_index: int in side_count:
		var angle: float = start_angle + TAU * float(side_index) / float(side_count)
		points.append(Vector2(cos(angle), sin(angle)) * SHAPE_RADIUS)
	return points

func _draw() -> void:
	if shape_type == Shape.CIRCLE:
		draw_circle(Vector2.ZERO, SHAPE_RADIUS, Color("2ee9e3"))
	else:
		draw_colored_polygon(_get_polygon_points(), Color("2ee9e3"))
	var font: Font = ThemeDB.fallback_font
	var health_text: String = str(_health)
	var font_size: int = 42
	var text_size: Vector2 = font.get_string_size(health_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	# 形状随障碍旋转，数字保持正向，确保高转角时仍可快速读数。
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_string(font, Vector2(-text_size.x * 0.5, text_size.y * 0.35), health_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color("09252b"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
