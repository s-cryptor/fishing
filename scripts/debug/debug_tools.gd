extends Node
## Отладочные режимы. Включаются аргументами после "--":
##   godot --path . -- --autoplay --shots=/tmp/shots --shot-every=2 --quit-after=30
##
##   --autoplay          бот сам забрасывает, подсекает и вываживает
##   --shots=DIR         сохранять скриншоты в DIR
##   --shot-every=SEC    интервал скриншотов (по умолчанию 2)
##   --quit-after=SEC    выйти через SEC секунд
##   --touch-ui          показать тач-контролы на десктопе
##   --save=PATH         отдельный файл сохранения (не портить свой)
##   --money=N           выдать N монет при старте
##   --teleport=X,Z      поставить игрока в точку острова
##   --action=NAME@SEC   нажать input action через SEC секунд (можно несколько раз)
##   --hold=NAME         держать input action всё время (проверка ходьбы)
##   При --quit-after в лог печатается позиция игрока.

var autoplay := false
var touch_ui := false
var save_path := ""

var _shots_dir := ""
var _shot_every := 2.0
var _quit_after := 0.0
var _time := 0.0
var _next_shot := 0.0
var _shot_index := 0
var _result_wait := 0.0
var _money := -1
var _teleport: Variant = null
## [[action, time], ...] — ещё не нажатые.
var _scheduled_actions: Array = []
var _held_actions: Array[StringName] = []


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		var value := parts[1] if parts.size() > 1 else ""
		match parts[0]:
			"--autoplay": autoplay = true
			"--touch-ui": touch_ui = true
			"--save": save_path = value
			"--shots": _shots_dir = value
			"--shot-every": _shot_every = value.to_float()
			"--quit-after": _quit_after = value.to_float()
			"--money": _money = value.to_int()
			"--teleport":
				var xz := value.split_floats(",")
				_teleport = Vector2(xz[0], xz[1])
			"--hold": _held_actions.append(StringName(value))
			"--action":
				var action_time := value.split("@")
				_scheduled_actions.append([StringName(action_time[0]), action_time[1].to_float()])
	if _shots_dir:
		DirAccess.make_dir_recursive_absolute(_shots_dir)


func _ready() -> void:
	# GameState грузится после нас — применяем стартовые правки на первом кадре.
	_apply_start_overrides.call_deferred()


func _apply_start_overrides() -> void:
	if _money >= 0:
		GameState.money = _money
		GameState.money_changed.emit(_money)
	if _teleport != null:
		var player := get_tree().get_first_node_in_group(&"player") as Node3D
		if player:
			player.global_position = Vector3(_teleport.x, player.global_position.y, _teleport.y)


func _process(delta: float) -> void:
	_time += delta
	if autoplay:
		_drive(delta)
	for scheduled in _scheduled_actions.duplicate():
		if _time >= scheduled[1]:
			_scheduled_actions.erase(scheduled)
			_tap_event(scheduled[0])
	if _shots_dir and _time >= _next_shot:
		_next_shot += _shot_every
		_take_shot()
	for action in _held_actions:
		Input.action_press(action)
	if _quit_after > 0.0 and _time >= _quit_after:
		var player := get_tree().get_first_node_in_group(&"player") as Node3D
		if player:
			print("DEBUG player_position=%s radius=%.2f" % [player.global_position,
					Vector2(player.global_position.x, player.global_position.z).length()])
		get_tree().quit()


func _drive(delta: float) -> void:
	var controller := get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	if controller == null:
		return
	match controller.phase:
		FishingController.Phase.IDLE:
			_tap()
		FishingController.Phase.CHARGING:
			_set_pressed(controller.cast_power() < 0.95)
		FishingController.Phase.SESSION:
			_set_pressed(AutoPlayer.wants_action(controller.session))
		FishingController.Phase.RESULT:
			# Даём попапу повисеть, чтобы его было видно на скриншоте.
			_result_wait += delta
			if _result_wait > 2.5:
				_result_wait = 0.0
				_tap()
		_:
			_set_pressed(false)


## Нажатие с отпусканием: is_action_just_pressed требует фронта.
func _tap() -> void:
	_set_pressed(not Input.is_action_pressed(&"fish_action"))


## Полноценное событие (а не Input.action_press), чтобы сработал _unhandled_input.
func _tap_event(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _set_pressed(pressed: bool) -> void:
	if pressed:
		Input.action_press(&"fish_action")
	else:
		Input.action_release(&"fish_action")


func _take_shot() -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/shot_%02d.png" % [_shots_dir, _shot_index]
	_shot_index += 1
	get_viewport().get_texture().get_image().save_png(path)
