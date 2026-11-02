extends Node
## Настройки устройства хранятся отдельно от игрового прогресса.

var sound_enabled := true
var vibration_enabled := true
var _config := ConfigFile.new()


func _ready() -> void:
	_config.load("user://settings.cfg")
	sound_enabled = bool(_config.get_value("comfort", "sound", true))
	vibration_enabled = bool(_config.get_value("comfort", "vibration", true))
	_apply_sound()


func set_sound(value: bool) -> void:
	sound_enabled = value
	_apply_sound()
	_save()


func set_vibration(value: bool) -> void:
	vibration_enabled = value
	_save()


func vibrate(duration_ms: int) -> void:
	if vibration_enabled and DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(duration_ms)


func _apply_sound() -> void:
	AudioServer.set_bus_volume_db(0, 0.0 if sound_enabled else -80.0)


func _save() -> void:
	_config.set_value("comfort", "sound", sound_enabled)
	_config.set_value("comfort", "vibration", vibration_enabled)
	_config.save("user://settings.cfg")
