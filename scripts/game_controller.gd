class_name GameController
extends Node

signal score_changed(score: int)
signal turn_changed(turn: int)
signal state_changed(state: int)

enum State {
	READY,
	BALL_ACTIVE,
	RESOLVING,
}

@export var config: GameConfig
@export var ball_scene: PackedScene
@export var obstacle_scene: PackedScene
@export var ball_layer: Node2D
@export var obstacle_layer: Node2D

var _active_ball: Ball
var _active_obstacle: Obstacle
var _score: int = 0
var _turn: int = 1
var _state: State = State.READY

func _ready() -> void:
	assert(config != null, "GameController requires a GameConfig resource.")
	assert(ball_scene != null, "GameController requires Ball scene.")
	assert(obstacle_scene != null, "GameController requires Obstacle scene.")
	assert(ball_layer != null and obstacle_layer != null, "GameController requires scene layers.")
	_spawn_obstacle()
	score_changed.emit(_score)
	turn_changed.emit(_turn)
	state_changed.emit(_state)

func request_launch(direction: Vector2) -> void:
	if _state != State.READY or direction.length_squared() <= 0.0:
		return
	_active_ball = ball_scene.instantiate() as Ball
	_active_ball.config = config
	_active_ball.recovered.connect(_on_ball_recovered)
	ball_layer.add_child(_active_ball)
	_active_ball.global_position = config.launcher_position
	_active_ball.launch(direction)
	_set_state(State.BALL_ACTIVE)

func _spawn_obstacle() -> void:
	_active_obstacle = obstacle_scene.instantiate() as Obstacle
	_active_obstacle.config = config
	_active_obstacle.damaged.connect(_on_obstacle_damaged)
	_active_obstacle.destroyed.connect(_on_obstacle_destroyed)
	obstacle_layer.add_child(_active_obstacle)
	_active_obstacle.global_position = config.initial_obstacle_position
	_active_obstacle.configure(config.initial_obstacle_health)

func _on_obstacle_damaged(_remaining_health: int) -> void:
	pass

func _on_obstacle_destroyed(points: int) -> void:
	_score += points
	score_changed.emit(_score)
	_active_obstacle = null

func _on_ball_recovered(_reason: StringName) -> void:
	if _state != State.BALL_ACTIVE:
		return
	_set_state(State.RESOLVING)
	if is_instance_valid(_active_ball):
		_active_ball.queue_free()
	_active_ball = null
	call_deferred("_finish_turn")

func _finish_turn() -> void:
	if _active_obstacle == null:
		_spawn_obstacle()
	_turn += 1
	turn_changed.emit(_turn)
	_set_state(State.READY)

func _set_state(next_state: State) -> void:
	_state = next_state
	state_changed.emit(_state)
