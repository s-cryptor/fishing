class_name MealData
extends Resource
## Рецепт и короткий походный эффект: тратятся только подходящие рыбы из садка.

enum Kind { SOUP, GRILLED }
@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var ingredient_label := ""
@export var ingredient_fish: StringName
@export var max_ingredient_rarity := FishData.Rarity.COMMON
@export_range(1, 10) var ingredient_count := 2
@export_range(1, 20) var charges := 5
@export var reel_speed_mult := 1.0
@export var luck_bonus := 0.0
@export var kind := Kind.SOUP


func effect_text() -> String:
	var effect := ""
	if reel_speed_mult > 1.0:
		effect = "Подмотка +%d%%" % roundi((reel_speed_mult - 1.0) * 100)
	if luck_bonus > 0.0:
		effect += (" · удача" if not effect.is_empty() else "Удача") + " +%d%%" % roundi(luck_bonus * 100)
	return "%s · %s" % [effect, casts_text(charges)]


static func casts_text(count: int) -> String:
	var word := "забросов"
	var n := absi(count)
	if n % 100 < 11 or n % 100 > 14:
		if n % 10 == 1:
			word = "заброс"
		elif n % 10 in [2, 3, 4]:
			word = "заброса"
	return "%d %s" % [count, word]
