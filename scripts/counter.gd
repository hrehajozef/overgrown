class_name Counter
extends Interactable

# Display surface for finished bouquets. Customers auto-pick a matching one.

const VISUAL_HEIGHT := 110.0
const BODY_WIDTH := 50.0
const BODY_HEIGHT := 100.0
const MAX_DISPLAY := 4

var bouquets: Array = []
var visual_root: Node2D
var game

func _ready() -> void:
	radius = 50.0
	super._ready()
	add_solid_rect(Vector2(BODY_WIDTH, BODY_HEIGHT), Vector2.ZERO)
	visual_root = get_node_or_null("DisplayRoot") as Node2D
	if visual_root == null:
		push_error("Counter '%s' is missing DisplayRoot in the scene." % name)

func add_bouquet(bouquet: Array) -> void:
	if bouquets.size() >= MAX_DISPLAY:
		return
	var copy: Array = bouquet.duplicate()
	copy.sort()
	bouquets.append(copy)
	_refresh_display()
	_check_match()

func _refresh_display() -> void:
	if visual_root == null:
		return
	for child in visual_root.get_children():
		child.queue_free()
	for i in range(bouquets.size()):
		var bouquet: Array = bouquets[i]
		var y := -VISUAL_HEIGHT / 2.0 - 24 - i * 28
		var bg := make_rect(Vector2(64, 22), Color(0.95, 0.95, 0.95, 0.95), Vector2.ZERO)
		bg.position = Vector2(0, y)
		visual_root.add_child(bg)
		var x := 8.0
		for t in bouquet:
			var dot := make_circle(5, FlowerDB.TYPE_COLORS[t], 16)
			dot.position = Vector2(x, y + 11)
			visual_root.add_child(dot)
			x += 11.0

func customer_arrived() -> void:
	_check_match()

func _check_match() -> void:
	if game == null:
		return
	var searching := true
	while searching:
		searching = false
		for customer in game.customers:
			if not customer.is_waiting():
				continue
			for bouquet_index in range(bouquets.size()):
				if bouquets[bouquet_index] == customer.order:
					bouquets.remove_at(bouquet_index)
					game.add_money(_bouquet_price(customer.order))
					AudioManager.play_sfx("bouquet_sold")
					customer.serve()
					searching = true
					break
			if searching:
				break
	_refresh_display()

func _bouquet_price(bouquet: Array) -> int:
	var total := 3
	for t in bouquet:
		total += FlowerDB.PRICE[t]
	return total

func get_hint(_player) -> String:
	return ""
