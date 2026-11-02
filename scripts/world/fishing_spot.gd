class_name FishingSpot
extends Node3D
## Рыбное место: пузыри и тень рыбы на воде. Заброс сюда ускоряет поклёвку
## и повышает шанс редких рыб. Место «выдыхается» после улова или со временем
## и переезжает в другую точку водоёма.

const CORE_RATIO := 0.3

@export var radius := 2.5
@export var bite_time_mult := 0.5
@export var luck_bonus := 1.0
@export var precision_luck_bonus := 0.5
@export var precision_bite_mult := 0.75
@export var min_lifetime := 40.0
@export var max_lifetime := 75.0
## Насколько далеко от берега может появиться место, м.
@export var min_offshore := 2.0
@export var max_offshore := 12.0

var _water: FishingWater
var _lifetime := 0.0
var _time := 0.0
var _relocating := false
var _reserved := false
var _school: Array[Node3D] = []

@onready var _shadow: Node3D = $Shadow
@onready var _bubbles: Array[Node] = $Bubbles.get_children()


func _ready() -> void:
	add_to_group(&"fishing_spot")
	_water = get_parent() as FishingWater
	for child in _shadow.get_children():
		child.hide()
	for i in 3:
		var fish := FishSilhouette.create(_shadow)
		fish.scale = Vector3.ONE * (0.75 + i * 0.12)
		_school.append(fish)
	var core := MeshInstance3D.new()
	core.name = "Core"
	var ring := TorusMesh.new()
	ring.inner_radius = radius * CORE_RATIO - 0.025
	ring.outer_radius = radius * CORE_RATIO
	ring.rings = 32
	ring.ring_segments = 6
	core.mesh = ring
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.92, 0.82, 0.56, 0.45)
	core.material_override = material
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)
	_relocate(false)


func contains(point: Vector3) -> bool:
	if _relocating or _reserved:
		return false
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() <= radius


func is_precise(point: Vector3) -> bool:
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() <= radius * CORE_RATIO


func reserve() -> bool:
	if _relocating or _reserved:
		return false
	_reserved = true
	return true


func release() -> void:
	_reserved = false


## Снасти с бонусами места. Исходный ресурс не меняем — он общий.
func boost(gear: GearStats, precise := false) -> GearStats:
	var boosted := gear.duplicate() as GearStats
	boosted.bite_time_mult *= bite_time_mult
	boosted.luck += luck_bonus
	if precise:
		boosted.bite_time_mult *= precision_bite_mult
		boosted.luck += precision_luck_bonus
	return boosted


## Рыбу отсюда вытащили — место переезжает.
func deplete() -> void:
	_reserved = false
	if not _relocating:
		_relocate(true)


func _process(delta: float) -> void:
	_time += delta
	if not _reserved:
		_lifetime -= delta
	if _lifetime <= 0.0 and not _relocating and not _reserved:
		_relocate(true)
	# Тень рыбы лениво кружит, пузыри поднимаются и появляются заново.
	_shadow.position = Vector3(cos(_time * 0.7), 0.0, sin(_time * 0.7)) * radius * 0.35
	_shadow.rotation.y = -_time * 0.7
	for i in _school.size():
		_school[i].position = Vector3(sin(_time * 1.2 + i * 2) * 0.22 + (i - 1) * 0.45, 0.005 + i * 0.002, cos(i * 2.5) * 0.45)
		_school[i].rotation.y = sin(_time * 2 + i) * 0.15
	$Ring.scale = Vector3.ONE * (0.86 + sin(_time * 0.8) * 0.08)
	for i in _bubbles.size():
		var bubble := _bubbles[i] as Node3D
		var phase := fmod(_time * 0.8 + i * 0.37, 1.0)
		bubble.position.y = phase * 0.25
		bubble.scale = Vector3.ONE * (1.0 - phase)


func _relocate(animated: bool) -> void:
	_relocating = true
	if animated:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.6)
		await tween.finished
	_lifetime = randf_range(min_lifetime, max_lifetime)
	var angle := randf() * TAU
	var distance := ShoreProfile.radius_at(angle, _water.shore_radius) + randf_range(min_offshore, max_offshore)
	global_position = _water.global_position + Vector3(cos(angle) * distance, _water.water_level + 0.02, sin(angle) * distance)
	scale = Vector3.ONE * 0.01
	var appear := create_tween()
	appear.tween_property(self, "scale", Vector3.ONE, 0.8)
	await appear.finished
	_relocating = false
