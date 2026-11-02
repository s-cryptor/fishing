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

var _nearby := false
var _travelling := false


func _ready() -> void:
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))
	hud.travel_requested.connect(_travel)


func _on_body_changed(body: Node3D, nearby: bool) -> void:
	if body is not Player:
		return
	_nearby = nearby
	if nearby:
		hud.set_travel_available(destination_water.biome.display_name)
	else:
		hud.clear_travel_available(destination_water.biome.display_name)


func _travel() -> void:
	if not _nearby or _travelling or hud.is_modal_open() or fishing_controller.phase != FishingController.Phase.IDLE:
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
	await hud.fade_in()
	player.can_move = true
	_travelling = false
