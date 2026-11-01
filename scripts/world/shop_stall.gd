class_name ShopStall
extends Area3D
## Прилавок торговца снастями. Пока игрок рядом, в HUD доступен магазин.
## Позже здесь будет NPC с диалогом.

@export var hud: Hud


func _ready() -> void:
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))


func _on_body_changed(body: Node3D, nearby: bool) -> void:
	if body is Player:
		hud.set_shop_available(nearby)
