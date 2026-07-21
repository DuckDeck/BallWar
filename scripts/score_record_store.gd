class_name ScoreRecordStore
extends RefCounted

const DEFAULT_PATH: String = "user://score_records.cfg"
const CLASSIC_SECTION: String = "classic"
const CHALLENGE_SECTION: String = "challenge"
const HISTORICAL_KEY: String = "historical_best"
const DAILY_KEY: String = "daily_best"
const DAILY_DATE_KEY: String = "daily_date"

var _path: String

func _init(path: String = DEFAULT_PATH) -> void:
	_path = path

func record_score(mode: int, score: int, date_key: String = "") -> Dictionary:
	var config: ConfigFile = _load_config()
	var section: String = _section_for_mode(mode)
	var normalized_score: int = maxi(0, score)
	var current_date: String = date_key if not date_key.is_empty() else _get_today_key()
	var historical_best: int = maxi(0, int(config.get_value(section, HISTORICAL_KEY, 0)))
	var stored_date: String = str(config.get_value(section, DAILY_DATE_KEY, ""))
	var daily_best: int = maxi(0, int(config.get_value(section, DAILY_KEY, 0))) if stored_date == current_date else 0
	historical_best = maxi(historical_best, normalized_score)
	daily_best = maxi(daily_best, normalized_score)
	config.set_value(section, HISTORICAL_KEY, historical_best)
	config.set_value(section, DAILY_DATE_KEY, current_date)
	config.set_value(section, DAILY_KEY, daily_best)
	var save_error: Error = config.save(_path)
	if save_error != OK:
		push_error("Unable to save score records to %s (error %s)." % [_path, save_error])
	return {
		"historical_best": historical_best,
		"daily_best": daily_best,
		"daily_date": current_date,
	}

func get_records(mode: int, date_key: String = "") -> Dictionary:
	var config: ConfigFile = _load_config()
	var section: String = _section_for_mode(mode)
	var current_date: String = date_key if not date_key.is_empty() else _get_today_key()
	var stored_date: String = str(config.get_value(section, DAILY_DATE_KEY, ""))
	return {
		"historical_best": maxi(0, int(config.get_value(section, HISTORICAL_KEY, 0))),
		"daily_best": maxi(0, int(config.get_value(section, DAILY_KEY, 0))) if stored_date == current_date else 0,
		"daily_date": current_date,
	}

func _load_config() -> ConfigFile:
	var config: ConfigFile = ConfigFile.new()
	var load_error: Error = config.load(_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Unable to read score records from %s (error %s); using empty records." % [_path, load_error])
	return config

func _section_for_mode(mode: int) -> String:
	return CHALLENGE_SECTION if mode == GameModeDefinition.Mode.CHALLENGE else CLASSIC_SECTION

func _get_today_key() -> String:
	var today: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(today.year), int(today.month), int(today.day)]
