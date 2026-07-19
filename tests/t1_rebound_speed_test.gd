# covers: [T1-MAN-08]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const OBSTACLE_SCENE: PackedScene = preload("res://scenes/obstacle.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var controller: GameController = main.get_node("GameController") as GameController
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	var obstacle_layer: Node2D = main.get_node("ObstacleLayer") as Node2D
	var obstacle: Obstacle = OBSTACLE_SCENE.instantiate() as Obstacle
	obstacle.config = controller.config
	obstacle.global_position = Vector2(700.0, 800.0)
	obstacle.configure(99, 0)
	obstacle_layer.add_child(obstacle)
	await physics_frame
	var ball: Ball = BALL_SCENE.instantiate() as Ball
	ball.config = controller.config
	ball.global_position = Vector2(600.0, 800.0)
	ball_layer.add_child(ball)
	ball.launch(Vector2.RIGHT)
	ball.velocity = Vector2(controller.config.ball_max_rebound_speed * 2.0, 0.0)
	ball.runtime_state.velocity = ball.velocity
	var frames_waited: int = 0
	while not ball.runtime_state.is_gravity_enabled and frames_waited < 12:
		await physics_frame
		frames_waited += 1
	assert(ball.runtime_state.is_gravity_enabled, "The probe ball must collide with the obstacle.")
	assert(ball.velocity.length() <= controller.config.ball_max_rebound_speed + 0.01, "A rebound must be capped so successive obstacle multipliers cannot stack.")
	assert(ball.velocity.x < 0.0, "The obstacle collision must still reverse the horizontal direction.")
	print("T1 rebound speed test passed: enhanced obstacle rebound is capped after collision.")
	quit(0)
