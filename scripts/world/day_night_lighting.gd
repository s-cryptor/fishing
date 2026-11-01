class_name DayNightLighting
extends Node
## Подстраивает солнце, небо и окружение под WorldClock.hour.
## Ключевые кадры по часам, между ними — линейная интерполяция.

const KEYS: Array[float] = [0.0, 5.0, 6.5, 9.0, 17.0, 19.5, 21.5, 24.0]

const NIGHT := {
	"sun": Color(0.45, 0.55, 0.9), "energy": 0.25, "ambient": 0.3,
	"top": Color(0.04, 0.07, 0.18), "horizon": Color(0.12, 0.16, 0.3),
}
const DAWN := {
	"sun": Color(1.0, 0.68, 0.45), "energy": 0.75, "ambient": 0.6,
	"top": Color(0.35, 0.45, 0.75), "horizon": Color(1.0, 0.72, 0.55),
}
const DAY := {
	"sun": Color(1.0, 0.97, 0.9), "energy": 1.0, "ambient": 0.8,
	"top": Color(0.32, 0.58, 0.88), "horizon": Color(0.72, 0.84, 0.95),
}
const DUSK := {
	"sun": Color(1.0, 0.55, 0.35), "energy": 0.7, "ambient": 0.55,
	"top": Color(0.3, 0.3, 0.6), "horizon": Color(1.0, 0.55, 0.4),
}

@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment

var _frames: Array[Dictionary] = [NIGHT, NIGHT, DAWN, DAY, DAY, DUSK, NIGHT, NIGHT]
var _sky: ProceduralSkyMaterial


func _ready() -> void:
	_sky = environment.environment.sky.sky_material as ProceduralSkyMaterial
	_apply(WorldClock.hour)


func _process(_delta: float) -> void:
	_apply(WorldClock.hour)


func _apply(hour: float) -> void:
	var i := 0
	while i < KEYS.size() - 2 and hour >= KEYS[i + 1]:
		i += 1
	var t := inverse_lerp(KEYS[i], KEYS[i + 1], hour)
	var a := _frames[i]
	var b := _frames[i + 1]

	sun.light_color = (a["sun"] as Color).lerp(b["sun"], t)
	sun.light_energy = lerpf(a["energy"], b["energy"], t)
	environment.environment.ambient_light_energy = lerpf(a["ambient"], b["ambient"], t)
	_sky.sky_top_color = (a["top"] as Color).lerp(b["top"], t)
	_sky.sky_horizon_color = (a["horizon"] as Color).lerp(b["horizon"], t)
	_sky.ground_horizon_color = _sky.sky_horizon_color

	# Днём солнце идёт по небу с востока на запад, ночью светит «луна» сверху.
	var daylight := sin((hour - 6.0) / 12.0 * PI)
	var elevation := deg_to_rad(lerpf(12.0, 65.0, daylight) if daylight > 0.0 else 50.0)
	var azimuth := deg_to_rad(lerpf(-70.0, 70.0, clampf((hour - 6.0) / 12.0, 0.0, 1.0)))
	sun.basis = Basis.from_euler(Vector3(-elevation, azimuth, 0.0), EULER_ORDER_YXZ)
