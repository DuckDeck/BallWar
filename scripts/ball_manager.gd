class_name BallManager
extends Node

signal batch_finished(batch_id: int)
signal launch_queue_changed(queued_definitions: Array[BallDefinition])
signal ball_recovered(definition: BallDefinition)

@export var config: GameConfig
@export var ball_scene: PackedScene
@export var ball_layer: Node2D

var _sequences_by_batch: Dictionary = {}

func _ready() -> void:
	assert(config != null, "BallManager requires a GameConfig resource.")
	assert(ball_scene != null, "BallManager requires a Ball scene.")
	assert(ball_layer != null, "BallManager requires a Ball layer.")

func launch_batch(batch: BallBatch, origin: Vector2, direction: Vector2) -> void:
	assert(not batch.definitions.is_empty(), "A BallBatch must contain at least one ball definition.")
	assert(not _sequences_by_batch.has(batch.id), "A batch ID must be unique while it is active.")
	var sequence: BallLaunchSequence = BallLaunchSequence.new(batch, origin, direction)
	_sequences_by_batch[batch.id] = sequence
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
		if sequence.seconds_until_next_launch <= 0.0:
			_launch_next_ball(sequence)

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

func freeze_active_balls_for_game_over() -> void:
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		for ball: Ball in sequence.active_balls.values():
			if is_instance_valid(ball):
				ball.freeze_for_game_over()

func begin_board_shift(offset: Vector2, duration_seconds: float) -> void:
	for sequence: BallLaunchSequence in _sequences_by_batch.values():
		for ball: Ball in sequence.active_balls.values():
			if is_instance_valid(ball):
				ball.begin_board_shift(offset, duration_seconds)

func _launch_next_ball(sequence: BallLaunchSequence) -> void:
	if sequence.pending_definitions.is_empty():
		_maybe_finish_batch(sequence)
		return
	var definition: BallDefinition = sequence.pending_definitions.pop_front()
	var ball: Ball = ball_scene.instantiate() as Ball
	ball.config = config
	ball.definition = definition
	ball.runtime_state = BallRuntimeState.new()
	ball.recovered.connect(_on_ball_recovered.bind(sequence.batch_id, ball))
	ball_layer.add_child(ball)
	ball.global_position = sequence.origin
	sequence.active_balls[ball.get_instance_id()] = ball
	ball.launch(sequence.launch_direction)
	sequence.seconds_until_next_launch = config.ball_launch_interval_seconds
	launch_queue_changed.emit(sequence.pending_definitions)

func _get_sequence(batch_id: int) -> BallLaunchSequence:
	return _sequences_by_batch.get(batch_id, null) as BallLaunchSequence

func _on_ball_recovered(_reason: StringName, batch_id: int, ball: Ball) -> void:
	var sequence: BallLaunchSequence = _get_sequence(batch_id)
	if sequence == null or not sequence.active_balls.has(ball.get_instance_id()):
		return
	sequence.active_balls.erase(ball.get_instance_id())
	ball_recovered.emit(ball.definition)
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
