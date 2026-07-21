# covers: [T4-AUTO-03]
extends SceneTree

const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")

var _pause_triggered: bool = false

func _initialize() -> void:
	var hud: GameHud = HUD_SCENE.instantiate() as GameHud
	root.add_child(hud)
	hud.size = Vector2(1080.0, 1920.0)
	await process_frame
	var pause_button: Button = hud.get_pause_button()
	assert(pause_button.position.y > 200.0, "The pause control must sit below the launcher slopes on a portrait phone layout.")
	assert(pause_button.size.x >= 52.0 and pause_button.size.x <= 70.0, "The pause control must retain a compact, touchable size.")
	hud.size = Vector2(720.0, 1280.0)
	await process_frame
	assert(pause_button.position.y >= 96.0 and pause_button.position.x >= 32.0, "HUD safe margins must also hold on a compact portrait canvas.")
	hud.set_score(42)
	hud.set_elapsed_time(65)
	assert(hud.get_node("ScoreLabel").text == "Score: 42", "HUD score rendering must stay inside the component.")
	assert(hud.get_node("TimeLabel").text == "Time: 01:05", "HUD time formatting must stay inside the component.")
	hud.set_challenge_mode(false)
	assert(not hud.get_node("WaveLabel").visible, "Classic HUD must hide the challenge countdown.")
	hud.set_challenge_mode(true)
	hud.set_challenge_remaining(8)
	assert(hud.get_node("WaveLabel").visible and hud.get_node("WaveLabel").text == "Wave: 08s", "Challenge HUD must show the remaining wave time.")
	hud.pause_requested.connect(_on_pause_requested)
	pause_button.pressed.emit()
	assert(_pause_triggered, "HUD must expose pause through its own signal.")
	print("T4 HUD test passed: responsive layout, state rendering, and pause signal verified.")
	quit(0)

func _on_pause_requested() -> void:
	_pause_triggered = true
