# covers: [T4-GO-AUTO-04, T4-GO-AUTO-05, T4-GO-AUTO-06, T4-GO-AUTO-07]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	var main: Main = MAIN_SCENE.instantiate() as Main
	root.add_child(main)
	await process_frame
	var controller: GameController = main.get_node("GameController") as GameController
	var board: BoardController = main.get_node("BoardController") as BoardController
	var panel: Control = main.get_node("CanvasLayer/GameOverPanel") as Control
	var mode_selection: Control = main.get_node("CanvasLayer/ModeSelection") as Control
	var arena: Node2D = main.get_node("ArenaRenderer") as Node2D
	var share_button: Button = panel.get_node("ShareButton") as Button
	var score_value: Label = panel.get_node("ScoreValue") as Label
	var return_caption: Label = panel.get_node("ReturnCaption") as Label
	main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	await physics_frame
	board.game_over_requested.emit()
	assert(paused and controller.get_state() == GameController.State.GAME_OVER, "Game over must freeze the scene through GAME_OVER and SceneTree.paused.")
	assert(panel.visible and share_button.disabled, "The game-over card must be visible and its share action must be disabled.")
	assert(score_value.text == "0", "The game-over card must show the final score.")
	assert(not share_button.flat, "Each bottom action must retain its configured circular background.")
	assert(return_caption.get_parent() == panel and return_caption.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Action captions must be independent, centered labels below their icons.")
	panel.emit_signal(&"restart_requested")
	await process_frame
	assert(not paused and controller.get_state() == GameController.State.READY, "Restart from game over must start a fresh same-mode game.")
	assert(controller.get_active_mode() == GameModeDefinition.Mode.CLASSIC and not panel.visible, "Restart must preserve the mode and hide the result card.")
	board.game_over_requested.emit()
	assert(paused and panel.visible, "A later terminal event must show the result card again.")
	panel.emit_signal(&"menu_requested")
	await process_frame
	assert(not paused and controller.get_state() == GameController.State.MODE_SELECTION, "Returning must leave the terminal state and restore mode selection.")
	assert(mode_selection.visible and not arena.visible, "Returning must show the startup mode selection instead of the gameplay scene.")
	print("T4 game-over test passed: result card, same-mode restart, and mode return verified.")
	quit(0)
