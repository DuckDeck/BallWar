class_name Obstacle
extends StaticBody2D

signal damaged(remaining_health: int)
signal destroyed(points: int)

@export var config: GameConfig

var board_cell: Vector2i = Vector2i(-1, -1)
var obstacle_id: int = -1
var _health: int = 0
var _points: int = 0
var _is_destroyed: bool = false

func _ready() -> void:
	assert(config != null, "Obstacle requires a GameConfig resource.")
	if _health == 0:
		configure(config.initial_obstacle_health, config.score_per_obstacle)

func configure(initial_health: int, points: int) -> void:
	_health = max(1, initial_health)
	_points = points
	_is_destroyed = false
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

func _draw() -> void:
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-54.0, -30.0), Vector2(0.0, -60.0), Vector2(54.0, -30.0),
		Vector2(54.0, 30.0), Vector2(0.0, 60.0), Vector2(-54.0, 30.0)
	])
	draw_colored_polygon(points, Color("2ee9e3"))
	var font: Font = ThemeDB.fallback_font
	var health_text: String = str(_health)
	var font_size: int = 42
	var text_size: Vector2 = font.get_string_size(health_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, text_size.y * 0.35), health_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color("09252b"))
