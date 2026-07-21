class_name RewardBlock
extends StaticBody2D

signal collected(reward_type: int, source_ball: Ball, reward_position: Vector2)

enum Type {
	ADD_BALL,
	ENLARGE_BALL,
}

const ICON_RADIUS: float = 30.0
const COLLISION_RADIUS: float = 34.0

var board_cell: Vector2i = Vector2i(-1, -1)
var board_node_id: int = -1
var reward_type: Type = Type.ADD_BALL
var _is_collected: bool = false

func _ready() -> void:
	_sync_collision_shape()
	queue_redraw()

func configure(next_reward_type: Type) -> void:
	reward_type = next_reward_type
	queue_redraw()

func receive_hit(context: HitContext) -> HitResult:
	var result: HitResult = HitResult.new()
	result.should_bounce = false
	if _is_collected:
		return result
	_is_collected = true
	_set_collision_enabled(false)
	AudioManager.play_sfx(GameAudio.Sfx.REWARD)
	collected.emit(reward_type, context.source_ball, global_position)
	queue_free()
	return result

func _sync_collision_shape() -> void:
	var collision_shape: CollisionShape2D = get_node("CollisionShape2D") as CollisionShape2D
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = COLLISION_RADIUS
	collision_shape.shape = circle

func _set_collision_enabled(is_enabled: bool) -> void:
	collision_layer = 1 if is_enabled else 0
	collision_mask = 1 if is_enabled else 0
	var collision_shape: CollisionShape2D = get_node("CollisionShape2D") as CollisionShape2D
	collision_shape.set_deferred("disabled", not is_enabled)

func _draw() -> void:
	if reward_type == Type.ADD_BALL:
		draw_circle(Vector2.ZERO, ICON_RADIUS, Color("38f5a6"))
		draw_line(Vector2(-10.0, 0.0), Vector2(10.0, 0.0), Color("082c28"), 5.0, true)
		draw_line(Vector2(0.0, -10.0), Vector2(0.0, 10.0), Color("082c28"), 5.0, true)
		return
	var ring_color: Color = Color("f1f4f2")
	for segment_index: int in 12:
		if segment_index % 2 != 0:
			continue
		var start_angle: float = TAU * float(segment_index) / 12.0
		draw_arc(Vector2.ZERO, ICON_RADIUS + 5.0, start_angle, start_angle + TAU / 18.0, 8, ring_color, 3.0, true)
	draw_circle(Vector2.ZERO, 13.0, Color("38f5a6"))
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 20, ring_color, 2.0, true)
