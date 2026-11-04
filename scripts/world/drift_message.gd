class_name DriftMessage
extends Node3D
## Бутылку подбирают только с лодки и отдельным действием, а не при пересечении точки.

@export var data: DriftMessageData
var _nearby := false
var _hud: Hud
var _controller: FishingController
var _player: Player
var _float: Node3D
var _ring: MeshInstance3D
var _ring_material := StandardMaterial3D.new()
var _sign: Label3D
var _time := 0.0


func _ready() -> void:
	add_to_group(&"drift_message")
	_hud = get_tree().get_first_node_in_group(&"game_hud") as Hud
	_controller = get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	_player = get_tree().get_first_node_in_group(&"player") as Player
	_time = posmod(String(data.id).hash(), 100) * 0.1
	_float = Node3D.new()
	add_child(_float)
	var art := ArtMesh.new()
	art.tube(Vector3(-0.4, 0.14, 0), Vector3(0.25, 0.21, 0), 0.18, Color("#589d8d"), 0.16, 8)
	art.tube(Vector3(0.25, 0.21, 0), Vector3(0.42, 0.23, 0), 0.16, Color("#79b6a0"), 0.07, 8)
	art.tube(Vector3(0.42, 0.23, 0), Vector3(0.58, 0.25, 0), 0.07, Color("#589d8d"), 0.07, 8)
	art.tube(Vector3(0.56, 0.25, 0), Vector3(0.66, 0.26, 0), 0.07, Color("#bd9768"), 0.075, 7)
	art.box(Vector3(-0.08, 0.3, 0), Vector3(0.32, 0.025, 0.19), Color("#ebdcb0"), Vector3(0, 0, 0.1))
	art.instance(_float, "BottleAndLetter")
	_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 0.94
	ring.rings = 24
	ring.ring_segments = 6
	_ring.mesh = ring
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.albedo_color = Color(0.91, 0.76, 0.4, 0.5)
	_ring.material_override = _ring_material
	_ring.position.y = 0.01
	add_child(_ring)
	_sign = Label3D.new()
	_sign.text = "Письмо в бутылке"
	_sign.position.y = 1.1
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 36
	_sign.pixel_size = 0.008
	_sign.outline_size = 3
	_sign.modulate = Color("#efdeb3")
	_sign.hide()
	add_child(_sign)
	_hud.landmark_requested.connect(_collect)
	GameState.journey_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var found := String(data.id) in GameState.found_messages
	visible = not found
	set_process(not found)
	if found:
		_nearby = false
		_sign.hide()
		_hud.clear_message_available(data)


func _process(delta: float) -> void:
	_time += delta
	_float.position.y = sin(_time * 1.6) * 0.045
	_float.rotation = Vector3(0.0, 0.35 + sin(_time * 0.5) * 0.15, sin(_time * 1.3) * 0.05)
	_ring_material.albedo_color.a = 0.38 + sin(_time * 2.0) * 0.12
	var distance := Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length()
	var nearby := distance <= 3.0 and is_instance_valid(_player.ride_target) and _controller.water.habitat_id() == data.habitat
	_sign.visible = nearby and not _hud.is_modal_open() and _controller.phase == FishingController.Phase.IDLE
	if nearby != _nearby:
		_nearby = nearby
		if nearby:
			_hud.set_message_available(data)
		else:
			_hud.clear_message_available(data)


func _collect() -> void:
	if not _nearby or _hud.is_modal_open() or _controller.phase != FishingController.Phase.IDLE:
		return
	if GameState.discover_message(data.id):
		_hud.show_message(data, true)
		Sfx.play(&"new_species", -8.0, 0.9)
