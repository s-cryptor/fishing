class_name LandmarkPoint
extends Area3D
## Осмотр места требует отдельного действия; само прохождение рядом не даёт награду.

@export var data: LandmarkData
var _nearby := false
var _hud: Hud
var _controller: FishingController
var _sign: Label3D


func _ready() -> void:
	add_to_group(&"landmark")
	LandmarkArt.build(self, data.kind)
	_hud = get_tree().get_first_node_in_group(&"game_hud") as Hud
	_controller = get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.3
	collision.shape = sphere
	collision.position = Vector3(0, 0.7, 1.8)
	add_child(collision)
	_sign = Label3D.new()
	_sign.text = data.title
	_sign.position = Vector3(0, 2.3, 1.6)
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 40
	_sign.pixel_size = 0.007
	_sign.outline_size = 4
	_sign.modulate = Color("#efe4be")
	_sign.hide()
	add_child(_sign)
	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))
	_hud.landmark_requested.connect(_inspect)


func _on_body(body: Node3D, nearby: bool) -> void:
	if body is not Player:
		return
	_nearby = nearby
	_sign.visible = nearby
	if nearby:
		_hud.set_landmark_available(data)
	else:
		_hud.clear_landmark_available(data)


func _inspect() -> void:
	if not _nearby or _hud.is_modal_open() or _controller.phase != FishingController.Phase.IDLE:
		return
	var is_new := GameState.discover_landmark(data.id)
	_hud.show_landmark(data, is_new)
	if is_new:
		Sfx.play(&"new_species", -8.0, 0.85)
