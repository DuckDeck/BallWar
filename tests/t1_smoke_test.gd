# covers: [T1-MAN-01, T1-MAN-02, T1-MAN-03, T1-MAN-04, T1-MAN-05]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const MAX_PHYSICS_FRAMES_PER_TURN: int = 600
const MAX_PHYSICS_FRAMES_FOR_REFLECTION: int = 180

var _completed_rounds: int = 0
var _score: int = 0
var _damage_events: int = 0

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	var obstacle_layer: Node2D = main.get_node("ObstacleLayer") as Node2D
	var initial_obstacle: Obstacle = obstacle_layer.get_child(0) as Obstacle
	assert(ball_layer.get_child_count() == 0, "Initial scene must not contain an active ball.")
	assert(obstacle_layer.get_child_count() == 1, "Initial scene must contain one obstacle.")
	assert(initial_obstacle._health == 3, "Initial obstacle health must be 3.")
	assert((main.get_node("CanvasLayer/ScoreLabel") as Label).text == "Score: 0", "Initial Score must be 0.")
	controller.state_changed.connect(_on_state_changed)
	controller.score_changed.connect(_on_score_changed)
	initial_obstacle.damaged.connect(_on_obstacle_damaged)
	var gravity_probe: Ball = BALL_SCENE.instantiate() as Ball
	gravity_probe.config = controller.config
	ball_layer.add_child(gravity_probe)
	gravity_probe.global_position = Vector2(540.0, 800.0)
	gravity_probe.launch(Vector2.UP)
	var initial_upward_velocity: float = gravity_probe.velocity.y
	var gravity_applied: bool = false
	var gravity_frames: int = 0
	while not gravity_applied and gravity_frames < 5:
		await physics_frame
		gravity_applied = gravity_probe.velocity.y > initial_upward_velocity
		gravity_frames += 1
	assert(gravity_applied, "Gravity must reduce upward speed every physics frame.")
	gravity_frames = 0
	while gravity_probe.velocity.y <= 0.0 and gravity_frames < 60:
		await physics_frame
		gravity_frames += 1
	assert(gravity_probe.velocity.y > 0.0, "Gravity must turn an upward ball into a falling ball.")
	gravity_probe.queue_free()
	await process_frame
	# 本回归用受控重力确保斜向球会先命中侧墙；不改项目资源中的用户调参值。
	controller.config.ball_gravity = 1400.0
	controller.config.ball_max_lifetime = 1.2
	_simulate_playfield_launch(launcher, Vector2(180.0, 180.0))
	var reflected_from_side_wall: bool = false
	var reflection_frames: int = 0
	while not reflected_from_side_wall and reflection_frames < MAX_PHYSICS_FRAMES_FOR_REFLECTION:
		await physics_frame
		if ball_layer.get_child_count() > 0:
			var angled_ball: Ball = ball_layer.get_child(0) as Ball
			if angled_ball.velocity.x < 0.0:
				reflected_from_side_wall = true
		reflection_frames += 1
	assert(reflected_from_side_wall, "Angled launch did not reflect from a side wall in time.")
	var initial_round_frames: int = 0
	while _completed_rounds < 1 and initial_round_frames < MAX_PHYSICS_FRAMES_PER_TURN:
		await physics_frame
		initial_round_frames += 1
	assert(_completed_rounds == 1, "First round did not return to READY in time.")
	for turn_index: int in 3:
		_simulate_playfield_launch(launcher, Vector2(0.0, 180.0))
		var target_rounds: int = turn_index + 2
		var frames_waited: int = 0
		while _completed_rounds < target_rounds and frames_waited < MAX_PHYSICS_FRAMES_PER_TURN:
			await physics_frame
			frames_waited += 1
		assert(_completed_rounds == target_rounds, "Round did not return to READY in time.")
	assert(_damage_events == 3, "Three centered launches must apply exactly three obstacle hits.")
	assert(_score == 10, "Three centered launches must destroy one health-3 obstacle and award 10 points.")
	print("T1 smoke test passed: three rounds completed, obstacle cleared, score is 10.")
	quit(0)

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
