@tool
extends RefCounted

const TEMPLATE_DIR_RES := "res://addons/godot-ohos/bin"
const DEFAULT_DEVECO_HOME := ""
const DEFAULT_SDK_VERSION := "6.0.2(22)"
const DEFAULT_SDK_API_LEVEL := 22
const DEFAULT_ORIENTATION := "landscape"

const OPTION_BUNDLE_ID := "package/unique_name"
const OPTION_SDK_VERSION := "openharmony/sdk_version"
const OPTION_ORIENTATION := "screen/orientation"
const OPTION_INTERNET := "permissions/internet"
const OPTION_MICROPHONE := "permissions/microphone"
const OPTION_CUSTOM_PERMISSIONS := "permissions/custom_permissions"

const PERMISSION_OPTIONS := [
	{"option": "permissions/internet", "permission": "ohos.permission.INTERNET", "default": true, "user_grant": false},
	{"option": "permissions/get_network_info", "permission": "ohos.permission.GET_NETWORK_INFO", "default": true, "user_grant": false},
	{"option": "permissions/camera", "permission": "ohos.permission.CAMERA", "default": false, "user_grant": true},
	{"option": "permissions/microphone", "permission": "ohos.permission.MICROPHONE", "default": false, "user_grant": true},
	{"option": "permissions/location", "permission": "ohos.permission.LOCATION", "default": false, "user_grant": true},
	{"option": "permissions/approximately_location", "permission": "ohos.permission.APPROXIMATELY_LOCATION", "default": false, "user_grant": true},
	{"option": "permissions/location_in_background", "permission": "ohos.permission.LOCATION_IN_BACKGROUND", "default": false, "user_grant": true},
	{"option": "permissions/media_location", "permission": "ohos.permission.MEDIA_LOCATION", "default": false, "user_grant": true},
	{"option": "permissions/read_image_video", "permission": "ohos.permission.READ_IMAGEVIDEO", "default": false, "user_grant": true},
	{"option": "permissions/write_image_video", "permission": "ohos.permission.WRITE_IMAGEVIDEO", "default": false, "user_grant": true},
	{"option": "permissions/read_audio", "permission": "ohos.permission.READ_AUDIO", "default": false, "user_grant": true},
	{"option": "permissions/write_audio", "permission": "ohos.permission.WRITE_AUDIO", "default": false, "user_grant": true},
	{"option": "permissions/read_document", "permission": "ohos.permission.READ_DOCUMENT", "default": false, "user_grant": true},
	{"option": "permissions/write_document", "permission": "ohos.permission.WRITE_DOCUMENT", "default": false, "user_grant": true},
	{"option": "permissions/read_contacts", "permission": "ohos.permission.READ_CONTACTS", "default": false, "user_grant": true},
	{"option": "permissions/write_contacts", "permission": "ohos.permission.WRITE_CONTACTS", "default": false, "user_grant": true},
	{"option": "permissions/read_calendar", "permission": "ohos.permission.READ_CALENDAR", "default": false, "user_grant": true},
	{"option": "permissions/write_calendar", "permission": "ohos.permission.WRITE_CALENDAR", "default": false, "user_grant": true},
	{"option": "permissions/activity_motion", "permission": "ohos.permission.ACTIVITY_MOTION", "default": false, "user_grant": true},
	{"option": "permissions/use_bluetooth", "permission": "ohos.permission.USE_BLUETOOTH", "default": false, "user_grant": false},
	{"option": "permissions/discover_bluetooth", "permission": "ohos.permission.DISCOVER_BLUETOOTH", "default": false, "user_grant": false},
	{"option": "permissions/access_bluetooth", "permission": "ohos.permission.ACCESS_BLUETOOTH", "default": false, "user_grant": true},
	{"option": "permissions/nfc_tag", "permission": "ohos.permission.NFC_TAG", "default": false, "user_grant": false},
	{"option": "permissions/vibrate", "permission": "ohos.permission.VIBRATE", "default": false, "user_grant": false},
	{"option": "permissions/modify_audio_settings", "permission": "ohos.permission.MODIFY_AUDIO_SETTINGS", "default": false, "user_grant": false},
	{"option": "permissions/running_lock", "permission": "ohos.permission.RUNNING_LOCK", "default": false, "user_grant": false},
]

const SETTING_DEVECO_HOME := "export/harmony/deveco_home"
const SETTING_EXPORT_PRESET := "export/harmony/export_preset"

var _editor_interface: EditorInterface


func _init(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface


static func register_editor_settings(editor_interface: EditorInterface) -> void:
	var settings := editor_interface.get_editor_settings()
	var plugin_template_dir := default_template_dir()
	var template_dir := plugin_template_dir
	if settings.has_setting(SETTING_EXPORT_PRESET):
		template_dir = str(settings.get_setting(SETTING_EXPORT_PRESET)).strip_edges()
	if template_dir.is_empty():
		template_dir = plugin_template_dir

	_register_setting(settings, SETTING_DEVECO_HOME, DEFAULT_DEVECO_HOME, PROPERTY_HINT_GLOBAL_DIR)
	_register_setting(settings, SETTING_EXPORT_PRESET, template_dir, PROPERTY_HINT_GLOBAL_DIR)
	settings.set_setting(SETTING_EXPORT_PRESET, template_dir)


static func _register_setting(settings: EditorSettings, name: String, default_value: Variant, hint: PropertyHint, hint_string: String = "") -> void:
	if not settings.has_setting(name):
		settings.set_setting(name, default_value)
	if settings.has_method("set_initial_value"):
		settings.set_initial_value(name, default_value, false)
	if settings.has_method("add_property_info"):
		settings.add_property_info({
			"name": name,
			"type": typeof(default_value),
			"hint": hint,
			"hint_string": hint_string,
		})


static func _is_valid_template_dir(path: String) -> bool:
	if path.is_empty():
		return false
	return FileAccess.file_exists(path.path_join("openharmony_debug_arm64-v8a.zip")) or FileAccess.file_exists(path.path_join("openharmony_release_arm64-v8a.zip"))


static func default_template_dir() -> String:
	return ProjectSettings.globalize_path(TEMPLATE_DIR_RES)


static func default_bundle_id() -> String:
	var app_name := str(ProjectSettings.get_setting("application/config/name", "Godot"))
	return "com.godothub.%s" % _slugify(app_name)


func export_project_from_preset(preset: EditorExportPreset, debug: bool, output_path: String, pck_path: String) -> Error:
	return _export_project_from_pack(preset.get_preset_name(), debug, output_path, pck_path, _export_config_from_preset(preset))


func get_export_environment_error(debug: bool) -> String:
	var settings := _editor_interface.get_editor_settings()
	var mode := "debug" if debug else "release"
	var template_zip := _template_zip_path(settings, mode)
	if not FileAccess.file_exists(template_zip):
		return "Template not found: %s" % template_zip
	return ""


func _export_project_from_pack(export_preset: String, debug: bool, output_path: String, pck_source_path: String, export_config: Dictionary) -> Error:
	var settings := _editor_interface.get_editor_settings()
	var project_dir := ProjectSettings.globalize_path("res://").simplify_path()
	var mode := "debug" if debug else "release"

	var template_zip := _template_zip_path(settings, mode)
	if not FileAccess.file_exists(template_zip):
		push_error("[godot-ohos] Template not found: %s" % template_zip)
		return ERR_FILE_NOT_FOUND

	var project_config := _read_text(project_dir.path_join("project.godot"))
	var app_name := _find_ini_value(project_config, "config/name", "Godot")
	var project_name := _slugify(app_name)
	var build_root := project_dir.path_join("build/ohos")
	var ohos_project := _resolve_project_dir(output_path, build_root.path_join(project_name))
	var pck_path := ohos_project.path_join("entry/src/main/resources/rawfile/template.pck")
	var bundle_id := str(export_config.get("bundle_id", default_bundle_id()))

	print("[godot-ohos] Preset: %s" % export_preset)
	print("[godot-ohos] Project: %s" % project_dir)
	print("[godot-ohos] OHOS project: %s" % ohos_project)
	print("[godot-ohos] Template: %s" % template_zip)
	print("[godot-ohos] Bundle ID: %s" % bundle_id)

	var preserved_signing := _read_preserved_signing(ohos_project)
	_remove_dir(ohos_project)
	var err := _extract_template(template_zip, ohos_project)
	if err != OK:
		return err

	_configure_project(ohos_project, app_name, export_config, preserved_signing)
	DirAccess.make_dir_recursive_absolute(pck_path.get_base_dir())
	err = DirAccess.copy_absolute(pck_source_path, pck_path)
	if err != OK:
		push_error("[godot-ohos] Failed to copy PCK to %s" % pck_path)
		return err

	print("[godot-ohos] OHOS project exported: %s" % ohos_project)
	return OK


func _template_zip_path(settings: EditorSettings, mode: String) -> String:
	var template_dir := str(settings.get_setting(SETTING_EXPORT_PRESET)).strip_edges()
	if template_dir.is_empty():
		template_dir = default_template_dir()
	return template_dir.path_join("openharmony_%s_arm64-v8a.zip" % mode)


func _extract_template(template_zip: String, project_dir: String) -> Error:
	var reader := ZIPReader.new()
	var err := reader.open(template_zip)
	if err != OK:
		push_error("[godot-ohos] Failed to open template zip: %s" % template_zip)
		return err

	DirAccess.make_dir_recursive_absolute(project_dir)
	for file_path in reader.get_files():
		var dest := project_dir.path_join(file_path)
		if file_path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(dest)
			continue
		DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
		var file := FileAccess.open(dest, FileAccess.WRITE)
		if file == null:
			reader.close()
			push_error("[godot-ohos] Failed to write template file: %s" % dest)
			return ERR_FILE_CANT_WRITE
		file.store_buffer(reader.read_file(file_path))
	reader.close()
	return OK


func _configure_project(project_dir: String, app_name: String, export_config: Dictionary, preserved_signing: Dictionary) -> void:
	var bundle_id := str(export_config.get("bundle_id", default_bundle_id()))
	var sdk_version := str(export_config.get("sdk_version", DEFAULT_SDK_VERSION))
	var orientation := str(export_config.get("orientation", DEFAULT_ORIENTATION))
	var permissions: Array[String] = []
	for permission in export_config.get("permissions", []):
		permissions.append(str(permission))
	var user_permissions := str(export_config.get("user_permissions", ""))

	var app_json := project_dir.path_join("AppScope/app.json5")
	if FileAccess.file_exists(app_json):
		var content := _read_text(app_json)
		content = _replace_json5_string_property(content, "bundleName", bundle_id)
		_write_text(app_json, content)

	var app_scope_strings := project_dir.path_join("AppScope/resources/base/element/string.json")
	if FileAccess.file_exists(app_scope_strings):
		var content := _read_text(app_scope_strings)
		content = _replace_resource_string(content, "app_name", app_name)
		_write_text(app_scope_strings, content)

	var entry_strings := project_dir.path_join("entry/src/main/resources/base/element/string.json")
	if FileAccess.file_exists(entry_strings):
		var content := _read_text(entry_strings)
		content = _replace_resource_string(content, "EntryAbility_label", app_name)
		content = _replace_resource_string(content, "user_permissions", user_permissions)
		content = _ensure_permission_reason_strings(content, permissions)
		_write_text(entry_strings, content)

	var module_json := project_dir.path_join("entry/src/main/module.json5")
	if FileAccess.file_exists(module_json):
		var content := _read_text(module_json)
		content = _replace_request_permissions(content, permissions)
		content = _replace_json5_string_property(content, "orientation", orientation)
		_write_text(module_json, content)

	var build_profile := project_dir.path_join("build-profile.json5")
	if FileAccess.file_exists(build_profile):
		var content := _read_text(build_profile)
		content = _replace_json5_string_property(content, "targetSdkVersion", sdk_version)
		content = _replace_json5_string_property(content, "compatibleSdkVersion", sdk_version)
		if preserved_signing.has("signing_configs"):
			content = _replace_array_property(content, "signingConfigs", preserved_signing["signing_configs"])
		if preserved_signing.has("signing_config_name"):
			content = _replace_json5_string_property(content, "signingConfig", preserved_signing["signing_config_name"])
		_write_text(build_profile, content)


func _read_preserved_signing(project_dir: String) -> Dictionary:
	var build_profile := project_dir.path_join("build-profile.json5")
	if not FileAccess.file_exists(build_profile):
		return {}
	var content := _read_text(build_profile)
	var signing_configs := _extract_array_property(content, "signingConfigs")
	if signing_configs.is_empty() or signing_configs.strip_edges() == "\"signingConfigs\": []":
		return {}
	var result := {
		"signing_configs": signing_configs,
	}
	var signing_config_name := _find_json5_string_property(content, "signingConfig", "")
	if not signing_config_name.is_empty():
		result["signing_config_name"] = signing_config_name
	return result


func _export_config_from_preset(preset: EditorExportPreset) -> Dictionary:
	var enabled_options: Array[String] = []
	for permission_option in PERMISSION_OPTIONS:
		var option_name := str(permission_option["option"])
		if preset.has(option_name) and bool(preset.get(option_name)):
			enabled_options.append(option_name)
	var custom_permissions: Array[String] = []
	if preset.has(OPTION_CUSTOM_PERMISSIONS):
		for permission in preset.get(OPTION_CUSTOM_PERMISSIONS):
			custom_permissions.append(str(permission))
	return _make_export_config(
		str(preset.get(OPTION_BUNDLE_ID)) if preset.has(OPTION_BUNDLE_ID) else default_bundle_id(),
		str(preset.get(OPTION_SDK_VERSION)) if preset.has(OPTION_SDK_VERSION) else DEFAULT_SDK_VERSION,
		str(preset.get(OPTION_ORIENTATION)) if preset.has(OPTION_ORIENTATION) else DEFAULT_ORIENTATION,
		enabled_options,
		custom_permissions
	)


func _make_export_config(bundle_id: String, sdk_version: String, orientation: String, enabled_options: Array[String], custom_permissions: Array[String]) -> Dictionary:
	bundle_id = bundle_id.strip_edges()
	sdk_version = sdk_version.strip_edges()
	orientation = orientation.strip_edges()
	if bundle_id.is_empty():
		bundle_id = default_bundle_id()
	sdk_version = normalize_sdk_version(sdk_version)
	if orientation != "portrait" and orientation != "auto":
		orientation = DEFAULT_ORIENTATION

	var permissions: Array[String] = []
	var user_permissions: Array[String] = []
	for permission_option in PERMISSION_OPTIONS:
		var option_name := str(permission_option["option"])
		if not enabled_options.has(option_name):
			continue
		var permission := str(permission_option["permission"])
		_append_unique(permissions, permission)
		if bool(permission_option["user_grant"]):
			_append_unique(user_permissions, permission)
	for permission in custom_permissions:
		permission = permission.strip_edges()
		if permission.is_empty():
			continue
		_append_unique(permissions, permission)
	return {
		"bundle_id": bundle_id,
		"sdk_version": sdk_version,
		"orientation": orientation,
		"permissions": permissions,
		"user_permissions": ",".join(user_permissions),
	}


static func _sdk_api_level(sdk_version: String) -> int:
	var start := sdk_version.find("(")
	var end := sdk_version.find(")", start + 1)
	if start == -1 or end == -1:
		return 0
	return int(sdk_version.substr(start + 1, end - start - 1))


static func normalize_sdk_version(sdk_version: String) -> String:
	sdk_version = sdk_version.strip_edges()
	if sdk_version.is_empty() or _sdk_api_level(sdk_version) < DEFAULT_SDK_API_LEVEL:
		return DEFAULT_SDK_VERSION
	return sdk_version


func _append_unique(values: Array[String], value: String) -> void:
	if not values.has(value):
		values.append(value)


func _resolve_project_dir(output_path: String, default_path: String) -> String:
	output_path = output_path.strip_edges()
	if output_path.is_empty():
		return default_path
	if output_path.begins_with("res://") or output_path.begins_with("user://"):
		output_path = ProjectSettings.globalize_path(output_path)
	elif output_path.begins_with("./"):
		output_path = ProjectSettings.globalize_path("res://" + output_path.trim_prefix("./"))
	elif not output_path.is_absolute_path():
		output_path = ProjectSettings.globalize_path("res://" + output_path)
	return output_path


func _permissions_json(permissions: Array[String]) -> String:
	if permissions.is_empty():
		return "\"requestPermissions\": [],"
	var lines: Array[String] = ["\"requestPermissions\": ["]
	for i in range(permissions.size()):
		var permission := permissions[i]
		var comma := "," if i < permissions.size() - 1 else ""
		var reason := permission.trim_prefix("ohos.permission.")
		lines.append_array([
			"      {",
			"        \"name\": \"%s\"," % permission,
			"        \"reason\": \"$string:%s_reason\"," % reason,
			"        \"usedScene\": {",
			"          \"abilities\": [",
			"            \"EntryAbility\"",
			"          ],",
			"          \"when\": \"always\"",
			"        }",
			"      }%s" % comma,
		])
	lines.append("    ],")
	return "\n".join(lines)


func _replace_request_permissions(content: String, permissions: Array[String]) -> String:
	var re := RegEx.new()
	if re.compile("\"requestPermissions\"\\s*:\\s*\\[\\]\\s*,") != OK:
		return content
	return re.sub(content, _permissions_json(permissions).replace("$", "$$"), true)


func _replace_json5_string_property(content: String, key: String, value: String) -> String:
	var re := RegEx.new()
	if re.compile("(\"%s\"\\s*:\\s*)\"[^\"]*\"" % key) != OK:
		return content
	return re.sub(content, "$1\"%s\"" % value, true)


func _replace_resource_string(content: String, name: String, value: String) -> String:
	var re := RegEx.new()
	if re.compile("(\"name\"\\s*:\\s*\"%s\"\\s*,\\s*\"value\"\\s*:\\s*)\"[^\"]*\"" % name) != OK:
		return content
	return re.sub(content, "$1\"%s\"" % value, true)


func _ensure_permission_reason_strings(content: String, permissions: Array[String]) -> String:
	for permission in permissions:
		var reason_name := _permission_reason_name(permission)
		if content.contains("\"name\": \"%s\"" % reason_name):
			continue
		var entry := ",\n    {\n      \"name\": \"%s\",\n      \"value\": \"Required by the application\"\n    }" % reason_name
		content = content.replace("\n  ]", entry + "\n  ]")
	return content


func _permission_reason_name(permission: String) -> String:
	return "%s_reason" % permission.trim_prefix("ohos.permission.")


func _find_json5_string_property(content: String, key: String, default_value: String) -> String:
	for line in content.split("\n"):
		var stripped := line.strip_edges()
		var prefix := "\"%s\":" % key
		if stripped.begins_with(prefix):
			var first_quote := stripped.find("\"", prefix.length())
			var second_quote := stripped.find("\"", first_quote + 1)
			if first_quote >= 0 and second_quote > first_quote:
				return stripped.substr(first_quote + 1, second_quote - first_quote - 1)
	return default_value


func _extract_array_property(content: String, key: String) -> String:
	var key_pos := content.find("\"%s\"" % key)
	if key_pos < 0:
		return ""
	var array_start := content.find("[", key_pos)
	if array_start < 0:
		return ""
	var depth := 0
	var in_string := false
	var escaped := false
	for i in range(array_start, content.length()):
		var c := content.substr(i, 1)
		if in_string:
			if escaped:
				escaped = false
			elif c == "\\":
				escaped = true
			elif c == "\"":
				in_string = false
		else:
			if c == "\"":
				in_string = true
			elif c == "[":
				depth += 1
			elif c == "]":
				depth -= 1
				if depth == 0:
					return content.substr(key_pos, i - key_pos + 1)
	return ""


func _replace_array_property(content: String, key: String, replacement: String) -> String:
	var current := _extract_array_property(content, key)
	if current.is_empty():
		return content
	return content.replace(current, replacement)


func _find_ini_value(text: String, key: String, default_value: String) -> String:
	var prefix := "%s=\"" % key
	for line in text.split("\n"):
		if line.begins_with(prefix) and line.ends_with("\""):
			return line.substr(prefix.length(), line.length() - prefix.length() - 1)
	return default_value


static func _slugify(value: String) -> String:
	var result := ""
	var lower := value.to_lower()
	for i in range(lower.length()):
		var c := lower.substr(i, 1)
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			result += c
		else:
			result += "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	result = result.strip_edges().trim_prefix("_").trim_suffix("_")
	return result if not result.is_empty() else "godot_project"


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(content)


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	_remove_dir_contents(path)
	DirAccess.remove_absolute(path)


func _remove_dir_contents(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		var child_path := path.path_join(file_name)
		if dir.current_is_dir():
			_remove_dir(child_path)
		else:
			DirAccess.remove_absolute(child_path)
		file_name = dir.get_next()
	dir.list_dir_end()
