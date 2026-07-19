class_name WaveGenerator
extends RefCounted

var _random: RandomNumberGenerator = RandomNumberGenerator.new()

func reset(seed: int) -> void:
	_random.seed = seed

func generate_bottom_row(layout: BoardLayout, config: GameConfig, safe_turns: int) -> Array[WaveEntry]:
	var columns: Array[int] = []
	for column: int in layout.columns:
		columns.append(column)
	for index: int in columns.size():
		var swap_index: int = _random.randi_range(index, columns.size() - 1)
		var temporary_column: int = columns[index]
		columns[index] = columns[swap_index]
		columns[swap_index] = temporary_column
	var max_blocks: int = mini(config.wave_max_blocks, layout.columns)
	var min_blocks: int = mini(config.wave_min_blocks, max_blocks)
	var block_count: int = _random.randi_range(min_blocks, max_blocks)
	var minimum_health: int = mini(config.wave_initial_health + safe_turns * config.wave_health_growth_per_turn, config.wave_max_health)
	var maximum_health: int = mini(minimum_health + config.wave_health_variance, config.wave_max_health)
	var entries: Array[WaveEntry] = []
	for index: int in block_count:
		entries.append(WaveEntry.new(columns[index], _random.randi_range(minimum_health, maximum_health)))
	return entries
