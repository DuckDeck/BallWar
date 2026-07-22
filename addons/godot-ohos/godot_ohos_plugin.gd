@tool
extends EditorPlugin

const GodotOhosExporter := preload("res://addons/godot-ohos/godot_ohos_exporter.gd")
const GodotOhosPlatform := preload("res://addons/godot-ohos/godot_ohos_platform.gd")

var _export_platform: EditorExportPlatform


func _enter_tree() -> void:
	GodotOhosExporter.register_editor_settings(get_editor_interface())
	_export_platform = GodotOhosPlatform.new(get_editor_interface())
	add_export_platform(_export_platform)


func _exit_tree() -> void:
	if _export_platform != null:
		remove_export_platform(_export_platform)
		_export_platform = null
