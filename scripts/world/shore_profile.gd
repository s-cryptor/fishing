class_name ShoreProfile
extends RefCounted
## Общий контур для меша берега, воды, рыбных мест и невидимой ограды.

const WAVES := Vector3(0.9, 0.38, 0.3)
const COVE := Vector3(0.35, 0.34, 2.8)

static func radius_at(angle: float, base := 12.8) -> float:
	var cove_angle := atan2(sin(angle - COVE.x), cos(angle - COVE.x))
	var cove := exp(-pow(cove_angle / COVE.y, 2.0)) * COVE.z
	return base + sin(angle * 3.0 + 0.4) * WAVES.x + sin(angle * 5.0 - 0.7) * WAVES.y + cos(angle * 2.0) * WAVES.z - cove
