# covers: [T1-MAN-05, T1-MAN-06]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const MAX_GRAVITY_FRAMES: int = 60

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
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
	assert(gravity_probe.velocity.y > 0.0, "Gravity must turn an upward ball into a falling ball.")
	print("T1 gravity test passed: upward ball slowed down and fell back.")
	quit(0)
