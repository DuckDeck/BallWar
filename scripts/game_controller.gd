class_name GameController
extends Node

signal score_changed(score: int)
signal turn_changed(turn: int)
signal state_changed(state: int)
signal elapsed_time_changed(elapsed_seconds: int)
signal game_over(final_score: int, reached_turn: int)
signal launcher_preview_changed(definitions: Array[BallDefinition])
signal challenge_wave_remaining_changed(remaining_seconds: int)
signal game_mode_changed(mode: int)

enum State {
	MODE_SELECTION,
	READY,
	BALLS_ACTIVE,
	RESOLVING,
	GAME_OVER,
}

@export var config: GameConfig
@export var ball_manager: BallManager
@export var board_controller: BoardController
@export var challenge_wave_clock: ChallengeWaveClock
@export var classic_mode: GameModeDefinition
@export var challenge_mode: GameModeDefinition

var _score: int = 0
var _turn: int = 1
var _state: State = State.MODE_SELECTION
var _elapsed_time: float = 0.0
var _displayed_elapsed_seconds: int = 0
var _next_batch_id: int = 1
var _active_mode: GameModeDefinition
var _current_ball_count: int = 1
var _classic_safe_turns: int = 0
var _pending_timed_wave: bool = false

func _ready() -> void:
	assert(config != null, "GameController requires a GameConfig resource.")
	assert(ball_manager != null, "GameController requires a BallManager.")
	assert(board_controller != null, "GameController requires a BoardController.")
	assert(challenge_wave_clock != null, "GameController requires a ChallengeWaveClock.")
	assert(classic_mode != null, "GameController requires a classic GameModeDefinition.")
	assert(challenge_mode != null, "GameController requires a challenge GameModeDefinition.")
	ball_manager.batch_finished.connect(_on_batch_finished)
	ball_manager.launch_queue_changed.connect(_on_launch_queue_changed)
	board_controller.obstacle_destroyed.connect(_on_obstacle_destroyed)
	board_controller.game_over_requested.connect(_on_board_game_over_requested)
	challenge_wave_clock.wave_due.connect(_on_challenge_wave_due)
	challenge_wave_clock.remaining_seconds_changed.connect(_on_challenge_wave_remaining_changed)
	score_changed.emit(_score)
	turn_changed.emit(_turn)
	state_changed.emit(_state)

func start_game_by_mode_id(mode: int) -> void:
	if mode == GameModeDefinition.Mode.CHALLENGE:
		start_game(challenge_mode)
		return
	start_game(classic_mode)

func start_game(mode: GameModeDefinition) -> void:
	if _state != State.MODE_SELECTION:
		return
	_active_mode = mode
	_current_ball_count = config.initial_ball_count
	_classic_safe_turns = 0
	_elapsed_time = 0.0
	_displayed_elapsed_seconds = 0
	board_controller.initialize_board(_current_ball_count)
	game_mode_changed.emit(_active_mode.mode)
	if _active_mode.uses_timed_waves():
		challenge_wave_clock.start_clock(_active_mode.timed_wave_interval_seconds)
	_set_state(State.READY)
	_publish_launcher_preview()

func _process(delta: float) -> void:
	if _state == State.MODE_SELECTION or _state == State.GAME_OVER:
		return
	_elapsed_time += delta
	var elapsed_seconds: int = int(_elapsed_time)
	if elapsed_seconds == _displayed_elapsed_seconds:
		return
	_displayed_elapsed_seconds = elapsed_seconds
	elapsed_time_changed.emit(_displayed_elapsed_seconds)

func _physics_process(_delta: float) -> void:
	if not _pending_timed_wave or _state == State.GAME_OVER:
		return
	_pending_timed_wave = false
	_resolve_timed_wave()

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
	if _state == State.MODE_SELECTION:
		return []
	return _build_ball_definitions()

func get_active_mode() -> int:
	return GameModeDefinition.Mode.CLASSIC if _active_mode == null else _active_mode.mode

func _build_ball_definitions() -> Array[BallDefinition]:
	var definitions: Array[BallDefinition] = []
	var ball_count: int = _current_ball_count
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
	if _active_mode != null and _active_mode.uses_timed_waves():
		_publish_launcher_preview()
		_set_state(State.READY)
		return
	_set_state(State.RESOLVING)
	call_deferred("_resolve_completed_batch", batch_id)

func _resolve_completed_batch(batch_id: int) -> void:
	var next_ball_count: int = _get_classic_next_ball_count()
	var is_safe_turn: bool = board_controller.resolve_completed_batch(batch_id, next_ball_count)
	if not is_safe_turn:
		return
	_current_ball_count = next_ball_count
	_turn += 1
	turn_changed.emit(_turn)
	_publish_launcher_preview()
	_set_state(State.READY)

func _on_challenge_wave_due() -> void:
	if _active_mode == null or not _active_mode.uses_timed_waves() or _state == State.GAME_OVER:
		return
	_pending_timed_wave = true

func _resolve_timed_wave() -> void:
	if _active_mode == null or not _active_mode.uses_timed_waves():
		return
	var next_ball_count: int = mini(
		_current_ball_count + _active_mode.temporary_ball_gain_per_timed_wave,
		config.maximum_ball_count
	)
	var is_safe_wave: bool = board_controller.resolve_timed_wave(next_ball_count)
	if not is_safe_wave:
		return
	_current_ball_count = next_ball_count
	_publish_launcher_preview()

func _get_classic_next_ball_count() -> int:
	_classic_safe_turns += 1
	var growth_steps: int = _classic_safe_turns / config.safe_turns_per_ball_growth
	return mini(config.initial_ball_count + growth_steps, config.maximum_ball_count)

func _on_launch_queue_changed(queued_definitions: Array[BallDefinition]) -> void:
	launcher_preview_changed.emit(queued_definitions)

func _publish_launcher_preview() -> void:
	launcher_preview_changed.emit(_build_ball_definitions())

func _on_board_game_over_requested() -> void:
	if _state == State.GAME_OVER:
		return
	_set_state(State.GAME_OVER)
	challenge_wave_clock.stop_clock()
	ball_manager.freeze_active_balls_for_game_over()
	game_over.emit(_score, _turn)

func _on_challenge_wave_remaining_changed(remaining_seconds: int) -> void:
	if _active_mode != null and _active_mode.uses_timed_waves():
		challenge_wave_remaining_changed.emit(remaining_seconds)

func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(_state)
