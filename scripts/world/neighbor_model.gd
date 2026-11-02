class_name NeighborModel
extends Node3D
## Свои игрушечные соседи: общие пропорции, узнаваемые лица и одежда.

@export var cook := false
var _visual: Node3D
var _player: Node3D
var _time := 0.0


func _ready() -> void:
	add_to_group(&"neighbor")
	_time = global_position.x * 0.37 + global_position.z * 0.43
	_visual = Node3D.new()
	add_child(_visual)
	var art := ArtMesh.new()
	var skin := Color("#dfb18a") if cook else Color("#bd9673")
	var coat := Color("#9a6854") if cook else Color("#4b7774")
	var apron := Color("#d8cba7") if cook else Color("#a7a482")
	for side in [-1, 1]:
		art.tube(Vector3(side * 0.17, 0.2, 0), Vector3(side * 0.17, 0.73, 0), 0.12, Color("#3d585b"), 0.13, 6)
		art.box(Vector3(side * 0.17, 0.11, 0.07), Vector3(0.24, 0.22, 0.37), Color("#4e4e40"))
		art.tube(Vector3(side * 0.33, 1.27, 0), Vector3(side * 0.42, 0.88, 0.18), 0.12, coat, 0.1, 6)
		art.pebble(Vector3(side * 0.42, 0.83, 0.2), Vector3(0.1, 0.11, 0.1), skin, side)
	art.box(Vector3(0, 1.03, 0), Vector3(0.63, 0.68, 0.43), coat)
	art.box(Vector3(0, 0.96, 0.23), Vector3(0.47, 0.66, 0.035), apron)
	art.box(Vector3(0, 0.91, 0.26), Vector3(0.27, 0.2, 0.02), apron.darkened(0.12))
	for side in [-1, 1]:
		art.tube(Vector3(side * 0.12, 1.37, 0.24), Vector3(side * 0.2, 0.66, 0.25), 0.025, apron, 0.025, 5)
	art.tube(Vector3(0, 1.31, 0), Vector3(0, 1.48, 0), 0.11, skin, 0.11, 7)
	art.pebble(Vector3(0, 1.64, 0), Vector3(0.27, 0.29, 0.25), skin, 3)
	for side in [-1, 1]:
		art.pebble(Vector3(side * 0.09, 1.7, 0.23), Vector3(0.028, 0.038, 0.018), Color("#233d39"))
	art.pebble(Vector3(0, 1.59, 0.27), Vector3(0.05, 0.055, 0.055), skin.lightened(0.08))
	if cook:
		art.pebble(Vector3(0, 1.75, -0.12), Vector3(0.27, 0.25, 0.2), Color("#715343"))
		art.pebble(Vector3(0, 1.8, -0.29), Vector3.ONE * 0.15, Color("#715343"))
		art.tube(Vector3(0, 1.86, 0), Vector3(0, 2.0, 0), 0.28, Color("#e4dcc1"), 0.29, 10)
		for x in [-0.14, 0, 0.14]:
			art.pebble(Vector3(x, 2.04, 0), Vector3(0.18, 0.17, 0.2), Color("#ece4cd"), x * 7)
		art.tube(Vector3(0.43, 0.88, 0.2), Vector3(0.5, 0.55, 0.6), 0.022, Color("#a38a60"), 0.018, 5)
		art.pebble(Vector3(0.5, 0.54, 0.61), Vector3(0.08, 0.025, 0.1), Color("#a38a60"))
	else:
		for side in [-1, 1]:
			art.pebble(Vector3(side * 0.06, 1.51, 0.24), Vector3(0.085, 0.035, 0.04), Color("#65513e"))
		art.tube(Vector3(0, 1.86, 0), Vector3(0, 1.92, 0), 0.43, Color("#c9b47d"), 0.43, 12)
		art.tube(Vector3(0, 1.92, 0), Vector3(0, 2.13, 0), 0.27, Color("#c9b47d"), 0.23, 10)
		art.tube(Vector3(0, 1.94, 0), Vector3(0, 1.99, 0), 0.28, coat, 0.27, 10)
	art.instance(_visual, "Neighbor")
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.55
	collision.shape = capsule
	collision.position.y = 0.78
	body.add_child(collision)
	add_child(body)


func _process(delta: float) -> void:
	_time += delta
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	var yaw := 0.0
	if _player and _player.global_position.distance_to(global_position) < 4.5:
		var offset := _player.global_position - global_position
		yaw = atan2(offset.x, offset.z) - global_rotation.y
	_visual.rotation.y = lerp_angle(_visual.rotation.y, yaw, 1.0 - exp(-3 * delta))
	_visual.scale.y = 1.0 + sin(_time * 1.8) * 0.008
