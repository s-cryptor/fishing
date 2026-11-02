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
var _preview: MeshInstance3D
var _preview_material: StandardMaterial3D
var _preview_label: Label3D
var _fight_time := 0.0
var _cast_guide: MeshInstance3D
var _guide_mesh := ImmediateMesh.new()


func _ready() -> void:
	add_to_group(&"fishing_controller")
	bobber.landed.connect(_on_bobber_landed)
	hud.catch_popup_closed.connect(_on_catch_popup_closed)
	line.detach()
	_create_preview()
	_to_idle()


func cast_power() -> float:
	return pingpong(_charge_time / CHARGE_TIME, 1.0)


func _process(delta: float) -> void:
	var fighting := session != null and session.state == FishingSession.State.FIGHTING
	player.fishing_pose(phase in [Phase.CHARGING, Phase.CASTING, Phase.SESSION],
		cast_power() if phase == Phase.CHARGING else 0.0,
		session.tension if fighting else 0.0, fighting and Input.is_action_pressed(ACTION))
	match phase:
		Phase.IDLE:
			if Input.is_action_just_pressed(ACTION) and not hud.is_modal_open():
				_start_charge()
		Phase.CHARGING:
			_aim_with_movement(delta)
			_charge_time += delta
			hud.show_charge(cast_power())
			_update_preview()
			if not Input.is_action_pressed(ACTION):
				_release_cast()
		Phase.SESSION:
			_update_session(delta)
		Phase.RESULT:
			if Input.is_action_just_pressed(ACTION):
				hud.close_catch_popup()


func _start_charge() -> void:
	hud.set_fishing_focus(true)
	phase = Phase.CHARGING
	_charge_time = 0.0
	player.can_move = false
	hud.show_charge_hint()
	_update_preview()
	camera_rig.focus = _preview


func _release_cast() -> void:
	_preview.hide()
	_cast_guide.hide()
	hud.hide_charge()
	var gear := GameState.fishing_gear(water.habitat_id())
	_cast_dir = player.facing_direction()
	_origin = Vector3(player.global_position.x, water.water_level, player.global_position.z)
	var distance := lerpf(gear.min_cast_m, gear.max_cast_m, cast_power())
	var landing := _origin + _cast_dir * distance
	if not water.is_water(landing):
		hud.toast("Не долетело до воды — подойди к берегу")
		_to_idle()
		return

	_spot = water.spot_at(landing)
	if _spot and _spot.reserve():
		var precise := _spot.is_precise(landing)
		gear = _spot.boost(gear, precise)
		hud.toast("Точный заброс · бонус удачи и клёва" if precise else "Рыбное место · клюнет быстрее")
	else:
		_spot = null
	session = FishingSession.create(GameState.catalog, water.habitat_id(), gear, distance, randi(), WorldClock.phase,
		water.landing_distance(_origin, _cast_dir, distance))
	if session == null:
		if _spot:
			_spot.release()
			_spot = null
		hud.toast("Здесь не водится рыба")
		_to_idle()
		return
	GameState.consume_fishing_supplies()
	session.state_changed.connect(_on_session_state_changed)
	session.thrash_started.connect(bobber.splash)
	session.thrash_started.connect(Sfx.play.bind(&"thrash", -4.0))
	session.thrash_warned.connect(func() -> void:
		Sfx.play(&"whoosh", -22.0, 1.8)
		PlayerSettings.vibrate(35))
	_fight_time = 0.0
	bobber.fish_size = lerpf(0.7, 1.5, inverse_lerp(session.fish.min_weight_kg, session.fish.max_weight_kg, session.weight_kg))
	bobber.heading = atan2(_cast_dir.x, _cast_dir.z) + PI

	phase = Phase.CASTING
	player.cast_gesture()
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
	_fight_time += delta
	var sway := sin(_fight_time * 2.4) * minf(1.0, session.distance * 0.12) * (1.0 if session.is_thrashing else 0.25)
	bobber.anchor = _origin + _cast_dir * session.distance + _cast_dir.cross(Vector3.UP) * sway
	bobber.thrashing = session.is_thrashing
	bobber.warning = session.is_telegraphing()
	line.tension = session.tension
	line.slack = 1.0 - clampf(session.tension * 1.5, 0.0, 1.0)
	hud.update_fight(session)


func _on_session_state_changed(state: FishingSession.State) -> void:
	match state:
		FishingSession.State.BITING:
			PlayerSettings.vibrate(90)
			bobber.mode = Bobber.Mode.BITE
			Sfx.play(&"plop")
			hud.set_hint("Клюёт! Жми {action}!")
		FishingSession.State.FIGHTING:
			bobber.mode = Bobber.Mode.FIGHT
			Sfx.play(&"splash", -3.0, 1.3)
			hud.show_fight()
			hud.set_hint("Держи {action} — тяни · отпускай — ослабляй · светлая зона — бонус")
		FishingSession.State.CAUGHT:
			PlayerSettings.vibrate(150)
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
	if _spot:
		_spot.release()
	_spot = null
	bobber.retract()
	line.detach()
	line.tension = 0.0
	hud.hide_fight()
	camera_rig.focus = null


func _on_catch_popup_closed() -> void:
	if phase == Phase.RESULT:
		_to_idle()


func _to_idle() -> void:
	hud.set_fishing_focus(false)
	phase = Phase.IDLE
	player.can_move = true
	camera_rig.focus = null
	hud.show_idle_hint()


func _create_preview() -> void:
	_preview = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.5
	_preview.mesh = ring
	_preview_material = StandardMaterial3D.new()
	_preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_material.no_depth_test = true
	_preview.material_override = _preview_material
	add_child(_preview)
	_preview_label = Label3D.new()
	_preview_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_preview_label.font_size = 48
	_preview_label.pixel_size = 0.01
	_preview_label.outline_size = 8
	_preview_label.position.y = 0.7
	_preview.add_child(_preview_label)
	_preview.hide()
	_cast_guide = MeshInstance3D.new()
	_cast_guide.mesh = _guide_mesh
	_cast_guide.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var guide_material := StandardMaterial3D.new()
	guide_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	guide_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	guide_material.albedo_color = Color(0.9, 0.88, 0.72, 0.45)
	_cast_guide.material_override = guide_material
	add_child(_cast_guide)
	_cast_guide.hide()


func _update_preview() -> void:
	var gear := GameState.gear
	var distance := lerpf(gear.min_cast_m, gear.max_cast_m, cast_power())
	var point := Vector3(player.global_position.x, water.water_level + 0.08, player.global_position.z) + player.facing_direction() * distance
	var valid := water.is_water(point)
	var spot := water.spot_at(point) if valid else null
	var precise := spot != null and spot.is_precise(point)
	_preview.global_position = point
	_preview_material.albedo_color = Color("#ffda78") if spot else (Color("#8fe8cb") if valid else Color("#f08080"))
	_preview_label.text = "%.1f м%s" % [distance, " · точный заброс!" if precise else (" · рыбное место" if spot else ("" if valid else " · суша"))]
	_preview.show()
	_update_cast_guide(point)


func _aim_with_movement(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if input.length_squared() < 0.04:
		return
	var direction := Vector3(input.x, 0, input.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	player.face_direction(direction, 1.0 - exp(-14 * delta))


func _unhandled_input(event: InputEvent) -> void:
	if phase != Phase.CHARGING or DisplayServer.is_touchscreen_available() or DebugTools.touch_ui:
		return
	if event is InputEventMouseMotion and event.relative.length_squared() > 0.1:
		aim_at_screen(event.position)


func aim_at_screen(screen_point: Vector2) -> bool:
	if phase != Phase.CHARGING:
		return false
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return false
	var plane := Plane(Vector3.UP, water.water_level)
	var point: Variant = plane.intersects_ray(camera.project_ray_origin(screen_point), camera.project_ray_normal(screen_point))
	if point == null:
		return false
	var direction: Vector3 = point - player.global_position
	direction.y = 0
	if direction.length_squared() < 0.25:
		return false
	player.face_direction(direction.normalized())
	return true


func _update_cast_guide(point: Vector3) -> void:
	var start := player.rod_tip.global_position
	var height := start.distance_to(point) * 0.35
	_guide_mesh.clear_surfaces()
	_guide_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for segment in range(0, 32, 2):
		for end in [segment, segment + 1]:
			var t: float = end / 32.0
			_guide_mesh.surface_add_vertex(start.lerp(point, t) + Vector3.UP * sin(t * PI) * height)
	_guide_mesh.surface_end()
	_cast_guide.show()
