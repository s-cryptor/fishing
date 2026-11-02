extends Node3D
## Небольшой ветер без тяжёлого шейдера; ствол и коллизия остаются неподвижны.

var strength := 0.012
var _phase := 0.0
var _rest := Vector3.ZERO


func _ready() -> void:
	_phase = global_position.x * 0.43 + global_position.z * 0.61
	_rest = rotation


func _process(delta: float) -> void:
	_phase += delta * 0.8
	rotation = _rest + Vector3(sin(_phase) * strength, 0, cos(_phase * 0.73) * strength * 0.7)
