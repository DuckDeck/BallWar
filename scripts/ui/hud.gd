class_name GameHud
extends Control

signal pause_requested()

@onready var _score_label: Label = %ScoreLabel
@onready var _time_label: Label = %TimeLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _pause_button: Button = %PauseButton

func _ready() -> void:
	_pause_button.pressed.connect(pause_requested.emit)
	resized.connect(_layout_contents)
	set_challenge_mode(false)
	call_deferred("_layout_contents")

func set_score(score: int) -> void:
	_score_label.text = "Score: %d" % maxi(0, score)

func set_elapsed_time(total_seconds: int) -> void:
	var minutes: int = maxi(0, total_seconds) / 60
	var seconds: int = maxi(0, total_seconds) % 60
	_time_label.text = "Time: %02d:%02d" % [minutes, seconds]

func set_challenge_mode(is_challenge: bool) -> void:
	_wave_label.visible = is_challenge
	if is_challenge:
		_wave_label.text = "Wave: 10s"

func set_challenge_remaining(remaining_seconds: int) -> void:
	_wave_label.text = "Wave: %02ds" % maxi(0, remaining_seconds)

func set_pause_visible(is_visible: bool) -> void:
	_pause_button.visible = is_visible

func get_pause_button() -> Button:
	return _pause_button

func _layout_contents() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var horizontal_margin: float = clampf(size.x * 0.09, 32.0, 104.0)
	var toolbar_top: float = clampf(size.y * 0.144, 96.0, 276.0)
	var pause_size: float = clampf(size.x * 0.065, 52.0, 70.0)
	var primary_font_size: int = int(clampf(size.x * 0.035, 26.0, 38.0))
	var wave_font_size: int = int(clampf(size.x * 0.022, 18.0, 24.0))
	_pause_button.position = Vector2(horizontal_margin, toolbar_top)
	_pause_button.size = Vector2(pause_size, pause_size)
	_score_label.position = Vector2(horizontal_margin, toolbar_top + pause_size + 4.0)
	_score_label.size = Vector2(size.x * 0.38, primary_font_size * 1.55)
	_score_label.add_theme_font_size_override(&"font_size", primary_font_size)
	_time_label.position = Vector2(size.x * 0.58, toolbar_top + pause_size + 4.0)
	_time_label.size = Vector2(size.x - horizontal_margin - size.x * 0.58, primary_font_size * 1.55)
	_time_label.add_theme_font_size_override(&"font_size", primary_font_size)
	_wave_label.position = Vector2(size.x * 0.62, toolbar_top + pause_size + primary_font_size * 1.40)
	_wave_label.size = Vector2(size.x - horizontal_margin - size.x * 0.62, wave_font_size * 1.55)
	_wave_label.add_theme_font_size_override(&"font_size", wave_font_size)
