# covers: [T1-MAN-08]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	var controller: GameController = main.get_node("GameController") as GameController
	var time_label: Label = main.get_node("CanvasLayer/TimeLabel") as Label
	assert(time_label.text == "Time: 00:00", "The timer must start at 00:00 when the main scene starts.")
	controller._process(65.0)
	assert(controller.get_elapsed_seconds() == 65, "The controller must accumulate elapsed seconds.")
	assert(time_label.text == "Time: 01:05", "The HUD must format elapsed time as mm:ss.")
	print("T1 timer test passed: the HUD starts at 00:00 and advances to 01:05.")
	quit(0)
