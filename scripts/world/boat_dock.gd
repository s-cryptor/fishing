class_name BoatDock
extends Area3D
## Причал-переход между биомами. Лодка пока служит транспортом:
## управление ей появится вместе с экспедициями и улучшениями.

@export var destination_water: FishingWater
@export var arrival_point: Marker3D
@export var player: Player
@export var fishing_controller: FishingController
@export var camera_rig: CameraRig
@export var hud: Hud
@export var requires_explorer := false

var _nearby := false
var _travelling := false


func _ready() -> void:
	HarborProps.dock(self)
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))
	hud.travel_requested.connect(_travel)
	GameState.supplies_changed.connect(_refresh_availability)
	_refresh_availability()


func _on_body_changed(body: Node3D, nearby: bool) -> void:
	if body is not Player:
		return
	_nearby = nearby
	if nearby:
		_refresh_availability()
	else:
		hud.clear_travel_available(destination_water.biome.display_name)


func _refresh_availability() -> void:
	$Sign.visible = _nearby
	$Sign.text = destination_water.biome.display_name
	if requires_explorer and not GameState.boat_upgraded:
		$Sign.text += "\nНужна лодка исследователя"
	$Sign.font_size = 42
	$Sign.modulate = Color("#f0e5c6")
	$Sign.outline_size = 4
	if _nearby:
		hud.set_travel_available(destination_water.biome.display_name, requires_explorer and not GameState.boat_upgraded)


func _travel() -> void:
	if not _nearby or _travelling or hud.is_modal_open() or fishing_controller.phase != FishingController.Phase.IDLE:
		return
	if requires_explorer and not GameState.boat_upgraded:
		hud.toast("Улучши лодку у Луки: %d монет" % GameState.BOAT.price)
		return
	_travelling = true
	player.can_move = false
	hud.clear_travel_available(destination_water.biome.display_name)
	await hud.fade_out("Плывём: %s" % destination_water.biome.display_name)
	fishing_controller.water = destination_water
	player.global_position = arrival_point.global_position
	player.velocity = Vector3.ZERO
	camera_rig.snap_to_target()
	hud.set_biome(destination_water.biome)
	GameState.visit_biome(destination_water.biome.id)
	await hud.fade_in()
	player.can_move = true
	_travelling = false
