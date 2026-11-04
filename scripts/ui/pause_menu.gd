extends CanvasLayer
## Пауза останавливает часы, поклёвку и вываживание. Меню работает на паузе.

var _overlay: Control
var _resume: Button
var _backup_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	add_to_group(&"pause_menu")
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.theme = preload("res://scenes/ui/ui_theme.tres")
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.09, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Тихая гавань · Пауза"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	_resume = Button.new()
	_resume.text = "Вернуться к рыбалке"
	_resume.pressed.connect(toggle)
	box.add_child(_resume)
	var sound := CheckButton.new()
	sound.text = "Звук"
	sound.button_pressed = PlayerSettings.sound_enabled
	sound.toggled.connect(PlayerSettings.set_sound)
	box.add_child(sound)
	var vibration := CheckButton.new()
	vibration.text = "Вибрация при поклёвке (телефон)"
	vibration.button_pressed = PlayerSettings.vibration_enabled
	vibration.toggled.connect(PlayerSettings.set_vibration)
	box.add_child(vibration)
	var help := Label.new()
	help.text = "\n".join([
		"Удерживай и отпускай — заброс. Мышь / стик — прицел.",
		"Клюнуло — нажми сразу. На рывке отпускай.",
		"Держи натяжение в золотой зоне для быстрой подмотки.", "",
		"WASD / стик — ходьба · E / X — разговор",
		"B / Y у причала — лодка",
		"C / Back — коллекция · I / RB — садок",
		"Tab / стрелки / крестовина — меню · Enter / A — выбор",
		"Esc / Start — пауза", "",
		"ПКМ / Q,R — поворот · колесо / +,− — масштаб",
		"Правый стик / два пальца — поворот и масштаб",
		"Home / R3 — исходный вид",
	])
	help.add_theme_font_size_override("font_size", 17)
	box.add_child(help)
	_backup_button = Button.new()
	_backup_button.name = "ExportProgressButton"
	_backup_button.text = _export_caption()
	_backup_button.add_theme_font_size_override("font_size", 18)
	_backup_button.tooltip_text = "Только локальный JSON. Прогресс не меняется и не отправляется на сервер."
	_backup_button.pressed.connect(_export_progress)
	box.add_child(_backup_button)
	var backup_note := Label.new()
	backup_note.text = "JSON для копии и поддержки. Импорт из меню пока недоступен."
	backup_note.add_theme_font_size_override("font_size", 14)
	box.add_child(backup_note)
	_overlay.hide()
	# На мобильном кнопка остаётся доступной без клавиатуры.
	var button := Button.new()
	button.text = "Пауза"
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = 16.0
	button.offset_top = -55.0
	button.offset_right = 110.0
	button.offset_bottom = -15.0
	button.add_theme_font_size_override("font_size", 16)
	button.theme = _overlay.theme
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(toggle)
	add_child(button)
	# Меню должно отрисовываться поверх кнопки.
	move_child(_overlay, -1)


func _export_caption() -> String:
	return "Скачать прогресс (JSON)" if OS.has_feature("web") else "Скопировать прогресс (JSON)"


func _export_progress() -> void:
	# Вызов остаётся синхронным внутри нажатия: браузеру нужен жест пользователя.
	var text := GameState.export_save_text()
	if text.is_empty():
		_backup_button.text = "Нет доступного сохранения для экспорта"
		return
	if OS.has_feature("web"):
		if not Engine.has_singleton("JavaScriptBridge"):
			_backup_button.text = "Экспорт недоступен в этой сборке"
			return
		var bridge := Engine.get_singleton("JavaScriptBridge")
		if not bridge.has_method("download_buffer"):
			_backup_button.text = "Экспорт недоступен в этой сборке"
			return
		bridge.call("download_buffer", text.to_utf8_buffer(), "quiet-harbor-progress.json", "application/json")
		# У API нет подтверждения записи файла: браузер вправе заблокировать скачивание.
		_backup_button.text = "Запрос на скачивание передан браузеру"
	elif DisplayServer.get_name() != "headless" and DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(text)
		_backup_button.text = "Прогресс скопирован" if DisplayServer.clipboard_get() == text else "Не удалось скопировать прогресс"
	else:
		_backup_button.text = "Буфер обмена недоступен"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_overlay.visible = paused
	if paused:
		_backup_button.text = _export_caption()
		Sfx.set_reel(false)
		_resume.grab_focus()
	else:
		_resume.release_focus()
		# Кнопка действия не должна остаться зажатой после переключения окна.
		Input.action_release(&"fish_action")
		var controller := get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
		if controller:
			controller.require_action_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_overlay) and not get_tree().paused and not DebugTools.automated and DisplayServer.get_name() != "headless":
		toggle()
