class_name ModeSelection
extends Control

signal mode_selected(mode: int)
signal resume_selected(mode: int)

@onready var _classic_button: Button = %ClassicModeButton
@onready var _challenge_button: Button = %ChallengeModeButton
@onready var _classic_continue_button: Button = %ClassicContinueButton
@onready var _challenge_continue_button: Button = %ChallengeContinueButton

const BACKGROUND_COLOR: Color = Color("131927")
const PRIMARY_COLOR: Color = Color("20c7bd")
const SECONDARY_COLOR: Color = Color("4779f5")

func _ready() -> void:
	_classic_button.pressed.connect(_on_classic_button_pressed)
	_challenge_button.pressed.connect(_on_challenge_button_pressed)
	_classic_continue_button.pressed.connect(_on_classic_continue_button_pressed)
	_challenge_continue_button.pressed.connect(_on_challenge_continue_button_pressed)
	_apply_button_style(_classic_button, SECONDARY_COLOR)
	_apply_button_style(_challenge_button, PRIMARY_COLOR)
	_apply_button_style(_classic_continue_button, SECONDARY_COLOR.darkened(0.22))
	_apply_button_style(_challenge_continue_button, PRIMARY_COLOR.darkened(0.22))
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	draw_circle(Vector2(size.x * 0.25, size.y * 0.36), 170.0, Color("21304b"))
	draw_circle(Vector2(size.x * 0.80, size.y * 0.28), 110.0, Color("2a214c"))

func _apply_button_style(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override(&"normal", _create_button_style(color))
	button.add_theme_stylebox_override(&"hover", _create_button_style(color.lightened(0.10)))
	button.add_theme_stylebox_override(&"pressed", _create_button_style(color.darkened(0.14)))
	button.add_theme_stylebox_override(&"focus", _create_button_style(color.lightened(0.06)))

func _create_button_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 8.0)
	return style

func _on_classic_button_pressed() -> void:
	mode_selected.emit(GameModeDefinition.Mode.CLASSIC)

func _on_challenge_button_pressed() -> void:
	mode_selected.emit(GameModeDefinition.Mode.CHALLENGE)

func set_resume_available(has_classic_session: bool, has_challenge_session: bool) -> void:
	_classic_continue_button.visible = has_classic_session
	_challenge_continue_button.visible = has_challenge_session

func _on_classic_continue_button_pressed() -> void:
	resume_selected.emit(GameModeDefinition.Mode.CLASSIC)

func _on_challenge_continue_button_pressed() -> void:
	resume_selected.emit(GameModeDefinition.Mode.CHALLENGE)
