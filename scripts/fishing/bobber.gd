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
var warning := false
var fish_size := 1.0
var heading := 0.0

var _time := 0.0
var _wake_time := 0.0
var _fx: FishingWaterFx

@onready var _bite_mark: Label3D = $BiteMark


func _ready() -> void:
	mode = Mode.HIDDEN
	_fx = FishingWaterFx.new()
	add_child(_fx)


func cast(from: Vector3, to: Vector3, duration: float) -> void:
	_fx.reset()
	thrashing = false
	warning = false
	_wake_time = 0.0
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
	_fx.reset()


## Круги на воде — при приводнении и рывках рыбы.
func splash() -> void:
	_fx.splash(Vector3(global_position.x, anchor.y, global_position.z))


func _process(delta: float) -> void:
	_time += delta
	_wake_time += delta
	if mode in [Mode.FLOATING, Mode.BITE, Mode.FIGHT] and _wake_time > (0.22 if thrashing else 0.9):
		_wake_time = 0.0
		_fx.ripple(anchor, 0.7 if mode == Mode.FLOATING else 1.0)
	match mode:
		Mode.FLOATING:
			global_position = anchor + Vector3.UP * sin(_time * 2.5) * 0.04
		Mode.BITE:
			global_position = anchor + Vector3.DOWN * 0.18 + Vector3.UP * sin(_time * 30.0) * 0.04
		Mode.FIGHT:
			var shake := 0.12 if thrashing else (0.06 if warning else 0.02)
			global_position = anchor + Vector3.DOWN * 0.1 \
					+ Vector3(sin(_time * 31) * shake, 0.0, cos(_time * 23) * shake)
			_fx.fish_at(anchor + Vector3(sin(_time * 3) * 0.25, 0, 0.2), heading + sin(_time * 5) * (0.5 if thrashing else 0.15), fish_size)
