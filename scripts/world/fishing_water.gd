class_name FishingWater
extends Node3D
## Водоём вокруг фигурного острова. Отвечает на вопрос «эта точка — вода?»
## и задаёт, какие рыбы здесь водятся.

@export var biome: BiomeData
@export var water_level := 0.0
## Средний радиус контура; бухта и изгибы заданы в ShoreProfile.
@export var shore_radius := 12.8


func is_water(point: Vector3) -> bool:
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() > ShoreProfile.radius_at(atan2(offset.z, offset.x), shore_radius)


func habitat_id() -> StringName:
	return biome.habitat if biome else &"lake"


## Забираем рыбу у кромки, а не протаскиваем поплавок под сушей до ног игрока.
func landing_distance(origin: Vector3, direction: Vector3, cast_distance: float) -> float:
	var wet := cast_distance
	var steps := ceili(cast_distance / 0.4)
	for i in range(1, steps + 1):
		var distance := cast_distance * (1.0 - float(i) / steps)
		if is_water(origin + direction * distance):
			wet = distance
			continue
		var dry := distance
		for search in 10:
			var middle := (dry + wet) * 0.5
			if is_water(origin + direction * middle):
				wet = middle
			else:
				dry = middle
		return clampf(wet + 0.25, FishingSession.LANDED_DISTANCE, maxf(FishingSession.LANDED_DISTANCE, cast_distance - 0.2))
	return FishingSession.LANDED_DISTANCE


## Рыбное место, в которое попала точка, или null.
func spot_at(point: Vector3) -> FishingSpot:
	for child in get_children():
		var spot := child as FishingSpot
		if spot and spot.contains(point):
			return spot
	return null
