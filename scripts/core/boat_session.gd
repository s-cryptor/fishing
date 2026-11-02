class_name BoatSession
extends RefCounted
## Чистая навигация прогулки: инерция, скольжение вдоль берега и граница бухты.

const HULL_CLEARANCE := 2.0
const EXCURSION_RADIUS := 34.0
var position: Vector2
var velocity := Vector2.ZERO
var heading := 0.0
var speed := 6.0
var shore_radius := 12.8
var blocked := false


func _init(start: Vector2, p_speed := 6.0, p_shore_radius := 12.8) -> void:
	shore_radius = p_shore_radius
	speed = p_speed
	var angle := start.angle()
	var minimum := ShoreProfile.radius_at(angle, shore_radius) + HULL_CLEARANCE + 0.1
	position = Vector2.from_angle(angle) * clampf(start.length(), minimum, EXCURSION_RADIUS - 0.1)


func is_safe(point: Vector2) -> bool:
	var radius := point.length()
	return radius <= EXCURSION_RADIUS and radius >= ShoreProfile.radius_at(point.angle(), shore_radius) + HULL_CLEARANCE


func tick(delta: float, direction: Vector2, anchored: bool) -> void:
	blocked = false
	if anchored:
		velocity = Vector2.ZERO
		return
	velocity = velocity.move_toward(direction.limit_length() * speed, delta * 7.0)
	var movement := velocity * delta
	var steps := maxi(1, ceili(movement.length() / 0.25))
	for i in steps:
		var step := movement / steps
		if is_safe(position + step):
			position += step
		else:
			blocked = true
			# Сохраняем безопасную составляющую хода вдоль берега.
			if is_safe(position + Vector2(step.x, 0)):
				position.x += step.x
			if is_safe(position + Vector2(0, step.y)):
				position.y += step.y
	if velocity.length_squared() > 0.05:
		var target := atan2(-velocity.x, -velocity.y)
		heading = lerp_angle(heading, target, 1.0 - exp(-5.0 * delta))
