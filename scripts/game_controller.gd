class_name GameController
extends Node

signal score_changed(score: int)
signal turn_changed(turn: int)
signal state_changed(state: int)
signal elapsed_time_changed(elapsed_seconds: int)
signal game_over(final_score: int, reached_turn: int)
signal launcher_preview_changed(definitions: Array[BallDefinition])

enum State {
	READY,
	BALLS_ACTIVE,
	RESOLVING,
	GAME_OVER,
}

@export var config: GameConfig
@export var ball_manager: BallManager
@export var board_controller: BoardController

var _score: int = 0
var _turn: int = 1
var _state: State = State.READY
var _elapsed_time: float = 0.0
var _displayed_elapsed_seconds: int = 0
var _next_batch_id: int = 1

func _ready() -> void:
	assert(config != null, "GameController requires a GameConfig resource.")
	assert(ball_manager != null, "GameController requires a BallManager.")
	assert(board_controller != null, "GameController requires a BoardController.")
	ball_manager.batch_finished.connect(_on_batch_finished)
	ball_manager.launch_queue_changed.connect(_on_launch_queue_changed)
	board_controller.obstacle_destroyed.connect(_on_obstacle_destroyed)
	board_controller.game_over_requested.connect(_on_board_game_over_requested)
	board_controller.initialize_board()
	score_changed.emit(_score)
	turn_changed.emit(_turn)
	state_changed.emit(_state)
	_publish_launcher_preview()

func _process(delta: float) -> void:
	if _state == State.GAME_OVER:
		return
	_elapsed_time += delta
	var elapsed_seconds: int = int(_elapsed_time)
	if elapsed_seconds == _displayed_elapsed_seconds:
		return
	_displayed_elapsed_seconds = elapsed_seconds
	elapsed_time_changed.emit(_displayed_elapsed_seconds)

func get_elapsed_seconds() -> int:
	return _displayed_elapsed_seconds

func request_launch(direction: Vector2) -> void:
	if _state != State.READY or direction.length_squared() <= 0.0:
		return
	var batch: BallBatch = BallBatch.new(_next_batch_id, _build_ball_definitions(), config.launch_spread_degrees)
	_next_batch_id += 1
	ball_manager.launch_batch(batch, config.launcher_position, direction)
	_set_state(State.BALLS_ACTIVE)

func get_state() -> State:
	return _state

func get_score() -> int:
	return _score

func get_launcher_preview_definitions() -> Array[BallDefinition]:
	return _build_ball_definitions()

func _build_ball_definitions() -> Array[BallDefinition]:
	var definitions: Array[BallDefinition] = []
	var ball_count: int = board_controller.get_next_ball_count()
	for ball_index: int in ball_count:
		var definition: BallDefinition = BallDefinition.new()
		definition.visual_color = config.ball_palette[ball_index % config.ball_palette.size()]
		definitions.append(definition)
	return definitions

func _on_obstacle_destroyed(points: int) -> void:
	_score += points
	score_changed.emit(_score)

func _on_batch_finished(batch_id: int) -> void:
	if _state != State.BALLS_ACTIVE:
		return
	_set_state(State.RESOLVING)
	call_deferred("_resolve_completed_batch", batch_id)

func _resolve_completed_batch(batch_id: int) -> void:
	var is_safe_turn: bool = board_controller.resolve_completed_batch(batch_id)
	if not is_safe_turn:
		return
	_turn += 1
	turn_changed.emit(_turn)
	_publish_launcher_preview()
	_set_state(State.READY)

func _on_launch_queue_changed(queued_definitions: Array[BallDefinition]) -> void:
	launcher_preview_changed.emit(queued_definitions)

func _publish_launcher_preview() -> void:
	launcher_preview_changed.emit(_build_ball_definitions())

func _on_board_game_over_requested() -> void:
	if _state == State.GAME_OVER:
		return
	_set_state(State.GAME_OVER)
	game_over.emit(_score, _turn)

func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(_state)
