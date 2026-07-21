class_name GameAudio
extends Node

enum Sfx {
	LAUNCH,
	RECOVER,
	BLOCK_HIT,
	REWARD,
}

const CLASSIC_BGM: AudioStream = preload("res://assets/audio/classic_bgm.wav")
const CHALLENGE_BGM: AudioStream = preload("res://assets/audio/challenge_bgm.wav")
const LAUNCH_SFX: AudioStream = preload("res://assets/audio/launch.wav")
const RECOVER_SFX: AudioStream = preload("res://assets/audio/recover.wav")
const BLOCK_HIT_SFX: AudioStream = preload("res://assets/audio/block_hit.wav")
const REWARD_SFX: AudioStream = preload("res://assets/audio/reward.wav")

@export_range(-40.0, 6.0, 0.5) var music_volume_db: float = -18.0
@export_range(-40.0, 6.0, 0.5) var sfx_volume_db: float = -8.0
@export_range(0.0, 0.5, 0.01) var repeated_sfx_cooldown_seconds: float = 0.05
@export_range(2, 16, 1) var sfx_pool_size: int = 8

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _last_played_at_seconds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_looping_bgm(CLASSIC_BGM)
	_configure_looping_bgm(CHALLENGE_BGM)
	_music_player = AudioStreamPlayer.new()
	_music_player.name = &"MusicPlayer"
	_music_player.volume_db = music_volume_db
	add_child(_music_player)
	for player_index: int in sfx_pool_size:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = StringName("SfxPlayer%d" % player_index)
		player.volume_db = sfx_volume_db
		add_child(player)
		_sfx_players.append(player)

func play_mode_bgm(mode: int) -> void:
	var requested_stream: AudioStream = CHALLENGE_BGM if mode == GameModeDefinition.Mode.CHALLENGE else CLASSIC_BGM
	if _music_player.stream == requested_stream and _music_player.playing:
		return
	_music_player.stop()
	_music_player.stream = requested_stream
	_music_player.volume_db = music_volume_db
	_music_player.play()

func pause_music() -> void:
	if _music_player.playing:
		_music_player.stream_paused = true

func resume_music() -> void:
	if _music_player.stream != null:
		_music_player.stream_paused = false

func stop_music() -> void:
	_music_player.stop()

func play_sfx(sfx: Sfx) -> void:
	if _is_rate_limited(sfx):
		return
	var stream: AudioStream = _get_sfx_stream(sfx)
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.stream = stream
	player.volume_db = sfx_volume_db
	player.play()

func _is_rate_limited(sfx: Sfx) -> bool:
	if sfx != Sfx.BLOCK_HIT and sfx != Sfx.RECOVER:
		return false
	var now_seconds: float = Time.get_ticks_msec() / 1000.0
	var previous_seconds: float = float(_last_played_at_seconds.get(sfx, -INF))
	if now_seconds - previous_seconds < repeated_sfx_cooldown_seconds:
		return true
	_last_played_at_seconds[sfx] = now_seconds
	return false

func _get_sfx_stream(sfx: Sfx) -> AudioStream:
	match sfx:
		Sfx.LAUNCH:
			return LAUNCH_SFX
		Sfx.RECOVER:
			return RECOVER_SFX
		Sfx.BLOCK_HIT:
			return BLOCK_HIT_SFX
		Sfx.REWARD:
			return REWARD_SFX
	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]

func _configure_looping_bgm(stream: AudioStream) -> void:
	if not (stream is AudioStreamWAV):
		return
	var wave_stream: AudioStreamWAV = stream as AudioStreamWAV
	wave_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave_stream.loop_begin = 0
