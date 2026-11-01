class_name CatchPopup
extends PanelContainer
## Карточка улова.

signal closed

@onready var _title: Label = %Title
@onready var _swatch: ColorRect = %Swatch
@onready var _name: Label = %FishName
@onready var _rarity: Label = %Rarity
@onready var _stats: Label = %Stats
@onready var _description: Label = %Description


func _ready() -> void:
	hide()
	%TakeButton.pressed.connect(close)


func open(fish: FishData, weight_kg: float, is_new: bool) -> void:
	_title.text = "Новый вид!" if is_new else "Улов!"
	_swatch.color = fish.color
	_name.text = fish.display_name
	_rarity.text = fish.rarity_name()
	_rarity.modulate = fish.rarity_color()
	_stats.text = "%.2f кг  ·  цена %d" % [weight_kg, fish.value_for(weight_kg)]
	_description.text = fish.description
	show()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 0.8
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if visible:
		hide()
		closed.emit()
