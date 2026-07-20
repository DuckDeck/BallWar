class_name Main
extends Node2D

@onready var _launcher: Launcher = %Launcher
@onready var _game_controller: GameController = %GameController
@onready var _score_label: Label = %ScoreLabel
@onready var _time_label: Label = %TimeLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _mode_selection: ModeSelection = %ModeSelection
@onready var _arena_renderer: Node2D = $ArenaRenderer

func _ready() -> void:
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_launcher.launch_requested.connect(_game_controller.request_launch)
	_game_controller.score_changed.connect(_on_score_changed)
	_game_controller.state_changed.connect(_on_state_changed)
	_game_controller.launcher_launchability_changed.connect(_on_launcher_launchability_changed)
	_game_controller.launcher_presentation_changed.connect(_on_launcher_presentation_changed)
	_game_controller.launcher_next_ball_release_requested.connect(_on_launcher_next_ball_release_requested)
	_game_controller.classic_launcher_recovery_received.connect(_on_classic_launcher_recovery_received)
	_game_controller.elapsed_time_changed.connect(_on_elapsed_time_changed)
	_game_controller.launcher_preview_changed.connect(_on_launcher_preview_changed)
	_game_controller.game_mode_changed.connect(_on_game_mode_changed)
	_game_controller.challenge_wave_remaining_changed.connect(_on_challenge_wave_remaining_changed)
	_mode_selection.mode_selected.connect(_on_mode_selected)
	_launcher.set_waiting_ball_definitions(_game_controller.get_launcher_preview_definitions())
	_launcher.next_ball_release_ready.connect(_on_launcher_next_ball_release_ready)
	_launcher.set_launch_ready(false)
	_score_label.text = "Score: 0"
	_time_label.text = _format_elapsed_time(_game_controller.get_elapsed_seconds())
	_wave_label.hide()
	_set_gameplay_visible(false)

func start_game_by_mode_id(mode: int) -> void:
	_on_mode_selected(mode)

func _on_mode_selected(mode: int) -> void:
	_mode_selection.hide()
	_set_gameplay_visible(true)
	_game_controller.start_game_by_mode_id(mode)

func _on_score_changed(score: int) -> void:
	_score_label.text = "Score: %d" % score

func _on_state_changed(state: int) -> void:
	_launcher.set_launch_ready(_game_controller.can_request_launch())

func _on_launcher_launchability_changed(is_ready: bool) -> void:
	_launcher.set_launch_ready(is_ready)

func _on_launcher_presentation_changed(presentation: int) -> void:
	_launcher.set_presentation(presentation)

func _on_launcher_next_ball_release_requested(batch_id: int) -> void:
	_launcher.request_next_ball_release(batch_id)

func _on_launcher_next_ball_release_ready(batch_id: int, definition: BallDefinition) -> void:
	_game_controller.confirm_launcher_next_ball_release(batch_id, definition)

func _on_classic_launcher_recovery_received(definition: BallDefinition, recovery_direction: float) -> void:
	_launcher.set_classic_recovery_direction(definition, recovery_direction)

func _on_elapsed_time_changed(elapsed_seconds: int) -> void:
	_time_label.text = _format_elapsed_time(elapsed_seconds)

func _on_launcher_preview_changed(definitions: Array[BallDefinition]) -> void:
	_launcher.set_waiting_ball_definitions(definitions)

func _on_game_mode_changed(mode: int) -> void:
	_wave_label.visible = mode == GameModeDefinition.Mode.CHALLENGE
	if _wave_label.visible:
		_wave_label.text = "Wave: 10s"

func _on_challenge_wave_remaining_changed(remaining_seconds: int) -> void:
	_wave_label.text = "Wave: %02ds" % remaining_seconds

func _set_gameplay_visible(is_visible: bool) -> void:
	_arena_renderer.visible = is_visible
	_launcher.visible = is_visible
	_score_label.visible = is_visible
	_time_label.visible = is_visible
	if not is_visible:
		_wave_label.hide()

func _format_elapsed_time(total_seconds: int) -> String:
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "Time: %02d:%02d" % [minutes, seconds]
