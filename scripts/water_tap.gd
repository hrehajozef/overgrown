class_name WaterTap
extends Interactable

func _ready() -> void:
	radius = 48.0
	super._ready()
	add_solid_rect(Vector2(62, 44), Vector2(0, -2))
	add_child(make_rect(Vector2(70, 50), Color(0.62, 0.62, 0.66), Vector2(-35, -25)))
	add_child(make_rect(Vector2(20, 30), Color(0.50, 0.50, 0.55), Vector2(-10, -55)))
	add_child(make_rect(Vector2(40, 8), Color(0.40, 0.40, 0.45), Vector2(-20, -28)))
	add_child(make_label("Water tap", Vector2(-40, -76), 80))

func continuous_action(player, delta: float) -> void:
	player.add_water(Player.CAN_REFILL_RATE * delta)

func get_hint(player) -> String:
	if player.water < Player.CAN_CAPACITY:
		return "[Hold F] Refill watering can"
	return "Watering can is full"
