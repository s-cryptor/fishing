class_name FishingWaterFx
extends Node3D
## Ограниченный пул кругов и капель: никаких новых узлов во время борьбы.

const RING_COUNT := 10
const DROP_COUNT := 14
var _rings: Array[MeshInstance3D] = []
var _ages: Array[float] = []
var _strengths: Array[float] = []
var _drops: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _drop_age := 1.0
var _water_y := 0.0
var _next := 0
var _shadow: MeshInstance3D


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	var ring := TorusMesh.new()
	ring.inner_radius = 0.47
	ring.outer_radius = 0.5
	ring.rings = 24
	ring.ring_segments = 6
	for i in RING_COUNT:
		var node := MeshInstance3D.new()
		node.mesh = ring
		node.material_override = _material(Color("#c5ded0"))
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_rings.append(node)
		_ages.append(2.0)
		_strengths.append(1.0)
	var drop := SphereMesh.new()
	drop.radius = 0.035
	drop.height = 0.12
	drop.radial_segments = 5
	drop.rings = 3
	var drop_material := _material(Color("#d3e7d8"))
	for i in DROP_COUNT:
		var node := MeshInstance3D.new()
		node.mesh = drop
		node.material_override = drop_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_drops.append(node)
		_velocities.append(Vector3.ZERO)
	var art := ArtMesh.new()
	art.pebble(Vector3.ZERO, Vector3(0.22, 0.018, 0.56), Color.WHITE)
	art.triangle(Vector3(0, 0, -0.36), Vector3(-0.24, 0, -0.75), Vector3(0.24, 0, -0.75), Color.WHITE)
	_shadow = art.instance(self, "FishSilhouette")
	_shadow.material_override = _material(Color(0.08, 0.25, 0.25, 0.28))
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reset()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func ripple(point: Vector3, strength := 1.0) -> void:
	var ring := _rings[_next]
	ring.position = point + Vector3.UP * 0.035
	_ages[_next] = 0.0
	_strengths[_next] = strength
	ring.scale = Vector3(0.25, 1, 0.25)
	ring.show()
	_next = (_next + 1) % RING_COUNT


func splash(point: Vector3) -> void:
	ripple(point, 1.6)
	_drop_age = 0.0
	_water_y = point.y
	for i in DROP_COUNT:
		var angle := TAU * i / DROP_COUNT
		_drops[i].position = point + Vector3.UP * 0.06
		_drops[i].show()
		_velocities[i] = Vector3(cos(angle) * 0.8, 1.3 + (i % 3) * 0.3, sin(angle) * 0.8)


func fish_at(point: Vector3, heading: float, size_factor: float) -> void:
	_shadow.show()
	_shadow.position = point + Vector3.UP * 0.02
	_shadow.rotation.y = heading
	_shadow.scale = Vector3.ONE * size_factor


func reset() -> void:
	for ring in _rings:
		ring.hide()
	for drop in _drops:
		drop.hide()
	if _shadow:
		_shadow.hide()
	_drop_age = 1.0
	for i in _ages.size():
		_ages[i] = 2.0


func _process(delta: float) -> void:
	for i in RING_COUNT:
		_ages[i] += delta
		var age := _ages[i]
		if age >= 1.4:
			_rings[i].hide()
			continue
		var radius := (0.25 + age * 1.5) * _strengths[i]
		_rings[i].scale = Vector3(radius, 1, radius)
		var material := _rings[i].material_override as StandardMaterial3D
		material.albedo_color.a = (1.0 - age / 1.4) * 0.45
	_drop_age += delta
	if _drop_age < 0.8:
		for i in DROP_COUNT:
			_velocities[i].y -= delta * 5.5
			_drops[i].position += _velocities[i] * delta
			if _drops[i].position.y < _water_y:
				_drops[i].hide()
