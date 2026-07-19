class_name GameModeDefinition
extends Resource

enum Mode {
	CLASSIC,
	CHALLENGE,
}

@export var mode: Mode = Mode.CLASSIC
@export var display_name: String = "经典模式"
@export_range(1.0, 60.0, 0.5, "suffix:s") var timed_wave_interval_seconds: float = 10.0
@export_range(0, 5, 1) var temporary_ball_gain_per_timed_wave: int = 1
@export_range(0.1, 1.0, 0.05, "suffix:s") var timed_wave_scroll_duration_seconds: float = 0.4

func uses_timed_waves() -> bool:
	return mode == Mode.CHALLENGE
