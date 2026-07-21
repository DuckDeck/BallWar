class_name WaveGenerator
extends RefCounted

var _random: RandomNumberGenerator = RandomNumberGenerator.new()

func reset(seed: int) -> void:
	_random.seed = seed

func get_random_state() -> int:
	return _random.state

func set_random_state(state: int) -> void:
	_random.state = state

func generate_bottom_row(layout: BoardLayout, config: GameConfig, next_ball_count: int, wave_index: int = 1) -> Array[WaveEntry]:
	var columns: Array[int] = []
	for column: int in layout.columns:
		columns.append(column)
	_shuffle_values(columns)
	# 正式棋盘每行至少四个占格对象；配置被旧资源或调试值降到 4 以下时仍保持该下限。
	var max_blocks: int = mini(maxi(4, config.wave_max_blocks), layout.columns)
	var min_blocks: int = mini(max_blocks, maxi(4, config.wave_min_blocks))
	var block_count: int = _random.randi_range(min_blocks, max_blocks)
	var minimum_multiplier: int = mini(config.wave_health_min_ball_multiplier, config.wave_health_max_ball_multiplier)
	var maximum_multiplier: int = maxi(config.wave_health_min_ball_multiplier, config.wave_health_max_ball_multiplier)
	var minimum_health: int = maxi(1, next_ball_count * minimum_multiplier)
	var maximum_health: int = maxi(minimum_health, next_ball_count * maximum_multiplier)
	var health_values: Array[int] = []
	for health_value: int in range(minimum_health, maximum_health + 1):
		health_values.append(health_value)
	_shuffle_values(health_values)
	var entries: Array[WaveEntry] = []
	for index: int in block_count:
		var shape_type: int = _random.randi_range(0, Obstacle.Shape.size() - 1)
		var rotation_degrees: float = _random.randf_range(0.0, 360.0)
		# 先遍历打散后的可用数字，数字范围不足一整行时才循环复用。
		var health: int = health_values[index % health_values.size()]
		entries.append(WaveEntry.new(columns[index], health, shape_type, rotation_degrees, _roll_entry_content(config, wave_index)))
	return entries

func _roll_entry_content(config: GameConfig, wave_index: int) -> WaveEntry.Content:
	if wave_index < config.reward_start_wave:
		return WaveEntry.Content.OBSTACLE
	var reward_roll: float = _random.randf()
	if reward_roll < config.add_ball_reward_probability:
		return WaveEntry.Content.ADD_BALL_REWARD
	if reward_roll < config.add_ball_reward_probability + config.enlarge_ball_reward_probability:
		return WaveEntry.Content.ENLARGE_BALL_REWARD
	return WaveEntry.Content.OBSTACLE

func _shuffle_values(values: Array[int]) -> void:
	for index: int in values.size():
		var swap_index: int = _random.randi_range(index, values.size() - 1)
		var temporary_value: int = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary_value
