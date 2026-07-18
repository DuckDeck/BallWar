class_name Main
extends Node2D

@onready var _launcher: Launcher = %Launcher
@onready var _game_controller: GameController = %GameController
@onready var _score_label: Label = %ScoreLabel

func _ready() -> void:
	_launcher.launch_requested.connect(_game_controller.request_launch)
	_game_controller.score_changed.connect(_on_score_changed)
	_score_label.text = "Score: 0"

func _on_score_changed(score: int) -> void:
	_score_label.text = "Score: %d" % score
