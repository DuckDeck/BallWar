class_name GameConfig
extends Resource

@export_group("Canvas")
@export var design_size: Vector2 = Vector2(1080.0, 1920.0)

@export_group("Ball")
@export var ball_speed: float = 980.0
@export var ball_gravity: float = 1400.0
# 六边形等障碍物碰撞后的速度保留比例：0=完全不反弹，1=保持全部速度；数值越小反弹越弱。
@export_range(0.0, 2.0, 0.01) var obstacle_bounce_restitution: float = 1.36
# 每次碰撞后的速度上限，防止连续障碍反弹的倍率累积。
@export_range(500.0, 4000.0, 10.0, "suffix:px/s") var ball_max_rebound_speed: float = 1400.0
@export var ball_max_lifetime: float = 12.0
@export var ball_radius: float = 13.333

@export_group("Ball Batch")
@export_range(1, 10, 1) var initial_ball_count: int = 1
@export_range(1, 30, 1) var maximum_ball_count: int = 10
@export_range(0.0, 30.0, 0.5) var launch_spread_degrees: float = 0.0
@export_range(0.02, 0.50, 0.01, "suffix:s") var ball_launch_interval_seconds: float = 0.10
@export var ball_palette: PackedColorArray = PackedColorArray([
	Color("d9ff3f"), Color("b96cff"), Color("ff8e4f"), Color("49e8ff"),
	Color("ff5bbd"), Color("b4ff58"), Color("ffd34f"), Color("7f9cff"),
	Color("ff705d"), Color("68f0c1"),
])

@export_group("Heavy Ball")
@export_range(0.0, 1.0, 0.01) var heavy_ball_spawn_probability: float = 0.20
@export_range(1.0, 2.0, 0.05) var heavy_ball_radius_multiplier: float = 1.30
@export_range(1.0, 3.0, 0.05) var heavy_ball_gravity_multiplier: float = 1.30
@export_range(0.0, 1.0, 0.01) var heavy_ball_double_damage_probability: float = 0.15
@export var heavy_ball_random_seed: int = 20260720

@export_group("Ball Trail")
# 拖尾保留的历史时长（秒）：越大尾巴越长；建议保持在 0.15~0.25 秒以兼顾清晰度与性能。
@export_range(0.05, 0.50, 0.01, "suffix:s") var ball_trail_duration: float = 0.32
# 拖尾在球头处的最大宽度相对球半径的倍数；越大越接近参考图的水滴状球头。
@export_range(0.50, 2.00, 0.05) var ball_trail_width_multiplier: float = 1.45

@export_group("Launcher")
@export var launcher_position: Vector2 = Vector2(540.0, 450.0)
@export var launcher_radius: float = 20.0

func get_classic_launcher_staging_position() -> Vector2:
	return Vector2(launcher_position.x, roof_apex_y - ball_radius * 2.8)

@export_group("Launcher Preview Physics")
@export_range(800.0, 6000.0, 100.0, "suffix:px/s²") var launcher_preview_gravity: float = 3200.0
@export_range(80.0, 1000.0, 10.0, "suffix:px/s") var launcher_preview_return_toss_speed: float = 680.0
@export_range(40.0, 400.0, 10.0, "suffix:px/s") var launcher_preview_return_inward_speed: float = 170.0
@export_range(80.0, 1000.0, 10.0, "suffix:px/s²") var launcher_preview_velocity_damping: float = 460.0
@export_range(4.0, 120.0, 2.0, "suffix:px/s") var launcher_preview_rest_speed: float = 26.0
@export_range(20.0, 240.0, 5.0, "suffix:px/s") var launcher_preview_collision_wake_speed: float = 70.0
@export_range(0.10, 2.00, 0.05, "suffix:s") var launcher_preview_stack_lock_delay_seconds: float = 0.55
@export_range(0.0, 0.5, 0.01) var launcher_preview_restitution: float = 0.06
@export_range(0.0, 1.0, 0.01) var launcher_preview_floor_friction: float = 0.92
@export_range(0.0, 1.0, 0.01) var launcher_preview_stacked_friction: float = 0.58
@export_range(0.3, 1.2, 0.05) var launcher_preview_slope: float = 0.68

@export_group("Aim Guide")
@export_range(200.0, 2400.0, 20.0) var aim_guide_max_length: float = 1800.0
@export_range(40.0, 600.0, 10.0) var aim_guide_reflection_length: float = 220.0

@export_group("Arena")
@export var arena_left: float = 72.0
@export var arena_right: float = 1008.0
@export var arena_top: float = 240.0
@export var roof_apex_y: float = 400.0
@export var roof_gap_width: float = 96.0
@export var roof_gap_drop: float = 20.0
@export var arena_bottom: float = 1640.0

@export_group("Bottom Recovery")
# 托底曲线中心与两端的高度。中心略高，形成贴近场地底部的浅碗形收线。
@export var bottom_trough_center_y: float = 1660.0
@export var bottom_trough_edge_y: float = 1710.0
# 球触底后不再使用重力或反弹，而是按以下速度完成回收动画。
@export var recovery_roll_speed: float = 820.0
@export var recovery_lift_speed: float = 1100.0
@export var recovery_roof_speed: float = 860.0
# 球达到最长存活时间后的可见下落速度；用于替代从空中直接吸附到托底线的跳变。
@export var recovery_timeout_descent_speed: float = 1100.0
# 仅用于异常兜底；正常回合会先经过托底回收流程。
@export var recovery_y: float = 1880.0

func get_bottom_trough_y(world_x: float) -> float:
	var center_x: float = (arena_left + arena_right) * 0.5
	var half_width: float = (arena_right - arena_left) * 0.5
	var normalized_x: float = clampf((world_x - center_x) / half_width, -1.0, 1.0)
	return bottom_trough_center_y + (bottom_trough_edge_y - bottom_trough_center_y) * normalized_x * normalized_x

@export_group("Round")
@export var initial_obstacle_position: Vector2 = Vector2(540.0, 1040.0)
@export var initial_obstacle_health: int = 3
@export var score_per_obstacle: int = 10

@export_group("Board")
@export_range(1, 12, 1) var board_columns: int = 7
@export var board_cell_size: Vector2 = Vector2(120.0, 120.0)
@export var board_bottom_row_y: float = 1420.0
@export var board_danger_line_y: float = 420.0

@export_group("Wave Progression")
@export var wave_seed: int = 20260719
@export_range(1, 12, 1) var wave_min_blocks: int = 1
@export_range(1, 12, 1) var wave_max_blocks: int = 7
# 新障碍数字范围 = 下一回合可控球数 × 此最小倍率。
@export_range(1, 10, 1) var wave_health_min_ball_multiplier: int = 1
# 新障碍数字范围 = 下一回合可控球数 × 此最大倍率。
@export_range(1, 10, 1) var wave_health_max_ball_multiplier: int = 2

@export_group("Reward Blocks")
@export_range(0.0, 1.0, 0.01) var add_ball_reward_probability: float = 0.09
@export_range(0.0, 1.0, 0.01) var enlarge_ball_reward_probability: float = 0.05
