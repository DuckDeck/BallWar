# covers: [T1-AUTO-03]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAX_RECOVERY_FRAMES: int = 480
const MAX_LAUNCHER_READY_FRAMES: int = 180

var _completed_reason: StringName = &""
var _completed_position: Vector2 = Vector2.ZERO

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var controller: GameController = main.get_node("GameController") as GameController
	var manager: BallManager = main.get_node("BallManager") as BallManager
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	controller.config.initial_ball_count = 1
	controller.config.maximum_ball_count = 1
	controller.config.ball_max_lifetime = 0.01
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	var launcher_frames: int = 0
	while not launcher.is_launch_ready() and launcher_frames < MAX_LAUNCHER_READY_FRAMES:
		await physics_frame
		launcher_frames += 1
	controller.request_launch(Vector2.DOWN)
	var startup_frames: int = 0
	while manager.get_active_ball_count() == 0 and startup_frames < 4:
		await physics_frame
		startup_frames += 1
	assert(controller.get_state() == GameController.State.BALLS_ACTIVE, "A lifetime fallback must not complete the turn immediately.")
	assert(manager.get_active_ball_count() == 1 and ball_layer.get_child_count() == 1, "The fallback ball must remain active while it follows the return path.")
	var ball: Ball = manager.get_active_balls(1)[0]
	ball.recovered.connect(_on_ball_recovered.bind(ball))
	var recovery_start_frames: int = 0
	while ball.get_motion_state() == Ball.MotionState.ACTIVE and recovery_start_frames < 4:
		await physics_frame
		recovery_start_frames += 1
	if ball.get_motion_state() != Ball.MotionState.TIMEOUT_DESCENT:
		push_error("The lifetime fallback must visibly descend toward the trough instead of disappearing.")
		quit(1)
		return
	var descent_start: Vector2 = ball.global_position
	await physics_frame
	var maximum_descent_step: float = controller.config.recovery_timeout_descent_speed / float(Engine.physics_ticks_per_second) + 0.1
	if ball.global_position.distance_to(descent_start) > maximum_descent_step:
		push_error("The lifetime fallback must not snap from mid-air to the trough.")
		quit(1)
		return
	var frames_waited: int = 0
	while controller.get_state() != GameController.State.READY and frames_waited < MAX_RECOVERY_FRAMES:
		await physics_frame
		frames_waited += 1
	if controller.get_state() != GameController.State.READY or manager.get_active_ball_count() != 0 or ball_layer.get_child_count() != 0:
		push_error("The round must resolve only after the return animation completes.")
		quit(1)
		return
	if _completed_reason != &"lifetime_expired" or _completed_position.distance_to(controller.config.get_classic_launcher_staging_position()) > 0.1:
		push_error("A classic-mode ball must reach the closed-launcher staging point and retain its fallback reason before turn resolution. reason=%s position=%s" % [_completed_reason, _completed_position])
		quit(1)
		return
	print("T1 recovery gate test passed: fallback recovery completes at the classic staging point before turn resolution.")
	quit(0)

func _on_ball_recovered(reason: StringName, ball: Ball) -> void:
	_completed_reason = reason
	_completed_position = ball.global_position
