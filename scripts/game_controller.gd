class_name GameController
extends Node

signal score_changed(score: int)
signal turn_changed(turn: int)
signal state_changed(state: int)
signal elapsed_time_changed(elapsed_seconds: int)
signal game_over(final_score: int, reached_turn: int)
signal launcher_preview_changed(definitions: Array[BallDefinition])
signal launcher_launchability_changed(is_ready: bool)
signal launcher_presentation_changed(presentation: int)
signal launcher_next_ball_release_requested(batch_id: int)
signal launcher_preview_recovery_received(definition: BallDefinition, recovery_direction: float)
signal challenge_wave_remaining_changed(remaining_seconds: int)
signal game_mode_changed(mode: int)

enum State {
	MODE_SELECTION,
	READY,
	BALLS_ACTIVE,
	RESOLVING,
	PAUSED,
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
var _state_before_pause: State = State.MODE_SELECTION
var _elapsed_time: float = 0.0
var _displayed_elapsed_seconds: int = 0
var _next_batch_id: int = 1
var _active_mode: GameModeDefinition
var _current_ball_count: int = 1
var _ball_type_random: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_timed_wave: bool = false
var _challenge_available_definitions: Array[BallDefinition] = []
var _challenge_queued_definitions: Array[BallDefinition] = []
var _classic_available_definitions: Array[BallDefinition] = []
var _classic_queued_definitions: Array[BallDefinition] = []
var _classic_recovered_definitions: Array[BallDefinition] = []

func _ready() -> void:
	assert(config != null, "GameController requires a GameConfig resource.")
	assert(ball_manager != null, "GameController requires a BallManager.")
	assert(board_controller != null, "GameController requires a BoardController.")
	assert(challenge_wave_clock != null, "GameController requires a ChallengeWaveClock.")
	assert(classic_mode != null, "GameController requires a classic GameModeDefinition.")
	assert(challenge_mode != null, "GameController requires a challenge GameModeDefinition.")
	ball_manager.batch_finished.connect(_on_batch_finished)
	ball_manager.launch_queue_changed.connect(_on_launch_queue_changed)
	ball_manager.ball_recovered.connect(_on_ball_recovered)
	ball_manager.next_ball_release_requested.connect(_on_next_ball_release_requested)
	board_controller.obstacle_destroyed.connect(_on_obstacle_destroyed)
	board_controller.reward_collected.connect(_on_reward_collected)
	board_controller.game_over_requested.connect(_on_board_game_over_requested)
	board_controller.timed_wave_scroll_started.connect(_on_timed_wave_scroll_started)
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
	_initialize_game(mode)

func restart_game() -> bool:
	if _active_mode == null or _state != State.PAUSED:
		return false
	challenge_wave_clock.stop_clock()
	ball_manager.reset_balls()
	board_controller.reset_board()
	_state = State.MODE_SELECTION
	_state_before_pause = State.MODE_SELECTION
	_pending_timed_wave = false
	_initialize_game(_active_mode)
	return true

func _initialize_game(mode: GameModeDefinition) -> void:
	_active_mode = mode
	_score = 0
	_turn = 1
	_next_batch_id = 1
	_current_ball_count = config.initial_ball_count
	_ball_type_random.seed = config.heavy_ball_random_seed
	_challenge_available_definitions.clear()
	_challenge_queued_definitions.clear()
	_classic_available_definitions.clear()
	_classic_queued_definitions.clear()
	_classic_recovered_definitions.clear()
	_elapsed_time = 0.0
	_displayed_elapsed_seconds = 0
	score_changed.emit(_score)
	turn_changed.emit(_turn)
	elapsed_time_changed.emit(_displayed_elapsed_seconds)
	board_controller.initialize_board(_current_ball_count)
	if _active_mode.uses_timed_waves():
		_challenge_available_definitions.append_array(_build_ball_definitions())
	else:
		_classic_available_definitions.append_array(_build_ball_definitions())
	game_mode_changed.emit(_active_mode.mode)
	if _active_mode.uses_timed_waves():
		challenge_wave_clock.start_clock(_active_mode.timed_wave_interval_seconds)
		_publish_launcher_presentation()
	else:
		launcher_presentation_changed.emit(Launcher.Presentation.CLASSIC_BLOCKED)
	_set_state(State.READY)
	_publish_launcher_preview()
	_publish_launcher_launchability()
	if not _active_mode.uses_timed_waves():
		_publish_launcher_presentation()

func _process(delta: float) -> void:
	if _state == State.MODE_SELECTION or _state == State.PAUSED or _state == State.GAME_OVER:
		return
	_elapsed_time += delta
	var elapsed_seconds: int = int(_elapsed_time)
	if elapsed_seconds == _displayed_elapsed_seconds:
		return
	_displayed_elapsed_seconds = elapsed_seconds
	elapsed_time_changed.emit(_displayed_elapsed_seconds)

func _physics_process(_delta: float) -> void:
	if not _pending_timed_wave or _state == State.PAUSED or _state == State.GAME_OVER:
		return
	_pending_timed_wave = false
	_resolve_timed_wave()

func get_elapsed_seconds() -> int:
	return _displayed_elapsed_seconds

func request_launch(direction: Vector2, preferred_definition: BallDefinition = null) -> void:
	if direction.length_squared() <= 0.0 or not can_request_launch():
		return
	var definitions: Array[BallDefinition] = []
	var recovery_terminal_position: Vector2 = config.get_classic_launcher_staging_position()
	if _active_mode != null and _active_mode.uses_timed_waves():
		definitions = _challenge_available_definitions.duplicate()
		_challenge_available_definitions.clear()
		recovery_terminal_position = config.launcher_position
	else:
		definitions = _classic_available_definitions.duplicate()
		_move_preferred_definition_to_front(definitions, preferred_definition)
		_classic_available_definitions.clear()
		_classic_queued_definitions = definitions.duplicate()
	var batch: BallBatch = BallBatch.new(_next_batch_id, definitions, config.launch_spread_degrees)
	_next_batch_id += 1
	ball_manager.launch_batch(batch, config.launcher_position, direction, recovery_terminal_position)
	_set_state(State.BALLS_ACTIVE)
	_publish_launcher_preview()
	_publish_launcher_presentation()
	_publish_launcher_launchability()

func get_state() -> State:
	return _state

func pause_game() -> bool:
	if _state == State.MODE_SELECTION or _state == State.PAUSED or _state == State.GAME_OVER:
		return false
	_state_before_pause = _state
	_set_state(State.PAUSED)
	return true

func resume_game() -> bool:
	if _state != State.PAUSED:
		return false
	_set_state(_state_before_pause)
	return true

func get_score() -> int:
	return _score

func get_launcher_preview_definitions() -> Array[BallDefinition]:
	if _state == State.MODE_SELECTION:
		return []
	if _active_mode != null and _active_mode.uses_timed_waves():
		return _challenge_queued_definitions.duplicate() if not _challenge_queued_definitions.is_empty() else _challenge_available_definitions.duplicate()
	if not _classic_queued_definitions.is_empty():
		return _classic_queued_definitions.duplicate()
	if _state == State.BALLS_ACTIVE or _state == State.RESOLVING:
		return _classic_recovered_definitions.duplicate()
	return _classic_available_definitions.duplicate()

func get_active_mode() -> int:
	return GameModeDefinition.Mode.CLASSIC if _active_mode == null else _active_mode.mode

func _build_ball_definitions() -> Array[BallDefinition]:
	var definitions: Array[BallDefinition] = []
	var ball_count: int = _current_ball_count
	for ball_index: int in ball_count:
		definitions.append(_create_ball_definition(ball_index))
	return definitions

func _create_ball_definition(ball_index: int) -> BallDefinition:
	var definition: BallDefinition = _create_normal_ball_definition(ball_index)
	if _ball_type_random.randf() < config.heavy_ball_spawn_probability:
		_configure_heavy_ball_definition(definition)
	return definition

func _create_normal_ball_definition(ball_index: int) -> BallDefinition:
	var definition: BallDefinition = BallDefinition.new()
	definition.visual_color = config.ball_palette[ball_index % config.ball_palette.size()]
	return definition

func _configure_heavy_ball_definition(definition: BallDefinition) -> void:
	definition.type = BallDefinition.Type.HEAVY
	definition.radius_multiplier = config.heavy_ball_radius_multiplier
	definition.gravity_multiplier = config.heavy_ball_gravity_multiplier
	definition.double_damage_probability = config.heavy_ball_double_damage_probability

func _on_obstacle_destroyed(points: int) -> void:
	_score += points
	score_changed.emit(_score)

func _on_reward_collected(reward_type: int, source_ball: Ball, reward_position: Vector2) -> void:
	if _state == State.GAME_OVER or not is_instance_valid(source_ball):
		return
	if reward_type == RewardBlock.Type.ADD_BALL:
		_spawn_persistent_bonus_ball(source_ball, _create_normal_ball_definition(_current_ball_count), reward_position)
		return
	if source_ball.definition.type == BallDefinition.Type.HEAVY:
		var heavy_definition: BallDefinition = source_ball.definition.duplicate() as BallDefinition
		_spawn_persistent_bonus_ball(source_ball, heavy_definition, reward_position)
		return
	source_ball.become_heavy(config.heavy_ball_radius_multiplier, config.heavy_ball_gravity_multiplier, config.heavy_ball_double_damage_probability)

func _spawn_persistent_bonus_ball(source_ball: Ball, definition: BallDefinition, reward_position: Vector2) -> void:
	if _current_ball_count >= config.maximum_ball_count:
		return
	if not ball_manager.spawn_bonus_ball(source_ball, definition, reward_position):
		return
	_current_ball_count += 1

func _on_batch_finished(batch_id: int) -> void:
	if _state != State.BALLS_ACTIVE:
		return
	if _active_mode != null and _active_mode.uses_timed_waves():
		if ball_manager.get_active_ball_count() == 0:
			_set_state(State.READY)
		_publish_launcher_preview()
		_publish_launcher_launchability()
		return
	_set_state(State.RESOLVING)
	call_deferred("_resolve_completed_batch", batch_id)

func _resolve_completed_batch(batch_id: int) -> void:
	var is_safe_turn: bool = board_controller.resolve_completed_batch(batch_id, _current_ball_count)
	if not is_safe_turn:
		return
	_classic_available_definitions = _classic_recovered_definitions.duplicate()
	_classic_recovered_definitions.clear()
	_classic_queued_definitions.clear()
	_turn += 1
	turn_changed.emit(_turn)
	_set_state(State.READY)
	_publish_launcher_preview()
	_publish_launcher_presentation()

func _on_challenge_wave_due() -> void:
	if _active_mode == null or not _active_mode.uses_timed_waves() or _state == State.GAME_OVER:
		return
	_pending_timed_wave = true

func _resolve_timed_wave() -> void:
	if _active_mode == null or not _active_mode.uses_timed_waves():
		return
	var is_safe_wave: bool = board_controller.resolve_timed_wave(_current_ball_count, _active_mode.timed_wave_scroll_duration_seconds)
	if not is_safe_wave:
		return

func _on_launch_queue_changed(queued_definitions: Array[BallDefinition]) -> void:
	if _active_mode != null and _active_mode.uses_timed_waves():
		_challenge_queued_definitions = queued_definitions.duplicate()
	else:
		_classic_queued_definitions = queued_definitions.duplicate()
	# 两种模式的顺序发射都会改变顶部预览；挑战模式不能保留旧队首画面。
	_publish_launcher_preview()
	if _active_mode == null or not _active_mode.uses_timed_waves():
		_publish_launcher_presentation()

func _on_ball_recovered(definition: BallDefinition, recovery_direction: float) -> void:
	if _active_mode == null or _state == State.GAME_OVER:
		return
	if _active_mode.uses_timed_waves():
		launcher_preview_recovery_received.emit(definition, recovery_direction)
		_challenge_available_definitions.append(definition)
	else:
		launcher_preview_recovery_received.emit(definition, recovery_direction)
		_classic_recovered_definitions.append(definition)
	_publish_launcher_preview()
	_publish_launcher_presentation()
	_publish_launcher_launchability()

func confirm_launcher_next_ball_release(batch_id: int, preferred_definition: BallDefinition) -> void:
	ball_manager.release_next_ball(batch_id, preferred_definition)

func _on_next_ball_release_requested(batch_id: int) -> void:
	launcher_next_ball_release_requested.emit(batch_id)

func _move_preferred_definition_to_front(definitions: Array[BallDefinition], preferred_definition: BallDefinition) -> void:
	if preferred_definition == null:
		return
	for index: int in definitions.size():
		if definitions[index].visual_color == preferred_definition.visual_color:
			var selected_definition: BallDefinition = definitions.pop_at(index)
			definitions.push_front(selected_definition)
			return

func _publish_launcher_preview() -> void:
	launcher_preview_changed.emit(get_launcher_preview_definitions())

func _publish_launcher_launchability() -> void:
	launcher_launchability_changed.emit(can_request_launch())

func _publish_launcher_presentation() -> void:
	if _active_mode == null:
		return
	if _active_mode.uses_timed_waves():
		launcher_presentation_changed.emit(Launcher.Presentation.CHALLENGE)
		return
	var presentation: int = Launcher.Presentation.CLASSIC_OPEN if _state == State.READY or not _classic_queued_definitions.is_empty() else Launcher.Presentation.CLASSIC_BLOCKED
	launcher_presentation_changed.emit(presentation)

func can_request_launch() -> bool:
	if _state == State.MODE_SELECTION or _state == State.PAUSED or _state == State.GAME_OVER:
		return false
	if _active_mode != null and _active_mode.uses_timed_waves():
		return not _challenge_available_definitions.is_empty() and not ball_manager.has_pending_launches()
	return _state == State.READY

func _on_board_game_over_requested() -> void:
	if _state == State.GAME_OVER:
		return
	_set_state(State.GAME_OVER)
	challenge_wave_clock.stop_clock()
	ball_manager.freeze_active_balls_for_game_over()
	_publish_launcher_launchability()
	game_over.emit(_score, _turn)

func _on_timed_wave_scroll_started(offset: Vector2, duration_seconds: float) -> void:
	ball_manager.begin_board_shift(offset, duration_seconds)

func _on_challenge_wave_remaining_changed(remaining_seconds: int) -> void:
	if _active_mode != null and _active_mode.uses_timed_waves():
		challenge_wave_remaining_changed.emit(remaining_seconds)

func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(_state)
	_publish_launcher_launchability()
