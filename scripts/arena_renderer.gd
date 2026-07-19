class_name ArenaRenderer
extends Node2D

@export var config: GameConfig

const BACKGROUND_COLOR: Color = Color("10171d")
const FRAME_COLOR: Color = Color("9ba5a6")
const DIVIDER_COLOR: Color = Color("d4dfdf")

func _ready() -> void:
	assert(config != null, "ArenaRenderer requires a GameConfig resource.")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, config.design_size), BACKGROUND_COLOR)
	_draw_dot_pattern()
	var left_top: Vector2 = Vector2(config.arena_left, config.arena_top)
	var gap_center_x: float = config.design_size.x * 0.5
	var left_roof_end: Vector2 = Vector2(gap_center_x - config.roof_gap_width * 0.5, config.roof_apex_y)
	var right_roof_start: Vector2 = Vector2(gap_center_x + config.roof_gap_width * 0.5, config.roof_apex_y)
	var left_roof_drop: Vector2 = left_roof_end + Vector2.DOWN * config.roof_gap_drop
	var right_roof_drop: Vector2 = right_roof_start + Vector2.DOWN * config.roof_gap_drop
	var right_top: Vector2 = Vector2(config.arena_right, config.arena_top)
	draw_line(left_top, left_roof_end, FRAME_COLOR, 10.0, true)
	draw_line(left_roof_end, left_roof_drop, FRAME_COLOR, 10.0, true)
	draw_line(right_roof_start, right_roof_drop, FRAME_COLOR, 10.0, true)
	draw_line(right_roof_start, right_top, FRAME_COLOR, 10.0, true)
	draw_line(left_top, Vector2(config.arena_left, config.arena_bottom), FRAME_COLOR, 10.0, true)
	draw_line(right_top, Vector2(config.arena_right, config.arena_bottom), FRAME_COLOR, 10.0, true)
	draw_dashed_line(Vector2(96.0, left_roof_drop.y), left_roof_drop, DIVIDER_COLOR, 5.0, 16.0)
	draw_dashed_line(right_roof_drop, Vector2(984.0, right_roof_drop.y), DIVIDER_COLOR, 5.0, 16.0)
	_draw_bottom_trough()

func _draw_bottom_trough() -> void:
	var points := PackedVector2Array()
	const SAMPLE_COUNT: int = 40
	for sample_index: int in SAMPLE_COUNT + 1:
		var progress: float = float(sample_index) / float(SAMPLE_COUNT)
		var x: float = lerpf(config.arena_left, config.arena_right, progress)
		points.append(Vector2(x, config.get_bottom_trough_y(x)))
	draw_polyline(points, FRAME_COLOR, 8.0, true)

func _draw_dot_pattern() -> void:
	var dot_color: Color = Color(0.18, 0.23, 0.27, 0.55)
	var row: int = 0
	while row < 76:
		var column: int = 0
		while column < 38:
			var x_offset: float = 18.0 if row % 2 == 0 else 30.0
			draw_circle(Vector2(x_offset + column * 30.0, 24.0 + row * 25.0), 2.0, dot_color)
			column += 1
		row += 1
