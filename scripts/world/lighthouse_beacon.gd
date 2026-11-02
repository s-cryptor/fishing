extends Node3D
## Тёплый фонарь и тихо вращающийся луч без объёмных постэффектов.

var _glass: StandardMaterial3D
var _spot: SpotLight3D
var _glow: OmniLight3D
var _pivot: Node3D
var _time := 0.0


func _ready() -> void:
	var lamp := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.51
	mesh.bottom_radius = 0.51
	mesh.height = 0.75
	mesh.radial_segments = 6
	lamp.mesh = mesh
	_glass = StandardMaterial3D.new()
	_glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp.material_override = _glass
	add_child(lamp)
	_glow = OmniLight3D.new()
	_glow.light_color = Color("#f3ca80")
	_glow.omni_range = 7.0
	add_child(_glow)
	_pivot = Node3D.new()
	add_child(_pivot)
	_spot = SpotLight3D.new()
	_spot.rotation.x = -0.22
	_spot.spot_range = 25.0
	_spot.spot_angle = 18.0
	_spot.spot_attenuation = 0.7
	_spot.light_color = Color("#f5d499")
	_pivot.add_child(_spot)
	_process(0.0)


func _process(delta: float) -> void:
	_time += delta
	_pivot.rotation.y = _time * 0.2
	var hour := WorldClock.hour
	var strength := clampf((hour - 17.5) / 2, 0, 1) if hour > 12 else 1.0 - clampf((hour - 5) / 2, 0, 1)
	_glass.albedo_color = Color("#829b8e").lerp(Color("#f6d48b"), strength)
	_glow.light_energy = strength * 1.3
	_spot.light_energy = strength * 2.0
	_glow.visible = strength > 0.01
	_spot.visible = strength > 0.01
