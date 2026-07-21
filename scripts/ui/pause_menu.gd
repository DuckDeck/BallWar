extends Control

signal resume_requested()
signal restart_requested()

@export var ui_font: Font

const OVERLAY_COLOR: Color = Color(0.015, 0.025, 0.035, 0.74)
const PANEL_COLOR: Color = Color("20283d")
const PANEL_SHADOW_COLOR: Color = Color(0.01, 0.015, 0.03, 0.55)
const ACCENT_COLOR: Color = Color("29c9bd")
const ACCENT_HOVER_COLOR: Color = Color("42d8ca")
const DISABLED_BUTTON_COLOR: Color = Color("246b70")
const TEXT_COLOR: Color = Color("f4fbff")
const DISABLED_TEXT_COLOR: Color = Color(0.85, 0.94, 0.95, 0.52)

var _title_label: Label
var _close_button: Button
var _resume_button: Button
var _restart_button: Button
var _save_exit_button: Button
var _header_style: StyleBoxFlat
var _panel_style: StyleBoxFlat
var _button_style: StyleBoxFlat
var _button_hover_style: StyleBoxFlat
var _button_pressed_style: StyleBoxFlat
var _button_disabled_style: StyleBoxFlat

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_header_style = _create_style(ACCENT_COLOR, 44)
	_panel_style = _create_style(PANEL_COLOR, 48)
	_button_style = _create_style(ACCENT_COLOR, 42)
	_button_hover_style = _create_style(ACCENT_HOVER_COLOR, 42)
	_button_pressed_style = _create_style(ACCENT_COLOR.darkened(0.12), 42)
	_button_disabled_style = _create_style(DISABLED_BUTTON_COLOR, 42)
	_build_controls()
	resized.connect(_layout_contents)
	hide_menu()
	call_deferred("_layout_contents")

func show_menu() -> void:
	show()
	_layout_contents()
	queue_redraw()

func hide_menu() -> void:
	hide()

func _build_controls() -> void:
	_title_label = Label.new()
	_title_label.name = &"PauseTitle"
	_title_label.text = "暂停"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	_title_label.add_theme_font_size_override(&"font_size", 64)
	if ui_font != null:
		_title_label.add_theme_font_override(&"font", ui_font)
	add_child(_title_label)

	_close_button = Button.new()
	_close_button.name = &"CloseButton"
	_close_button.text = "×"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.flat = true
	_close_button.add_theme_color_override(&"font_color", TEXT_COLOR)
	_close_button.add_theme_font_size_override(&"font_size", 84)
	if ui_font != null:
		_close_button.add_theme_font_override(&"font", ui_font)
	_close_button.pressed.connect(resume_requested.emit)
	add_child(_close_button)

	_resume_button = Button.new()
	_resume_button.name = &"ResumeButton"
	_resume_button.text = "▶  继续游戏"
	_resume_button.focus_mode = Control.FOCUS_NONE
	_resume_button.add_theme_color_override(&"font_color", TEXT_COLOR)
	_resume_button.add_theme_font_size_override(&"font_size", 52)
	_resume_button.add_theme_stylebox_override(&"normal", _button_style)
	_resume_button.add_theme_stylebox_override(&"hover", _button_hover_style)
	_resume_button.add_theme_stylebox_override(&"pressed", _button_pressed_style)
	if ui_font != null:
		_resume_button.add_theme_font_override(&"font", ui_font)
	_resume_button.pressed.connect(resume_requested.emit)
	add_child(_resume_button)

	_restart_button = Button.new()
	_restart_button.name = &"RestartButton"
	_restart_button.text = "↻  重新开始"
	_restart_button.focus_mode = Control.FOCUS_NONE
	_restart_button.add_theme_color_override(&"font_color", TEXT_COLOR)
	_restart_button.add_theme_font_size_override(&"font_size", 48)
	_restart_button.add_theme_stylebox_override(&"normal", _button_style)
	_restart_button.add_theme_stylebox_override(&"hover", _button_hover_style)
	_restart_button.add_theme_stylebox_override(&"pressed", _button_pressed_style)
	if ui_font != null:
		_restart_button.add_theme_font_override(&"font", ui_font)
	_restart_button.pressed.connect(restart_requested.emit)
	add_child(_restart_button)

	_save_exit_button = Button.new()
	_save_exit_button.name = &"SaveExitButton"
	_save_exit_button.text = "⌂  保存并退出"
	_save_exit_button.disabled = true
	_save_exit_button.focus_mode = Control.FOCUS_NONE
	_save_exit_button.add_theme_color_override(&"font_disabled_color", DISABLED_TEXT_COLOR)
	_save_exit_button.add_theme_font_size_override(&"font_size", 46)
	_save_exit_button.add_theme_stylebox_override(&"disabled", _button_disabled_style)
	if ui_font != null:
		_save_exit_button.add_theme_font_override(&"font", ui_font)
	add_child(_save_exit_button)

func _layout_contents() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var panel_width: float = size.x * 0.82
	var panel_left: float = (size.x - panel_width) * 0.5
	var header_height: float = size.y * 0.105
	var header_top: float = size.y * 0.325
	var body_top: float = header_top + header_height * 0.76
	var body_height: float = size.y * 0.49
	var title_icon_offset: float = minf(126.0, panel_width * 0.18)
	_title_label.position = Vector2(panel_left + title_icon_offset, header_top)
	_title_label.size = Vector2(panel_width - title_icon_offset - 128.0, header_height)
	_close_button.position = Vector2(panel_left + panel_width - 126.0, header_top + 8.0)
	_close_button.size = Vector2(112.0, header_height - 16.0)
	var button_height: float = minf(128.0, body_height * 0.2)
	var button_gap: float = body_height * 0.06
	var buttons_top: float = body_top + body_height * 0.12
	_resume_button.position = Vector2(panel_left + 76.0, buttons_top)
	_resume_button.size = Vector2(panel_width - 152.0, button_height)
	_restart_button.position = Vector2(panel_left + 76.0, buttons_top + button_height + button_gap)
	_restart_button.size = Vector2(panel_width - 152.0, button_height)
	_save_exit_button.position = Vector2(panel_left + 76.0, buttons_top + (button_height + button_gap) * 2.0)
	_save_exit_button.size = Vector2(panel_width - 152.0, button_height)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OVERLAY_COLOR)
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var panel_width: float = size.x * 0.82
	var panel_left: float = (size.x - panel_width) * 0.5
	var header_height: float = size.y * 0.105
	var header_top: float = size.y * 0.325
	var body_top: float = header_top + header_height * 0.76
	var body_height: float = size.y * 0.49
	var body_rect: Rect2 = Rect2(panel_left, body_top, panel_width, body_height)
	draw_style_box(_create_style(PANEL_SHADOW_COLOR, 48), body_rect.grow(14.0))
	draw_style_box(_panel_style, body_rect)
	draw_style_box(_header_style, Rect2(panel_left, header_top, panel_width, header_height))
	_draw_pause_icon(Vector2(size.x * 0.5 - minf(126.0, panel_width * 0.18), header_top + header_height * 0.5), header_height)

func _draw_pause_icon(center: Vector2, header_height: float) -> void:
	var bar_width: float = header_height * 0.075
	var bar_height: float = header_height * 0.3
	var gap: float = header_height * 0.075
	var bar_top: float = center.y - bar_height * 0.5
	draw_rect(Rect2(center.x - gap * 0.5 - bar_width, bar_top, bar_width, bar_height), TEXT_COLOR, true)
	draw_rect(Rect2(center.x + gap * 0.5, bar_top, bar_width, bar_height), TEXT_COLOR, true)

func _create_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
