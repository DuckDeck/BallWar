# covers: [T3-AUTO-04]
extends SceneTree

const OBSTACLE_SCENE: PackedScene = preload("res://scenes/obstacle.tscn")

func _initialize() -> void:
	var config: GameConfig = GameConfig.new()
	config.design_size = Vector2(1080.0, 1920.0)
	config.board_columns = 7
	config.board_cell_size = Vector2(120.0, 120.0)
	config.wave_min_blocks = 6
	config.wave_max_blocks = 6
	config.wave_health_min_ball_multiplier = 1
	config.wave_health_max_ball_multiplier = 2
	config.add_ball_reward_probability = 0.0
	config.enlarge_ball_reward_probability = 0.0
	var layout: BoardLayout = BoardLayout.new()
	layout.configure(config)
	var generator: WaveGenerator = WaveGenerator.new()
	generator.reset(20260720)
	var observed_shapes: Dictionary = {}
	for wave_index: int in 24:
		var entries: Array[WaveEntry] = generator.generate_bottom_row(layout, config, 4)
		assert(entries.size() == 6, "The configured wave must create six obstacles.")
		var healths_in_wave: Dictionary = {}
		for entry: WaveEntry in entries:
			assert(entry.health >= 4 and entry.health <= 8, "Obstacle health must be between one and two times the next ball count.")
			healths_in_wave[entry.health] = true
			assert(entry.shape_type >= Obstacle.Shape.HEXAGON and entry.shape_type <= Obstacle.Shape.DIAMOND, "Every generated obstacle must use a supported shape.")
			assert(entry.rotation_degrees >= 0.0 and entry.rotation_degrees < 360.0, "Every obstacle must receive a center rotation in [0, 360).")
			observed_shapes[entry.shape_type] = true
		assert(healths_in_wave.size() >= 2, "A row must not give every obstacle the same number when its range permits variety.")
	assert(observed_shapes.size() == Obstacle.Shape.size(), "The seeded generator must be able to produce all six obstacle shapes.")
	for shape_type: int in Obstacle.Shape.size():
		var obstacle: Obstacle = OBSTACLE_SCENE.instantiate() as Obstacle
		obstacle.config = config
		root.add_child(obstacle)
		obstacle.configure(4, 10, shape_type, 47.0)
		assert(obstacle.shape_type == shape_type, "Obstacle must retain the generated shape type.")
		assert(is_equal_approx(obstacle.rotation_degrees, 47.0), "Obstacle must rotate around its center by the generated angle.")
		var collision_shape: CollisionShape2D = obstacle.get_node("CollisionShape2D") as CollisionShape2D
		if shape_type == Obstacle.Shape.CIRCLE:
			assert(collision_shape.shape is CircleShape2D, "Circle obstacles require circle collision geometry.")
		else:
			assert(collision_shape.shape is ConvexPolygonShape2D, "Polygon obstacles require matching convex collision geometry.")
		obstacle.queue_free()
	await process_frame
	print("T3 obstacle variety test passed: shapes, rotations, collision geometry, and ball-scaled health verified.")
	quit(0)
