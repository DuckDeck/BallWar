class_name GameConfig
extends Resource

@export_group("Canvas")
@export var design_size: Vector2 = Vector2(1080.0, 1920.0)

@export_group("Ball")
@export var ball_speed: float = 980.0
@export var ball_gravity: float = 1400.0
# 六边形等障碍物碰撞后的速度保留比例：0=完全不反弹，1=保持全部速度；数值越小反弹越弱。
@export_range(0.0, 1.0, 0.01) var obstacle_bounce_restitution: float = 0.68
@export var ball_max_lifetime: float = 12.0
@export var ball_radius: float = 20.0

@export_group("Ball Trail")
# 拖尾保留的历史时长（秒）：越大尾巴越长；建议保持在 0.15~0.25 秒以兼顾清晰度与性能。
@export_range(0.05, 0.50, 0.01, "suffix:s") var ball_trail_duration: float = 0.20
# 拖尾在球头处的最大宽度相对球半径的倍数；越大越接近参考图的水滴状球头。
@export_range(0.50, 2.00, 0.05) var ball_trail_width_multiplier: float = 1.45

@export_group("Launcher")
@export var launcher_position: Vector2 = Vector2(540.0, 460.0)
@export var launcher_radius: float = 58.0

@export_group("Arena")
@export var arena_left: float = 72.0
@export var arena_right: float = 1008.0
@export var arena_top: float = 240.0
@export var arena_bottom: float = 1640.0
@export var recovery_y: float = 1690.0

@export_group("Round")
@export var initial_obstacle_position: Vector2 = Vector2(540.0, 1040.0)
@export var initial_obstacle_health: int = 3
@export var score_per_obstacle: int = 10
