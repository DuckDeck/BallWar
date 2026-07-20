# covers: [T1-MAN-07]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const OBSTACLE_SCENE: PackedScene = preload("res://scenes/obstacle.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await physics_frame
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	var ball_layer: Node2D = main.get_node("BallLayer") as Node2D
	var obstacle_layer: Node2D = main.get_node("ObstacleLayer") as Node2D
	var guide_segments: Array[PackedVector2Array] = launcher.get_aim_guide_segments(Vector2(1.0, 0.2))
	assert(guide_segments.size() == 2, "A guide aimed at the side wall must include one reflection segment.")
	var primary_segment: PackedVector2Array = guide_segments[0]
	var reflected_segment: PackedVector2Array = guide_segments[1]
	assert(primary_segment[0] == launcher.global_position, "The guide must start at the launch origin.")
	var expected_contact_center_x: float = launcher.config.arena_right - launcher.config.ball_radius
	assert(primary_segment[1].x < expected_contact_center_x and primary_segment[1].x > expected_contact_center_x - launcher.config.ball_radius * 0.5, "The guide must stop at the swept ball's first safe contact position.")
	assert(is_equal_approx(reflected_segment[0].x, primary_segment[1].x), "The reflection must begin at the first hit point.")
	assert(reflected_segment[1].x < reflected_segment[0].x, "A right-wall reflection must point back into the arena.")
	assert(is_equal_approx(reflected_segment[0].distance_to(reflected_segment[1]), launcher.config.aim_guide_reflection_length), "The reflection must use the configured short length.")
	var ball: Ball = BALL_SCENE.instantiate() as Ball
	ball.config = launcher.config
	ball_layer.add_child(ball)
	ball.global_position = launcher.global_position
	ball.launch(Vector2(1.0, 0.2))
	var collision_frames: int = 0
	while not ball.runtime_state.is_gravity_enabled and collision_frames < 60:
		await physics_frame
		collision_frames += 1
	assert(ball.runtime_state.is_gravity_enabled, "The launched ball must reach the predicted side-wall collision.")
	var predicted_reflection: Vector2 = (reflected_segment[1] - reflected_segment[0]).normalized()
	assert(ball.velocity.normalized().dot(predicted_reflection) > 0.999, "The guide reflection angle must match the real ball rebound angle.")
	ball.queue_free()
	var obstacle: Obstacle = OBSTACLE_SCENE.instantiate() as Obstacle
	obstacle.config = launcher.config
	obstacle_layer.add_child(obstacle)
	obstacle.global_position = launcher.global_position + Vector2(0.0, 360.0)
	obstacle.configure(1, 0, Obstacle.Shape.CIRCLE)
	await physics_frame
	var obstacle_segments: Array[PackedVector2Array] = launcher.get_aim_guide_segments(Vector2.DOWN)
	assert(obstacle_segments.size() == 2, "A guide aimed at an obstacle must include one reflection segment.")
	var obstacle_primary: PackedVector2Array = obstacle_segments[0]
	var obstacle_reflection: PackedVector2Array = obstacle_segments[1]
	var expected_contact_center_y: float = obstacle.global_position.y - Obstacle.SHAPE_RADIUS - launcher.config.ball_radius
	assert(obstacle_primary[1].y < expected_contact_center_y and obstacle_primary[1].y > expected_contact_center_y - launcher.config.ball_radius * 0.5, "The guide must stop at the swept ball's first safe obstacle contact position.")
	assert(obstacle_reflection[1].y < obstacle_reflection[0].y, "An obstacle reflection must point away from the obstacle.")
	obstacle.queue_free()
	print("T1 aim guide test passed: first hit and one short reflection are predicted.")
	quit(0)
