class_name FishingController
extends Node
## Связывает ввод игрока, логику FishingSession и визуал (поплавок, леска, HUD).
## Одна кнопка на всё: удерживать — сила заброса или подмотка, нажать — подсечка.

enum Phase { IDLE, CHARGING, CASTING, SESSION, RESULT }

const ACTION := &"fish_action"
## Время, за которое шкала силы проходит от 0 до 1.
const CHARGE_TIME := 1.0
const CAST_FLIGHT_TIME := 0.6

@export var player: Player
@export var water: FishingWater
@export var hud: Hud
@export var bobber: Bobber
@export var line: FishingLine
@export var camera_rig: CameraRig

var phase := Phase.IDLE
var session: FishingSession

var _charge_time := 0.0
## Рыбное место, куда заброшен поплавок, если попали.
var _spot: FishingSpot
var _cast_dir := Vector3.FORWARD
## Точка на уровне воды под игроком в момент заброса — от неё считается дистанция.
var _origin := Vector3.ZERO


func _ready() -> void:
	add_to_group(&"fishing_controller")
	bobber.landed.connect(_on_bobber_landed)
	hud.catch_popup_closed.connect(_on_catch_popup_closed)
	line.detach()
	_to_idle()


func cast_power() -> float:
	return pingpong(_charge_time / CHARGE_TIME, 1.0)


func _process(delta: float) -> void:
	match phase:
		Phase.IDLE:
			if Input.is_action_just_pressed(ACTION) and not hud.is_modal_open():
				_start_charge()
		Phase.CHARGING:
			_charge_time += delta
			hud.show_charge(cast_power())
			if not Input.is_action_pressed(ACTION):
				_release_cast()
		Phase.SESSION:
			_update_session(delta)
		Phase.RESULT:
			if Input.is_action_just_pressed(ACTION):
				hud.close_catch_popup()


func _start_charge() -> void:
	phase = Phase.CHARGING
	_charge_time = 0.0
	player.can_move = false
	hud.set_hint("Отпусти {action}, когда шкала наберёт нужную силу")


func _release_cast() -> void:
	hud.hide_charge()
	var gear := GameState.gear
	_cast_dir = player.facing_direction()
	_origin = Vector3(player.global_position.x, water.water_level, player.global_position.z)
	var distance := lerpf(gear.min_cast_m, gear.max_cast_m, cast_power())
	var landing := _origin + _cast_dir * distance
	if not water.is_water(landing):
		hud.toast("Не долетело до воды — подойди к берегу")
		_to_idle()
		return

	_spot = water.spot_at(landing)
	if _spot:
		gear = _spot.boost(gear)
		hud.toast("Рыбное место! Клюнет быстрее")
	session = FishingSession.create(GameState.catalog, water.habitat_id(), gear, distance, randi(), WorldClock.phase)
	if session == null:
		hud.toast("Здесь не водится рыба")
		_to_idle()
		return
	session.state_changed.connect(_on_session_state_changed)
	session.thrash_started.connect(bobber.splash)
	session.thrash_started.connect(Sfx.play.bind(&"thrash", -4.0))

	phase = Phase.CASTING
	Sfx.play(&"whoosh")
	hud.set_hint("")
	bobber.cast(player.rod_tip.global_position, landing, CAST_FLIGHT_TIME)
	line.attach(player.rod_tip, bobber)
	line.slack = 0.2
	camera_rig.focus = bobber


func _on_bobber_landed() -> void:
	if phase != Phase.CASTING:
		return
	phase = Phase.SESSION
	line.slack = 0.6
	Sfx.play(&"splash", -6.0)
	hud.set_hint("Ждём поклёвку… Нажми {action}, чтобы смотать")


func _update_session(delta: float) -> void:
	var just_pressed := Input.is_action_just_pressed(ACTION)
	match session.state:
		FishingSession.State.WAITING:
			if just_pressed:
				hud.toast("Удочка смотана")
				_end_session()
				_to_idle()
				return
		FishingSession.State.BITING:
			if just_pressed:
				session.hook()

	var reeling := Input.is_action_pressed(ACTION) and session.state == FishingSession.State.FIGHTING
	session.tick(delta, reeling)
	# Сессия могла завершиться внутри tick — обработчик сигнала уже всё убрал.
	if session == null or session.state != FishingSession.State.FIGHTING:
		return

	Sfx.set_reel(reeling, session.tension)
	bobber.anchor = _origin + _cast_dir * session.distance
	bobber.thrashing = session.is_thrashing
	line.slack = 1.0 - clampf(session.tension * 1.5, 0.0, 1.0)
	hud.update_fight(session)


func _on_session_state_changed(state: FishingSession.State) -> void:
	match state:
		FishingSession.State.BITING:
			bobber.mode = Bobber.Mode.BITE
			Sfx.play(&"plop")
			hud.set_hint("Клюёт! Жми {action}!")
		FishingSession.State.FIGHTING:
			bobber.mode = Bobber.Mode.FIGHT
			Sfx.play(&"splash", -3.0, 1.3)
			hud.show_fight()
			hud.set_hint("Держи {action} — подматывать. Отпускай, когда леска в красной зоне")
		FishingSession.State.CAUGHT:
			var fish := session.fish
			var weight := session.weight_kg
			var is_new := GameState.register_catch(fish, weight)
			if _spot:
				_spot.deplete()
			_end_session()
			Sfx.play(&"new_species" if is_new else &"catch")
			phase = Phase.RESULT
			hud.set_hint("")
			hud.show_catch(fish, weight, is_new)
		FishingSession.State.MISSED:
			_fail("Поклёвка прозевана")
		FishingSession.State.ESCAPED:
			_fail("Леска провисла — рыба сошла с крючка")
		FishingSession.State.SNAPPED:
			Sfx.play(&"snap")
			_fail("Леска оборвалась!")


func _fail(message: String) -> void:
	hud.toast(message)
	_end_session()
	_to_idle()


func _end_session() -> void:
	Sfx.set_reel(false)
	session = null
	_spot = null
	bobber.retract()
	line.detach()
	hud.hide_fight()
	camera_rig.focus = null


func _on_catch_popup_closed() -> void:
	if phase == Phase.RESULT:
		_to_idle()


func _to_idle() -> void:
	phase = Phase.IDLE
	player.can_move = true
	hud.set_hint("Повернись к воде и удерживай {action}, чтобы забросить")
