class_name BoatVisual
extends Node3D
## Одна и та же собственная модель у причалов и во время прогулки.

var _origin: Vector3
var _rig: Node3D
var _time := 0.0
var _pennant: Node3D


func _ready() -> void:
	_origin = position
	# Старые сценовые заглушки остаются совместимы с существующими причалами.
	for child in get_children():
		if child is MeshInstance3D:
			child.hide()
	_rig = BoatArt.build(self)
	var lantern := Node3D.new()
	lantern.position = Vector3(-0.52, 0.27, 1.1)
	lantern.scale = Vector3.ONE * 0.25
	lantern.set_script(preload("res://scripts/world/harbor_lantern.gd"))
	add_child(lantern)
	GameState.supplies_changed.connect(_refresh)
	GameState.journey_changed.connect(_refresh)
	_pennant = _build_pennant()
	_refresh()


func _refresh() -> void:
	_rig.visible = GameState.boat_upgraded
	_pennant.visible = GameState.found_messages.size() == GameState.MESSAGES.messages.size()


func _build_pennant() -> Node3D:
	var pennant := Node3D.new()
	pennant.name = "HomePennant"
	pennant.add_to_group(&"boat_pennant")
	add_child(pennant)
	var art := ArtMesh.new()
	var foot := Vector3(0.58, 0.27, 1.28)
	art.tube(foot, foot + Vector3.UP * 1.55, 0.025, Color("#8f7152"), 0.02, 6)
	var top := foot + Vector3.UP * 1.45
	art.triangle(top, top + Vector3(0.18, -0.24, 0.85), top + Vector3(0, -0.24, 0), Color("#d7b76e"))
	art.triangle(top + Vector3(0, -0.24, 0), top + Vector3(0.18, -0.24, 0.85), top + Vector3(0, -0.48, 0), Color("#527c69"))
	art.instance(pennant, "GreenAndGoldPennant")
	return pennant


func _process(delta: float) -> void:
	_time += delta
	position.y = _origin.y + sin(_time * 1.3 + _origin.x) * 0.05
	rotation.z = sin(_time * 0.8) * 0.02
