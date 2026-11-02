extends Node
## Звуки игры. Короткие эффекты играют через небольшой пул плееров,
## треск катушки — через отдельный зацикленный плеер.

const POOL_SIZE := 6

var _streams: Dictionary[StringName, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _reel: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_streams = {
		&"splash": SfxSynth.splash(),
		&"thrash": SfxSynth.splash(0.25, 0.6),
		&"plop": SfxSynth.plop(),
		&"snap": SfxSynth.snap(),
		&"whoosh": SfxSynth.whoosh(),
		&"catch": SfxSynth.jingle(),
		&"new_species": SfxSynth.jingle([0, 4, 7, 12, 16, 19, 24]),
		&"coins": SfxSynth.jingle([12, 19]),
	}
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)

	_reel = AudioStreamPlayer.new()
	_reel.stream = SfxSynth.reel_loop()
	_reel.volume_db = -10.0
	add_child(_reel)


func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Нет звука %s" % sound)
		return
	if not PlayerSettings.sound_enabled or AudioServer.is_bus_mute(0):
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch * _random_pitch()
	player.play()


## Треск катушки: чем сильнее натяжение, тем чаще щелчки.
func set_reel(active: bool, tension := 0.0) -> void:
	if not active or not PlayerSettings.sound_enabled or AudioServer.is_bus_mute(0):
		_reel.stop()
		return
	_reel.pitch_scale = lerpf(0.8, 1.8, clampf(tension, 0.0, 1.0))
	if not _reel.playing:
		_reel.play()


func _random_pitch() -> float:
	# Косметический звук не должен менять глобальную последовательность улова.
	return _rng.randf_range(0.95, 1.05)
