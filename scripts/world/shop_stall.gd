class_name ShopStall
extends Area3D
## Прилавок Луки: рядом доступны разговор, снасти и заказы соседей.

@export var hud: Hud


func _ready() -> void:
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))


func _on_body_changed(body: Node3D, nearby: bool) -> void:
	if body is Player:
		hud.set_shop_available(nearby)
