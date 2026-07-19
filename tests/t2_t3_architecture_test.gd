# covers: [T2-AUTO-01, T2-AUTO-02, T2-AUTO-03, T3-AUTO-01, T3-AUTO-02, T3-AUTO-03]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var manager: BallManager = main.get_node("BallManager") as BallManager
	var board: BoardController = main.get_node("BoardController") as BoardController
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	controller.config.initial_ball_count = 10
	controller.config.ball_launch_interval_seconds = 0.01
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	assert(board.get_obstacle_count() >= 1, "The board must create at least one bottom-row obstacle.")
	assert(controller.config.launcher_position == Vector2(540.0, 450.0), "The launch origin must sit one ball diameter below the roof exit.")
	assert(launcher.global_position == controller.config.launcher_position, "The visual launcher and physics origin must stay aligned.")
	controller.request_launch(Vector2.DOWN)
	var active_balls: Array[Ball] = manager.get_active_balls(1)
	assert(active_balls.size() == 1, "Only the first ball may launch immediately.")
	assert(active_balls[0].global_position == controller.config.launcher_position, "The first ball must spawn from the lowered launch origin.")
	assert(manager.get_pending_ball_count(1) == 9, "The remaining balls must stay in the launch queue.")
	assert(launcher.get_waiting_ball_count() == 9, "The pending balls must remain visible in the top launcher slot.")
	await create_timer(0.15).timeout
	active_balls = manager.get_active_balls(1)
	assert(active_balls.size() == 10, "A configured batch must launch every ball in order.")
	assert(manager.get_pending_ball_count(1) == 0, "The queue must be empty after the final sequential launch.")
	assert(launcher.get_waiting_ball_count() == 0, "The launcher slot must clear after the final ball launches.")
	assert(BallBatch.new(1, [], 0.0).get_launch_direction(Vector2.DOWN, 3) == Vector2.DOWN, "Every queued ball must preserve the first ball's aim direction.")
	var colors: Array[Color] = []
	for ball: Ball in active_balls:
		assert(ball.collision_layer == 2 and ball.collision_mask == 1, "Balls must only detect WORLD layer 1, never other balls.")
		assert(not colors.has(ball.get_visual_color()), "The first ten configured balls must use distinct palette colors.")
		colors.append(ball.get_visual_color())
	for index: int in active_balls.size() - 1:
		active_balls[index].force_recover(&"test")
	assert(manager.get_active_ball_count() == 1, "Recovering one ball must not end the batch while other balls remain.")
	assert(controller.get_state() == GameController.State.BALLS_ACTIVE, "The controller must remain active until the final ball returns.")
	active_balls.back().force_recover(&"test")
	await process_frame
	await process_frame
	assert(manager.get_active_ball_count() == 0, "The manager must unregister every recovered ball.")
	assert(controller.get_state() == GameController.State.READY, "The final recovered ball must resolve exactly one safe turn.")
	var cells_after_first_turn: Array[Vector2i] = board.get_cells()
	var has_bottom_row: bool = false
	var has_advanced_row: bool = false
	for cell: Vector2i in cells_after_first_turn:
		has_bottom_row = has_bottom_row or cell.y == 0
		has_advanced_row = has_advanced_row or cell.y >= 1
	assert(has_bottom_row and has_advanced_row, "A safe turn must advance existing blocks and generate one new bottom row.")
	var batch_id: int = 100
	while not board.is_game_over() and batch_id < 120:
		board.resolve_completed_batch(batch_id)
		batch_id += 1
	assert(board.is_game_over(), "A block reaching the danger line must end the game.")
	assert(controller.get_state() == GameController.State.GAME_OVER, "The controller must expose GAME_OVER after a danger-line failure.")
	print("T2/T3 architecture test passed: batch ownership, ball isolation, board advance, and danger line verified.")
	quit(0)
