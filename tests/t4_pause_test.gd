# covers: [T4-AUTO-01]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SESSION_PATH: String = "user://t4_pause_test_sessions.cfg"

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	main.session_store_path = TEST_SESSION_PATH
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var manager: BallManager = main.get_node("BallManager") as BallManager
	var board: BoardController = main.get_node("BoardController") as BoardController
	var clock: ChallengeWaveClock = main.get_node("ChallengeWaveClock") as ChallengeWaveClock
	var pause_button: Button = main.get_node("CanvasLayer/Hud/PauseButton") as Button
	var pause_menu: Control = main.get_node("CanvasLayer/PauseMenu") as Control
	var save_exit_button: Button = pause_menu.get_node("SaveExitButton") as Button
	controller.config.initial_ball_count = 1
	main.start_game_by_mode_id(GameModeDefinition.Mode.CHALLENGE)
	await physics_frame
	controller.request_launch(Vector2.DOWN)
	assert(manager.get_active_ball_count() == 1, "The pause test requires an active challenge ball.")
	await physics_frame
	var active_ball: Ball = manager.get_active_balls(1)[0]
	var position_before_pause: Vector2 = active_ball.global_position
	var elapsed_before_pause: int = controller.get_elapsed_seconds()
	var wave_time_before_pause: float = clock.time_left
	pause_button.pressed.emit()
	assert(paused and controller.get_state() == GameController.State.PAUSED, "The pause button must freeze the game through the PAUSED state.")
	assert(pause_menu.visible, "Pausing must show the pause overlay.")
	assert(not save_exit_button.disabled, "Save and exit must be available from the paused menu.")
	assert(pause_menu.get("icon_font") is Font, "The pause menu must bind the project icon font separately from its Chinese text font.")
	await create_timer(1.1, true).timeout
	assert(active_ball.global_position.is_equal_approx(position_before_pause), "An active ball must not move while the tree is paused.")
	assert(controller.get_elapsed_seconds() == elapsed_before_pause, "The session timer must freeze while paused.")
	assert(is_equal_approx(clock.time_left, wave_time_before_pause), "The challenge wave clock must freeze while paused.")
	pause_menu.emit_signal(&"resume_requested")
	await physics_frame
	assert(not paused and controller.get_state() == GameController.State.BALLS_ACTIVE, "Closing the pause overlay must resume the previous game state.")
	assert(not pause_menu.visible, "The pause overlay must hide after resume.")
	await create_timer(1.1).timeout
	assert(controller.get_elapsed_seconds() > elapsed_before_pause, "The session timer must resume after closing the pause overlay.")
	pause_button.pressed.emit()
	assert(paused and controller.get_state() == GameController.State.PAUSED, "Restart must only be available from the paused menu.")
	pause_menu.emit_signal(&"restart_requested")
	await process_frame
	assert(not paused, "Restarting must release the SceneTree pause state.")
	assert(controller.get_state() == GameController.State.READY, "Restarting must return the current mode to its ready state.")
	assert(controller.get_active_mode() == GameModeDefinition.Mode.CHALLENGE, "Restarting must preserve the selected challenge mode.")
	assert(manager.get_active_ball_count() == 0, "Restarting must remove every active ball from the previous session.")
	assert(controller.get_score() == 0 and controller.get_elapsed_seconds() == 0, "Restarting must reset score and session time.")
	assert(board.get_obstacle_count() >= 4, "Restarting must create a fresh first row of board content.")
	assert(not clock.is_stopped(), "Restarting challenge mode must start a fresh wave clock.")
	pause_button.pressed.emit()
	assert(paused and controller.get_state() == GameController.State.PAUSED, "Save and exit must only operate from the paused state.")
	save_exit_button.pressed.emit()
	await process_frame
	assert(not paused and controller.get_state() == GameController.State.MODE_SELECTION, "Save and exit must return to the mode selection screen.")
	assert(main.get_node("CanvasLayer/ModeSelection").visible, "Mode selection must be visible after saving and exiting.")
	assert(main.get_node_or_null("CanvasLayer/ModeSelection/ChallengeContinueButton") == null, "Mode selection must not create a dedicated continue button.")
	main.get_node("CanvasLayer/ModeSelection").emit_signal(&"mode_selected", GameModeDefinition.Mode.CHALLENGE)
	await process_frame
	assert(main.get_node("CanvasLayer/ProgressDialog").visible, "Selecting a mode with a saved session must show the progress confirmation dialog.")
	var session_store: GameSessionStore = GameSessionStore.new(TEST_SESSION_PATH)
	session_store.clear_session(GameModeDefinition.Mode.CLASSIC)
	session_store.clear_session(GameModeDefinition.Mode.CHALLENGE)
	print("T4 pause test passed: overlay, freeze, resume, restart, and save-and-exit verified.")
	quit(0)
