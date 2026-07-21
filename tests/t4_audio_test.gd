# covers: [T4-AU-AUTO-01]
extends SceneTree

func _initialize() -> void:
	var audio_manager: GameAudio = root.get_node("AudioManager") as GameAudio
	assert(audio_manager != null, "AudioManager must be registered as a project autoload.")
	audio_manager.play_mode_bgm(GameModeDefinition.Mode.CLASSIC)
	var music_player: AudioStreamPlayer = audio_manager.get_node("MusicPlayer") as AudioStreamPlayer
	assert(music_player.stream != null and music_player.playing, "Classic mode must start a looping BGM stream.")
	assert((music_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "BGM streams must loop.")
	audio_manager.play_mode_bgm(GameModeDefinition.Mode.CHALLENGE)
	assert(music_player.stream != null and music_player.playing, "Challenge mode must switch the active BGM stream.")
	audio_manager.play_sfx(GameAudio.Sfx.LAUNCH)
	audio_manager.play_sfx(GameAudio.Sfx.RECOVER)
	audio_manager.play_sfx(GameAudio.Sfx.BLOCK_HIT)
	audio_manager.play_sfx(GameAudio.Sfx.REWARD)
	assert(audio_manager.get_node("SfxPlayer0") is AudioStreamPlayer, "AudioManager must pre-create an SFX player pool.")
	audio_manager.stop_music()
	print("T4 audio test passed: music selection, looping, and SFX pool verified.")
	quit(0)
