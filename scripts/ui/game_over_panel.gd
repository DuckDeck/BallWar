extends Control

signal restart_requested()
signal menu_requested()

@export var ui_font: Font
@export var icon_font: Font

const OVERLAY_COLOR: Color = Color(0.015, 0.025, 0.035, 0.78)
const PANEL_COLOR: Color = Color("222b42")
const PANEL_SHADOW_COLOR: Color = Color(0.005, 0.01, 0.02, 0.62)
const HEADER_COLOR: Color = Color("36c9bd")
const TEXT_COLOR: Color = Color("f7fbff")
const MUTED_TEXT_COLOR: Color = Color("b9c5d8")
const STAR_COLOR: Color = Color("35cec0")
const RETURN_COLOR: Color = Color("ff5d63")
const SHARE_COLOR: Color = Color("f2ce3f")
const RESTART_COLOR: Color = Color("65cf73")
const ICON_RETURN: String = "\ue641"
const ICON_SHARE: String = "\ue663"
const ICON_RESTART: String = "\ue689"

var _title_label: Label
var _score_label: Label
var _historical_label: Label
var _historical_value_label: Label
var _daily_label: Label
var _daily_value_label: Label
var _mode_label: Label
var _return_button: Button
var _share_button: Button
var _restart_button: Button
var _return_icon: Label
var _share_icon: Label
var _restart_icon: Label
var _return_caption: Label
var _share_caption: Label
var _restart_caption: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	resized.connect(_layout_contents)
	hide_panel()
	call_deferred("_layout_contents")

func show_results(score: int, records: Dictionary, mode: int) -> void:
	_score_label.text = str(maxi(0, score))
	_historical_value_label.text = str(int(records.get("historical_best", 0)))
	_daily_value_label.text = str(int(records.get("daily_best", 0)))
	_mode_label.text = "经典模式" if mode == GameModeDefinition.Mode.CLASSIC else "挑战模式"
	show()
	_layout_contents()
	queue_redraw()

func hide_panel() -> void:
	hide()

func _build_controls() -> void:
	_title_label = _create_text_label("本局结束", 70, TEXT_COLOR)
	_title_label.name = &"GameOverTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)
	_score_label = _create_text_label("0", 126, TEXT_COLOR)
	_score_label.name = &"ScoreValue"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_score_label)
	_historical_label = _create_text_label("历史最高", 48, TEXT_COLOR)
	_historical_label.name = &"HistoricalLabel"
	add_child(_historical_label)
	_historical_value_label = _create_text_label("0", 48, TEXT_COLOR)
	_historical_value_label.name = &"HistoricalValue"
	_historical_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_historical_value_label)
	_daily_label = _create_text_label("今日最佳", 48, TEXT_COLOR)
	_daily_label.name = &"DailyLabel"
	add_child(_daily_label)
	_daily_value_label = _create_text_label("0", 48, TEXT_COLOR)
	_daily_value_label.name = &"DailyValue"
	_daily_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_daily_value_label)
	_mode_label = _create_text_label("经典模式", 30, MUTED_TEXT_COLOR)
	_mode_label.name = &"ModeLabel"
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_mode_label)
	_return_button = _create_action_button("ReturnButton", RETURN_COLOR, menu_requested.emit)
	_share_button = _create_action_button("ShareButton", SHARE_COLOR, Callable())
	_share_button.disabled = true
	_restart_button = _create_action_button("RestartButton", RESTART_COLOR, restart_requested.emit)
	_return_icon = _create_icon_label(ICON_RETURN)
	_share_icon = _create_icon_label(ICON_SHARE)
	_restart_icon = _create_icon_label(ICON_RESTART)
	_return_caption = _create_text_label("返回", 38, TEXT_COLOR)
	_share_caption = _create_text_label("炫耀", 38, TEXT_COLOR)
	_restart_caption = _create_text_label("重新开始", 38, TEXT_COLOR)
	_return_caption.name = &"ReturnCaption"
	_share_caption.name = &"ShareCaption"
	_restart_caption.name = &"RestartCaption"
	_add_action_content(_return_button, _return_icon, _return_caption)
	_add_action_content(_share_button, _share_icon, _share_caption)
	_add_action_content(_restart_button, _restart_icon, _restart_caption)

func _create_text_label(text_value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", font_size)
	if ui_font != null:
		label.add_theme_font_override(&"font", ui_font)
	return label

func _create_action_button(node_name: String, color: Color, action: Callable) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override(&"normal", _create_circle_style(color))
	button.add_theme_stylebox_override(&"hover", _create_circle_style(color.lightened(0.10)))
	button.add_theme_stylebox_override(&"pressed", _create_circle_style(color.darkened(0.12)))
	button.add_theme_stylebox_override(&"disabled", _create_circle_style(color))
	if action.is_valid():
		button.pressed.connect(action)
	add_child(button)
	return button

func _create_circle_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.shadow_color = Color(0.005, 0.01, 0.02, 0.52)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 10.0)
	return style

func _create_icon_label(glyph: String) -> Label:
	var label: Label = Label.new()
	label.text = glyph if icon_font != null else "•"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", TEXT_COLOR)
	label.add_theme_font_size_override(&"font_size", 64)
	if icon_font != null:
		label.add_theme_font_override(&"font", icon_font)
	elif ui_font != null:
		label.add_theme_font_override(&"font", ui_font)
	return label

func _add_action_content(button: Button, icon: Label, caption: Label) -> void:
	button.add_child(icon)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(caption)

func _layout_contents() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var panel_width: float = size.x * 0.80
	var panel_left: float = (size.x - panel_width) * 0.5
	var header_height: float = size.y * 0.105
	var header_top: float = size.y * 0.235
	var body_top: float = header_top + header_height * 0.72
	var body_height: float = size.y * 0.57
	_title_label.position = Vector2(panel_left, header_top)
	_title_label.size = Vector2(panel_width, header_height)
	_score_label.position = Vector2(panel_left, body_top + body_height * 0.08)
	_score_label.size = Vector2(panel_width, body_height * 0.18)
	_mode_label.position = Vector2(panel_left, body_top + body_height * 0.255)
	_mode_label.size = Vector2(panel_width, body_height * 0.07)
	var record_left: float = panel_left + panel_width * 0.24
	var record_width: float = panel_width * 0.52
	var records_top: float = body_top + body_height * 0.36
	_historical_label.position = Vector2(record_left, records_top)
	_historical_label.size = Vector2(record_width, body_height * 0.09)
	_historical_value_label.position = Vector2(record_left, records_top)
	_historical_value_label.size = Vector2(record_width, body_height * 0.09)
	_daily_label.position = Vector2(record_left, records_top + body_height * 0.095)
	_daily_label.size = Vector2(record_width, body_height * 0.09)
	_daily_value_label.position = Vector2(record_left, records_top + body_height * 0.095)
	_daily_value_label.size = Vector2(record_width, body_height * 0.09)
	var action_size: float = minf(panel_width * 0.19, body_height * 0.23)
	var actions_top: float = body_top + body_height * 0.69
	_layout_action(_return_button, _return_icon, _return_caption, panel_left + panel_width * 0.08, actions_top, action_size)
	_layout_action(_share_button, _share_icon, _share_caption, size.x * 0.5 - action_size * 0.5, actions_top, action_size)
	_layout_action(_restart_button, _restart_icon, _restart_caption, panel_left + panel_width * 0.73, actions_top, action_size)
	queue_redraw()

func _layout_action(button: Button, icon: Label, caption: Label, x: float, y: float, action_size: float) -> void:
	button.position = Vector2(x, y)
	button.size = Vector2(action_size, action_size)
	icon.position = Vector2(0.0, action_size * -0.02)
	icon.size = Vector2(action_size, action_size * 1.02)
	caption.position = Vector2(x - action_size * 0.45, y + action_size * 1.10)
	caption.size = Vector2(action_size * 1.90, action_size * 0.42)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OVERLAY_COLOR)
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var panel_width: float = size.x * 0.80
	var panel_left: float = (size.x - panel_width) * 0.5
	var header_height: float = size.y * 0.105
	var header_top: float = size.y * 0.235
	var body_top: float = header_top + header_height * 0.72
	var body_height: float = size.y * 0.57
	var body_rect: Rect2 = Rect2(panel_left, body_top, panel_width, body_height)
	draw_style_box(_create_panel_style(PANEL_SHADOW_COLOR), body_rect.grow(14.0))
	draw_style_box(_create_panel_style(PANEL_COLOR), body_rect)
	draw_style_box(_create_header_style(), Rect2(panel_left, header_top, panel_width, header_height))
	_draw_star(Vector2(panel_left + panel_width * 0.10, body_top + body_height * 0.14), 36.0, 16.0)
	_draw_star(Vector2(panel_left + panel_width * 0.19, body_top + body_height * 0.11), 20.0, 9.0)
	_draw_star(Vector2(panel_left + panel_width * 0.82, body_top + body_height * 0.13), 38.0, 17.0)
	_draw_star(Vector2(panel_left + panel_width * 0.90, body_top + body_height * 0.23), 20.0, 9.0)

func _create_panel_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 48
	style.corner_radius_top_right = 48
	style.corner_radius_bottom_left = 48
	style.corner_radius_bottom_right = 48
	return style

func _create_header_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = HEADER_COLOR
	style.corner_radius_top_left = 48
	style.corner_radius_top_right = 48
	style.corner_radius_bottom_left = 42
	style.corner_radius_bottom_right = 42
	return style

func _draw_star(center: Vector2, outer_radius: float, inner_radius: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index: int in 10:
		var radius: float = outer_radius if point_index % 2 == 0 else inner_radius
		var angle: float = -PI * 0.5 + point_index * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, STAR_COLOR)
