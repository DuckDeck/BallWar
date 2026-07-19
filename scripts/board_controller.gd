class_name BoardController
extends Node

signal obstacle_destroyed(points: int)
signal game_over_requested()

@export var config: GameConfig
@export var obstacle_scene: PackedScene
@export var obstacle_layer: Node2D

var _layout: BoardLayout = BoardLayout.new()
var _state: BoardState = BoardState.new()
var _wave_generator: WaveGenerator = WaveGenerator.new()
var _obstacles_by_id: Dictionary = {}
var _next_obstacle_id: int = 1
var _last_resolved_batch_id: int = -1
var _is_game_over: bool = false

func _ready() -> void:
	assert(config != null, "BoardController requires a GameConfig resource.")
	assert(obstacle_scene != null, "BoardController requires an Obstacle scene.")
	assert(obstacle_layer != null, "BoardController requires an Obstacle layer.")

func initialize_board(next_ball_count: int = 1) -> void:
	_layout.configure(config)
	_wave_generator.reset(config.wave_seed)
	_spawn_bottom_row(next_ball_count)

func get_obstacle_count() -> int:
	return _state.get_obstacle_count()

func get_cells() -> Array[Vector2i]:
	return _state.get_occupied_cells()

func is_game_over() -> bool:
	return _is_game_over

func resolve_completed_batch(batch_id: int, next_ball_count: int = 1) -> bool:
	if _is_game_over or batch_id == _last_resolved_batch_id:
		return false
	_last_resolved_batch_id = batch_id
	return _advance_wave(next_ball_count)

func resolve_timed_wave(next_ball_count: int) -> bool:
	if _is_game_over:
		return false
	return _advance_wave(next_ball_count)

func _advance_wave(next_ball_count: int) -> bool:
	var cells_by_obstacle_id: Dictionary = _state.advance_rows()
	_sync_obstacles_to_cells(cells_by_obstacle_id)
	if _has_reached_danger_line():
		_is_game_over = true
		game_over_requested.emit()
		return false
	_spawn_bottom_row(next_ball_count)
	return true

func _spawn_bottom_row(next_ball_count: int) -> void:
	var entries: Array[WaveEntry] = _wave_generator.generate_bottom_row(_layout, config, next_ball_count)
	for entry: WaveEntry in entries:
		var cell: Vector2i = Vector2i(entry.column, 0)
		_spawn_obstacle(cell, entry.health, entry.shape_type, entry.rotation_degrees)

func _spawn_obstacle(cell: Vector2i, health: int, shape_type: int, rotation_degrees: float) -> void:
	var obstacle_id: int = _next_obstacle_id
	_next_obstacle_id += 1
	if not _state.register_obstacle(obstacle_id, cell):
		return
	var obstacle: Obstacle = obstacle_scene.instantiate() as Obstacle
	obstacle.config = config
	obstacle.board_cell = cell
	obstacle.obstacle_id = obstacle_id
	obstacle.destroyed.connect(_on_obstacle_destroyed.bind(obstacle_id))
	obstacle_layer.add_child(obstacle)
	obstacle.global_position = _layout.get_cell_center(cell)
	obstacle.configure(health, config.score_per_obstacle, shape_type, rotation_degrees)
	_obstacles_by_id[obstacle_id] = obstacle

func _sync_obstacles_to_cells(cells_by_obstacle_id: Dictionary) -> void:
	for obstacle_id: int in cells_by_obstacle_id.keys():
		var obstacle: Obstacle = _obstacles_by_id.get(obstacle_id, null) as Obstacle
		if not is_instance_valid(obstacle):
			continue
		var cell: Vector2i = cells_by_obstacle_id[obstacle_id] as Vector2i
		obstacle.board_cell = cell
		obstacle.global_position = _layout.get_cell_center(cell)

func _has_reached_danger_line() -> bool:
	for cell: Vector2i in _state.get_occupied_cells():
		if _layout.get_cell_top_y(cell) <= _layout.danger_line_y:
			return true
	return false

func _on_obstacle_destroyed(points: int, obstacle_id: int) -> void:
	_state.release_obstacle(obstacle_id)
	_obstacles_by_id.erase(obstacle_id)
	obstacle_destroyed.emit(points)
