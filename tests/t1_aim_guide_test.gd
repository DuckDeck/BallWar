# covers: [T1-MAN-07]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await physics_frame
	var launcher: Launcher = main.get_node("Launcher") as Launcher
	var guide_segments: Array[PackedVector2Array] = launcher.get_aim_guide_segments(Vector2(1.0, 0.2))
	assert(guide_segments.size() == 2, "A guide aimed at the side wall must include one reflection segment.")
	var primary_segment: PackedVector2Array = guide_segments[0]
	var reflected_segment: PackedVector2Array = guide_segments[1]
	assert(primary_segment[0] == launcher.global_position, "The guide must start at the launch origin.")
	var expected_contact_center_x: float = launcher.config.arena_right - launcher.config.ball_radius
	assert(absf(primary_segment[1].x - expected_contact_center_x) < 1.0, "The guide must stop where the real ball center reaches the first wall.")
	assert(is_equal_approx(reflected_segment[0].x, primary_segment[1].x), "The reflection must begin at the first hit point.")
	assert(reflected_segment[1].x < reflected_segment[0].x, "A right-wall reflection must point back into the arena.")
	assert(is_equal_approx(reflected_segment[0].distance_to(reflected_segment[1]), launcher.config.aim_guide_reflection_length), "The reflection must use the configured short length.")
	print("T1 aim guide test passed: first hit and one short reflection are predicted.")
	quit(0)
