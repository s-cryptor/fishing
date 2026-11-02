class_name ShopStall
extends Area3D
## Прилавок Луки: рядом доступны разговор, снасти и заказы соседей.

@export var hud: Hud


func _ready() -> void:
	HarborProps.shop(self)
	for child in $Luka.get_children():
		if child is MeshInstance3D:
			child.hide()
	# Не прячем лицо под навесом: Лука стоит сбоку у ящика.
	$Luka.position = Vector3(-1.8, 0, -0.85)
	$Luka.add_child(NeighborModel.new())
	$Sign.hide()
	$Sign.modulate = Color("#f0e5c6")
	$Sign.outline_size = 4
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))


func _on_body_changed(body: Node3D, nearby: bool) -> void:
	if body is Player:
		$Sign.visible = nearby
		hud.set_shop_available(nearby)
