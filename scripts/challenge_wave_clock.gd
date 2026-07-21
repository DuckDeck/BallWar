class_name ChallengeWaveClock
extends Timer

signal wave_due()
signal remaining_seconds_changed(remaining_seconds: int)

var _last_reported_seconds: int = -1

func _ready() -> void:
	one_shot = false
	timeout.connect(_on_timeout)
	set_process(false)

func start_clock(interval_seconds: float) -> void:
	wait_time = maxf(0.1, interval_seconds)
	_last_reported_seconds = -1
	start()
	set_process(true)
	_publish_remaining_seconds()

func resume_clock(interval_seconds: float, remaining_seconds: float) -> void:
	wait_time = maxf(0.1, interval_seconds)
	_last_reported_seconds = -1
	start(clampf(remaining_seconds, 0.1, wait_time))
	set_process(true)
	_publish_remaining_seconds()

func stop_clock() -> void:
	stop()
	set_process(false)
	_last_reported_seconds = -1

func _process(_delta: float) -> void:
	_publish_remaining_seconds()

func _on_timeout() -> void:
	wave_due.emit()
	call_deferred("_publish_remaining_seconds")

func _publish_remaining_seconds() -> void:
	if is_stopped():
		return
	var remaining_seconds: int = maxi(0, int(ceilf(time_left)))
	if remaining_seconds == _last_reported_seconds:
		return
	_last_reported_seconds = remaining_seconds
	remaining_seconds_changed.emit(remaining_seconds)
