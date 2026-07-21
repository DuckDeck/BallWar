# covers: [T4-AUTO-04]
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TEST_SESSION_PATH: String = "user://t4_session_restore_test.cfg"

func _initialize() -> void:
	var classic_main: Main = _create_main()
	classic_main.start_game_by_mode_id(GameModeDefinition.Mode.CLASSIC)
	await physics_frame
	var classic_controller: GameController = classic_main.get_node("GameController") as GameController
	var classic_snapshot: Dictionary = classic_controller.get_session_snapshot()
	assert(not classic_snapshot.is_empty(), "Classic mode must produce a stable ready-turn checkpoint.")
	classic_controller.request_launch(Vector2.DOWN)
	await physics_frame
	assert(classic_controller.restore_session(classic_snapshot) == false, "A live controller must not replace an in-progress turn directly.")
	classic_main.queue_free()
	await process_frame
	var restored_classic_main: Main = _create_main()
	var classic_store: GameSessionStore = GameSessionStore.new(TEST_SESSION_PATH)
	assert(classic_store.save_session(GameModeDefinition.Mode.CLASSIC, classic_snapshot), "Classic checkpoint must persist to its own section.")
	assert(restored_classic_main.get_node("GameController").restore_session(classic_store.load_session(GameModeDefinition.Mode.CLASSIC)), "Classic checkpoint must restore into a ready state.")
	var restored_classic: GameController = restored_classic_main.get_node("GameController") as GameController
	assert(restored_classic.get_state() == GameController.State.READY and restored_classic.get_score() == int(classic_snapshot.get("score", -1)), "Classic restore must use the previous stable turn state.")
	restored_classic_main.queue_free()
	await process_frame
	var challenge_main: Main = _create_main()
	challenge_main.start_game_by_mode_id(GameModeDefinition.Mode.CHALLENGE)
	await physics_frame
	var challenge_controller: GameController = challenge_main.get_node("GameController") as GameController
	challenge_controller.request_launch(Vector2.DOWN)
	await physics_frame
	var challenge_snapshot: Dictionary = challenge_controller.get_session_snapshot()
	assert(not challenge_snapshot.is_empty(), "Challenge mode must snapshot an active run.")
	challenge_main.queue_free()
	await process_frame
	var restored_challenge_main: Main = _create_main()
	var challenge_store: GameSessionStore = GameSessionStore.new(TEST_SESSION_PATH)
	assert(challenge_store.save_session(GameModeDefinition.Mode.CHALLENGE, challenge_snapshot), "Challenge data must persist independently from classic data.")
	assert(restored_challenge_main.get_node("GameController").restore_session(challenge_store.load_session(GameModeDefinition.Mode.CHALLENGE)), "Challenge snapshot must restore successfully.")
	var restored_challenge: GameController = restored_challenge_main.get_node("GameController") as GameController
	var restored_manager: BallManager = restored_challenge_main.get_node("BallManager") as BallManager
	assert(restored_challenge.get_state() == GameController.State.READY, "Challenge restore must return balls to a ready launcher state.")
	assert(restored_manager.get_active_ball_count() == 0, "Challenge restore must not recreate in-flight physical balls.")
	challenge_store.clear_session(GameModeDefinition.Mode.CLASSIC)
	challenge_store.clear_session(GameModeDefinition.Mode.CHALLENGE)
	print("T4 session restore test passed: separate classic/challenge persistence and safe recovery verified.")
	quit(0)

func _create_main() -> Main:
	var main: Main = MAIN_SCENE.instantiate() as Main
	main.session_store_path = TEST_SESSION_PATH
	root.add_child(main)
	return main
