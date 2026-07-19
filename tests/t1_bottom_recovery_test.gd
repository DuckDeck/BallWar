# covers: [T1-MAN-07]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const MAX_RECOVERY_FRAMES: int = 480

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	if not await _verify_bottom_recovery(controller.config, ball_layer, -1.0):
		quit(1)
		return
	if not await _verify_bottom_recovery(controller.config, ball_layer, 1.0):
		quit(1)
		return
	if not await _verify_controller_round(controller, ball_layer, main.get_node("Launcher") as Launcher):
		quit(1)
		return
	print("T1 bottom recovery test passed: both landing sides return through the roof gap.")
	quit(0)

func _verify_bottom_recovery(config: GameConfig, ball_layer: Node2D, side: float) -> bool:
	var ball: Ball = BALL_SCENE.instantiate() as Ball
	ball.config = config
	ball_layer.add_child(ball)
	var center_x: float = (config.arena_left + config.arena_right) * 0.5
	var landing_x: float = center_x + side * 140.0
	ball.global_position = Vector2(landing_x, config.get_bottom_trough_y(landing_x) - config.ball_radius - 1.0)
	ball.launch(Vector2.DOWN)
	var rolling_seen: bool = false
	var lifting_seen: bool = false
	var roof_return_seen: bool = false
	var furthest_roll_x: float = landing_x
	var frame_count: int = 0
	while not ball.has_recovered() and frame_count < MAX_RECOVERY_FRAMES:
		await physics_frame
		match ball.get_motion_state():
			Ball.MotionState.ROLLING:
				rolling_seen = true
				if side < 0.0:
					furthest_roll_x = minf(furthest_roll_x, ball.global_position.x)
				else:
					furthest_roll_x = maxf(furthest_roll_x, ball.global_position.x)
			Ball.MotionState.LIFTING:
				lifting_seen = true
			Ball.MotionState.ROOF_RETURN:
				roof_return_seen = true
		frame_count += 1
	if not ball.has_recovered():
		push_error("Bottom recovery did not complete in time for side %s. state=%s position=%s" % [side, ball.get_motion_state(), ball.global_position])
		return false
	if not rolling_seen or not lifting_seen or not roof_return_seen:
		push_error("Bottom recovery must visit ROLLING, LIFTING, and ROOF_RETURN for side %s." % side)
		return false
	if side < 0.0 and furthest_roll_x >= landing_x:
		push_error("A left-side landing must roll left before leaving the arena.")
		return false
	if side > 0.0 and furthest_roll_x <= landing_x:
		push_error("A right-side landing must roll right before leaving the arena.")
		return false
	if ball.get_recovery_reason() != &"bottom_trough":
		push_error("Bottom recovery must use the bottom_trough completion reason.")
		return false
	if ball.global_position.distance_to(config.launcher_position) > 0.1:
		push_error("The active ball must physically reach the roof-gap launcher before recovery.")
		return false
	ball.queue_free()
	await process_frame
	return true

func _verify_controller_round(controller: GameController, ball_layer: Node2D, launcher: Launcher) -> bool:
	controller.request_launch(Vector2.DOWN)
	var frame_count: int = 0
	while not launcher.is_launch_ready() and frame_count < MAX_RECOVERY_FRAMES:
		await physics_frame
		frame_count += 1
	if not launcher.is_launch_ready() or ball_layer.get_child_count() != 0:
		push_error("A recovered ball must return GameController to READY and remove the active ball.")
		return false
	return true
