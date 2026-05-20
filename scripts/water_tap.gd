class_name WaterTap
extends Interactable

const WATER_TAP_ICON := preload("res://assets/water_tap_icon.png")
var icon_sprite: Sprite2D

func _ready() -> void:
	radius = 48.0
	super._ready()
	add_solid_rect(Vector2(62, 44), Vector2(0, -2))
	if get_node_or_null("TapLabel") == null:
		push_error("WaterTap '%s' is missing visual children in the scene." % name)
	_add_icon()

func _add_icon() -> void:
	# Render the placeholder water tap icon in the center of the square, tinted
	# black-on-color so it pops against the inner colored panel.
	icon_sprite = Sprite2D.new()
	icon_sprite.texture = WATER_TAP_ICON
	icon_sprite.position = Vector2(0, 0)
	var tw: float = max(1.0, icon_sprite.texture.get_width())
	icon_sprite.scale = Vector2(36.0 / tw, 36.0 / tw)
	icon_sprite.modulate = Color(0.10, 0.10, 0.12, 0.95)
	icon_sprite.z_index = 1
	add_child(icon_sprite)

func continuous_action(player, delta: float) -> void:
	if player.water < Player.CAN_CAPACITY:
		player.add_water(Player.CAN_REFILL_RATE * delta)
		AudioManager.tick_water()

func get_hint(player) -> String:
	if player.water < Player.CAN_CAPACITY:
		return "[Hold F] Refill watering can"
	return "Watering can is full"
