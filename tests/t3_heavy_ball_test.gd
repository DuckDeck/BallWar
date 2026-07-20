# covers: [T3-AUTO-05, L1-MB-12]
extends SceneTree

const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	var config: GameConfig = GameConfig.new()
	config.ball_radius = 15.0
	var heavy_definition: BallDefinition = BallDefinition.new()
	heavy_definition.type = BallDefinition.Type.HEAVY
	heavy_definition.radius_multiplier = 1.30
	heavy_definition.gravity_multiplier = 1.30
	heavy_definition.double_damage_probability = 1.0
	var heavy_ball: Ball = BALL_SCENE.instantiate() as Ball
	heavy_ball.config = config
	heavy_ball.definition = heavy_definition
	root.add_child(heavy_ball)
	await process_frame
	assert(is_equal_approx(heavy_ball.get_effective_radius(), 19.5), "A heavy ball must use a 130% collision and render radius.")
	assert(is_equal_approx(heavy_ball.definition.gravity_multiplier, 1.30), "A heavy ball must retain its configured heavier gravity multiplier.")
	assert(heavy_ball.roll_obstacle_damage() == 2, "A 100% heavy-ball probability must apply two damage on every obstacle hit.")
	heavy_definition.double_damage_probability = 0.0
	assert(heavy_ball.roll_obstacle_damage() == 1, "A 0% heavy-ball probability must keep normal one-point damage.")
	var normal_definition: BallDefinition = BallDefinition.new()
	normal_definition.type = BallDefinition.Type.NORMAL
	normal_definition.double_damage_probability = 1.0
	heavy_ball.definition = normal_definition
	assert(heavy_ball.roll_obstacle_damage() == 1, "Normal balls must never receive the heavy-ball double-damage roll.")
	heavy_ball.queue_free()
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	controller.config.initial_ball_count = 3
	controller.config.heavy_ball_spawn_probability = 1.0
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var starting_definitions: Array[BallDefinition] = controller.get_launcher_preview_definitions()
	assert(starting_definitions.size() == 3, "Fixed opening inventory must keep the configured starting ball count.")
	for definition: BallDefinition in starting_definitions:
		assert(definition.type == BallDefinition.Type.HEAVY, "A 100% spawn probability must create heavy-ball definitions at game start.")
	print("T3 heavy-ball test passed: fixed inventory, 130% radius, gravity, and configurable double damage verified.")
	quit(0)
