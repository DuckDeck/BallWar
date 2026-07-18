class_name Obstacle
extends StaticBody2D

signal damaged(remaining_health: int)
signal destroyed(points: int)

@export var config: GameConfig

var _health: int = 0
var _is_destroyed: bool = false

func _ready() -> void:
	assert(config != null, "Obstacle requires a GameConfig resource.")
	if _health == 0:
		configure(config.initial_obstacle_health)

func configure(initial_health: int) -> void:
	_health = max(1, initial_health)
	_is_destroyed = false
	queue_redraw()

func take_hit() -> void:
	if _is_destroyed:
		return
	_health -= 1
	damaged.emit(_health)
	if _health <= 0:
		_is_destroyed = true
		destroyed.emit(config.score_per_obstacle)
		queue_free()
	else:
		queue_redraw()

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
