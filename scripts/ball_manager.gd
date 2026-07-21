class_name BallManager
extends Node

signal batch_finished(batch_id: int)
signal launch_queue_changed(queued_definitions: Array[BallDefinition])
signal ball_recovered(definition: BallDefinition, recovery_direction: float)
signal next_ball_release_requested(batch_id: int)

@export var config: GameConfig
@export var ball_scene: PackedScene
@export var ball_layer: Node2D

var _sequences_by_batch: Dictionary = {}

func _ready() -> void:
	assert(config != null, "BallManager requires a GameConfig resource.")
	assert(ball_scene != null, "BallManager requires a Ball scene.")
	assert(ball_layer != null, "BallManager requires a Ball layer.")

func launch_batch(batch: BallBatch, origin: Vector2, direction: Vector2, recovery_terminal_position: Vector2) -> void:
	assert(not batch.definitions.is_empty(), "A BallBatch must contain at least one ball definition.")
	assert(not _sequences_by_batch.has(batch.id), "A batch ID must be unique while it is active.")
	var sequence: BallLaunchSequence = BallLaunchSequence.new(batch, origin, direction, recovery_terminal_position)
	_sequences_by_batch[batch.id] = sequence
	AudioManager.play_sfx(GameAudio.Sfx.LAUNCH)
	_launch_next_ball(sequence)

func _process(delta: float) -> void:
	var batch_ids: Array[int] = []
	for batch_id: Variant in _sequences_by_batch.keys():
		batch_ids.append(int(batch_id))
	for batch_id: int in batch_ids:
		var sequence: BallLaunchSequence = _get_sequence(batch_id)
		if sequence == null or sequence.pending_definitions.is_empty():
			continue
		sequence.seconds_until_next_launch -= delta
		if sequence.seconds_until_next_launch <= 0.0 and not sequence.awaiting_launcher_slot:
			sequence.awaiting_launcher_slot = true
			next_ball_release_requested.emit(sequence.batch_id)

func release_next_ball(batch_id: int, preferred_definition: BallDefinition = null) -> void:
	var sequence: BallLaunchSequence = _get_sequence(batch_id)
	if sequence == null or not sequence.awaiting_launcher_slot:
		return
	sequence.awaiting_launcher_slot = false
	_launch_next_ball(sequence, preferred_definition)

func get_active_ball_count() -> int:
	var count: int = 0
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		count += sequence.active_balls.size()
	return count

func get_active_balls(batch_id: int) -> Array[Ball]:
	var result: Array[Ball] = []
	var sequence: BallLaunchSequence = _get_sequence(batch_id)
	if sequence == null:
		return result
	for ball: Ball in sequence.active_balls.values():
		if is_instance_valid(ball):
			result.append(ball)
	return result

func get_pending_ball_count(batch_id: int) -> int:
	var sequence: BallLaunchSequence = _get_sequence(batch_id)
	return 0 if sequence == null else sequence.pending_definitions.size()

func has_pending_launches() -> bool:
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		if not sequence.pending_definitions.is_empty() or sequence.awaiting_launcher_slot:
			return true
	return false

func get_in_flight_definitions() -> Array[BallDefinition]:
	var definitions: Array[BallDefinition] = []
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		definitions.append_array(sequence.pending_definitions)
		for ball: Ball in sequence.active_balls.values():
			if is_instance_valid(ball):
				definitions.append(ball.definition)
	return definitions

func freeze_active_balls_for_game_over() -> void:
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		for ball: Ball in sequence.active_balls.values():
			if is_instance_valid(ball):
				ball.freeze_for_game_over()

func reset_balls() -> void:
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		for ball: Ball in sequence.active_balls.values():
			if is_instance_valid(ball):
				ball.queue_free()
	_sequences_by_batch.clear()
	var empty_queue: Array[BallDefinition] = []
	launch_queue_changed.emit(empty_queue)

func begin_board_shift(offset: Vector2, duration_seconds: float) -> void:
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		for ball: Ball in sequence.active_balls.values():
			if is_instance_valid(ball):
				ball.begin_board_shift(offset, duration_seconds)

func spawn_bonus_ball(source_ball: Ball, definition: BallDefinition, spawn_position: Vector2) -> bool:
	if source_ball == null or definition == null:
		return false
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		if not sequence.active_balls.has(source_ball.get_instance_id()):
			continue
		var bonus_ball: Ball = _create_active_ball(sequence, definition, spawn_position)
		bonus_ball.launch_bonus_drop()
		return true
	return false

func _launch_next_ball(sequence: BallLaunchSequence, preferred_definition: BallDefinition = null) -> void:
	if sequence.pending_definitions.is_empty():
		_maybe_finish_batch(sequence)
		return
	var definition: BallDefinition = _take_next_definition(sequence, preferred_definition)
	var ball: Ball = _create_active_ball(sequence, definition, sequence.origin)
	ball.launch(sequence.launch_direction)
	sequence.seconds_until_next_launch = config.ball_launch_interval_seconds
	launch_queue_changed.emit(sequence.pending_definitions)

func _create_active_ball(sequence: BallLaunchSequence, definition: BallDefinition, position: Vector2) -> Ball:
	var ball: Ball = ball_scene.instantiate() as Ball
	ball.config = config
	ball.definition = definition
	ball.runtime_state = BallRuntimeState.new()
	ball.set_recovery_terminal_position(sequence.recovery_terminal_position)
	ball.recovered.connect(_on_ball_recovered.bind(sequence.batch_id, ball))
	ball_layer.add_child(ball)
	ball.global_position = position
	sequence.active_balls[ball.get_instance_id()] = ball
	return ball

func _take_next_definition(sequence: BallLaunchSequence, preferred_definition: BallDefinition) -> BallDefinition:
	if preferred_definition != null:
		for index: int in sequence.pending_definitions.size():
			if sequence.pending_definitions[index].visual_color == preferred_definition.visual_color:
				return sequence.pending_definitions.pop_at(index)
	return sequence.pending_definitions.pop_front()

func _get_sequence(batch_id: int) -> BallLaunchSequence:
	return _sequences_by_batch.get(batch_id, null) as BallLaunchSequence

func _on_ball_recovered(_reason: StringName, batch_id: int, ball: Ball) -> void:
	var sequence: BallLaunchSequence = _get_sequence(batch_id)
	if sequence == null or not sequence.active_balls.has(ball.get_instance_id()):
		return
	sequence.active_balls.erase(ball.get_instance_id())
	AudioManager.play_sfx(GameAudio.Sfx.RECOVER)
	ball_recovered.emit(ball.definition, ball.get_recovery_direction())
	if is_instance_valid(ball):
		ball.queue_free()
	_maybe_finish_batch(sequence)

func _maybe_finish_batch(sequence: BallLaunchSequence) -> void:
	if not sequence.pending_definitions.is_empty() or not sequence.active_balls.is_empty():
		return
	_sequences_by_batch.erase(sequence.batch_id)
	var empty_queue: Array[BallDefinition] = []
	launch_queue_changed.emit(empty_queue)
	batch_finished.emit(sequence.batch_id)
