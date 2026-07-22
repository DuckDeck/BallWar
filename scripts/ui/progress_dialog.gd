class_name ProgressDialog
extends Control

signal continue_requested(mode: int)
signal discard_requested(mode: int)

@export var ui_font: Font

const OVERLAY_COLOR: Color = Color(0.015, 0.025, 0.035, 0.76)
const PANEL_COLOR: Color = Color("222b42")
const PANEL_SHADOW_COLOR: Color = Color(0.005, 0.01, 0.02, 0.62)
const HEADER_COLOR: Color = Color("9651b2")
const TEXT_COLOR: Color = Color("f7fbff")
const MUTED_TEXT_COLOR: Color = Color("b7c2e1")
const DISCARD_COLOR: Color = Color("ff5d63")
const CONTINUE_COLOR: Color = Color("65cf73")

var _selected_mode: int = GameModeDefinition.Mode.CLASSIC
var _title_label: Label
var _message_label: Label
var _close_button: Button
var _discard_button: Button
var _continue_button: Button
var _discard_caption: Label
var _continue_caption: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	resized.connect(_layout_contents)
	hide_dialog()
	call_deferred("_layout_contents")

func show_progress(mode: int, score: int) -> void:
	_selected_mode = mode
	_message_label.text = "上次玩到%d，是否继续？" % maxi(0, score)
	show()
	_layout_contents()
	queue_redraw()

func hide_dialog() -> void:
	hide()

func _build_controls() -> void:
	_title_label = _create_label("进度", 70, TEXT_COLOR)
	_title_label.name = &"ProgressTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	_message_label = _create_label("上次玩到0，是否继续？", 50, MUTED_TEXT_COLOR)
	_message_label.name = &"ProgressMessage"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_message_label)

	_close_button = Button.new()
	_close_button.name = &"CloseButton"
	_close_button.text = "×"
	_close_button.flat = true
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.add_theme_color_override(&"font_color", TEXT_COLOR)
	_close_button.add_theme_font_size_override(&"font_size", 88)
	if ui_font != null:
		_close_button.add_theme_font_override(&"font", ui_font)
	_close_button.pressed.connect(hide_dialog)
	add_child(_close_button)

	_discard_button = _create_circle_button("DiscardButton", DISCARD_COLOR, "×")
	_discard_button.pressed.connect(_on_discard_pressed)
	_continue_button = _create_circle_button("ContinueButton", CONTINUE_COLOR, "✓")
	_continue_button.pressed.connect(_on_continue_pressed)
	_discard_caption = _create_label("不继续", 44, TEXT_COLOR)
	_discard_caption.name = &"DiscardCaption"
	_continue_caption = _create_label("继续", 44, TEXT_COLOR)
	_continue_caption.name = &"ContinueCaption"
	for caption: Label in [_discard_caption, _continue_caption]:
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(caption)

func _create_label(text_value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", font_size)
	if ui_font != null:
		label.add_theme_font_override(&"font", ui_font)
	return label

func _create_circle_button(node_name: String, color: Color, glyph: String) -> Button:
	var button: Button = Button.new()
	button.name = node_name
	button.text = glyph
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override(&"font_color", TEXT_COLOR)
	button.add_theme_font_size_override(&"font_size", 74)
	button.add_theme_stylebox_override(&"normal", _create_circle_style(color))
	button.add_theme_stylebox_override(&"hover", _create_circle_style(color.lightened(0.10)))
	button.add_theme_stylebox_override(&"pressed", _create_circle_style(color.darkened(0.14)))
	if ui_font != null:
		button.add_theme_font_override(&"font", ui_font)
	add_child(button)
	return button

func _layout_contents() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var panel_width: float = size.x * 0.80
	var panel_left: float = (size.x - panel_width) * 0.5
	var header_height: float = size.y * 0.105
	var header_top: float = size.y * 0.315
	var body_top: float = header_top + header_height * 0.74
	var body_height: float = size.y * 0.34
	_title_label.position = Vector2(panel_left, header_top)
	_title_label.size = Vector2(panel_width, header_height)
	_close_button.position = Vector2(panel_left + panel_width - 132.0, header_top + 4.0)
	_close_button.size = Vector2(116.0, header_height - 8.0)
	_message_label.position = Vector2(panel_left + 32.0, body_top + body_height * 0.15)
	_message_label.size = Vector2(panel_width - 64.0, body_height * 0.22)
	var action_size: float = minf(panel_width * 0.17, body_height * 0.30)
	var actions_top: float = body_top + body_height * 0.52
	_layout_action(_discard_button, _discard_caption, panel_left + panel_width * 0.25 - action_size * 0.5, actions_top, action_size)
	_layout_action(_continue_button, _continue_caption, panel_left + panel_width * 0.75 - action_size * 0.5, actions_top, action_size)
	queue_redraw()

func _layout_action(button: Button, caption: Label, x: float, y: float, action_size: float) -> void:
	button.position = Vector2(x, y)
	button.size = Vector2(action_size, action_size)
	caption.position = Vector2(x - action_size * 0.45, y + action_size * 1.10)
	caption.size = Vector2(action_size * 1.90, action_size * 0.44)

func _on_discard_pressed() -> void:
	discard_requested.emit(_selected_mode)

func _on_continue_pressed() -> void:
	continue_requested.emit(_selected_mode)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OVERLAY_COLOR)
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var panel_width: float = size.x * 0.80
	var panel_left: float = (size.x - panel_width) * 0.5
	var header_height: float = size.y * 0.105
	var header_top: float = size.y * 0.315
	var body_top: float = header_top + header_height * 0.74
	var body_height: float = size.y * 0.34
	var body_rect: Rect2 = Rect2(panel_left, body_top, panel_width, body_height)
	draw_style_box(_create_panel_style(PANEL_SHADOW_COLOR), body_rect.grow(14.0))
	draw_style_box(_create_panel_style(PANEL_COLOR), body_rect)
	draw_style_box(_create_header_style(), Rect2(panel_left, header_top, panel_width, header_height))

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
