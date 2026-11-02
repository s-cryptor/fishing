class_name BoatVisual
extends Node3D
## Одна и та же собственная модель у причалов и во время прогулки.

var _origin: Vector3
var _rig: Node3D
var _time := 0.0


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
	_refresh()


func _refresh() -> void:
	_rig.visible = GameState.boat_upgraded


func _process(delta: float) -> void:
	_time += delta
	position.y = _origin.y + sin(_time * 1.3 + _origin.x) * 0.05
	rotation.z = sin(_time * 0.8) * 0.02
