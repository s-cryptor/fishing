extends Node3D
## Тёплый свет у причала включается в сумерках, помогая найти дорогу домой.

var _light: OmniLight3D
var _material: StandardMaterial3D


func _ready() -> void:
	var post := MeshInstance3D.new()
	var stem := CylinderMesh.new()
	stem.top_radius = 0.06
	stem.bottom_radius = 0.08
	stem.height = 2.3
	stem.radial_segments = 6
	post.mesh = stem
	post.position.y = 1.15
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#5b493c")
	post.material_override = wood
	add_child(post)
	var lamp := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.34, 0.45, 0.34)
	lamp.mesh = shape
	lamp.position.y = 2.3
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color("#ffd391")
	_material.emission_enabled = true
	_material.emission = Color("#ffb85f")
	lamp.material_override = _material
	add_child(lamp)
	_light = OmniLight3D.new()
	_light.position.y = 2.3
	_light.light_color = Color("#ffca82")
	_light.omni_range = 8.0
	_light.shadow_enabled = false
	add_child(_light)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var hour := WorldClock.hour
	var strength := clampf((hour - 17.5) / 2.0, 0.0, 1.0) if hour > 12.0 else 1.0 - clampf((hour - 5.0) / 2.0, 0.0, 1.0)
	_light.light_energy = strength * 1.6
	_light.visible = strength > 0.01
	_material.emission_energy_multiplier = strength * 2.0
