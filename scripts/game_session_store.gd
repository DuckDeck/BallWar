class_name GameSessionStore
extends RefCounted

const DEFAULT_PATH: String = "user://game_sessions.cfg"
const SCHEMA_VERSION: int = 1
const SNAPSHOT_KEY: String = "snapshot"
const VERSION_KEY: String = "schema_version"
const CLASSIC_SECTION: String = "classic"
const CHALLENGE_SECTION: String = "challenge"

var _path: String

func _init(path: String = DEFAULT_PATH) -> void:
	_path = path

func save_session(mode: int, snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false
	var config: ConfigFile = _load_config()
	var section: String = _section_for_mode(mode)
	config.set_value(section, VERSION_KEY, SCHEMA_VERSION)
	config.set_value(section, SNAPSHOT_KEY, snapshot)
	return config.save(_path) == OK

func load_session(mode: int) -> Dictionary:
	var config: ConfigFile = _load_config()
	var section: String = _section_for_mode(mode)
	if int(config.get_value(section, VERSION_KEY, -1)) != SCHEMA_VERSION:
		return {}
	var raw_snapshot: Variant = config.get_value(section, SNAPSHOT_KEY, {})
	if not (raw_snapshot is Dictionary):
		clear_session(mode)
		return {}
	var snapshot: Dictionary = raw_snapshot as Dictionary
	if int(snapshot.get("mode", -1)) != mode:
		clear_session(mode)
		return {}
	return snapshot

func has_session(mode: int) -> bool:
	return not load_session(mode).is_empty()

func clear_session(mode: int) -> void:
	var config: ConfigFile = _load_config()
	config.erase_section(_section_for_mode(mode))
	config.save(_path)

func _load_config() -> ConfigFile:
	var config: ConfigFile = ConfigFile.new()
	var load_error: Error = config.load(_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("Unable to read game session store from %s (error %s)." % [_path, load_error])
	return config

func _section_for_mode(mode: int) -> String:
	return CHALLENGE_SECTION if mode == GameModeDefinition.Mode.CHALLENGE else CLASSIC_SECTION
