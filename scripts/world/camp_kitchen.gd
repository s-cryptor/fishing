class_name CampKitchen
extends Area3D
## Марта у огорода: обычный улов превращается в походные усиления.

var _hud: Hud
var _controller: FishingController
var _nearby := false
var _steam: Array[MeshInstance3D] = []
var _fire: OmniLight3D
var _time := 0.0
var _sign: Label3D


func _ready() -> void:
	add_to_group(&"camp_kitchen")
	_hud = get_tree().get_first_node_in_group(&"game_hud") as Hud
	_controller = get_tree().get_first_node_in_group(&"fishing_controller") as FishingController
	_build()
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.6
	collision.shape = sphere
	collision.position = Vector3(0, 0.8, 0.9)
	add_child(collision)
	body_entered.connect(_on_body.bind(true))
	body_exited.connect(_on_body.bind(false))
	_hud.kitchen_requested.connect(_open)


func _build() -> void:
	var art := ArtMesh.new()
	for i in 8:
		var angle := TAU * i / 8
		art.pebble(Vector3(cos(angle) * 0.52, 0.12, sin(angle) * 0.52), Vector3(0.19, 0.16, 0.18), Color("#879181"), i)
	for side in [-1, 1]:
		art.tube(Vector3(side * 0.25, 0.12, -0.2), Vector3(-side * 0.25, 0.2, 0.25), 0.08, Color("#75634b"), 0.08)
		art.tube(Vector3(side * 0.38, 0.15, 0), Vector3(side * 0.38, 0.72, 0), 0.03, Color("#4b5d51"), 0.03)
	art.pebble(Vector3(0, 0.22, 0), Vector3(0.3, 0.14, 0.25), Color("#cb8b51"))
	art.tube(Vector3(0, 0.55, 0), Vector3(0, 0.89, 0), 0.35, Color("#45584f"), 0.46, 12)
	art.tube(Vector3(0, 0.885, 0), Vector3(0, 0.905, 0), 0.4, Color("#bf9759"), 0.4, 12)
	for x in [-0.47, 0.47]:
		art.tube(Vector3(x, 0.7, -0.1), Vector3(x, 0.83, 0), 0.022, Color("#45584f"), 0.022, 5)
		art.tube(Vector3(x, 0.83, 0), Vector3(x, 0.7, 0.1), 0.022, Color("#45584f"), 0.022, 5)
	art.box(Vector3(1.15, 0.65, -0.1), Vector3(1.1, 0.12, 0.75), Color("#a48b65"))
	for x in [0.7, 1.6]:
		for z in [-0.35, 0.15]:
			art.box(Vector3(x, 0.3, z), Vector3(0.08, 0.6, 0.08), Color("#806d52"))
	art.pebble(Vector3(1.1, 0.79, -0.05), Vector3(0.26, 0.13, 0.14), Color("#bd9a62"))
	for i in 3:
		art.tube(Vector3(1.5, 0.72, 0), Vector3(1.4 + i * 0.08, 0.98, 0.03), 0.016, Color("#78915d"), 0.008, 5)
	art.instance(self, "MartaKitchen")
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 1.0, 1.0)
	shape.shape = box
	shape.position = Vector3(0.6, 0.5, 0)
	body.add_child(shape)
	add_child(body)
	var marta := NeighborModel.new()
	marta.cook = true
	marta.position = Vector3(-0.25, 0, -0.9)
	add_child(marta)
	_sign = Label3D.new()
	_sign.position = Vector3(0, 2.8, -0.5)
	_sign.text = "Марта · походная кухня"
	_sign.font_size = 42
	_sign.pixel_size = 0.007
	_sign.outline_size = 4
	_sign.modulate = Color("#efe4be")
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.hide()
	add_child(_sign)
	var steam_mesh := SphereMesh.new()
	steam_mesh.radial_segments = 8
	steam_mesh.rings = 4
	for i in 4:
		var puff := MeshInstance3D.new()
		puff.mesh = steam_mesh
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = material
		add_child(puff)
		_steam.append(puff)
	_fire = OmniLight3D.new()
	_fire.position = Vector3(0, 0.6, 0.2)
	_fire.light_color = Color("#efb56c")
	_fire.omni_range = 3.0
	add_child(_fire)


func _on_body(body: Node3D, nearby: bool) -> void:
	if body is not Player:
		return
	_nearby = nearby
	_sign.visible = nearby
	_hud.set_kitchen_available(nearby)


func _open() -> void:
	if _nearby and not _hud.is_modal_open() and _controller.phase == FishingController.Phase.IDLE:
		_hud.open_kitchen()


func _process(delta: float) -> void:
	_time += delta
	for i in _steam.size():
		var phase := fmod(_time * 0.35 + i * 0.25, 1.0)
		_steam[i].position = Vector3(sin(phase * 5 + i) * 0.08, 1.0 + phase * 0.9, phase * 0.12)
		_steam[i].scale = Vector3.ONE * (0.12 + phase * 0.24)
		var material := _steam[i].material_override as StandardMaterial3D
		material.albedo_color = Color(0.88, 0.87, 0.78, sin(phase * PI) * 0.12)
	_fire.light_energy = 0.45 + sin(_time * 3) * 0.035
