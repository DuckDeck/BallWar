extends Button

const BACKGROUND_COLOR: Color = Color("243047")
const BORDER_COLOR: Color = Color(0.72, 0.82, 0.9, 0.28)
const SHADOW_COLOR: Color = Color(0.01, 0.02, 0.04, 0.48)
const ICON_COLOR: Color = Color("f4fbff")

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	tooltip_text = "暂停"
	queue_redraw()

func _draw() -> void:
	var radius: float = minf(size.x, size.y) * 0.45
	var center: Vector2 = size * 0.5
	draw_circle(center + Vector2(0.0, 4.0), radius, SHADOW_COLOR)
	draw_circle(center, radius, BACKGROUND_COLOR)
	draw_arc(center, radius, 0.0, TAU, 32, BORDER_COLOR, 2.0, true)
	var bar_width: float = radius * 0.24
	var bar_height: float = radius * 0.88
	var gap: float = radius * 0.26
	var bar_top: float = center.y - bar_height * 0.5
	draw_rect(Rect2(center.x - gap * 0.5 - bar_width, bar_top, bar_width, bar_height), ICON_COLOR, true)
	draw_rect(Rect2(center.x + gap * 0.5, bar_top, bar_width, bar_height), ICON_COLOR, true)
