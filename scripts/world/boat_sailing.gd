class_name BoatSailing
extends Node3D
## Прогулки вокруг текущего острова. Быстрые переходы между биомами сохранены.

@export var player: Player
@export var controller: FishingController
@export var hud: Hud

var session: BoatSession
var active := false
var _water: FishingWater
var _source_dock: Node3D
var _visual: BoatVisual
var _rider: Marker3D
var _fx: FishingWaterFx
var _wake_time := 0.0


func _ready() -> void:
	add_to_group(&"boat_sailing")
	_visual = BoatVisual.new()
	add_child(_visual)
	_rider = Marker3D.new()
	_rider.position = Vector3(0, 0.23, 0.45)
	add_child(_rider)
	_fx = FishingWaterFx.new()
	add_child(_fx)
	hud.sailing_requested.connect(_on_sailing_requested)
	hide()


func _on_sailing_requested() -> void:
	if hud.is_modal_open() or controller.phase != FishingController.Phase.IDLE:
		return
	if active:
		var dock := nearest_dock()
		if dock and _dock_distance(dock) <= 8.5:
			_land(dock)
		return
	for dock in get_tree().get_nodes_in_group(&"boat_dock"):
		if dock._nearby and not dock._travelling:
			launch(dock)
			return


func launch(dock: Node3D) -> void:
	if active or hud.is_modal_open() or controller.phase != FishingController.Phase.IDLE:
		return
	if player.global_position.distance_to(dock.global_position) > 4.0:
		return
	_source_dock = dock
	_water = controller.water
	var spawn: Vector3 = dock.get_node("Boat").global_position - _water.global_position
	session = BoatSession.new(Vector2(spawn.x, spawn.z), GameState.BOAT.sailing_speed if GameState.boat_upgraded else 6.0, _water.shore_radius)
	position = _water.global_position + Vector3(session.position.x, _water.water_level, session.position.y)
	rotation.y = session.heading
	active = true
	show()
	dock.get_node("Boat").hide()
	dock._nearby = false
	dock._refresh_availability()
	hud.clear_travel_available(dock.destination_water.biome.display_name)
	hud.set_sailing_mode(true)
	player.ride_target = _rider
	player.velocity = Vector3.ZERO
	player.get_node("CollisionShape3D").set_deferred("disabled", true)
	_sync_rider()
	controller.camera_rig.snap_to_target()
	Sfx.play(&"splash", -9.0)


func _land(dock: Node3D) -> void:
	active = false
	player.ride_target = null
	player.global_position = dock.to_global(Vector3(0, 0.15, 0.8))
	player.velocity = Vector3.ZERO
	player.can_move = true
	player.get_node("CollisionShape3D").set_deferred("disabled", false)
	_source_dock.get_node("Boat").show()
	_fx.reset()
	hide()
	hud.set_sailing_mode(false)
	hud.set_sailing_available(false)
	hud.show_idle_hint()
	controller.camera_rig.snap_to_target()
	Sfx.play(&"splash", -12.0)


func nearest_dock() -> Node3D:
	var nearest: Node3D
	var distance := INF
	for dock in get_tree().get_nodes_in_group(&"boat_dock"):
		# Прогулка не обходит открытие биомов: ходим только вокруг текущего острова.
		if Vector2(dock.global_position.x - _water.global_position.x, dock.global_position.z - _water.global_position.z).length() > 25:
			continue
		var d := _dock_distance(dock)
		if d < distance:
			distance = d
			nearest = dock
	return nearest


func _dock_distance(dock: Node3D) -> float:
	return Vector2(global_position.x - dock.global_position.x, global_position.z - dock.global_position.z).length()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var anchored := controller.phase != FishingController.Phase.IDLE or hud.is_modal_open()
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := Vector3(input.x, 0, input.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	session.tick(delta, Vector2(direction.x, direction.z), anchored)
	global_position = _water.global_position + Vector3(session.position.x, _water.water_level, session.position.y)
	rotation.y = session.heading
	_sync_rider()
	_wake_time += delta
	if not anchored and session.velocity.length() > 0.5 and _wake_time > 0.3:
		_wake_time = 0.0
		_fx.ripple(to_global(Vector3(0, 0, 1.65)), 0.8)
	var dock := nearest_dock()
	var can_land := dock != null and _dock_distance(dock) <= 8.5
	hud.set_sailing_available(can_land, "Причалить · B / E")
	if dock and camera:
		var projected := direction_to_dock(dock)
		var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
		var arrow: String = arrows[posmod(roundi(projected.angle() / (PI / 4)), 8)]
		var north := camera.unproject_position(player.global_position + Vector3.FORWARD * 5) - camera.unproject_position(player.global_position)
		var north_arrow: String = arrows[posmod(roundi(north.angle() / (PI / 4)), 8)]
		hud.set_sailing_status("%s  Причал · %d м   %s Север" % [arrow, roundi(_dock_distance(dock)), north_arrow])
	if not anchored:
		hud.show_sailing_hint(session.blocked)


func _sync_rider() -> void:
	player.global_position = _rider.global_position
	if player.can_move:
		player.face_direction(-global_basis.z)


func direction_to_dock(dock: Node3D) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	var target := dock.global_position
	target.y = player.global_position.y
	# Направление относительно лодки, не центра кадра со смещённой камерой.
	return camera.unproject_position(target) - camera.unproject_position(player.global_position)
