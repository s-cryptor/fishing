extends Node
## Звуки игры. Короткие эффекты играют через небольшой пул плееров,
## треск катушки и фон — через отдельные зацикленные плееры.

const POOL_SIZE := 6

var _streams: Dictionary[StringName, AudioStream] = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _reel: AudioStreamPlayer
var _ambience: AudioStreamPlayer


func _ready() -> void:
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

	_ambience = AudioStreamPlayer.new()
	_ambience.stream = SfxSynth.water_ambience()
	_ambience.volume_db = -22.0
	add_child(_ambience)
	_ambience.play()


func play(sound: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Нет звука %s" % sound)
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch * randf_range(0.95, 1.05)
	player.play()


## Треск катушки: чем сильнее натяжение, тем чаще щелчки.
func set_reel(active: bool, tension := 0.0) -> void:
	if not active:
		_reel.stop()
		return
	_reel.pitch_scale = lerpf(0.8, 1.8, clampf(tension, 0.0, 1.0))
	if not _reel.playing:
		_reel.play()
