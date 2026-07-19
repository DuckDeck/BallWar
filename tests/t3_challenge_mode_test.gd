# covers: [T3-CH-AUTO-01, T3-CH-AUTO-02, T3-CH-AUTO-03, T3-CH-AUTO-04]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var board: BoardController = main.get_node("BoardController") as BoardController
	var manager: BallManager = main.get_node("BallManager") as BallManager
	var clock: ChallengeWaveClock = main.get_node("ChallengeWaveClock") as ChallengeWaveClock
	var mode_selection: ModeSelection = main.get_node("CanvasLayer/ModeSelection") as ModeSelection
	assert(controller.get_state() == GameController.State.MODE_SELECTION, "The game must wait for a mode choice before creating a board.")
	assert(board.get_obstacle_count() == 0, "No bottom row may exist before a mode is selected.")
	assert(mode_selection.visible, "The mode selection screen must be visible at startup.")
	controller.challenge_mode.timed_wave_interval_seconds = 10.0
	controller.challenge_mode.temporary_ball_gain_per_timed_wave = 1
	main.start_game_by_mode_id(GameModeDefinition.Mode.CHALLENGE)
	await process_frame
	assert(controller.get_active_mode() == GameModeDefinition.Mode.CHALLENGE, "The selected challenge mode must be stored by the controller.")
	assert(controller.get_state() == GameController.State.READY, "Selecting challenge mode must create a launch-ready game.")
	assert(board.get_obstacle_count() >= 1, "Challenge mode must create an initial bottom row immediately.")
	assert(is_equal_approx(clock.wait_time, 10.0) and not clock.is_stopped(), "Challenge mode must start its independent 10-second wave clock.")
	var preview_before_wave: Array[BallDefinition] = controller.get_launcher_preview_definitions()
	assert(preview_before_wave.size() == 1, "Challenge mode must begin with the configured initial ball count.")
	controller.request_launch(Vector2.DOWN)
	assert(controller.get_state() == GameController.State.BALLS_ACTIVE and manager.get_active_ball_count() == 1, "The first challenge ball must become active before the timed wave.")
	clock.wave_due.emit()
	controller._physics_process(0.0)
	var cells_after_wave: Array[Vector2i] = board.get_cells()
	var has_advanced_cell: bool = false
	var has_new_bottom_cell: bool = false
	for cell: Vector2i in cells_after_wave:
		has_advanced_cell = has_advanced_cell or cell.y >= 1
		has_new_bottom_cell = has_new_bottom_cell or cell.y == 0
	assert(has_advanced_cell and has_new_bottom_cell, "A timed wave must advance old blocks and add one new bottom row while the ball is active.")
	assert(controller.get_state() == GameController.State.BALLS_ACTIVE and manager.get_active_ball_count() == 1, "A timed wave must not pause, remove, or resolve the active ball batch.")
	assert(controller.get_launcher_preview_definitions().size() == 2, "A successful timed wave must temporarily add one ball for the next batch.")
	clock.stop_clock()
	var cells_before_recovery: Array[Vector2i] = board.get_cells()
	var active_ball: Ball = manager.get_active_balls(1)[0]
	active_ball.force_recover(&"test")
	assert(controller.get_state() == GameController.State.READY, "A completed challenge batch must restore launch readiness.")
	assert(board.get_cells() == cells_before_recovery, "A completed challenge batch must not advance the board or spawn a row.")
	var timed_wave_count: int = 2
	while not board.is_game_over() and timed_wave_count < 20:
		board.resolve_timed_wave(2)
		timed_wave_count += 1
	assert(board.is_game_over() and controller.get_state() == GameController.State.GAME_OVER, "A timed danger-line failure must stop challenge mode.")
	print("T3 challenge mode test passed: menu gate, timed waves, active-ball concurrency, batch separation, and danger stop verified.")
	quit(0)
