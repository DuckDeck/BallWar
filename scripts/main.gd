class_name Main
extends Node2D

@onready var _launcher: Launcher = %Launcher
@onready var _game_controller: GameController = %GameController
@onready var _score_label: Label = %ScoreLabel
@onready var _time_label: Label = %TimeLabel

func _ready() -> void:
	_launcher.launch_requested.connect(_game_controller.request_launch)
	_game_controller.score_changed.connect(_on_score_changed)
	_game_controller.state_changed.connect(_on_state_changed)
	_game_controller.elapsed_time_changed.connect(_on_elapsed_time_changed)
	_game_controller.launcher_preview_changed.connect(_on_launcher_preview_changed)
	_launcher.set_waiting_ball_definitions(_game_controller.get_launcher_preview_definitions())
	_launcher.set_launch_ready(true)
	_score_label.text = "Score: 0"
	_time_label.text = _format_elapsed_time(_game_controller.get_elapsed_seconds())

func _on_score_changed(score: int) -> void:
	_score_label.text = "Score: %d" % score

func _on_state_changed(state: int) -> void:
	_launcher.set_launch_ready(state == GameController.State.READY)

func _on_elapsed_time_changed(elapsed_seconds: int) -> void:
	_time_label.text = _format_elapsed_time(elapsed_seconds)

func _on_launcher_preview_changed(definitions: Array[BallDefinition]) -> void:
	_launcher.set_waiting_ball_definitions(definitions)

func _format_elapsed_time(total_seconds: int) -> String:
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "Time: %02d:%02d" % [minutes, seconds]
