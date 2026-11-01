class_name Bobber
extends Node3D
## Поплавок: полёт при забросе, покачивание, поклёвка, борьба.

signal landed

enum Mode { HIDDEN, FLYING, FLOATING, BITE, FIGHT }

var mode := Mode.HIDDEN:
	set(value):
		mode = value
		visible = mode != Mode.HIDDEN
		_bite_mark.visible = mode == Mode.BITE
## Точка на воде, вокруг которой поплавок качается.
var anchor := Vector3.ZERO
var thrashing := false

var _time := 0.0

@onready var _bite_mark: Label3D = $BiteMark
@onready var _ripple: MeshInstance3D = $Ripple


func _ready() -> void:
	mode = Mode.HIDDEN
	_ripple.visible = false


func cast(from: Vector3, to: Vector3, duration: float) -> void:
	anchor = to
	mode = Mode.FLYING
	var arc_height := from.distance_to(to) * 0.35
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		global_position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * arc_height,
		0.0, 1.0, duration)
	tween.finished.connect(func() -> void:
		mode = Mode.FLOATING
		splash()
		landed.emit())


func retract() -> void:
	mode = Mode.HIDDEN


## Круги на воде — при приводнении и рывках рыбы.
func splash() -> void:
	_ripple.visible = true
	_ripple.global_position = Vector3(global_position.x, anchor.y + 0.02, global_position.z)
	_ripple.scale = Vector3.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(_ripple, "scale", Vector3.ONE * 2.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_ripple.hide)


func _process(delta: float) -> void:
	_time += delta
	match mode:
		Mode.FLOATING:
			global_position = anchor + Vector3.UP * sin(_time * 2.5) * 0.04
		Mode.BITE:
			global_position = anchor + Vector3.DOWN * 0.18 + Vector3.UP * sin(_time * 30.0) * 0.04
		Mode.FIGHT:
			var shake := 0.12 if thrashing else 0.02
			global_position = anchor + Vector3.DOWN * 0.1 \
					+ Vector3(randf_range(-shake, shake), 0.0, randf_range(-shake, shake))
