extends Node3D
## Окна становятся тёплыми к вечеру и освещают дорожку у дома.

var _glass := StandardMaterial3D.new()
var _lights: Array[OmniLight3D] = []


func _ready() -> void:
	_glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for data in [[Vector3(-1.1, 1.55, 1.88), Vector3(0.8, 0.74, 0.035)],
			[Vector3(-2.12, 1.55, 0.1), Vector3(0.035, 0.74, 0.8)],
			[Vector3(-0.75, 1.55, -1.88), Vector3(0.9, 0.8, 0.035)]]:
		var window := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = data[1]
		window.mesh = box
		window.position = data[0]
		window.material_override = _glass
		add_child(window)
		var light := OmniLight3D.new()
		light.position = data[0] + Vector3(-0.25, 0, 0.3 * signf(data[0].z))
		light.light_color = Color("#efba72")
		light.omni_range = 4.0
		add_child(light)
		_lights.append(light)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var hour := WorldClock.hour
	var night := clampf((hour - 17.0) / 3.0, 0.0, 1.0) if hour > 12.0 else 1.0 - clampf((hour - 5.0) / 2.0, 0.0, 1.0)
	_glass.albedo_color = Color("#acbfa7").lerp(Color("#f1c475"), night)
	for light in _lights:
		light.light_energy = night * 0.9
		light.visible = night > 0.01
