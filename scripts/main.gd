class_name Main
extends Node2D

const SCORE_RECORD_STORE_SCRIPT: GDScript = preload("res://scripts/score_record_store.gd")
const GAME_SESSION_STORE_SCRIPT: GDScript = preload("res://scripts/game_session_store.gd")

@export var session_store_path: String = "user://game_sessions.cfg"

@onready var _launcher: Launcher = %Launcher
@onready var _game_controller: GameController = %GameController
@onready var _hud: GameHud = %Hud
@onready var _pause_menu: Control = %PauseMenu
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _mode_selection: ModeSelection = %ModeSelection
@onready var _arena_renderer: Node2D = $ArenaRenderer

var _score_record_store: ScoreRecordStore
var _game_session_store: GameSessionStore

func _ready() -> void:
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_score_record_store = SCORE_RECORD_STORE_SCRIPT.new() as ScoreRecordStore
	_game_session_store = GAME_SESSION_STORE_SCRIPT.new(session_store_path) as GameSessionStore
	_launcher.launch_requested.connect(_game_controller.request_launch)
	_game_controller.score_changed.connect(_on_score_changed)
	_game_controller.state_changed.connect(_on_state_changed)
	_game_controller.launcher_launchability_changed.connect(_on_launcher_launchability_changed)
	_game_controller.launcher_presentation_changed.connect(_on_launcher_presentation_changed)
	_game_controller.launcher_next_ball_release_requested.connect(_on_launcher_next_ball_release_requested)
	_game_controller.launcher_preview_recovery_received.connect(_on_launcher_preview_recovery_received)
	_game_controller.elapsed_time_changed.connect(_on_elapsed_time_changed)
	_game_controller.launcher_preview_changed.connect(_on_launcher_preview_changed)
	_game_controller.game_mode_changed.connect(_on_game_mode_changed)
	_game_controller.challenge_wave_remaining_changed.connect(_on_challenge_wave_remaining_changed)
	_game_controller.game_over.connect(_on_game_over)
	_game_controller.session_checkpoint_changed.connect(_on_session_checkpoint_changed)
	_mode_selection.mode_selected.connect(_on_mode_selected)
	_mode_selection.resume_selected.connect(_on_resume_selected)
	_hud.pause_requested.connect(_on_pause_button_pressed)
	_pause_menu.connect(&"resume_requested", _on_pause_menu_resume_requested)
	_pause_menu.connect(&"restart_requested", _on_pause_menu_restart_requested)
	_pause_menu.connect(&"save_exit_requested", _on_pause_menu_save_exit_requested)
	_game_over_panel.connect(&"restart_requested", _on_game_over_restart_requested)
	_game_over_panel.connect(&"menu_requested", _on_game_over_menu_requested)
	_launcher.set_waiting_ball_definitions(_game_controller.get_launcher_preview_definitions())
	_launcher.next_ball_release_ready.connect(_on_launcher_next_ball_release_ready)
	_launcher.set_launch_ready(false)
	_hud.set_score(0)
	_hud.set_elapsed_time(_game_controller.get_elapsed_seconds())
	_pause_menu.hide()
	_game_over_panel.hide()
	_set_gameplay_visible(false)
	_refresh_resume_actions()

func start_game_by_mode_id(mode: int) -> void:
	_on_mode_selected(mode)

func _on_mode_selected(mode: int) -> void:
	_game_session_store.clear_session(mode)
	_mode_selection.hide()
	_set_gameplay_visible(true)
	_game_controller.start_game_by_mode_id(mode)

func _on_resume_selected(mode: int) -> void:
	var snapshot: Dictionary = _game_session_store.load_session(mode)
	if snapshot.is_empty() or not _game_controller.restore_session(snapshot):
		_game_session_store.clear_session(mode)
		_refresh_resume_actions()
		return
	_mode_selection.hide()
	_set_gameplay_visible(true)

func _on_score_changed(score: int) -> void:
	_hud.set_score(score)

func _on_state_changed(state: int) -> void:
	_launcher.set_launch_ready(_game_controller.can_request_launch())
	_hud.set_pause_visible(_arena_renderer.visible and state != GameController.State.MODE_SELECTION and state != GameController.State.GAME_OVER)

func _on_launcher_launchability_changed(is_ready: bool) -> void:
	_launcher.set_launch_ready(is_ready)

func _on_launcher_presentation_changed(presentation: int) -> void:
	_launcher.set_presentation(presentation)

func _on_launcher_next_ball_release_requested(batch_id: int) -> void:
	_launcher.request_next_ball_release(batch_id)

func _on_launcher_next_ball_release_ready(batch_id: int, definition: BallDefinition) -> void:
	_game_controller.confirm_launcher_next_ball_release(batch_id, definition)

func _on_launcher_preview_recovery_received(definition: BallDefinition, recovery_direction: float) -> void:
	_launcher.set_preview_recovery_direction(definition, recovery_direction)

func _on_elapsed_time_changed(elapsed_seconds: int) -> void:
	_hud.set_elapsed_time(elapsed_seconds)
	if _game_controller.get_active_mode() == GameModeDefinition.Mode.CHALLENGE and not get_tree().paused:
		_persist_current_session()

func _on_launcher_preview_changed(definitions: Array[BallDefinition]) -> void:
	_launcher.set_waiting_ball_definitions(definitions)

func _on_game_mode_changed(mode: int) -> void:
	_hud.set_challenge_mode(mode == GameModeDefinition.Mode.CHALLENGE)
	AudioManager.play_mode_bgm(mode)

func _on_challenge_wave_remaining_changed(remaining_seconds: int) -> void:
	_hud.set_challenge_remaining(remaining_seconds)

func request_pause() -> bool:
	if not _game_controller.pause_game():
		return false
	_pause_menu.show()
	AudioManager.pause_music()
	get_tree().paused = true
	return true

func resume_game() -> bool:
	if not get_tree().paused:
		return false
	get_tree().paused = false
	_pause_menu.hide()
	var resumed: bool = _game_controller.resume_game()
	if resumed:
		AudioManager.resume_music()
	return resumed

func _on_pause_button_pressed() -> void:
	request_pause()

func _on_pause_menu_resume_requested() -> void:
	resume_game()

func restart_game() -> bool:
	if not get_tree().paused:
		return false
	_game_session_store.clear_session(_game_controller.get_active_mode())
	AudioManager.stop_music()
	get_tree().paused = false
	_pause_menu.hide()
	_game_over_panel.hide()
	var restarted: bool = _game_controller.restart_game()
	_refresh_resume_actions()
	return restarted

func return_to_mode_selection() -> bool:
	if not get_tree().paused:
		return false
	get_tree().paused = false
	_pause_menu.hide()
	_game_over_panel.hide()
	if not _game_controller.return_to_mode_selection():
		return false
	AudioManager.stop_music()
	_set_gameplay_visible(false)
	_mode_selection.show()
	return true

func _on_pause_menu_restart_requested() -> void:
	restart_game()

func _on_pause_menu_save_exit_requested() -> void:
	save_and_exit()

func _on_game_over(final_score: int, _reached_turn: int) -> void:
	var active_mode: int = _game_controller.get_active_mode()
	_game_session_store.clear_session(active_mode)
	_refresh_resume_actions()
	var records: Dictionary = _score_record_store.record_score(active_mode, final_score)
	_game_over_panel.call("show_results", final_score, records, active_mode)
	AudioManager.pause_music()
	get_tree().paused = true

func _on_game_over_restart_requested() -> void:
	restart_game()

func _on_game_over_menu_requested() -> void:
	return_to_mode_selection()

func _set_gameplay_visible(is_visible: bool) -> void:
	_arena_renderer.visible = is_visible
	_launcher.visible = is_visible
	_hud.visible = is_visible
	if not is_visible:
		_pause_menu.hide()
		_game_over_panel.hide()

func save_and_exit() -> bool:
	if not get_tree().paused or _game_controller.get_state() != GameController.State.PAUSED:
		return false
	if not _persist_current_session():
		return false
	get_tree().paused = false
	_pause_menu.hide()
	_game_over_panel.hide()
	if not _game_controller.return_to_mode_selection():
		return false
	AudioManager.stop_music()
	_set_gameplay_visible(false)
	_mode_selection.show()
	_refresh_resume_actions()
	return true

func _on_session_checkpoint_changed(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	_game_session_store.save_session(int(snapshot.get("mode", GameModeDefinition.Mode.CLASSIC)), snapshot)
	_refresh_resume_actions()

func _persist_current_session() -> bool:
	var snapshot: Dictionary = _game_controller.get_session_snapshot()
	if snapshot.is_empty():
		return false
	return _game_session_store.save_session(_game_controller.get_active_mode(), snapshot)

func _refresh_resume_actions() -> void:
	_mode_selection.set_resume_available(
		_game_session_store.has_session(GameModeDefinition.Mode.CLASSIC),
		_game_session_store.has_session(GameModeDefinition.Mode.CHALLENGE)
	)

func _notification(what: int) -> void:
	if _game_session_store == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_persist_current_session()
