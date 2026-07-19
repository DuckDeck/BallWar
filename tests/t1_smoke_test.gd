# covers: [T1-MAN-01, T1-MAN-02, T1-MAN-03, T1-MAN-04, T1-MAN-05]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const MAX_PHYSICS_FRAMES_PER_TURN: int = 600

var _completed_rounds: int = 0
var _score: int = 0
var _damage_events: int = 0

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var controller: GameController = main.get_node("GameController") as GameController
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	var obstacle_layer: Node2D = main.get_node("ObstacleLayer") as Node2D
	var initial_obstacle: Obstacle = obstacle_layer.get_child(0) as Obstacle
	assert(ball_layer.get_child_count() == 0, "Initial scene must not contain an active ball.")
	assert(obstacle_layer.get_child_count() >= 1, "Initial scene must contain a generated bottom row.")
	assert((main.get_node("CanvasLayer/ScoreLabel") as Label).text == "Score: 0", "Initial Score must be 0.")
	controller.state_changed.connect(_on_state_changed)
	controller.score_changed.connect(_on_score_changed)
	initial_obstacle.damaged.connect(_on_obstacle_damaged)
	await _verify_initial_flight(controller, ball_layer)
	var no_damage_context: HitContext = HitContext.new()
	no_damage_context.damage = 0
	var bounce_result: HitResult = initial_obstacle.receive_hit(no_damage_context)
	assert(is_equal_approx(bounce_result.bounce_multiplier, 1.36), "Obstacle rebound speed must be doubled to 1.36.")
	initial_obstacle.configure(3, controller.config.score_per_obstacle)
	for hit_index: int in 3:
		var context: HitContext = HitContext.new()
		context.damage = 1
		initial_obstacle.receive_hit(context)
	assert(_damage_events == 3, "Three valid hits must apply exactly three obstacle damage events.")
	assert(_score == 10, "Destroying one health-3 obstacle must award ten points exactly once.")
	controller.config.initial_ball_count = 1
	controller.config.maximum_ball_count = 1
	controller.config.ball_gravity = 1400.0
	controller.config.ball_max_lifetime = 1.2
	for turn_index: int in 3:
		_simulate_playfield_launch(launcher, Vector2(180.0, 180.0))
		var target_rounds: int = turn_index + 1
		var frames_waited: int = 0
		while _completed_rounds < target_rounds and frames_waited < MAX_PHYSICS_FRAMES_PER_TURN:
			await physics_frame
			frames_waited += 1
		assert(_completed_rounds == target_rounds, "A single-ball batch must return to READY in time.")
	print("T1 smoke test passed: straight initial flight, unified hit scoring, and three single-ball rounds verified.")
	quit(0)

func _verify_initial_flight(controller: GameController, ball_layer: Node2D) -> void:
	var gravity_probe: Ball = BALL_SCENE.instantiate() as Ball
	gravity_probe.config = controller.config
	ball_layer.add_child(gravity_probe)
	gravity_probe.global_position = Vector2(540.0, 800.0)
	gravity_probe.launch(Vector2.UP)
	var initial_upward_velocity: float = gravity_probe.velocity.y
	var flight_frames: int = 0
	while flight_frames < 5:
		await physics_frame
		assert(not gravity_probe.runtime_state.is_gravity_enabled, "Gravity must stay disabled before the first world collision.")
		assert(is_equal_approx(gravity_probe.velocity.y, initial_upward_velocity), "The initial flight must preserve the exact aim velocity.")
		flight_frames += 1
	gravity_probe.queue_free()
	await process_frame

func _simulate_playfield_launch(launcher: Launcher, target_offset: Vector2) -> void:
	var press_event: InputEventMouseButton = InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.position = launcher.global_position + target_offset
	launcher._unhandled_input(press_event)
	var release_event: InputEventMouseButton = InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = press_event.position
	launcher._unhandled_input(release_event)

func _on_state_changed(state: int) -> void:
	if state == GameController.State.READY:
		_completed_rounds += 1

func _on_score_changed(score: int) -> void:
	_score = score

func _on_obstacle_damaged(_remaining_health: int) -> void:
	_damage_events += 1
