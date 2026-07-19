class_name ProgressionState
extends RefCounted

var safe_turns: int = 0

func advance() -> void:
	safe_turns += 1

func get_ball_count(config: GameConfig) -> int:
	var growth_steps: int = safe_turns / config.safe_turns_per_ball_growth
	return mini(config.initial_ball_count + growth_steps, config.maximum_ball_count)
