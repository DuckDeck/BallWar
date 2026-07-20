# covers: [T1-MAN-05, T1-MAN-06]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const MAX_GRAVITY_FRAMES: int = 60
const MAX_LAUNCHER_READY_FRAMES: int = 180

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var controller: GameController = main.get_node("GameController") as GameController
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	var launcher_frames: int = 0
	while not launcher.is_launch_ready() and launcher_frames < MAX_LAUNCHER_READY_FRAMES:
		await physics_frame
		launcher_frames += 1
	assert(launcher.is_launch_ready(), "A waiting ball must be visible at the roof gap while the round is READY.")
	if launcher.global_position != controller.config.launcher_position:
		push_error("Launcher visual and ball spawn positions must stay aligned.")
		quit(1)
		return
	var launch_probe: Ball = BALL_SCENE.instantiate() as Ball
	launch_probe.config = controller.config
	ball_layer.add_child(launch_probe)
	launch_probe.global_position = controller.config.launcher_position
	launch_probe.launch(Vector2.DOWN)
	var launch_origin_y: float = launch_probe.global_position.y
	var entered_playfield: bool = false
	var launch_frames: int = 0
	while not entered_playfield and launch_frames < 3:
		await physics_frame
		entered_playfield = launch_probe.global_position.y > launch_origin_y
		launch_frames += 1
	if not entered_playfield:
		push_error("A ball launched from the roof gap must enter the playfield without an immediate roof collision.")
		quit(1)
		return
	launch_probe.queue_free()
	await process_frame
	var gravity_probe: Ball = BALL_SCENE.instantiate() as Ball
	gravity_probe.config = controller.config
	ball_layer.add_child(gravity_probe)
	gravity_probe.global_position = Vector2(140.0, 800.0)
	gravity_probe.launch(Vector2.LEFT)
	var gravity_enabled: bool = false
	var gravity_frames: int = 0
	while not gravity_enabled and gravity_frames < 10:
		await physics_frame
		gravity_enabled = gravity_probe.runtime_state.is_gravity_enabled
		if not gravity_enabled:
			assert(is_zero_approx(gravity_probe.velocity.y), "Before its first collision, a ball must follow the exact aim direction without gravity.")
		gravity_frames += 1
	assert(gravity_enabled, "A wall collision must enable gravity for that ball.")
	var velocity_after_first_collision: float = gravity_probe.velocity.y
	await physics_frame
	assert(gravity_probe.velocity.y > velocity_after_first_collision, "Gravity must affect the ball starting on the physics frame after its first collision.")
	var trail: Line2D = gravity_probe.get_node_or_null("MotionTrail") as Line2D
	if trail == null:
		push_error("An active ball must create a Line2D trail renderer.")
		quit(1)
		return
	var trail_frames: int = 0
	while trail.get_point_count() < 2 and trail_frames < 3:
		await physics_frame
		trail_frames += 1
	if trail.get_point_count() < 2:
		push_error("The trail renderer must retain the ball's recent movement points.")
		quit(1)
		return
	gravity_frames = 0
	while gravity_probe.velocity.y <= 0.0 and gravity_frames < MAX_GRAVITY_FRAMES:
		await physics_frame
		gravity_frames += 1
	assert(gravity_probe.velocity.y > 0.0, "Gravity must pull a post-collision ball downward.")
	print("T1 gravity test passed: first-flight aim is straight and post-collision gravity is active.")
	quit(0)
