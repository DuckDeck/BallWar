# covers: [T4-AUTO-05]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SESSION_PATH: String = "user://t4_progress_dialog_test.cfg"

func _initialize() -> void:
	var store: GameSessionStore = GameSessionStore.new(TEST_SESSION_PATH)
	store.clear_session(GameModeDefinition.Mode.CLASSIC)
	store.clear_session(GameModeDefinition.Mode.CHALLENGE)
	var snapshot: Dictionary = await _create_classic_snapshot()
	snapshot["score"] = 43
	assert(store.save_session(GameModeDefinition.Mode.CLASSIC, snapshot), "The progress dialog test needs a classic saved session.")

	var continue_main: Main = _create_main()
	await process_frame
	var continue_selection: ModeSelection = continue_main.get_node("CanvasLayer/ModeSelection") as ModeSelection
	continue_selection.emit_signal(&"mode_selected", GameModeDefinition.Mode.CLASSIC)
	await process_frame
	var continue_dialog: Control = continue_main.get_node("CanvasLayer/ProgressDialog") as Control
	assert(continue_dialog.visible, "Selecting a mode with saved progress must open the confirmation dialog.")
	assert((continue_dialog.get_node("ProgressMessage") as Label).text == "上次玩到43，是否继续？", "The dialog must show the raw saved score without zero padding.")
	(continue_dialog.get_node("ContinueButton") as Button).pressed.emit()
	await physics_frame
	var continued_controller: GameController = continue_main.get_node("GameController") as GameController
	assert(not continue_dialog.visible and continued_controller.get_state() == GameController.State.READY, "Continue must restore the saved game into the ready state.")
	assert(continued_controller.get_score() == 43, "Continue must restore the saved score.")
	continue_main.queue_free()
	await process_frame

	var discard_main: Main = _create_main()
	await process_frame
	(discard_main.get_node("CanvasLayer/ModeSelection") as ModeSelection).emit_signal(&"mode_selected", GameModeDefinition.Mode.CLASSIC)
	await process_frame
	var discard_dialog: Control = discard_main.get_node("CanvasLayer/ProgressDialog") as Control
	(discard_dialog.get_node("DiscardButton") as Button).pressed.emit()
	await physics_frame
	var discarded_controller: GameController = discard_main.get_node("GameController") as GameController
	assert(not discard_dialog.visible and discarded_controller.get_state() == GameController.State.READY, "Discard must close the dialog and begin a new game.")
	assert(discarded_controller.get_score() == 0, "Discard must not retain the old saved score.")
	assert(not store.has_session(GameModeDefinition.Mode.CLASSIC) or int(store.load_session(GameModeDefinition.Mode.CLASSIC).get("score", -1)) == 0, "Discard must replace the old session with the new game's checkpoint only.")
	store.clear_session(GameModeDefinition.Mode.CLASSIC)
	store.clear_session(GameModeDefinition.Mode.CHALLENGE)
	print("T4 progress dialog test passed: saved score, continue, and discard paths verified.")
	quit(0)

func _create_classic_snapshot() -> Dictionary:
	var source_main: Main = _create_main()
	await process_frame
	source_main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	await physics_frame
	var controller: GameController = source_main.get_node("GameController") as GameController
	var snapshot: Dictionary = controller.get_session_snapshot()
	source_main.queue_free()
	await process_frame
	return snapshot

func _create_main() -> Main:
	var main: Main = MAIN_SCENE.instantiate() as Main
	main.session_store_path = TEST_SESSION_PATH
	root.add_child(main)
	return main
