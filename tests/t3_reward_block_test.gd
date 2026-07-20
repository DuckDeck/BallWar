# covers: [T3-AUTO-06, L1-MB-13]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	_verify_reward_generation()
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var manager: BallManager = main.get_node("BallManager") as BallManager
	var board: BoardController = main.get_node("BoardController") as BoardController
	controller.config.initial_ball_count = 1
	controller.config.maximum_ball_count = 4
	controller.config.heavy_ball_spawn_probability = 0.0
	controller.config.reward_start_wave = 1
	controller.config.add_ball_reward_probability = 1.0
	controller.config.enlarge_ball_reward_probability = 0.0
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var reward: RewardBlock = _get_first_reward(board)
	assert(reward != null and reward.reward_type == RewardBlock.Type.ADD_BALL, "A 100% add-ball probability must replace the generated obstacle with an add-ball reward.")
	controller.request_launch(Vector2.DOWN)
	var source_ball: Ball = manager.get_active_balls(1)[0]
	var hit_context: HitContext = HitContext.new()
	hit_context.source_ball = source_ball
	var hit_result: HitResult = reward.receive_hit(hit_context)
	assert(not hit_result.should_bounce and hit_result.points_awarded == 0, "Rewards must disappear without score or bounce.")
	assert(manager.get_active_ball_count() == 2, "An add-ball reward must immediately create a gravity-drop ball in the current batch.")
	var active_balls: Array[Ball] = manager.get_active_balls(1)
	var dropped_ball: Ball = active_balls[0] if active_balls[1] == source_ball else active_balls[1]
	assert(dropped_ball.runtime_state.is_gravity_enabled and dropped_ball.velocity.is_zero_approx(), "The reward ball must begin as a zero-speed gravity drop.")
	await process_frame
	for ball: Ball in active_balls:
		ball.force_recover(&"test")
	for frame: int in 8:
		await process_frame
	assert(controller.get_launcher_preview_definitions().size() == 2, "An add-ball reward must permanently increase the next classic batch inventory.")
	controller.request_launch(Vector2.DOWN)
	var normal_ball: Ball = manager.get_active_balls(2)[0]
	assert(normal_ball.definition.type == BallDefinition.Type.NORMAL, "The normal-ball branch requires a normal source ball.")
	controller._on_reward_collected(RewardBlock.Type.ENLARGE_BALL, normal_ball, normal_ball.global_position)
	assert(normal_ball.definition.type == BallDefinition.Type.HEAVY, "A normal ball must become heavy when it collects an enlarge reward.")
	var active_count_before_heavy_reward: int = manager.get_active_ball_count()
	controller._on_reward_collected(RewardBlock.Type.ENLARGE_BALL, normal_ball, normal_ball.global_position)
	assert(manager.get_active_ball_count() == active_count_before_heavy_reward + 1, "A heavy ball must create an additional heavy gravity-drop ball when it collects an enlarge reward.")
	for ball: Ball in manager.get_active_balls(2):
		ball.force_recover(&"test")
	print("T3 reward-block test passed: generation replacement, no-bounce collection, permanent inventory, enlarge, and heavy duplication verified.")
	quit(0)

func _verify_reward_generation() -> void:
	var config: GameConfig = GameConfig.new()
	config.reward_start_wave = 3
	config.add_ball_reward_probability = 1.0
	config.enlarge_ball_reward_probability = 0.0
	var layout: BoardLayout = BoardLayout.new()
	layout.configure(config)
	var generator: WaveGenerator = WaveGenerator.new()
	generator.reset(9)
	for early_wave_index: int in 2:
		for entry: WaveEntry in generator.generate_bottom_row(layout, config, 1, early_wave_index + 1):
			assert(entry.content == WaveEntry.Content.OBSTACLE, "The first two generated rows must not contain rewards.")
	for entry: WaveEntry in generator.generate_bottom_row(layout, config, 1, 3):
		assert(entry.content == WaveEntry.Content.ADD_BALL_REWARD, "Add-ball probability must control reward replacement independently.")
	config.add_ball_reward_probability = 0.0
	config.enlarge_ball_reward_probability = 1.0
	generator.reset(9)
	for entry: WaveEntry in generator.generate_bottom_row(layout, config, 1, 3):
		assert(entry.content == WaveEntry.Content.ENLARGE_BALL_REWARD, "Enlarge probability must control reward replacement independently.")

func _get_first_reward(board: BoardController) -> RewardBlock:
	for child: Node in board.obstacle_layer.get_children():
		if child is RewardBlock:
			return child as RewardBlock
	return null
