class_name WaterTap
extends Interactable

func _ready() -> void:
	radius = 48.0
	super._ready()
	add_solid_rect(Vector2(62, 44), Vector2(0, -2))
	if not _has_baked_visuals():
		push_error("WaterTap '%s' is missing visual children in the scene." % name)

func _has_baked_visuals() -> bool:
	for child in get_children():
		if child is Label:
			return true
	return false

func continuous_action(player, delta: float) -> void:
	if player.water < Player.CAN_CAPACITY:
		player.add_water(Player.CAN_REFILL_RATE * delta)
		AudioManager.tick_water()

func get_hint(player) -> String:
	if player.water < Player.CAN_CAPACITY:
		return "[Hold F] Refill watering can"
	return "Watering can is full"
