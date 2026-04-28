class_name Counter
extends Interactable

# Display surface for finished bouquets. Customers auto-pick a matching one.

const MAX_DISPLAY := 6
var bouquets: Array = []  # Array of sorted Array[int]
var visual_root: Node2D
var game

func _ready() -> void:
	radius = 60.0
	super._ready()
	add_child(make_rect(Vector2(80, 240), Color(0.65, 0.45, 0.28), Vector2(-40, -120)))
	add_child(make_rect(Vector2(80, 8), Color(0.45, 0.30, 0.18), Vector2(-40, -120)))
	add_child(make_rect(Vector2(28, 22), Color(0.20, 0.20, 0.20), Vector2(-14, -104)))  # register
	add_child(make_rect(Vector2(20, 6), Color(0.85, 0.75, 0.20), Vector2(-10, -110)))
	add_child(make_label("Counter", Vector2(-50, -140), 100))
	visual_root = Node2D.new()
	add_child(visual_root)

func add_bouquet(bouquet: Array) -> void:
	if bouquets.size() >= MAX_DISPLAY:
		return
	var copy: Array = bouquet.duplicate()
	copy.sort()
	bouquets.append(copy)
	_refresh_display()
	_check_match()

func _refresh_display() -> void:
	for c in visual_root.get_children():
		c.queue_free()
	for i in bouquets.size():
		var b: Array = bouquets[i]
		var bx := -32
		var by := -90 + i * 38
		var bg := make_rect(Vector2(64, 32), Color(0, 0, 0, 0.25), Vector2(bx, by))
		visual_root.add_child(bg)
		var px: float = bx + 8
		for t in b:
			var dot := make_circle(6, FlowerDB.TYPE_COLORS[t], 16)
			dot.position = Vector2(px, by + 16)
			visual_root.add_child(dot)
			px += 13

func customer_arrived() -> void:
	_check_match()

func _check_match() -> void:
	if game == null:
		return
	var done := false
	while not done:
		done = true
		for c in game.customers:
			if not c.is_waiting():
				continue
			for j in range(bouquets.size()):
				if _arrays_equal(bouquets[j], c.order):
					bouquets.remove_at(j)
					game.add_money(_bouquet_price(c.order))
					c.serve()
					done = false
					break
			if not done:
				break
	_refresh_display()

func _arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true

func _bouquet_price(b: Array) -> int:
	var total := 3  # flat tip
	for t in b:
		total += FlowerDB.PRICE[t]
	return total

func get_hint(_player) -> String:
	return ""
