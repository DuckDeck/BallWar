# covers: [T4-GO-AUTO-01, T4-GO-AUTO-02, T4-GO-AUTO-03]
extends SceneTree

const TEST_PATH: String = "user://t4_score_records_test.cfg"

func _initialize() -> void:
	_remove_test_file()
	var store: ScoreRecordStore = ScoreRecordStore.new(TEST_PATH)
	var classic_first: Dictionary = store.record_score(GameModeDefinition.Mode.CLASSIC, 68, "2026-07-21")
	assert(int(classic_first.historical_best) == 68 and int(classic_first.daily_best) == 68, "The first classic result must initialize both best scores.")
	var classic_lower: Dictionary = store.record_score(GameModeDefinition.Mode.CLASSIC, 12, "2026-07-21")
	assert(int(classic_lower.historical_best) == 68 and int(classic_lower.daily_best) == 68, "Lower scores must not reduce same-day or historical records.")
	var challenge_first: Dictionary = store.record_score(GameModeDefinition.Mode.CHALLENGE, 42, "2026-07-21")
	assert(int(challenge_first.historical_best) == 42 and int(challenge_first.daily_best) == 42, "Challenge records must be independent from classic records.")
	var classic_next_day: Dictionary = store.record_score(GameModeDefinition.Mode.CLASSIC, 20, "2026-07-22")
	assert(int(classic_next_day.historical_best) == 68 and int(classic_next_day.daily_best) == 20, "A new calendar day must reset only the daily comparison.")
	var stored_challenge: Dictionary = store.get_records(GameModeDefinition.Mode.CHALLENGE, "2026-07-21")
	assert(int(stored_challenge.historical_best) == 42 and int(stored_challenge.daily_best) == 42, "A classic update must not alter challenge records.")
	_remove_test_file()
	print("T4 score record test passed: per-mode historical and daily records verified.")
	quit(0)

func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
